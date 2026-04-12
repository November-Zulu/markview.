#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_NAME="MarkView"        # Swift Package target/executable name
DISPLAY_NAME="markview."      # User-facing app name
APP_BUNDLE="$PROJECT_DIR/build/$DISPLAY_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

CONFIG="${1:-release}"

echo "Building $DISPLAY_NAME ($CONFIG)..."
swift build -c "$CONFIG" --package-path "$PROJECT_DIR"

BUILD_DIR="$PROJECT_DIR/.build/arm64-apple-macosx/$CONFIG"
EXECUTABLE="$BUILD_DIR/$TARGET_NAME"
RESOURCE_BUNDLE="$BUILD_DIR/${TARGET_NAME}_${TARGET_NAME}.bundle"

if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: executable not found at $EXECUTABLE"
    exit 1
fi

# Clean previous build
rm -rf "$APP_BUNDLE"

# Create .app bundle structure
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

# Copy executable
cp "$EXECUTABLE" "$CONTENTS/MacOS/$TARGET_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Sources/$TARGET_NAME/Resources/Info.plist" "$CONTENTS/Info.plist"

# Copy icon
if [ -f "$PROJECT_DIR/assets/markview.icns" ]; then
    cp "$PROJECT_DIR/assets/markview.icns" "$CONTENTS/Resources/markview.icns"
fi

# Copy Swift Package resource bundle (needed for Bundle.main resource loading)
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$CONTENTS/Resources/"
fi

echo ""
echo "Built $APP_BUNDLE"
echo "To run:  open \"$APP_BUNDLE\""
