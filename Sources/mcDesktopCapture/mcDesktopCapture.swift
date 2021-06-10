import AVFoundation
import CmcDesktopCapture
import Metal

struct mcDesktopCapture {
    var text = "Hello, World!"
}

@_cdecl("mcDesktopCapture_addOne")
public func mcDesktopCapture_addOne(_ src: Int64) -> Int64 {
    return src + 1
}

@_cdecl("mcDesktopCapture_startCapture")
public func mcDesktopCapture_startCapture() {
    DesktopCapture.shared?.stop()
    DesktopCapture.shared = nil
    DesktopCapture.shared = DesktopCapture()
    DesktopCapture.shared?.start()
}

@_cdecl("mcDesktopCapture_stopCapture")
public func mcDesktopCapture_stopCapture() {
    DesktopCapture.shared?.stop()
    DesktopCapture.shared = nil
}

@_cdecl("mcDesktopCapture_getCurrentFrame")
public func mcDesktopCapture_getCurrentFrame(_ width: UnsafeMutablePointer<Int64>,
                                             _ height: UnsafeMutablePointer<Int64>,
                                             _ texturePtr: UnsafeMutableRawPointer) {
    guard let texture = DesktopCapture.shared?.currentTexture else { return }
    width.initialize(to: Int64(texture.width))
    height.initialize(to: Int64(texture.height))
    let ptr: UnsafeMutablePointer<MTLTexture> = texturePtr.bindMemory(to: MTLTexture.self, capacity: 1)
    ptr.initialize(to: texture)
}

@_cdecl("mcDesktopCapture_getCurrentFrame2")
public func mcDesktopCapture_getCurrentFrame2(_ width: UnsafeMutablePointer<Int64>,
                                              _ height: UnsafeMutablePointer<Int64>) -> UnsafeMutableRawPointer? {
    guard let texture = DesktopCapture.shared?.currentTexture else { return nil }
    width.initialize(to: Int64(texture.width))
    height.initialize(to: Int64(texture.height))
    return Unmanaged.passRetained(texture).toOpaque()
}

@_cdecl("mcDesktopCapture_getCurrentFrame3")
public func mcDesktopCapture_getCurrentFrame3() -> FrameEntity {
    guard let texture = DesktopCapture.shared?.currentTexture else {
        let e = FrameEntity(width: -1, height: -1, texturePtr: nil)
        return e
    }
    let texturePtr = Unmanaged.passRetained(texture).toOpaque()
    let e = FrameEntity(width: texture.width, height: texture.height, texturePtr: texturePtr)
    return e
}

@_cdecl("mcDesktopCapture_clearFrame")
public func mcDesktopCapture_clearFrame(_ texturePtr: UnsafeMutableRawPointer) {
    _ = Unmanaged<MTLTexture>.fromOpaque(texturePtr).takeRetainedValue()
}

class DesktopCapture: NSObject {
    
    public static var shared: DesktopCapture? = nil
    
    public var currentTexture: MTLTexture? = nil
    
    private let captureSession = AVCaptureSession()
    private let videoQueue: DispatchQueue = DispatchQueue(label: "fuziki.factory.mcDesktopCapture.queue")
    private let mainQueue: DispatchQueue = DispatchQueue.main

    private let mtlDevice: MTLDevice = MTLCreateSystemDefaultDevice()!
    
    private var frameCount: Int = 0
    private let startDate: Date = Date()
    
    override init() {
        super.init()
        let displayID = CGDirectDisplayID(CGMainDisplayID())

        let input: AVCaptureScreenInput = AVCaptureScreenInput(displayID: displayID)!
        captureSession.addInput(input)
        
        
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoDataOutput)
    }
    
    public func start() {
        captureSession.startRunning()
    }
    
    public func stop() {
        captureSession.stopRunning()
    }
    
}

extension DesktopCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let timeInterval = Date().timeIntervalSince(startDate)
        frameCount += 1
        print("fps: \(Double(frameCount) / timeInterval)")
        
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        var textureCache : CVMetalTextureCache! = nil
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, mtlDevice, nil, &textureCache)
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        var imageTexture: CVMetalTexture! = nil

        _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache,
                                                      imageBuffer, nil, .bgra8Unorm_srgb,
                                                      width, height, 0, &imageTexture)
        
        let texture: MTLTexture = CVMetalTextureGetTexture(imageTexture)!
        mainQueue.async { [weak self] in
            self?.currentTexture = texture
        }
        
    }
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("drop frame")
    }
}
