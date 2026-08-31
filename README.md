# Copy Save

Press ⌘V. The image on your clipboard becomes a PNG on your Desktop.

That's the whole app. No Save dialog, no "where do you want this?", no format
picker, no menu bar icon, no preferences. One window, one keystroke, one file.
Roughly 130 lines of Swift, zero dependencies.

## Why

macOS makes you open Preview, paste, hit ⌘S, pick a folder, pick a format, and
confirm — six steps to get a screenshot out of a chat window and onto disk.
Copy Save is that flow collapsed into ⌘V.

## Install

Requires macOS 13 or later and the Swift toolchain from Xcode or the Command
Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/katsos/copy-save.git && cd copy-save && ./build.sh
```

This produces an ad-hoc signed `CopySave.app` next to the script. Move it to
`/Applications`, or symlink it so rebuilds are picked up automatically:

```sh
ln -s "$PWD/CopySave.app" /Applications/CopySave.app
```

A symlinked app generally isn't indexed by Spotlight. Launch it from Finder or
keep it in the Dock, which stores the resolved path and survives rebuilds.

## Use

1. Copy an image anywhere — screenshot, browser, Slack, Figma.
2. Focus the Copy Save window.
3. Press ⌘V.

Dragging an image, or an image file, onto the window does the same thing.

Files land on the Desktop as `Clipboard 2026-08-27 at 19.24.11.084.png`. The
millisecond stamp means nothing is ever overwritten.

## Notes

- The app is signed ad-hoc, so the first launch needs right-click → Open.
- macOS asks once for permission to write to the Desktop folder.
- Everything is re-encoded to PNG, including pasted JPEGs.

## License

MIT — see [LICENSE](LICENSE).
