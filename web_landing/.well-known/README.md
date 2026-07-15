# Verified App Links / Universal Links — `.well-known` files

These two files make the **shared https product link** open the app **directly**
(no browser bounce), when the app is installed:

```
https://arasanmobiles.in/product/<slug>/p/<id>?variant=<v>   ─▶  opens the app
```

The app side is already wired:
- Android: `android/app/src/main/AndroidManifest.xml` — verified intent-filter
  (`android:autoVerify="true"`, host `arasanmobiles.in`, pathPrefix `/product/`).
- iOS: `ios/Runner/Runner.entitlements` — `applinks:arasanmobiles.in`.
- Runtime: `lib/core/routing/deep_link_handler.dart` already maps the https link
  to `/shop/product/<id>`.

## What YOU must do

### 1. Fill in the placeholders

**`assetlinks.json`** (Android) — replace `REPLACE_WITH_PLAY_APP_SIGNING_SHA256`
with the app's **release signing SHA-256**:

- If you publish on Google Play: **Play Console → your app → Test and release →
  App integrity → App signing** → copy the **SHA-256 certificate fingerprint**.
  (Google re-signs your app, so this is the fingerprint that matters in
  production. Also add the **upload key** SHA-256 as a second entry so debug
  installs from your machine verify too — optional.)
- For local testing with a debug build, get the debug fingerprint:
  ```
  keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  ```
  Copy the `SHA256:` line, remove the colons or keep them — both accepted.

> NOTE: `android/app/build.gradle` currently signs release with the **debug key**
> (`signingConfig = signingConfigs.getByName("debug")`). For a real release you
> must add a proper release keystore, and the fingerprint above must match
> whatever signs the **installed** app.

**`apple-app-site-association`** (iOS) — replace `REPLACE_WITH_APPLE_TEAM_ID`
with your **Apple Developer Team ID** (10 chars, e.g. `A1B2C3D4E5`), found at
developer.apple.com → Membership. Also add the same Associated Domains capability
to the Runner target in Xcode (Signing & Capabilities) and set your Team ID there.

### 2. Host them on arasanmobiles.in

Both must be served over **https** at the domain root, under `/.well-known/`:

```
https://arasanmobiles.in/.well-known/assetlinks.json
https://arasanmobiles.in/.well-known/apple-app-site-association
```

- `apple-app-site-association` has **no file extension** and must be served with
  `Content-Type: application/json` (no redirects).
- The site is the SvelteKit project `E:\Arasan mobiles\arasan-mobiles-website`
  (Firebase Hosting). Copy this `.well-known/` folder into that project's static
  root (`static/.well-known/`) and deploy. For Firebase, add to `firebase.json`
  hosting so the AASA file gets the right content-type:
  ```json
  "headers": [
    {
      "source": "/.well-known/apple-app-site-association",
      "headers": [{ "key": "Content-Type", "value": "application/json" }]
    }
  ]
  ```

### 3. Verify

- Android: reinstall the app, then
  `adb shell pm get-app-links com.arasanmobiles.arasan_user` → should show
  `arasanmobiles.in: verified`. Or test: `adb shell am start -a android.intent.action.VIEW -d "https://arasanmobiles.in/product/x/p/123"`.
- iOS: test on a real device (Universal Links don't work in Simulator for pasted
  links); tap the link from Notes/Messages → app should open.
- Online checkers: Google's Statement List Generator/Tester, and Apple's AASA
  validator.

Until these files are hosted with the correct fingerprint/Team ID, the https link
keeps falling back to `web_landing/product.html` (the "Open in App" launcher) — so
nothing breaks in the meantime.
