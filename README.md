# Copy Save

A tiny macOS app that saves the clipboard image to your Desktop when you press ⌘V.

No Save dialog, no format questions, no window chrome to fight. Copy an image
anywhere, focus the Copy Save window, press ⌘V, and a timestamped PNG lands on
the Desktop. Dragging an image or an image file onto the window works too.

## Build

Requires the Swift toolchain that ships with Xcode or the Command Line Tools.

```sh
./build.sh
```

This produces `CopySave.app` next to the script and signs it ad-hoc.

## Install

Copy the app into `/Applications`, or symlink it so rebuilds are picked up
automatically:

```sh
ln -s "$PWD/CopySave.app" /Applications/CopySave.app
```

A symlinked app is generally not indexed by Spotlight. Launch it from Finder or
keep it in the Dock, which stores the resolved path and survives rebuilds.

## Notes

- The app is signed ad-hoc, so the first launch needs right-click → Open.
- macOS asks once for permission to write to the Desktop folder.
- Files are named `Clipboard 2026-08-27 at 19.24.11.png`. Dropped files keep
  their original name plus a timestamp. Collisions get a `-2`, `-3` suffix, so
  nothing is ever overwritten.
