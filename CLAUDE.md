# DrugRegister

iOS app for the North Macedonia drug register. It is read-only. It reads the Drug Register API
(`https://drug-register-api.vercel.app`, spec in `api.yaml`) and shows drugs with search, filters and details.

Stack: SwiftUI, Swift 6 (strict concurrency), `@Observable`, async/await, Swift Testing. iOS 18.6+. No third-party packages.

## Building and testing

- Do not build the project, run the tests or run the app (no `xcodebuild`, no simulator, no Xcode tools). The developer does that.
- Still write and update tests with every change. Say in your summary which tests you added or changed, so the developer knows what to run.

- ## Architecture

Keep it simple. Add a layer only when it solves a problem the app has today.

```
View → ViewModel → Service → APIClient
```

- **Features first.** Code for one feature lives in `Features/<Name>/`. Code used by many features lives in `Core/`.
- **`App/`** only builds the app: `DrugRegisterApp`, `AppEnvironment`, `RootView`, navigation. No feature logic.
- **`AppEnvironment`** creates the dependencies once (API client, services). Pass them down through `init`. No singletons, no DI framework.
- **Views** hold UI logic only: small state, bindings, layout. No networking, no business rules.
- **View models** are `@MainActor @Observable final class`. They hold screen state and business logic. They never navigate. They call the router through the view.
- **Services** are structs. Add a protocol only when it helps tests or previews (`DrugService` does). Do not add a protocol "just in case".
- **Repositories only where there is local data.** `MedicineRepository` (SwiftData, in `Features/MyMedicines/Persistence`) stores My medicines. View models depend on the protocol only. `FavoritesStore` keeps saved drugs (full copies) in a JSON file. Add `DrugRepository` when the app keeps the whole register offline. The API serves it as one file at `/data/drug-register.json`.
- **`LiveAPIClient`** is the only code that uses `URLSession`. It is a `Sendable` struct, not `@MainActor`. Do not call `URLSession` anywhere else.
- **Navigation** goes through `AppRouter` and the `AppRoute` enum. The tab bar has Search, My medicines, Favorites and Settings. Search, My medicines and Favorites each have their own path in the router. Views call `router.showDrug(...)`, which pushes onto the current tab. They never edit a path themselves.
- **No view model** for a screen that only shows data it already has (`DrugDetailView`). Add one when the screen gets loading, validation or rules.
- **Models** match the API directly. Add a DTO and a mapper only when the API shape and the app need to differ.
- **Design system** in `Core/DesignSystem`: use `.padding(.spacingMedium)`, `.font(.appBody)`, `.foregroundStyle(.appAccent)`. No magic numbers or raw `.system(size:)` fonts. Add a token when a value appears twice.

## Concurrency

- Only UI state is `@MainActor`. Do not put services or the API client on the main actor.
- Shared mutable state that is not UI goes in an `actor`. No locks.
- Use `.task(id:)` for work that follows a value. SwiftUI cancels the old run. Treat `CancellationError` and `URLError.cancelled` as normal, not as errors to show.
- Guard against stale answers: check the `generation` after every `await` in search and paging code.
- Do not fix a Swift 6 warning with `@unchecked Sendable` or `nonisolated(unsafe)`. Find the real cause.

## API rules (from the spec)

- Every `/api/v1/*` call needs `Authorization: Bearer <token>`. `LiveAPIClient` adds it. Features never do.
- GET and HEAD only. Unknown or repeated query parameters get `400`, so only send what is set, never twice.
- `q` is 1 to 100 characters: trim it, cut it at 100, leave it out when empty. `limit` is 1 to 100. `page` is 1 to 10000.
- Error body: `{ "error": { "code", "message", "parameter"? } }`. `429` has a `Retry-After` header (seconds).
- Rate limit: 120 requests per minute per IP. Keep the 300 ms debounce and cancel old requests.
- Dates are `yyyy-MM-dd`. Decode with `JSONDecoder.api()`. Show with `dateOnlyFormatted` (GMT, so the day never shifts).
- Prices are MKD. Empty values are `null`, so the Swift property is optional.
- Enums can grow. Keep the `unknown` case in `Dispensing` and `ProductType`.
- PDF links point to the register's own site. We show them from there and never store or host them. The site sends them as `Content-Disposition: attachment`, so Safari would download them. `DocumentView` reads them into memory with `LiveAPIClient.data(from:)` (no token) and shows them with PDFKit.
- When the spec changes, update the models, `SearchDrugsRequest` and the decoding tests in the same change.

## Barcode scan

