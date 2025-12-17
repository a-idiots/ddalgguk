# Verification Plan: Google Analytics

## Objective
Verify that Google Analytics is correctly integrated and tracking events.

## Verification Steps
1.  **Debug View Check**
    *   Run the app on a simulator or physical device (`flutter run`).
    *   Open the [Firebase Console](https://console.firebase.google.com/).
    *   Select your project.
    *   Go to **Analytics** -> **DebugView**.
    *   Navigate through the app (Splash -> Login -> Home -> etc.).
    *   **Expectation:** You should see `screen_view` events appearing in real-time in the DebugView timeline.

2.  **Navigation Tracking**
    *   Move between tabs (Calendar, Report, etc.).
    *   **Expectation:** Each route change should trigger a `screen_view` event with the `firebase_screen` parameter matching the route name or path (e.g., `/`, `/login`, `/splash`).

## Implementation Details
*   Added `firebase_analytics` dependency.
*   Added `FirebaseAnalyticsObserver` to `GoRouter` in `lib/core/router/app_router.dart`.
