<p align="center">
  <img src="docs/icon.png" width="128" alt="WinDummy icon">
</p>

<h1 align="center">WinDummy</h1>

<p align="center">
  For lost Windows people on Mac.
</p>

---

You switched to a Mac and you keep reaching for `Win+Shift+S` and `Win+V`. WinDummy is a tiny menu bar app that gives those habits back, one click or one hotkey away, and teaches you the Mac way while you use it.

<p align="center">
  <img src="docs/screenshot.png" width="420" alt="The WinDummy panel with clipboard history">
</p>

## What it does

| | On Windows | Here |
|---|---|---|
| **Snip an area** to the clipboard | `Win+Shift+S` | `⌃⌥⌘S` |
| **Copy a window** to the clipboard by clicking it | `Alt+PrtScn` | `⌃⌥⌘W` |
| **Clipboard history**: choose what to paste | `Win+V` | `⌃⌥⌘V` |

The hotkeys use the same letters as on Windows, combined with `⌃⌥⌘`: the three keys in the bottom-left corner of the keyboard.

Everything lives in one floating panel. Click the ⌘ icon in the menu bar, or press `⌃⌥⌘V` anywhere:

- **Quick actions** for snipping an area, copying a window, and opening the macOS screenshot and recording toolbar.
- **Clipboard** tab: the last 40 things you copied: text with its formatting, files from Finder, and the 5 latest images. Type to filter, choose with `↑` `↓` and press Return, or press `⌘1` to `⌘9`. Pin the clips you keep needing. Hold `⌥` to paste as plain text; for files that pastes their paths.
- **Characters** tab: where `@`, `|`, `\`, `{ }`, `[ ]`, `~` and about 30 other hard-to-find characters are on *your* keyboard layout, worked out from the layout itself, so it is right for Swedish, German, French and the rest. Click a character to type it, star the ones you use to keep them at the top.
- **Cheat sheet** tab: about 60 Windows shortcuts translated to their Mac equivalents. Search by the Windows keys (`Alt+Tab`) or by what you want to do (`rename`).

Clipboard history is kept in memory only and is gone when you quit; from the ⋯ menu you can also have clips forgotten after 15 minutes, an hour or 8 hours. The one exception is clips you pin: those are saved to `~/Library/Application Support/WinDummy/Pinned.plist` so they survive a restart. Entries that password managers mark as secret are never recorded.

## Download

Grab `WinDummy.zip` from the [latest release](../../releases/latest), unzip it and move `WinDummy.app` to `/Applications`.

The app is not notarized by Apple, so the first time macOS says it cannot check it for malicious software. Right-click the app, choose **Open**, then **Open** again. On newer macOS versions you may instead have to go to **System Settings → Privacy & Security** and click **Open Anyway**. After that it opens normally.

## Build and run

You need macOS 14 or later and the Xcode Command Line Tools. Full Xcode is not required.

```sh
xcode-select --install        # once, if you do not have the tools yet

git clone <this repository>
cd windummy
./scripts/build-app.sh --run
```

The app bundle ends up in `build/WinDummy.app`. Drag it to `/Applications` if you want to keep it, and turn on **Launch at login** from the ⋯ menu in the panel.

While developing you can also open `Package.swift` in Xcode, or run `swift run` from the terminal.

Run the tests with `swift test`. They use a private pasteboard, so they never touch your clipboard.

### Releases

Every push to `main` runs the tests and builds the app on GitHub (`.github/workflows/ci.yml`). To publish a release, push a version tag:

```sh
git tag v0.2.0
git push origin v0.2.0
```

`.github/workflows/release.yml` then builds the app with that version number and attaches `WinDummy.zip` to a new GitHub release.

## Permissions

macOS asks for these the first time they are needed.

| Permission | Why | Required? |
|---|---|---|
| Screen & System Audio Recording | Snipping an area or a window | For the snip actions |
| Accessibility | Pressing `⌘V` for you after you pick a clip, the way `Win+V` pastes | Optional. Without it the clip is put on the clipboard and you press `⌘V` yourself |
| Paste from other apps | Reading the clipboard to build the history. Newer macOS versions may ask | For clipboard history |

### Keeping permissions between builds

macOS ties these permissions to the app's signature. By default the build script signs the app ad hoc, and that signature changes with every build, so macOS treats each rebuild as a new app: snipping brings up the crosshair but nothing lands on the clipboard until you grant the permission again.

Create a signing certificate once and the problem goes away:

1. Open **Keychain Access**.
2. In the menu bar choose **Keychain Access → Certificate Assistant → Create a Certificate…**
3. Name it `WinDummy Dev`, set **Identity Type** to *Self-Signed Root* and **Certificate Type** to *Code Signing*, then click **Create**.

The build script finds a certificate with that name and uses it. The first time, macOS asks whether `codesign` may use the key; choose **Always Allow**. Grant the permissions once more after that build, and they stay.

If you have an Apple Developer identity you can use that instead:

```sh
CODESIGN_IDENTITY="Apple Development: you@example.com (TEAMID)" ./scripts/build-app.sh
```

If a permission is stuck, reset it and let macOS ask again:

```sh
tccutil reset ScreenCapture dev.windummy.app
tccutil reset Accessibility dev.windummy.app
```

## How it is built

Swift, with AppKit for the plumbing and SwiftUI for everything you see. No dependencies.

```
Sources/WinDummy/
├── main.swift                  Entry point (menu bar only, no Dock icon)
├── App/
│   ├── AppDelegate.swift       Menu bar icon, panel, hotkeys
│   ├── FloatingPanel.swift     A panel that takes focus without activating the app
│   ├── PanelModel.swift        UI state
│   └── HoverTracker.swift      Which row the pointer is over
├── Services/
│   ├── ClipboardStore.swift    Clipboard history
│   ├── HotKeyCenter.swift      Global hotkeys (Carbon)
│   ├── ScreenCapture.swift     Wraps the system `screencapture` tool
│   ├── KeyboardCharacters.swift Where each character is on the current layout, favourites
│   └── Paster.swift            Sends ⌘V, types characters
├── Data/
│   ├── CheatSheet.swift        The shortcut translations
│   └── Characters.swift        The characters in the Characters tab
└── Views/                      SwiftUI views
```

Two details worth knowing if you read the code:

- The panel is a **non-activating** `NSPanel`. It can take keyboard focus while the app you were working in stays the active app, which is why a paste lands exactly where your cursor was.
- Global hotkeys go through Carbon's `RegisterEventHotKey`. It is old, but it needs no Accessibility permission and it swallows the key press.
- The views use no `@State`. In recent SDKs it is a macro whose compiler plugin ships only with full Xcode, so view state lives in small observable objects instead. That keeps the project buildable with just the Command Line Tools.

## Add your own shortcuts

The cheat sheet is one plain Swift file, `Sources/WinDummy/Data/CheatSheet.swift`. Add a line and rebuild:

```swift
Shortcut("Lock the screen", win: "Win+L", mac: "⌃⌘Q"),
```

Corrections and additions are welcome, especially for non-US keyboard layouts.

## Ideas

- Configurable hotkeys
- More languages

## License

MIT. See [LICENSE](LICENSE).
