# UI audit follow-up - 2026-11-16

Scope: passenger booking and ride tracking in the provided worktree.

Design Read: mobile campus ride booking and tracking for students, map-led with the existing navy and green palette. ENERGY 2 / RHYTHM 2 / MOTION 1.

The user later asked to restore the previous blue theme. That direction supersedes the earlier recommendation to use green as the primary color.

## Approved findings

1. **PASS - R-02:** Replaced the em dash in the map instruction with a period.
2. **UPDATED - R-01/R-29:** Restored navy `#1E3A8A`, green `#78A632`, and the cool light background per the user's latest direction.
3. **PASS - R-05/R-20:** The booking map now fills the screen behind a draggable form panel, which groups the existing route and schedule controls without hiding the map entirely.
4. **PASS - R-05/R-20:** Tracking now uses a full-screen map with a draggable status and route panel. Firestore location updates move the map camera and update the driver marker. No ETA, driver photo, or contact details were added because the current data model does not provide them.

## Design reasons

- The navy palette preserves the earlier visual identity and follows the user's explicit preference.
- The booking sheet keeps the route form reachable while leaving the campus map as the focal point.
- The tracking sheet puts trip progress next to the live map; the camera follows the latest driver coordinates.
- Flutter's existing system sans typography remains in place for legibility. Map, location, flag, and motorcycle icons describe real controls or markers.
- The only motion is the user-controlled sheet drag and map recentering on a new location update.

## Delivery gate

### Hard gate

- R-02 PASS: Map prompt copy uses ordinary punctuation; no em dash remains in changed UI text.
- R-03 PASS: Booking and tracking widget tests use narrow 320px viewports and report no overflow.
- R-17 PASS: No invented metrics were added; step numbers correspond to the real booking flow.
- R-18 PASS: No testimonials or people images were added.
- R-23 PASS: No visual assets were created.
- R-24 PASS: Existing navigation destinations were not changed.
- R-25 PASS: Navy primary buttons use white text; body and muted text use dark colors on light surfaces.
- R-26 PASS: Booking controls retain their existing actions; the new tracking panel is draggable and location updates move the map.
- R-27 PASS: Existing loading, error, missing-location, stale-location, and terminal trip states remain visible.
- R-28 PASS: No FAQ was added.
- R-32 PASS: Existing Flutter form controls retain standard focus and keyboard behavior; no focus outline or semantics were removed.
- R-33 PASS: No source or CSS patching script was used.
- R-34 PASS: No theme toggle was added; the requested light theme remains consistent.
- R-35 PASS: Ran the app in Chrome. Widget tests exercised form validation, map picking, booking navigation, narrow layouts, tracking panel drag, and live driver marker/camera updates.
- R-36 PASS: No security, performance, or customer claims were added.
- R-37 PASS: The user supplied the visual direction and explicitly requested the blue palette.
- R-38 PASS: No driver profile, ETA, or other unsupported content was fabricated.

### Purpose gate

- R-01 PASS: Solid navy follows the user's stated preference; no gradient was introduced.
- R-04 PASS: Location, flag, and motorcycle icons identify map points and the driver.
- R-06 PASS: The existing system sans font remains for readable mobile controls.
- R-07 PASS: No decorative grid or pattern was added.
- R-08 PASS: No decorative button arrows were added.
- R-09 PASS: No decorative status badge was added.
- R-10 PASS: No glass effect was added.
- R-12 PASS: Sheet shadows distinguish controls from the map surface.
- R-13 PASS: No glow was added.
- R-14 PASS: No feature-card grid was added.
- R-19 PASS: Sheet dragging and map recentering serve direct interaction and tracking needs; no looped animation was added.
- R-22 PASS: No illustration was added.

### Liveliness

- Dials PASS: ENERGY 2 / RHYTHM 2 / MOTION 1 are stated above.
- Consistency PASS: The two screens share a map-led hierarchy and restrained motion.
- Focal point PASS: The map anchors booking and tracking.
- Whitespace PASS: The panels separate route controls and status from map content.
- Accent PASS: Navy marks primary actions; green retains a restrained secondary role.
- Identity motif PASS: Campus map, pickup and destination markers, and trip progress define the app's visual motif.
- Design Read PASS: The audience, page type, visual direction, and dials are stated above.

### Craftsmanship and quality locks

- C-1 PASS: Palette, panel, shadow, and icon choices have reasons above.
- C-2 PASS: No control was made decorative; the new sheet has a real drag behavior.
- C-3 PASS: Panels contain only booking or trip information used by those screens.
- C-4 PASS: Loading/error/empty states are preserved; booking and tracking pass narrow viewport tests.
- C-5 PASS: No claims or driver data were invented.
- R-05 PASS: Composition follows each task, booking on a map and progress in a tracking panel.
- R-11 PASS: Existing field and card radii remain varied by component.
- R-15 PASS: The primary booking action remains “Pesan jemput”.
- R-16 PASS: No marketing buzzwords were added.
- R-20 PASS: Navy, green accents, and campus map interactions retain the app's identity without copying Gojek assets.
- R-21 PASS: The light theme follows the user's reference and map readability.
- R-29 PASS: Navy and green are the two core colors; light surfaces are neutral.
- R-30 PASS: No Gojek logo, assets, or exact screen was copied.
- R-31 PASS: Major choices and their reasons are recorded above.

## Validation and limitation

- `flutter analyze`: passed with no issues.
- `flutter test`: all tests passed, including live location camera-follow coverage.
- `flutter run -d chrome`: running from the selected worktree. `flutter_map` prints its OpenStreetMap tile usage notice.
- Firebase is not configured in this Chrome run. The real-time UI was exercised with a test stream; end-to-end driver updates require Firebase configuration and an active driver location publisher.
- The Stitch URL returned only the app shell in this environment, so the supplied screenshots and the user's description were used as the visual reference.
