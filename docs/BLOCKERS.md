# Current blockers

## Native signing and physical-device verification remain

**Evidence (2026-08-18):** this checkout now contains standard `android/` and
`ios/` host projects. A release Android APK built at
`build/app/outputs/flutter-apk/app-release.apk`, and an unsigned iOS release
app built at `build/ios/iphoneos/Runner.app`. iOS privacy declarations now
cover camera barcode/label capture and choosing progress/meal photos; the
Android release manifest includes the camera permission supplied by
`mobile_scanner`.

**Impact:** native code compiles, but it cannot ship to devices or app stores
until the app is signed with the correct Apple/Google identities and exercised
on physical devices. Browser responsive verification remains separate.

**Smallest decisions:** select the launch channel (web/PWA, Android, iOS, or
all three), then provide or authorize the associated signing and store-release
workflow. Do not treat an unsigned build as a distributable iOS app.

## User-owned visual verification

The user explicitly performs browser verification. Static widget coverage,
analyzer, test suite, and web/macOS builds are maintained by this task, but
interactive visual confirmation at mobile/tablet/desktop breakpoints remains
with the user.
