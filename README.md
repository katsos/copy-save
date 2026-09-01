# Copy Save

**Copy an image. Click the menu bar icon. It's a PNG on your Desktop.**

One click, from any app. No window, no dialog, no keyboard shortcut to learn.

<!-- Add a demo GIF here: copy a screenshot, click the icon, file appears. -->

| Getting a copied image onto disk | Steps |
| --- | --- |
| Preview: File → New from Clipboard, ⌘S, name it, pick a folder, pick a format, Save | 6 |
| Screenshot app: re-take the shot you already have, wait for the thumbnail, drag it out | 3–4 |
| Paste into Finder (macOS 14+): open a Finder window, focus it, ⌘V | 3 |
| **Copy Save** | **1** |

Copy Save has no window and no preferences, because there is nothing to
configure. It is one icon in the menu bar: click it, and whatever image is on
your clipboard becomes a timestamped PNG on your Desktop. The icon flashes a
checkmark to confirm.

95 lines of Swift. Zero dependencies. No global hotkey, so **no Accessibility
or Input Monitoring permission** — no prompt, nothing to grant, and nothing in
Copy Save that could observe a keystroke.

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

To have it there every time you log in, add it under System Settings → General
→ Login Items.

## Use

Copy an image anywhere — a screenshot, a browser, Slack, Figma — then click the
Copy Save icon in the menu bar.

Right-click or control-click the icon for the menu: Save Clipboard Image, Quit.

Files land on the Desktop as `Clipboard 2026-08-31 at 12.42.21.783.png`. The
millisecond stamp means nothing is ever overwritten.

## Notes

- The app is signed ad-hoc, so the first launch needs right-click → Open.
- macOS asks once for permission to write to the Desktop folder.
- There is no Dock icon and no window. Quit from the icon's menu.
- Everything is re-encoded to PNG, including pasted JPEGs.
- If there is no image on the clipboard, or the save fails, you get an alert
  saying why.

## License

MIT — see [LICENSE](LICENSE).
