//
//  mcDesktopCapture2.swift
//  
//
//  Created by fuziki on 2022/07/22.
//

import CmcDesktopCapture
import Metal
import ScreenCaptureKit

public struct WindowProperty: Codable {
    public struct Frame: Codable {
        public let width: Int
        public let height: Int
        public init(rect: CGRect) {
            self.width = Int(rect.width)
            self.height = Int(rect.height)
        }
    }
    public struct RunningApplication: Codable {
        public let applicationName: String
        public let bundleIdentifier: String
        public init(applicationName: String, bundleIdentifier: String) {
            self.applicationName = applicationName
            self.bundleIdentifier = bundleIdentifier
        }
    }
    public let windowID: UInt32
    public let title: String
    public let isOnScreen: Bool
    public let owningApplication: RunningApplication
    public let frame: Frame
    public init(windowID: UInt32,
                title: String,
                isOnScreen: Bool,
                owningApplication: RunningApplication,
                frame: Frame) {
        self.windowID = windowID
        self.title = title
        self.isOnScreen = isOnScreen
        self.owningApplication = owningApplication
        self.frame = frame
    }
}

public struct WindowList: Codable {
    public let count: Int
    public let windows: [WindowProperty]
}

public struct StartCaptureConfig: Codable {
    public let windowID: UInt32
    public let width: Int
    public let height: Int
    public let showsCursor: Bool
    public init(windowID: UInt32, width: Int, height: Int, showsCursor: Bool) {
        self.windowID = windowID
        self.width = width
        self.height = height
        self.showsCursor = showsCursor
    }
}

@_cdecl("mcDesktopCapture2_addTwo")
public func mcDesktopCapture2_addTwo(_ src: Int64) -> Int64 {
    return src + 2
}

@_cdecl("mcDesktopCapture2_init")
public func mcDesktopCapture2_init() -> UnsafePointer<CChar>? {
    let res: String
    if #available(macOS 12.3, *) {
        do {
            ScreenCapture.shared = try ScreenCapture("hogehoge")
            res = "completed"
        } catch let error {
            res = error.localizedDescription
        }
    } else {
        res = "mcDesktopCapture2 support macOS 12.3 +"
    }
    let ptr = (res as NSString).utf8String!
    return UnsafePointer(strdup(ptr))
}

@_cdecl("mcDesktopCapture2_destroy")
public func mcDesktopCapture2_destroy() {
    if #available(macOS 12.3, *) {
        ScreenCapture.shared?.destroy()
        ScreenCapture.shared = nil
    }
}

@_cdecl("mcDesktopCapture2_windows")
public func mcDesktopCapture2_windows() -> UnsafePointer<CChar>? {
    let res: WindowList
    if #available(macOS 12.3, *) {
        res = ScreenCapture.shared?.windows ?? WindowList(count: 0, windows: [])
    } else {
        res = WindowList(count: 0, windows: [])
    }
    let str = (try? JSONEncoder().encode(res)).flatMap { String(data: $0, encoding: .utf8) } ?? "unknown error"
    let ptr = (str as NSString).utf8String!
    return UnsafePointer(strdup(ptr))
}

@_cdecl("mcDesktopCapture2_startWithWindowID")
public func mcDesktopCapture2_startWithWindowID(_ config: UnsafePointer<CChar>?) {
    if #available(macOS 12.3, *) {
        guard let config = config,
              let data = String(cString: config).data(using: .utf8),
              let config = try? JSONDecoder().decode(StartCaptureConfig.self, from: data) else {
            return
        }        
        ScreenCapture.shared?.start(windowID: config.windowID, width: config.width, height: config.height, showsCursor: config.showsCursor)
    }
}

@_cdecl("mcDesktopCapture2_stop")
public func mcDesktopCapture2_stop() {
    if #available(macOS 12.3, *) {
        ScreenCapture.shared?.stop()
    }
}

@_cdecl("mcDesktopCapture2_getTexture")
public func mcDesktopCapture2_getTexture() -> FrameEntity {
    if #available(macOS 12.3, *) {
        return ScreenCapture.shared?.currentFrame ?? FrameEntity(width: -1, height: -1, texturePtr: nil)
    } else {
        return FrameEntity(width: -1, height: -1, texturePtr: nil)
    }
}

@available(macOS 12.3, *)
class ScreenCapture: NSObject {
    static var shared: ScreenCapture?

    public var currentTexture: MTLTexture?
    public var currentFrame: FrameEntity?

    private var currentShareableContent: SCShareableContent!
    private var stream: SCStream?

    // metal
    private let mtlDevice: MTLDevice = MTLCreateSystemDefaultDevice()!
    private var textureCache : CVMetalTextureCache! = nil
    private var commandQueue: MTLCommandQueue!

    convenience init(_: String) throws {
        self.init()
        let semaphore = DispatchSemaphore(value: 0)
        var content: SCShareableContent?
        var error: Error?
        SCShareableContent.getWithCompletionHandler { (c: SCShareableContent?, e: Error?) in
            content = c
            error = e
            semaphore.signal()
        }
        semaphore.wait()
        if let error = error {
            throw error
        }
        currentShareableContent = content

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, mtlDevice, nil, &textureCache)
        commandQueue = mtlDevice.makeCommandQueue()!
    }

    var windows: WindowList {
        let windows = currentShareableContent.windows.compactMap { (window: SCWindow) -> WindowProperty? in
            guard window.frame.width > 200, window.frame.height > 200 else { return nil }
            let owningApplication = window.owningApplication
                .map { WindowProperty.RunningApplication(applicationName: $0.applicationName, bundleIdentifier: $0.bundleIdentifier) } ??
                .init(applicationName: "no-app", bundleIdentifier: "no-app")
            let frame = WindowProperty.Frame(rect: window.frame)
            return WindowProperty(windowID: window.windowID,
                                  title: window.title ?? "no-title",
                                  isOnScreen: window.isOnScreen,
                                  owningApplication: owningApplication,
                                  frame: frame)
        }
        return .init(count: windows.count, windows: windows)
    }

    func destroy() {
        stop()
    }

    func start(windowID: CGWindowID, width: Int, height: Int, showsCursor: Bool) {
        guard let window = currentShareableContent.windows.first(where: { $0.windowID == windowID }) else { return }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.width = width
        configuration.height = height
        configuration.showsCursor = showsCursor
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        stream = SCStream(filter: filter,
                          configuration: configuration,
                          delegate: self)
        do {
            try stream?.addStreamOutput(self,
                                        type: .screen,
                                        sampleHandlerQueue: DispatchQueue.main)
        } catch let error {
            print("addStreamOutput error: \(error)")
            return
        }
        stream?.startCapture { (error: Error?) in
            if let error = error {
                print("stream.startCapture error: \(error)")
            }
        }
    }

    func stop() {
        stream?.stopCapture()
        currentFrame = nil
        currentTexture = nil
    }
}

@available(macOS 12.3, *)
extension ScreenCapture: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("error no imageBuffer")
            return
        }

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        print("captured width: \(width), height: \(height)")

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
}

@available(macOS 12.3, *)
extension ScreenCapture: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("SCStreamDelegate.didStopWithError: \(error)")
    }
}
