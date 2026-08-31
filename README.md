# Copy Save

**Copy an image. Click the menu bar icon. It's a PNG on your Desktop.**

One click, from any app, with no window to open or focus. Every other way of
doing this on macOS costs three to six steps.

<!-- Add a demo GIF here: copy a screenshot, click the icon, file appears. -->

| Getting a copied image onto disk | Steps |
| --- | --- |
| Preview: File → New from Clipboard, ⌘S, name it, pick a folder, pick a format, Save | 6 |
| Screenshot app: re-take the shot you already have, wait for the thumbnail, drag it out | 3–4 |
| Paste into Finder (macOS 14+): open a Finder window, focus it, ⌘V | 3 |
| **Copy Save** | **1** |

No Save dialog. No "where do you want this?". No format picker. No
preferences, no accounts, no login item to configure. It sits in the menu bar
as a single icon so you can see it's ready — about 195 lines of Swift and zero
dependencies.

No global hotkey, which means **no Accessibility or Input Monitoring
permission** — no prompt, nothing to grant, and nothing in Copy Save that can
observe a keystroke you didn't aim at it.

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

Copy an image anywhere — a screenshot, a browser, Slack, Figma — then click the
Copy Save icon in the menu bar. The icon flashes a checkmark and the PNG is on
your Desktop.

Right-click or control-click the icon for the menu: Save Clipboard Image, Show
Window, Quit.

The window is optional. It shows what was saved last, accepts ⌘V, and takes
images dragged onto it.

Files land on the Desktop as `Clipboard 2026-08-31 at 12.42.21.783.png`. The
millisecond stamp means nothing is ever overwritten.

## Notes

- The app is signed ad-hoc, so the first launch needs right-click → Open.
- macOS asks once for permission to write to the Desktop folder.
- Copy Save lives in the menu bar and has no Dock icon. Quit it from the icon's
  menu, or press ⌘Q with its window focused.
- Everything is re-encoded to PNG, including pasted JPEGs.

## License

MIT — see [LICENSE](LICENSE).
