import Foundation
import ImageIO

// Encode the prepared PNG frames without changing their pixels. The longer
// neutral bookends are preview-only pauses; gameplay keeps its existing timing.
guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: swift encode_biscuit_wink_preview.swift FRAME_DIRECTORY OUTPUT.gif")
}
let frameDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let durations = [0.75, 0.12, 0.12, 0.13, 0.18, 0.10, 0.10, 0.85]
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, "com.compuserve.gif" as CFString, durations.count, nil) else {
    fatalError("Cannot create animation preview")
}
CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
for (index, duration) in durations.enumerated() {
    let frameURL = frameDirectory.appendingPathComponent(String(format: "frame_%02d.png", index + 1))
    guard let source = CGImageSourceCreateWithURL(frameURL as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("Missing preview frame: \(frameURL.path)")
    }
    let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: duration, kCGImagePropertyGIFUnclampedDelayTime: duration]] as CFDictionary
    CGImageDestinationAddImage(destination, image, properties)
}
guard CGImageDestinationFinalize(destination) else { fatalError("Cannot save animation preview") }
print("Saved animated preview: \(outputURL.path)")
