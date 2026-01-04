#!/bin/bash

# Updated Flutter Path (Nested)
FLUTTER_BIN="/Users/nawazashraf/Documents/flutter/flutter/bin/flutter"
EMULATOR_ID="Pixel_4_API_31"

echo "🚀 Starting Candlestick Master..."

if [ ! -f "$FLUTTER_BIN" ]; then
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter not found."
        exit 1
    else
        FLUTTER_BIN="flutter"
    fi
fi

# Check for connected devices
DEVICES=$("$FLUTTER_BIN" devices | grep -v "connected" | grep -v "Chrome" | grep -v "macOS" | wc -l)

if [ $DEVICES -lt 2 ]; then
    echo "🔍 No mobile device found. Launching Emulator: $EMULATOR_ID..."
    "$FLUTTER_BIN" emulators --launch $EMULATOR_ID
    
    echo "⏳ Waiting for emulator to boot..."
    # Simple wait, in reality we'd poll adb but let's just give it a moment to invoke
    sleep 10
else
    echo "✅ Mobile device detected."
fi

echo "📦 Installing Dependencies..."
"$FLUTTER_BIN" pub get

echo "📱 Launching App..."
"$FLUTTER_BIN" run
