# Linky

A small macOS menu bar app for quick-access links and files. Press a shortcut, pick what you need, copy or drag it wherever.

## Features

- **Global hotkey** — `⌘⇧L` by default, customizable
- **Links & files** — store URLs and file paths in one place
- **Copy to clipboard** — one click to copy any item
- **Drag & drop** — drag items out to Finder, browsers, or any app
- **Drop files in** — drag files from Finder into the window to add them
- **Search** — filter items by title, value, or category
- **Categories** — organize items into groups
- **Persistent** — everything is saved across restarts

## Install

Requires macOS 13+ and Swift 5.9+.

```bash
git clone https://github.com/VishiATChoudhary/linky.git
cd linky/Links
swift build -c release
```

### Create app bundle

```bash
mkdir -p Linky.app/Contents/MacOS
cp .build/release/Links Linky.app/Contents/MacOS/Linky
cat > Linky.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Linky</string>
    <key>CFBundleIdentifier</key><string>com.linky.app</string>
    <key>CFBundleExecutable</key><string>Linky</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
EOF
```

Move `Linky.app` to `/Applications` and add to Login Items to launch at startup.

### Run without app bundle

```bash
swift run Links
```

## Usage

1. Click the link icon in the menu bar or press `⌘⇧L`
2. Click `+` to add links or files (with optional category)
3. Click the copy icon to copy a value to clipboard
4. Drag the icon on any row to drag it into another app
5. Drag files from Finder into the window to add them
6. Click the gear icon to change the keyboard shortcut

## License

MIT
