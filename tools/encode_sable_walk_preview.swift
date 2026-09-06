import Foundation
import ImageIO

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: encode_sable_walk_preview.swift FRAME_DIRECTORY OUTPUT.gif")
}
let frameDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let durations = Array(repeating: 1.0 / 10.0, count: 12)
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, "com.compuserve.gif" as CFString, durations.count, nil) else {
    fatalError("Cannot create Sable walk preview")
}
CGImageDestinationSetProperties(
    destination,
    [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary
)
for (index, duration) in durations.enumerated() {
    let frameURL = frameDirectory.appendingPathComponent(
        String(format: "frame_%02d.png", index + 1)
    )
    guard
        let source = CGImageSourceCreateWithURL(frameURL as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        fatalError("Missing Sable preview frame: \(frameURL.path)")
    }
    let properties = [
        kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFDelayTime: duration,
            kCGImagePropertyGIFUnclampedDelayTime: duration
        ]
    ] as CFDictionary
    CGImageDestinationAddImage(destination, image, properties)
}
guard CGImageDestinationFinalize(destination) else {
    fatalError("Cannot save Sable walk preview")
}
print("Saved Sable animated preview: \(outputURL.path)")
