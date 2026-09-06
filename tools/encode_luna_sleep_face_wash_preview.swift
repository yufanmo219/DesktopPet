import Foundation
import ImageIO

// Encode prepared PNGs; longer endpoint holds only make the preview easier to
// inspect. The runtime uses the durations in PetAvatar.
guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: swift encode_luna_sleep_face_wash_preview.swift FRAME_DIRECTORY OUTPUT.gif")
}
let frameDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let durations = [0.80, 0.18, 0.16, 0.18, 0.22, 0.35, 0.30, 0.22, 0.18, 0.16, 0.18, 1.00]
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