- `BarcodeScannerView` (VisionKit `DataScannerViewController`) reads EAN-13 and EAN-8. It is the only code that uses the camera.
- There is no scanner on the simulator or on older devices, and the user may deny the camera. The scan sheet always offers typing the number instead.
- Every `ean` goes through `EAN.normalized` (8 to 14 digits) before it is sent. A barcode search clears text and filters.
- One match opens the detail right away: the view model sets `scannedDrug` and the view navigates.

## My medicines

- The user's own packs at home, with the expiry date printed on the package. Local only: SwiftData, no account, no server.
- **`Drug.authorization.expiryDate` is the validity of the register decision, NOT a package expiry date.** Never use it, suggest it or show it as a package expiry. On the detail screen it is labeled "Decision valid until" and kept out of the overview.
- A saved medicine keeps a `DrugSnapshot` (id, names, strength, form, detail URL). Opening it loads fresh data with `DrugService.drug(id:)` and falls back to the snapshot when offline or when the register answers 404.
- Dates are `CalendarDay` (year, month, day), never a `Date`, so a time zone cannot move them. Month and year mean the last day of that month.
- Groups: expired (before today), within 30 days (today to today + 30, both included), within 3 months (calendar months), later. A pack is not expired on its expiry day.
- Time is injected: `MedicineServices.now` and `.calendar`. Grouping, labels and reminders never read the real clock. Tests use `Calendar.test` and a fixed `now`.
- Reminders go through the `ReminderScheduler` protocol. `ReminderPlanner` makes them: 30 days, 7 days and on the day, at the time set in Settings (`ReminderSettings.time`, 09:00 by default), the 64 soonest only (the iOS limit). Every change replaces all pending reminders with the new plan, and so does the app becoming active. Permission is asked on the first save, never at launch.
- The Settings switch (`ReminderSettings`, on by default) turns reminders off without iOS Settings. Off means `syncReminders` schedules nothing and no permission is asked.
- Notification text has only the drug name and the date. Notes are private: never log, print or put them in a notification.
- Show dates and facts only. No "safe to use" or similar. Keep the line "Check the package or ask a pharmacist." on the list.

## Medical data

- Show Macedonian text exactly as the API sends it. Do not translate, shorten, reformat or "fix" drug names, composition, dosage or warnings.
- Do not add medical advice, dosage tips or interaction claims. The app shows register data and links to the official documents.
- Keep the "not medical advice" note on the detail screen.

## Testing

- Swift Testing (`@Test`, `#expect`). No XCTest for new tests.
- No test touches the network. Use `StubDrugService` and the samples in `Drug+Samples.swift` (`#if DEBUG`).
- View models: test paging, query change, errors, cancellation and stale results.
- Networking: test URL, query items and headers with `makeURLRequest`. Test error reading with `LiveAPIClient.error(for:data:)`.
- Decoding: test with JSON in the same shape as the spec examples, including `null` values and an unknown enum value.
- Add a test with every bug fix.
- Never hardcode Macedonian UI text in a test. Build the expected value from the same catalog key: `String(localized: "The medicine could not be saved.")`. Then changing a translation never breaks a test. Text from the API or test data (drug names, notes) is fine as a literal.

## Code style

- Short, clear names. Small files. One main type per file.
- Plain comments that explain **why**, not what. No comment for obvious code.
- `private` by default. Use `internal` only when tests or other files need it.
- Previews live under `#if DEBUG` and use stubs. No network in previews.
- The app is Macedonian only, whatever the device language. Macedonian is the development language and the only one in the project.
- Screen text lives in `Resources/Localizable.xcstrings`. Keys in code are short English identifiers, values are Macedonian. Every new key needs a Macedonian value. Use `LocalizedStringKey` parameters or `String(localized:)`, never plain `String` for UI text. Do not build text from pieces.
- Format dates, numbers and prices with `Locale.app` (`mk_MK`). `RootView` sets it as the SwiftUI locale.
- iOS has no Macedonian system strings. Avoid views whose text comes from iOS (`EditButton`, `onDelete`, `ContentUnavailableView.search`). Use your own Macedonian labels instead.
- No force unwraps (`!`) in app code. The only accepted ones are fixed literal URLs and sample data.
- Do not add a dependency without asking.

## Git

- Commit messages and PR descriptions: plain, direct language. Short sentences. What changed and why.
- Keep commits small. One idea per commit.
- Never commit `Secrets.swift`, `xcuserdata/` or `DerivedData/`.

## Not built yet (add when needed)

- Full offline copy of the register (needs `DrugRepository`).
- Refreshing all favorites at once with `DrugService.drug(id:)`, and deep links.
- Dosage form and manufacturer filters. The API does not support them yet.
