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

@_cdecl("mcDesktopCapture_displayList")
public func mcDesktopCapture_displayList() -> UnsafePointer<CChar>? {
    struct List: Codable {
        let list: [QuartzDisplayUtil.DisplayProperty]
    }
    let list = List(list: QuartzDisplayUtil.displayList)
    let data = try! JSONEncoder().encode(list)
    let str = String(data: data, encoding: .utf8)! as NSString
    let ptr = str.utf8String!
    return UnsafePointer(strdup(ptr))
}

@_cdecl("mcDesktopCapture_startCapture")
public func mcDesktopCapture_startCapture(displayID: CLong) {
    DesktopCapture.shared?.stop()
    DesktopCapture.shared = nil
    DesktopCapture.shared = DesktopCapture(displayID: displayID)
    DesktopCapture.shared?.start()
}

@_cdecl("mcDesktopCapture_stopCapture")
public func mcDesktopCapture_stopCapture() {
    DesktopCapture.shared?.stop()
    DesktopCapture.shared = nil
}

@_cdecl("mcDesktopCapture_getCurrentFrame")
public func mcDesktopCapture_getCurrentFrame() -> FrameEntity {
    DesktopCapture.shared?.currentFrame ?? FrameEntity(width: -1, height: -1, texturePtr: nil)
}

class DesktopCapture: NSObject {
    public static var shared: DesktopCapture? = nil

    public var currentTexture: MTLTexture?
    public var currentFrame: FrameEntity?

    // display capture
    private let captureSession = AVCaptureSession()
    private let videoQueue: DispatchQueue = DispatchQueue.main// (label: "fuziki.factory.mcDesktopCapture.queue")
    private let mainQueue: DispatchQueue = DispatchQueue.main

    // metal
    private let mtlDevice: MTLDevice = MTLCreateSystemDefaultDevice()!
    private var textureCache : CVMetalTextureCache! = nil
    private var commandQueue: MTLCommandQueue!

    // analytics
    private var frameCount: Int = 0
    private var startDate: Date = Date()

    init(displayID: CLong) {
        super.init()
        let displayID: CGDirectDisplayID = CGDirectDisplayID(displayID)

        print("displayID: \(displayID)")
        print("displayID: \(displayID), vendor: \(CGDisplayVendorNumber(displayID)), product: \(CGDisplayModelNumber(displayID)), serial: \(CGDisplaySerialNumber(displayID))")

        print("displayList: \(QuartzDisplayUtil.displayList)")

        guard CGDisplayIsActive(displayID) != 0 else { return }

        let input: AVCaptureScreenInput = AVCaptureScreenInput(displayID: displayID)!
        captureSession.addInput(input)

        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoDataOutput)

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, mtlDevice, nil, &textureCache)

        commandQueue = mtlDevice.makeCommandQueue()!
    }

    public func start() {
        captureSession.startRunning()
    }

    public func stop() {
        captureSession.stopRunning()
        currentTexture = nil
    }
}

extension DesktopCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let current = Date()
        let timeInterval = current.timeIntervalSince(startDate)
        frameCount += 1
        print("fps: \(timeInterval), \(Double(1) / timeInterval)")
        startDate = current

        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        var imageTexture: CVMetalTexture! = nil

        _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache,
                                                      imageBuffer, nil, .bgra8Unorm_srgb,
                                                      width, height, 0, &imageTexture)

        let texture: MTLTexture = CVMetalTextureGetTexture(imageTexture)!

        if currentTexture == nil {
            let texdescriptor = MTLTextureDescriptor
                .texture2DDescriptor(pixelFormat: texture.pixelFormat,
                                     width: texture.width,
                                     height: texture.height,
                                     mipmapped: false)
            texdescriptor.usage = .unknown
            currentTexture = mtlDevice.makeTexture(descriptor: texdescriptor)!
        }

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!

        blitEncoder.copy(from: texture,
                         sourceSlice: 0, sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSizeMake(texture.width, texture.height, texture.depth),
                         to: currentTexture!, destinationSlice: 0, destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if currentFrame == nil {
            let ptr = Unmanaged.passUnretained(currentTexture!).toOpaque()
            currentFrame = .init(width: width, height: height, texturePtr: ptr)
        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("drop frame")
    }
}
