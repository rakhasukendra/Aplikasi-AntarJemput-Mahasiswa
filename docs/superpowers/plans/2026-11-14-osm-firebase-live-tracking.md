# OpenStreetMap and Firebase Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add interactive OpenStreetMap location picking and a passenger/driver trip flow with Firebase-backed live driver location, styled in navy blue and light surfaces.

**Architecture:** Use `flutter_map` and `latlong2` for map rendering and coordinate selection, `geolocator` for driver GPS, and Firebase Authentication/Cloud Firestore for identity, trip state, and location streams. Keep current passenger ride flow compatible through a repository boundary; when Firebase configuration is absent, show an explicit setup state and never label demo coordinates as live.

**Tech Stack:** Flutter/Dart, `flutter_map`, `latlong2`, `geolocator`, `firebase_core`, `firebase_auth`, `cloud_firestore`.

**Spec:** `docs/superpowers/specs/2026-11-14-osm-firebase-live-tracking-design.md`

## Global Constraints

- One Flutter app supports Passenger and Driver roles.
- OpenStreetMap tiles follow provider usage policy; production may require a hosted tile provider.
- Driver GPS is published only for an accepted active trip.
- Firestore Rules restrict trip and location access to involved users.
- Missing Firebase config must produce explicit setup UI, not fake live data.
- Navy is primary; light surfaces are neutral; green is reserved for active/success states.
- No credentials, test identities, names, avatars, or fake coordinates in production UI.

## Review Focus

- Location permission denied/permanently denied: explain why map centering/GPS publishing is unavailable and allow manual map selection where possible.
- Firebase config absent or initialization failure: app still builds and presents setup/error state, never says live.
- Driver disconnects or Firestore stream errors: passenger sees stale/disconnected state and last update time, not an active status.
- Trip is assigned to a different driver or passenger: Firestore Rules reject reads/writes.
- Driver ends or cancels trip: GPS stream stops and passenger sees terminal trip state.

---

