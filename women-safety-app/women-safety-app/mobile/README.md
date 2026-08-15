# mobile/ — Week 2 + Week 3 (Flutter)

This is the **Flutter/Dart** implementation of the app, replacing the earlier
native-Android (Kotlin) skeleton in `android-app/` (that folder can now be
considered legacy/reference — the team switched to Flutter for this app).

> **Important — same disclaimer as before:** this code was written directly
> as files, not built/run inside an actual Flutter environment (this
> sandbox has no Flutter/Dart SDK). It follows standard, well-established
> Flutter/Firebase/Google Maps patterns and passed basic sanity checks
> (balanced braces/parens, valid YAML), but **you must run `flutter pub
> get` and `flutter run` yourselves** and be ready to fix small issues —
> a version mismatch, a missing platform config — before it builds clean.
> Section 5 tells you exactly how to verify each part works.

## 1. What's new in this delivery

| Week | What was built |
|---|---|
| **Week 2** | Phone number + OTP login (no email/password), emergency contacts CRUD (Firestore), map screen showing current location |
| **Week 3** | **Safest route feature**: fetches 2-3 alternative walking routes, scores each using the Week 1 crime-data-pipeline's zone safety scores, ranks them, and displays all routes color-coded (green = safest, selected in purple, others dashed grey) with a bottom panel showing each route's distance, duration, and safety score |

## 2. Folder structure (only the parts this delivery adds/changes)

```
mobile/
├── pubspec.yaml                    <- added Firebase, Maps, Geolocator, http, csv deps
├── assets/
│   └── data/
│       └── nerul_zone_safety_scores.csv   <- copied from data-pipeline/ (Week 1 output)
└── lib/
    ├── main.dart                    <- Firebase init + auth-state routing
    ├── config.dart                  <- Google Maps/Directions API key placeholder
    ├── models/
    │   ├── contact.dart
    │   ├── safety_zone.dart          <- one row of the Week 1 CSV
    │   └── route_option.dart         <- one candidate route + its safety score
    ├── services/
    │   ├── auth_service.dart          <- Firebase Phone Auth (OTP)
    │   ├── contacts_service.dart      <- Firestore CRUD
    │   ├── directions_service.dart    <- Google Directions API, decodes polylines
    │   └── safety_score_service.dart  <- WEEK 3 CORE: scores & ranks routes
    └── screens/
        ├── phone_auth_screen.dart
        ├── otp_verify_screen.dart
        ├── home_screen.dart
        ├── contacts_screen.dart
        └── map_screen.dart            <- current location (Wk2) + safe route UI (Wk3)
```

Everything else in your `mobile/` folder (android/, ios/, web/, windows/,
linux/, macos/, test/, .idea/, etc.) is what `flutter create` already
generated — untouched by this delivery except for the manual config steps
in Section 3.

## 3. Required setup before this builds (do this yourselves)

### A. Install dependencies
```bash
cd mobile
flutter pub get
```

