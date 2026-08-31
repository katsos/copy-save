# Copy Save

**Copy an image. Press ⌘V. It's a PNG on your Desktop.**

Every other way of doing this on macOS costs four to six steps. Copy Save costs
one keystroke.

<!-- Add a demo GIF here: copy a screenshot, press ⌘V, file appears. -->

| Getting a copied image onto disk | Steps |
| --- | --- |
| Preview: File → New from Clipboard, ⌘S, name it, pick a folder, pick a format, Save | 6 |
| Screenshot app: re-take the shot you already have, wait for the thumbnail, drag it out | 3–4 |
| Paste into Finder (macOS 14+): ⌘V into a window you first have to open and focus | 2–3 |
| **Copy Save** | **1** |

No Save dialog. No "where do you want this?". No format picker. No
preferences, no accounts, no menu bar clutter. One window, one keystroke, one
file — about 140 lines of Swift and zero dependencies.

## Install

Requires macOS 13 or later and the Swift toolchain from Xcode or the Command
Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/katsos/copy-save.git && cd copy-save && ./build.sh
```

That produces an ad-hoc signed `CopySave.app` next to the script. Move it to
`/Applications`, or symlink it so rebuilds are picked up automatically:

```sh
ln -s "$PWD/CopySave.app" /Applications/CopySave.app
```

A symlinked app generally isn't indexed by Spotlight. Launch it from Finder or
keep it in the Dock, which stores the resolved path and survives rebuilds.

## Use

Copy an image anywhere — a screenshot, a browser, Slack, Figma — then press ⌘V
in the Copy Save window. Dragging an image, or an image file, onto the window
does the same thing.

Keep the window open on a second display or a corner of the screen and it is
genuinely a single keystroke away, all day.

Files land on the Desktop as `Clipboard 2026-08-31 at 12.42.21.783.png`. The
millisecond stamp means nothing is ever overwritten.

## Notes

- The app is signed ad-hoc, so the first launch needs right-click → Open.
- macOS asks once for permission to write to the Desktop folder.
- Everything is re-encoded to PNG, including pasted JPEGs.
- The window has to be focused for ⌘V to reach it. A system-wide hotkey is the
  obvious next step; see the issues.

## License

MIT — see [LICENSE](LICENSE).
