# SDD ledger — plan: docs/superpowers/plans/2026-11-14-osm-firebase-live-tracking.md

Pre-flight: Task 1 returns RideLocation coordinates consumed by Task 3 trip draft and Task 5 tracking map; use shared `RideLocation` model.
Pre-flight: Task 2 returns AppUser and Firebase bootstrap state consumed by Tasks 3-5; role and missing-config handling must be stable.
Pre-flight: Task 3 TripRepository status/stream APIs consumed by Tasks 4-5; Task 4 location service stream consumed by Task 5.
Ruling: Prior task changes are dirty in this worktree and define current baseline; preserve them, do not restore unrelated files or generated plugin registrants.
Ruling: Firebase CLI credentials/project provisioning unavailable locally; implement guarded initialization, setup docs, and emulator-ready rules, never claim live operation without user configuration.
Ruling: Driver role cannot be selected by public registration; new accounts get passenger role and trusted admin assigns driver because self-assigned driver accounts would bypass dispatch trust. Cost if wrong: team must provision approved drivers manually.
Task 1: complete (tests: map picker, passenger form, coordinate persistence passed)
Task 2: complete (tests: missing Firebase bootstrap and setup state passed; live auth awaits configured Firebase)
Task 3: complete (Trip serialization/unconfigured guard tests passed; Firestore Rules emulator validation blocked because Java not installed)
Task 4: complete (driver setup state and status timeline tested; GPS device permission/live Firestore require Firebase-configured device)
Task 5: complete (tracking stream UI implemented; live location not testable without Firebase/device)
Task 6: complete (verification: `flutter analyze` → no issues, `flutter test` → 16 passed, `flutter build apk --debug` → built APK, `git diff --check` → passed; emulator unavailable)
Final review: self-review (no subagent tool)
