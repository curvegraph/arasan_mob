# Product share → app launcher page

The **web** half of product deep-linking. When someone taps a shared product link,
this tiny page **opens the app on that exact product**, or — if the app isn't
installed — **sends them to the app store** to install it. No website/product page
is shown.

The Flutter app side (deep-link handling, native scheme registration, variant in
the share URL) is already implemented in the app repo.

## Flow

Shared link (from the app, `lib/core/utils/product_share_url.dart`):

```
https://arasanmobiles.in/product/<slug>/p/<id>?variant=<variantId>
```

```
tap link ─▶ arasanmobiles.in/product/...  ─▶ product.html (this launcher)
                                                 ├─ app installed     → opens app on the product
                                                 └─ app NOT installed → redirects to Play Store / App Store
```

The page reads `<id>` (segment after `/p/`) and `?variant=` from the URL and fires
`com.arasanmobiles.user://product/<id>?variant=<v>`. If the app doesn't take over
within ~1.5s, it redirects to the store. Buttons ("Open in App" / "Install the
App") are shown as a manual fallback.

## Prerequisites

1. **The app must be published** on the Play Store / App Store — otherwise there's
   nowhere to send users who don't have it. Set the URLs in `product.html` →
   `CONFIG`:
   - `PLAY_STORE_URL` (Android package `com.arasanmobiles.arasan_user` — already set)
   - `APP_STORE_URL` (iOS — fill in after publishing)
2. Keep `APP_SCHEME` as `com.arasanmobiles.user` (must match the app).

## Deploy to arasanmobiles.in (the marketing SvelteKit site)

`arasanmobiles.in` is the static SvelteKit marketing site in
`E:\Arasan mobiles\arasan-mobiles-website` (Firebase project `curvegraph-pvt-ltd`,
hosting site `arasanmobiles`).

1. Put the launcher where the site serves it. Two options:
   - **Static file:** copy `product.html` into that project's `static/` folder, and
     add a SvelteKit catch-all route (or a Firebase rewrite) so `/product/**`
     serves it; **or**
   - **SvelteKit route:** add a catch-all `src/routes/product/[...rest]/+page.svelte`
     that runs the same launcher logic (cleaner for that SvelteKit setup).
2. Add the rewrite from `firebase-hosting-snippet.json` if using the static-file
   route, **before** any catch-all rewrite. Don't replace the whole `firebase.json`.
3. `firebase login` (your account), then `firebase deploy --only hosting`.

> ⚠️ This deploys your live `arasanmobiles.in`. Don't overwrite the existing site —
> only add the page + rewrite.

## WhatsApp caveat
WhatsApp opens links in its **own in-app browser**, which often blocks the app
launch. The page detects this and shows a tip ("open in browser, then tap Open in
App"). For the most reliable "tap → app opens" you'd additionally set up **Android
App Links / iOS Universal Links** (verified `https`), which needs a
`/.well-known/assetlinks.json` (with the app's release SHA-256 signing fingerprint)
and `apple-app-site-association` hosted on the domain. Ask if you want that too.
