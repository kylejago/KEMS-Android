# KEMS Companion for Android

A dedicated Android companion for the Kyle Energy Management System. Home Assistant remains the backend and source of truth; this app provides a focused mobile dashboard, reports, alerts and safe KEMS controls.

## Included

- Home Assistant URL and Long-Lived Access Token setup
- Encrypted token storage on Android
- REST API connection testing and state/history retrieval
- WebSocket live state updates
- Live KEMS dashboard
- Octopus/Ohme-ready cards with graceful handling of unavailable solar/battery data
- 24-hour house-power report
- KEMS alert/entity feed
- Observe, Advise, Simulate and Live mode controls
- Home, Away and Holiday controls
- Live-control switch and confirmed emergency stop
- GitHub Actions APK builds and tagged GitHub Releases

## Upload to GitHub

1. Create a new public or private repository called `KEMS-Android`.
2. Upload every file and folder from this project to the repository root.
3. Commit to `main`.
4. Open **Actions → Build Android → Run workflow**.
5. Download `KEMS-Companion-APK` from the completed workflow.

The workflow generates the native Android host project, analyses and tests the code, and builds `app-release.apk`.

To publish a GitHub Release automatically, create and push a tag such as:

```bash
git tag v0.2.0
git push origin v0.2.0
```

## Connect the app

1. In Home Assistant, open your profile.
2. Create a Long-Lived Access Token.
3. Install the APK on Android.
4. Enter the externally reachable Home Assistant URL or local URL.
5. Paste the complete token.

The token is stored using Android encrypted storage. For access outside your home, use Home Assistant Cloud or a properly secured HTTPS reverse proxy. Do not expose an unprotected Home Assistant port directly to the internet.

## Entity contract

See [`docs/HOME_ASSISTANT_ENTITY_CONTRACT.md`](docs/HOME_ASSISTANT_ENTITY_CONTRACT.md). Entity IDs are centralised in `lib/models/entity_mapping.dart` and can be changed there until KEMS exposes the final standard entities.

## Development

With Flutter installed:

```bash
flutter create --platforms=android --org uk.co.kems --project-name kems_companion /tmp/kems_host
cp -R /tmp/kems_host/android ./android
flutter pub get
flutter analyze
flutter test
flutter run
```

## Current release boundary

Version 0.1 is a complete companion-app foundation and is ready to build and install. It uses Long-Lived Access Token login rather than Home Assistant's full native-app OAuth registration flow. Push notifications continue through the official Home Assistant Companion App (`notify.mobile_app_g1`, `notify.mobile_app_clair`) while this app shows KEMS alert entities.


## KEMS 0.6 integration compatibility

Version 0.2.0 is aligned with the current KEMS 0.6.0-alpha1 diagnostics and its Observe → Learn phase. The app is deliberately read-only until the Home Assistant integration exposes a documented control API. It supports live power, tariff, EV, learning, simulation, gas, whole-home, lifetime, ROI and data-quality entities.

## v1.0.0 Android networking rebuild

This release adds the Android `INTERNET` and `ACCESS_NETWORK_STATE` permissions to release builds and explicitly permits local cleartext HTTP connections for addresses such as `http://192.168.1.111:8123`.

It also adds:

- friendly connection and authentication errors;
- WebSocket readiness checks and automatic reconnect;
- REST refresh fallback;
- safer URL validation;
- automatic discovery of KEMS sensors and binary sensors;
- a CI manifest verification step so a release cannot silently omit network access.

## v1.0.2

- Fix Energy Flow screen syntax so Dart formatting and analysis can run.

## v1.4.0 interface

- **Live** contains the measured Home Assistant/KEMS data and a complete dynamic list of non-simulation KEMS entities.
- **Simulation** contains modelled battery, solar, grid, savings, ROI and proposal outputs, including a complete dynamic list of simulation-related KEMS entities.
- **Flow** switches between Live and Simulation data. Moving particles show direction; inactive paths stay dim, and particle speed rises with power.
- Startup now moves immediately into a full-screen Flutter splash while Home Assistant initialises. The native Android splash also uses a full-screen branded background on supported Android versions.

## Version 1.4.0

- Defaults new connections to `http://homeassistant.local:8123/` while keeping the server editable.
- Opens on Flow by default.
- Uses smooth travelling energy waves and branches EV demand from Home.
- Combines Live and Simulation under Data with a mode selector.
- Adds Live and Simulation selectors to Reports.
- Adds model/system context to data and reports.
- Clips and sizes report charts correctly.

### Version 1.4.0 flow intelligence

- Smoothly interpolates between Home Assistant power updates.
- Shows a live input-versus-use balance check.
- Adds tap-to-expand details for Solar, Grid, Home, Battery and EV.
- Displays source data age on every flow node.
- Adds a KEMS decision ribbon above the flow diagram.
