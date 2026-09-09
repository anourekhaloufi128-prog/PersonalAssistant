# Personal Assistant

A production-ready, offline-first iOS app that combines **study planning**, **focus & screen-time blocking**, **wellness tracking**, **business CRM/finance**, **goal management**, and an **AI assistant** behind one "What should I do now?" dashboard.

Built with Swift, SwiftUI, SwiftData, WidgetKit, App Intents, FamilyControls/ManagedSettings, UserNotifications and HealthKit. Requires iOS 17+.

---

## Feature Map

| Area | Highlights |
| --- | --- |
| Dashboard | Priority engine recommends the single highest-value next action; generated daily plan; study/focus progress |
| Study | Subjects → Topics → Tasks; exams with countdown; spaced-repetition flashcards; quizzes; notes |
| Focus | Pomodoro timer with pause/resume, screen-time blocking (Screen Time API), app/website restrictions, emergency unlock |
| Wellness | Water, sleep, exercise, mood, habits (streaks), optional HealthKit sync |
| Business | Clients, leads with pipeline, projects, tasks, invoices, income/expenses, idea log |
| Goals | Outcomes with measurable milestones |
| AI assistant | Context-aware chat + validated actions (create/update/delete tasks, clients, notes…) with confirmation for destructive actions |
| Widget | "My Day" widget (small/medium/large + Lock Screen/accessory) powered by an app-group snapshot |
| Siri / Shortcuts | App Shortcuts: "What should I do now?", Start Focus, Add Task, Log Water, Show Business Tasks, Open Today Plan |
| Notifications | Study, focus, wellness, habit reminders (individual toggles) |
| Privacy & sync | Local-first with an encrypted optional Supabase sync layer; full data export; account deletion |

---

## Project Layout

```
PersonalAssistant/
├── App/                 # App entry, AppState, root ContentView, deep links
├── Core/                # Networking, SecureTokenStore (Keychain), config, notifications,
│                        # permissions, HealthKit, sync engine, widget snapshot writer
├── Domain/
│   ├── Models/          # All SwiftData @Model types
│   └── Services/        # PriorityEngine, StudyPlanner, Analytics services
├── Features/
│   ├── Dashboard/ Study/ Focus/ Blocking/ Wellness/ Business/
│   ├── Goals/ AI/ Settings/ Onboarding/ Calendar/
│   └── (…all feature views + view models)
├── Intents/             # AppIntents / Siri shortcuts provider
├── SharedUI/            # Reusable components, extensions, themed views
├── Tests/UnitTests/     # Unit + integration tests
├── Widgets/             # MyDayWidget (widget target) + shared WidgetSnapshot
└── Resources/           # Info.plist, entitlements, asset catalog,
                         # PrivacyInfo.xcprivacy, Widget plist, en/fr/ar localization
```

## Targets

- **PersonalAssistant** — the app (`com.anwar.personalassistant`)
- **PersonalAssistantWidgets** — the "My Day" widget extension
- **PersonalAssistantTests** — unit/integration tests
- **PersonalAssistantUITests** — UI test target (add your own tests)

App Group: `group.com.anwar.personalassistant`

---

## Getting Started

1. **Open the project**: `open PersonalAssistant.xcodeproj` (Xcode 15 or newer).
2. **Set your signing / team**: select the `PersonalAssistant` target → Signing & Capabilities → choose your Development Team. Both the app and widget target must share the same team.
3. **Bundle identifier**: change the bundle IDs (app + widget + tests) to something you own before building.
4. **Add the Screen Time capability**: Target → Signing & Capabilities → `+` → Screen Time. (Entitlements are already declared in `Resources/PersonalAssistant.entitlements`.)
5. **Add the HealthKit capability** for optional sleep/activity sync (entitlements already declared).
6. Build and run on a device or simulator.

### Screen Time setup

- Screen Time requires **User-Initiated Authorization**; the user must grant permission from Settings → Privacy & Security → Screen Time the first time the app opens. The app surfaces this via its permissions screen.
- To test blocking, install at least one app under your own Apple ID so it appears in the selection picker.
- Blocking is opt-in per policy and can be turned off at any time.

### Widgets

- Add the **My Day** widget from the widget gallery.
- Data flows from the app to the widget via the shared app group `UserDefaults(suiteName: "group.com.anwar.personalassistant")`; the app writes a JSON snapshot and reloads timelines whenever the today plan or task state changes.

### Siri Shortcuts

- Open the Shortcuts app → the actions appear under the Personal Assistant category:
  - *What should I do now?* (returns the next recommended action)
  - *Start Focus* (returns the session label)
  - *Add Task*, *Log Water*, *Show Business Tasks*, *Open Today Plan*

---

## Configuration (optional) — AI & Sync backends

The app is fully functional and private locally (**no backend required**). Cloud features are disabled by default.

- Set `AppConfiguration.isCloudSyncAvailable` to `true` to enable the sync UI.
- Provide values at runtime (NOT hard-coded):
  - `API_BASE_URL` — your backend entry point (already a placeholder: `https://api.your-domain.example`)
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY` — Supabase client settings
- **Never ship service-role keys or AI provider secrets in the app.** AI and server-side keys live only on your backend (`AIService` calls your endpoint, rate-limits per user, and validates responses).
- Review `Core/Sync/SyncEngine.swift` and `Core/Networking/APIClient.swift` before enabling.

---

## Privacy

- HealthKit data is only read when explicitly enabled and is used to display the user's own sleep/activity.
- Screen Time selections apply only with the user's consent and can be removed at any time.
- `PrivacyInfo.xcprivacy` documents the small set of data types the app collects (see `Resources/PrivacyInfo.xcprivacy`).
- No analytics/tracking SDKs are included; product analytics are optional and disabled by default.

---

## Testing

Run the test plan from Xcode:

- `CoreServiceTests`: priority engine, planner, analytics, keychain, sync, notifications, deep-link routing
- `ModelTests`: SwiftData model persistence and relationships
- `IntegrationTests`: end-to-end flows across services

## App Store preparation checklist

1. Set `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` for each target.
2. Upload a final `AppIcon.png` (1024×1024) into `Resources/Assets.xcassets/AppIcon.appiconset`.
3. Fill in the export compliance switch in `Resources/Info.plist` (`ITSAppUsesNonExemptEncryption = false`).
4. Write your privacy nutrition labels to match `PrivacyInfo.xcprivacy`.
5. Add your team and real bundle identifiers; remove the placeholder backend URLs if unused.
6. Consider optional paid plans (StoreKit) for AI quota / sync for your monetization strategy — none are implemented yet.

## Known limitations

- iOS **cannot** block arbitrary apps programmatically (Screen Time API limits): blocking is user-enabled via a Family Controls picker and includes a built-in explanation screen.
- HealthKit quantities (glasses of water) are estimates; the app maps plain numbers to HK units.
- Widget uses a snapshot strategy (app-group store); for richer widgets you may extend the schema to publish more fields.
- Built and verified structurally for Xcode 15+/iOS 17 using the bundled `.xcodeproj`; compile on a Mac before release.