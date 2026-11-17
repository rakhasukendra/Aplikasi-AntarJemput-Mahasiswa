# Firebase setup

Live booking and driver tracking require a Firebase project owned by the app team. No Firebase project or credentials are included in this repository.

## Configure Firebase

1. Create a Firebase project in the Firebase Console.
2. Enable **Authentication > Email/Password** and create a Cloud Firestore database.
3. Install Firebase CLI and FlutterFire CLI in your development environment.
4. From the repository root, authenticate and configure Android/iOS:

   ```powershell
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android,ios
   ```

5. Deploy initial Firestore rules to the same project:

   ```powershell
   firebase deploy --only firestore:rules --project=PROJECT_ID_DARI_FIREBASE
   ```

## Run with Chrome

Register a Web app in Firebase Console, then copy `apiKey`, `appId`,
`messagingSenderId`, `projectId`, `authDomain`, and `storageBucket` from its
Firebase SDK configuration. The first four values are required. These are
client configuration values, not service-account credentials.

Run from the repository root and replace each placeholder with the matching
value from your Firebase Web app:

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_ENABLED=true `
  --dart-define=FIREBASE_API_KEY=API_KEY_DARI_FIREBASE `
  --dart-define=FIREBASE_APP_ID=APP_ID_DARI_FIREBASE `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=SENDER_ID_DARI_FIREBASE `
  --dart-define=FIREBASE_PROJECT_ID=PROJECT_ID_DARI_FIREBASE `
  --dart-define=FIREBASE_AUTH_DOMAIN=AUTH_DOMAIN_DARI_FIREBASE `
  --dart-define=FIREBASE_STORAGE_BUCKET=STORAGE_BUCKET_DARI_FIREBASE
```

`FIREBASE_MEASUREMENT_ID` is optional. Do not add a service-account key to the
Flutter app.

## Run on Android/iOS

Configure native apps with FlutterFire, then run with Firebase initialization
enabled:

```powershell
flutter run --dart-define=FIREBASE_ENABLED=true
```

The native `google-services.json` / `GoogleService-Info.plist` supplies the
default options. Without Firebase configuration the app stays in local mode,
where bookings are not sent to drivers.

## Driver access

For demos, the sign-up form lets the user choose **Penumpang** or **Driver**, and the chosen role is written to `users/{uid}`.

This self-selected role is a demo convenience, not production security: any account can register as a driver. In production, restrict `role` in `firestore.rules` to `passenger` again and approve drivers from a trusted admin process/console by setting `users/{uid}` with `role: "driver"` and a display name.

## Exercise live tracking

1. Run the app with Firebase enabled and sign in as a passenger.
2. Create a booking after selecting both pickup and destination on the map. The tracking map opens and waits for a driver.
3. Sign in as an approved driver on a second device or browser session. Accept the request from **Perjalanan driver**.
4. Allow location access and enable GPS on the driver device. The driver screen publishes its position while the trip is accepted, arrived, or in progress.
5. The passenger map follows the driver's latest reported position. Use **Saya tiba di titik jemput**, **Mulai perjalanan**, and **Selesaikan perjalanan** from the driver screen to test status changes.

## OpenStreetMap

The app currently uses `https://tile.openstreetmap.org/{z}/{x}/{y}.png` and includes visible © OpenStreetMap attribution. Review https://operations.osmfoundation.org/policies/tiles before production. Standard OSM tiles are not an unrestricted production tile service; choose a tile provider and follow its terms for production traffic.

## Data paths

- `users/{uid}`: role and display name.
- `trips/{tripId}`: passenger, driver name/id, route coordinates/labels, passenger count, schedule, and trip status.
- `drivers/{uid}/locations/current`: latest coordinates, heading/accuracy, trip id, and server update timestamp.

Review `firestore.rules` and run emulator rule tests before deployment to production. The Flutter client cannot securely provision privileged driver accounts.
