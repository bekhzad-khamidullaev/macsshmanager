#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/assets"
OUTPUT_PATH="$OUTPUT_DIR/AppIcon.icns"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS only" >&2
  exit 1
fi

SOURCE_ICON=""
for candidate in \
  "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" \
  "/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns"
do
  if [[ -f "$candidate" ]]; then
    SOURCE_ICON="$candidate"
    break
  fi
done

if [[ -z "$SOURCE_ICON" ]]; then
  echo "Terminal icon not found" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BASE_ICONSET="$TMP_DIR/base.iconset"
RENDER_ICONSET="$TMP_DIR/render.iconset"
mkdir -p "$RENDER_ICONSET"

iconutil -c iconset "$SOURCE_ICON" -o "$BASE_ICONSET"

cat > "$TMP_DIR/render.swift" <<'SWIFT'
import AppKit
import Foundation

let fm = FileManager.default
let source = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let destination = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)

let files = try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "png" }

func symbolConfiguration(for size: CGFloat) -> NSImage.SymbolConfiguration {
    let pointSize = max(9, size * 0.16)
    return NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
}

for fileURL in files {
    guard let image = NSImage(contentsOf: fileURL),
          let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).max(by: {
              $0.pixelsWide * $0.pixelsHigh < $1.pixelsWide * $1.pixelsHigh
          }) else {
        continue
    }

    let size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    let canvas = NSImage(size: size)
    canvas.lockFocus()

    image.draw(in: NSRect(origin: .zero, size: size))

    let badgeSide = max(size.width * 0.36, 12)
    let badgeRect = NSRect(
        x: size.width - badgeSide - size.width * 0.08,
        y: size.height * 0.08,
        width: badgeSide,
        height: badgeSide
    )

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = max(1, size.width * 0.025)
    shadow.shadowOffset = NSSize(width: 0, height: -max(1, size.width * 0.01))
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.set()
    let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: badgeSide * 0.34, yRadius: badgeSide * 0.34)
    NSColor(calibratedRed: 0.13, green: 0.55, blue: 0.94, alpha: 0.96).setFill()
    badgePath.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    let strokePath = NSBezierPath(roundedRect: badgeRect.insetBy(dx: 0.75, dy: 0.75), xRadius: badgeSide * 0.30, yRadius: badgeSide * 0.30)
    NSColor.white.withAlphaComponent(0.28).setStroke()
    strokePath.lineWidth = max(1, size.width * 0.012)
    strokePath.stroke()
    NSGraphicsContext.restoreGraphicsState()

    if let symbol = NSImage(
        systemSymbolName: "network",
        accessibilityDescription: "SSH"
    )?.withSymbolConfiguration(symbolConfiguration(for: size.width)) {
        let symbolInset = badgeSide * 0.24
        let symbolRect = badgeRect.insetBy(dx: symbolInset, dy: symbolInset)
        symbol.draw(in: symbolRect)
    } else {
        let text = size.width >= 64 ? "SSH" : "S"
        let fontSize = size.width >= 64 ? badgeSide * 0.28 : badgeSide * 0.46
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        let textRect = NSRect(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributed.draw(in: textRect)
    }

    let dotSide = max(size.width * 0.08, 4)
    let dotRect = NSRect(
        x: badgeRect.minX - dotSide * 0.55,
        y: badgeRect.maxY - dotSide * 0.45,
        width: dotSide,
        height: dotSide
    )
    let dotPath = NSBezierPath(ovalIn: dotRect)
    NSColor(calibratedRed: 0.19, green: 0.84, blue: 0.68, alpha: 1).setFill()
    dotPath.fill()
    canvas.unlockFocus()

    guard let tiff = canvas.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        continue
    }

    try pngData.write(to: destination.appendingPathComponent(fileURL.lastPathComponent))
}
SWIFT

swift "$TMP_DIR/render.swift" "$BASE_ICONSET" "$RENDER_ICONSET"
iconutil -c icns "$RENDER_ICONSET" -o "$OUTPUT_PATH"

echo "Generated app icon: $OUTPUT_PATH"