### Task 1: Map selection and coordinate model

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/models/ride_location.dart`
- Create: `lib/widgets/location_picker_map.dart`
- Modify: `lib/screens/passenger/passenger_home_tab.dart`
- Test: `test/location_picker_map_test.dart`
- Test: `test/passenger_home_tab_test.dart`

**Interfaces:**
- Produces: `RideLocation({required double latitude, required double longitude, required String label})`; `LocationPickerMap(initialLocation, onLocationSelected)` returning a confirmed coordinate.
- Consumes: Existing two-step form and current textual location inputs.

- [ ] Add widget tests: opening picker exposes map controls; confirming returns the selected coordinate; cancel returns no value.
- [ ] Run targeted tests and verify they fail because map picker/model do not exist.
- [ ] Add `flutter_map`, `latlong2`, and `geolocator`; implement coordinate model and map picker with a centered movable pin and explicit confirmation.
- [ ] Add map-picker actions beside pickup and destination inputs; save both display label and coordinates in pending order state.
- [ ] Run map and passenger form tests; verify long labels and narrow viewport do not overflow.

### Task 2: Firebase bootstrap and authenticated roles

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Create: `lib/services/firebase_bootstrap.dart`
- Create: `lib/screens/auth/auth_gate.dart`
- Create: `lib/screens/auth/sign_in_screen.dart`
- Create: `lib/screens/auth/sign_up_screen.dart`
- Create: `lib/models/app_user.dart`
- Test: `test/auth_gate_test.dart`
- Docs: `firebase/SETUP.md`

**Interfaces:**
- Produces: bootstrap status `configured | unavailable | failed`; `AppUser(uid, role, displayName)`; authenticated route choice from stored role.
- Consumes: Firebase config supplied later by FlutterFire CLI; never requires committed credential file.

- [ ] Add tests for unavailable config, signed-out user, and user with passenger/driver roles.
- [ ] Run auth tests and observe expected failures before implementation.
- [ ] Add `firebase_core` and `firebase_auth`; initialize only when platform options exist, otherwise load explicit setup screen.
- [ ] Implement email/password sign-in and sign-up with role choice and clear validation/error copy.
- [ ] Add `firebase/SETUP.md` with FlutterFire CLI setup for Android/iOS and local run instructions.
- [ ] Run auth widget tests and `flutter analyze`.

### Task 3: Firestore trips and security rules

**Files:**
- Create: `lib/services/trip_repository.dart`
- Create: `lib/models/trip.dart`
- Create: `firebase/firestore.rules`
- Modify: `firebase/SETUP.md`
- Test: `test/trip_repository_test.dart`

**Interfaces:**
- Produces: `createTrip(TripDraft)`, `availableTrips()`, `watchTrip(tripId)`, `acceptTrip(tripId)`, `updateTripStatus(tripId, status)`.
- Trip fields: passengerId, driverId, status, pickup/destination lat-lng-label, passengerCount, createdAt, updatedAt.

- [ ] Test trip serialization, status transitions, and malformed/missing coordinates using repository fakes or Firestore emulator.
- [ ] Add tests first and verify RED.
- [ ] Implement Firestore repository and status transition validation; integrate passenger submit into trip creation.
- [ ] Add restrictive Firestore Rules: passenger reads own trips; driver reads available and assigned trips; only assigned driver changes operational status.
- [ ] Document Firebase Emulator rules tests and deploy command; verify repository tests.

### Task 4: Driver trip acceptance and GPS publishing

**Files:**
- Create: `lib/screens/driver/driver_shell.dart`
- Create: `lib/screens/driver/available_trips_screen.dart`
- Create: `lib/screens/driver/active_trip_screen.dart`
- Create: `lib/services/driver_location_service.dart`
- Modify: `lib/services/trip_repository.dart`
- Test: `test/driver_trip_flow_test.dart`

**Interfaces:**
- Produces: `Stream<DriverLocation> watchDriverLocation(tripId)` and `startPublishing(tripId)` / `stopPublishing()`.
- Consumes: authenticated `AppUser.role == driver`, `TripRepository.acceptTrip`, and permission state.

- [ ] Test driver can accept an available trip; non-driver cannot; GPS publishing starts only after accepted trip and stops at terminal status.
- [ ] Verify tests fail before implementation.
- [ ] Implement permission handling with denied/permanently-denied states and location stream throttled to meaningful movement/time intervals.
- [ ] Publish lat/lng/accuracy/heading/updatedAt/tripId under `drivers/{uid}/locations/current`; update Rules for owner write and assigned passenger read only.
- [ ] Add driver actions: accept, arrived, start trip, complete; verify state transitions and GPS stop behavior.
- [ ] Run driver flow tests; document required device location permissions.

### Task 5: Passenger live tracking and blue UI direction

**Files:**
- Create: `lib/screens/passenger/trip_tracking_screen.dart`
- Create: `lib/widgets/trip_status_timeline.dart`
- Modify: `lib/screens/passenger/ride_list_tab.dart`
- Modify: `lib/screens/passenger/passenger_shell.dart`
- Modify: `lib/main.dart`
- Test: `test/passenger_tracking_test.dart`
- Test: `test/theme_test.dart`

**Interfaces:**
- Consumes: `TripRepository.watchTrip`, `DriverLocationService.watchDriverLocation`, `RideLocation`, and authenticated passenger ID.
- Produces: map markers for pickup, destination, and current driver; status/timeline with connection and last-update state.

- [ ] Test loading, no driver location, live location, stale/error state, and completed trip state.
- [ ] Test theme uses navy primary and light background; verify contrast for primary controls.
- [ ] Implement tracking map and Firestore stream UI; only display “Live” when fresh snapshots arrive.
- [ ] Add route from passenger history to tracking screen and keep unavailable/error recovery visible.
- [ ] Apply navy theme to auth, passenger, and driver screens; use green only for active/success indicators.
- [ ] Run targeted tests and test narrow/mobile layout.

### Task 6: Integration verification and handoff

**Files:**
- Check: all files above.
- Update: `firebase/SETUP.md`

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze` and full `flutter test`.
- [ ] Run Firestore Rules tests against Firebase Emulator if emulator tooling is available; otherwise report exact unverified rules step.
- [ ] Verify app build without Firebase configuration and confirm explicit setup state appears.
- [ ] Verify Android/iOS permissions and OSM attribution are visible; check tile provider policy and no unauthorized high-volume tile usage.
- [ ] Inspect final diff and confirm no generated credential files or unrelated local changes entered the feature branch.
