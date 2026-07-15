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
- Runtime: `lib/core/routing/deep_link_handler.dart` maps both the custom-scheme
  (`com.arasanmobiles.user://product/<id>`) and the https link to
  `/shop/product/<id>`.

> **Routing fix (commit `db928ef`)** — inbound links are also mapped inside
> go_router's `redirect` (`lib/core/routing/app_router.dart`), reusing
> `DeepLinkHandler.locationFor`. This is required because Flutter pushes the raw
> intent URI straight to go_router; without the redirect mapping the link landed
> on go_router's **"Page Not Found"** (`GoException: no routes for location`).
> Note `flutter_deeplinking_enabled=false` alone does **not** prevent this — the
> redirect mapping is the actual fix. Verified end-to-end on an emulator: the
> custom-scheme deep link now opens the product page.

## Deferred deep linking (app NOT installed → install → same product)

The "not installed" half is handled **natively on Android** via the Google Play
**Install Referrer** API — no Branch.io / third-party account, no data leaving
your infra (this is the "equivalent solution" the brief allows; it's how
Flipkart/Meesho do Android):

```
shared https link → website /product launcher → Play Store with
  ?referrer=product%3D<id>%26variant%3D<v> → user installs → FIRST launch:
  the app reads the referrer and opens /shop/product/<id> automatically.
```

- Web side: `web_landing/product.html` **and** the website route
  `src/routes/product/[...path]/+page.svelte` build the Play Store URL with the
  `referrer` param (`storeUrl()`).
- App side: `lib/core/routing/deferred_deep_link_handler.dart`
  (`DeferredDeepLinkHandler`) reads it once on first launch (guarded by a
  SharedPreferences flag) and routes to the product. Package:
  `play_install_referrer`.

> **iOS deferred linking is NOT covered** — Apple offers no free native install
> referrer. It requires Branch.io / AppsFlyer (their SDK + your Apple account).
> iOS **Universal Links** for *already-installed* users DO work once the AASA
> file below is hosted with your real Team ID.

## What YOU must do

### 1. Fill in the placeholders

**`assetlinks.json`** (Android) — ✅ **already filled** with the current signing
SHA-256 (`95:08:…:07`). This is the **debug** key, which `build.gradle` currently
also uses to sign **release** (`signingConfig = signingConfigs.getByName("debug")`),
so verified links work for the APKs you build today. When you publish on Google
Play, Google **re-signs** your app — add the **Play App Signing SHA-256**
(Play Console → App integrity → App signing) as a **second entry** in the
`sha256_cert_fingerprints` array, or verification breaks in production.

<details><summary>How to re-read a signing SHA-256</summary>

- Play (production): **Play Console → Test and release → App integrity → App
  signing** → copy the **SHA-256 certificate fingerprint**.
- Debug/local:
  ```
  keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  ```
  Copy the `SHA256:` line (colons optional — both accepted).
</details>

Old note (kept for reference):

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

### 2. Host them on arasanmobiles.in — ✅ files staged, you just DEPLOY

The website is the SvelteKit project `E:\Arasan mobiles\arasan-mobiles-website`
(Firebase Hosting, site `arasanmobiles`, project `curvegraph-pvt-ltd`). The
following have **already been staged there** for you:

- `static/.well-known/assetlinks.json` (real fingerprint) — served at
  `https://arasanmobiles.in/.well-known/assetlinks.json`.
- `static/.well-known/apple-app-site-association` (⚠️ still Team-ID placeholder) —
  served at `https://arasanmobiles.in/.well-known/apple-app-site-association`.
- `src/routes/product/[...path]/+page.svelte` (+ `+page.ts`) — the **launcher**
  route. Without this, `arasanmobiles.in/product/…/p/<id>` hit the SPA fallback
  and showed the homepage in the browser (the bug you saw). Now it opens the app
  or redirects to the Play Store **with the deferred referrer**.
- `firebase.json` — added the AASA `Content-Type: application/json` header.

`npm run build` was verified to succeed with these changes. **To go live:**

```
cd "E:\Arasan mobiles\arasan-mobiles-website"
firebase deploy --only hosting
```

(Firebase login/deploy is yours to run — it publishes to production.)

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