### B. Firebase project
1. [Firebase Console](https://console.firebase.google.com) → create a project (or reuse one from earlier)
2. **Recommended path:** install the FlutterFire CLI and let it configure everything automatically:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and wires up Android/iOS automatically. If you do this, update `main.dart`'s `Firebase.initializeApp()` to `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` and add `import 'firebase_options.dart';` at the top — FlutterFire's own setup docs show this exact snippet.
   - **Simpler alternative (Android-only, manual):** in Firebase Console, add an Android app with package name matching your `android/app/build.gradle` (`applicationId`), download `google-services.json`, place it at `android/app/google-services.json`. This works fine for a demo without the CLI, but you'll need to add the Google Services Gradle plugin manually (search "Add Firebase to Flutter app Android manual setup" if you go this route).
3. Firebase Console → **Authentication** → Sign-in method → enable **Phone**
4. Firebase Console → **Firestore Database** → Create database → start in **test mode** (tighten security rules before final submission — same rule as the Week 2 android-app README)

### C. Google Maps + Directions API key
1. [Google Cloud Console](https://console.cloud.google.com) → enable **Maps SDK for Android**, **Maps SDK for iOS** (if building for iOS), and **Directions API**
2. Create an API key
3. Paste it into **`lib/config.dart`** (replaces `YOUR_GOOGLE_MAPS_API_KEY_HERE`)
4. **Also** paste it into `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_KEY_HERE" />
   ```
5. Add these permissions in the same `AndroidManifest.xml` (above the `<application>` tag):
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.SEND_SMS" />
   <uses-permission android:name="android.permission.CALL_PHONE" />
   ```
   (SEND_SMS and CALL_PHONE are declared now so the manifest doesn't need touching again in Week 4's volume-button SOS feature.)
6. **Directions API requires billing enabled** on the Google Cloud project (free quota is generous, a student project won't exceed it). Without it, route search will simply show "Could not find a route" — the current-location display still works fine without it.

### D. iOS only (skip if you're only building/demoing for Android)
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show it on the map and suggest safe routes.</string>
```
And add the Maps API key in `ios/Runner/AppDelegate.swift` per the `google_maps_flutter` package's setup docs.

## 4. How Week 3's safety scoring actually works

This is the part your teacher will want explained clearly:

1. `DirectionsService.fetchRouteAlternatives()` calls Google Directions API with `alternatives=true`, getting back 2-3 different walking routes as encoded polylines, which get decoded into lists of lat/lng points.
2. `SafetyScoreService.loadZones()` reads `assets/data/nerul_zone_safety_scores.csv` — the exact same 236-zone output your Week 1 Python pipeline generated — bundled straight into the app so scoring works offline, no server round-trip needed.
3. `SafetyScoreService.scoreRoute()` samples up to ~30 points along a route's path. For each sampled point, it finds the **nearest** scored zone (simple nearest-center comparison — 236 zones is small enough that this is fast without needing a spatial index).
4. The route's overall safety score = the **average** of its sampled points' zone scores.
5. `scoreAndRankRoutes()` sorts all candidate routes **safest-first**.
6. `MapScreen` draws every route on the map (safest highlighted, others dashed) and shows a bottom panel listing each route's distance, duration, and safety score — so the safest recommendation is explainable, not a black box.

This directly reuses the exact algorithm and dataset from Week 1 — nothing about the scoring math changed, only that it now runs inside the Flutter app instead of a standalone Python script.

## 5. How to verify it works (you do this, since I can't run Flutter here)

1. `flutter pub get`, fix any dependency version conflicts Flutter reports
2. `flutter run` on an emulator or device
3. Sign up with your real phone number → confirm you receive an actual SMS with a 6-digit code → confirm Firestore Console shows a new `users/{uid}` document with your name
4. Add/edit/delete an emergency contact → confirm it updates instantly in Firestore Console
5. Open "Find Safe Route" → grant location permission → confirm your current location marker appears
6. Type a nearby destination (e.g. "Seawoods Grand Central, Nerul") → tap search → confirm 2-3 routes appear, color-coded, with the bottom panel showing different safety scores per route
7. Tap different routes in the bottom panel → confirm the map highlights the tapped one and re-centers

If step 6 shows "Could not find a route," that's most likely your Directions API key/billing — not a bug in the scoring logic itself. Everything up to that point (auth, contacts, current location) doesn't depend on the Directions API at all.

## 6. Known gaps to flag in your report (same spirit as Week 2)

- Firestore security rules still need tightening from test mode before final submission
- The safety-scoring "nearest zone" lookup is a simple linear scan — fine for 236 zones, but wouldn't scale directly to a full city without a proper spatial index (mention this as a known limitation if your evaluator asks about scalability)
- No offline caching of routes yet — if Directions API is unreachable, route search simply fails with a message, no cached fallback
