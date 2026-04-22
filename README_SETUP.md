# NurtureAI — Setup Checklist

## Create the Xcode project

1. Open Xcode → New Project → iOS → App
2. Product Name: `NurtureAI`
3. Bundle ID: `com.nurtureai.app`
4. Interface: SwiftUI | Lifecycle: SwiftUI App | Language: Swift
5. Storage: **None** (SwiftData is wired manually)
6. Save into this folder (replace the generated stub files)

## Add all source files

Drag the `NurtureAI/` source folder into the project navigator.
Drag the `NurtureAITests/` folder into the test target.

## Capabilities to enable

- Keychain Sharing (App Groups not needed)
- No other entitlements needed for Weeks 1–3

## Dev API Key

1. Run the app once
2. Go to Settings tab → paste your `sk-...` key
3. Tap "Save Key" — stored in Keychain, never in code

⚠️ Remove the API key field from SettingsView before any TestFlight build.

## Week 4 extension points

| Feature | Stub to replace | File |
|---|---|---|
| StoreKit 2 | `StubStoreKitService` | `Services/Stubs/StoreKitServiceProtocol.swift` |
| HealthKit | `StubHealthKitService` | `Services/Stubs/HealthKitServiceProtocol.swift` |
| Push notifications | `StubNotificationService` | `Services/Stubs/NotificationServiceProtocol.swift` |
| Sleep regression prediction | `StubPredictionService` | `Services/Stubs/PredictionServiceProtocol.swift` |
| Caregiver invites | `StubCaregiverService` | `Services/Stubs/CaregiverServiceProtocol.swift` |

Swap the concrete implementation in `DependencyContainer.swift`. No other files need changing.

## Run tests first

```
PatternServiceTests — run these before any UI work.
```

The pattern math feeds directly into every AI response.
All 16 tests should be green before touching the UI.
