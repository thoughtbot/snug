# Snug

A native macOS client for Google Meet. Snug opens your Meet links in a real Mac
app, with camera, microphone, native screen sharing, per-meeting windows, and
URL routing so meeting links open in Snug, while everything else goes to your
regular browser.

Built with SwiftUI and the macOS 26 `WebView`/`WebPage` API. Requires
**macOS 26 (Tahoe)** or later.

## Install (from a release DMG)

1. Open the DMG and drag **Snug** to Applications.
2. Launch Snug and sign in to Google.
   - If Google offers a passkey, choose **"Try another way"** and use your
     email + password (passkeys aren't currently supported).
   - Password managers also can't autofill yet. You'll need to copy/paste
     credentials.
3. On your first meeting, allow the **camera** and **microphone** access to
   Snug.

Optional, in **Snug → Settings**:
- Pick which browser receives non-Meet links.
- Click **"Use Snug for All Links…"** to make Snug your default browser —
  Meet links open in Snug, everything else forwards to the browser above.
- **"Hide my video tile once others join"** (on by default) minimizes your
  self-view automatically when a call starts.

You can also route links to Snug with [Choosy](https://choosy.app) or apps like
it, instead of making it the default browser.

## Build from source

Requires Xcode 26+.

```sh
make bootstrap   # installs XcodeGen; checks for the dev signing cert
./scripts/make-dev-cert.sh   # one-time: stable "Snug Dev" signing identity
make build && make run
make test
```

The stable self-signed cert keeps camera/mic permission grants across
rebuilds (ad-hoc signing would re-prompt every build).

## Release (signed + notarized DMG)

One-time setup:
1. Install a **Developer ID Application** certificate (Xcode → Settings →
   Accounts → Manage Certificates).
2. Create an **App Store Connect API key** (Users and Access → Integrations)
   and store it: `xcrun notarytool store-credentials snug-notary
   --key <AuthKey.p8> --key-id <KEY_ID> --issuer <ISSUER_ID>`

Then:

```sh
make release   # Release build → DMG → notarize → staple → verify
```

Release builds are placed in files like `dist/Snug-<version>.dmg`.

## Notes

- Meet sees Snug as Safari, so any Google Meet Safari-based limitations apply.
- Google Meet offers no API for controlling a call, so the features below reach
  into the page itself. They depend on Meet's own markup and key bindings rather
  than on anything supported, and can break when Meet changes. If one of them
  stops working, that's the first place to look:
  - **Menu items** don't call anything — they replay Meet's own keyboard
    shortcuts inside the page, so they inherit whatever Meet currently binds.
    **Help → Google Meet Keyboard Shortcuts** shows Meet's full list.
  - **Meeting → Microphone** takes its checkmark from Meet's on-screen mic
    button, which is what keeps it correct when you mute from the page rather
    than from the menu. Note that macOS reports the microphone as in use the
    whole time you're in a call, muted or not; that's Meet holding the
    capture open, and is unrelated to the menu's state.
  - **Self-view hiding** drives Meet's own UI (a port of
    [google-meet-hide-self](https://github.com/Cryptacular/google-meet-hide-self)).
