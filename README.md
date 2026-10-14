# DrugRegister

An iOS app for the North Macedonia drug register. It reads the
[Drug Register API](https://drug-register-api.vercel.app/docs) and uses the same simple
architecture as the DemoShop app: features first, few layers, plain dependency injection.

## Run it

1. Open `DrugRegister.xcodeproj` in Xcode 16 or newer.
2. Open `DrugRegister/App/Secrets.swift` and paste your API token.
3. Pick an iOS 18.6+ simulator or device and press Run.
4. Run the tests with **⌘U**. They never touch the network.

The API needs `Authorization: Bearer <token>` on every call. The docs say the token is an
app ID and a quota key, not a secret. `Secrets.swift` is in `.gitignore` anyway.

## What the app does

Four tabs: **Search**, **My medicines**, **Favorites** and **Settings**.

- **Home**: large "Lekovi" title, search bar, recent searches as chips and quick filters
  (On prescription, Over the counter, Generics). Nothing is loaded until you type or filter.
- **Barcode scan**: scan the EAN barcode on the package (or type its number). One match
  opens the drug right away. Several matches show as a list under a "Barcode …" banner.
- **Search**: type a Latin or Cyrillic name or a generic name. The server does the matching
  (case and accent insensitive, best matches first). Results are cards, 20 per page. The next
  page loads when you scroll near the end.
- **Filters** (sheet): prescription type, product type, ATC group and "positive list only".
  The sheet edits a copy. Nothing changes until you tap Apply.
- **Detail**: overview card, prices, composition, dosage, manufacturer, authorization dates.
  The leaflet and SmPC buttons open the PDFs inside the app (PDFKit). They are read from the
  register's site into memory and never saved on the phone. Heart to save, share sends the
  official register link.
- **Favorites**: saved drugs, swipe to delete. They are full copies, so they open offline.
- **My medicines**: the packs you have at home. Add one from a drug's detail screen with the
  expiry date printed on the package (month and year, or an exact day), the number of packs,
  an optional opened date and a private note. The list groups them as expired, within 30 days,
  within 3 months and later, soonest first, with a summary at the top. Local reminders come
  30 days and 7 days before and on the expiry day. Stored with SwiftData on the device only.
  Note: the register's "decision valid until" date is not a package expiry date and is never
  used here.
- **Settings**: data source, last data update, a switch for expiry reminders, app version and
  the "not medical advice" note. When iOS blocks notifications, it links to iOS Settings.
- **Language**: Macedonian only, whatever the device language. Text is in
  `Resources/Localizable.xcstrings`. Dates, numbers and prices use `Locale.app` (`mk_MK`).

## Structure

```
DrugRegister/
├── App/
│   ├── DrugRegisterApp.swift     Builds the app, nothing else
│   ├── AppEnvironment.swift      Creates the API client, service and stores once
│   ├── RootView.swift            Tab bar, one navigation stack per tab
│   ├── Secrets.swift             Your API token (git-ignored)
│   └── Navigation/               AppTab, AppRoute, AppRouter
├── Core/
│   ├── Networking/               APIClient, APIRequest, APIError
│   ├── Extensions/               Date-only decoding and formatting
│   └── DesignSystem/             Spacing, fonts, colors, card style, TagBadge, Chip, ...
├── Features/
│   ├── Drugs/
│   │   ├── Models/               Drug, DrugPage, RegisterMeta, Dispensing, ProductType, ATCGroup
│   │   ├── DrugService.swift     Protocol, live version, endpoints
│   │   ├── DrugQuery.swift       Text + DrugFilters (no paging)
│   │   ├── DrugSearchViewModel   Debounce, paging, errors, recent searches
│   │   ├── DrugSearchView        Home and results
│   │   ├── DrugFilterSheet
│   │   ├── DrugDetailView
│   │   └── Components/           DrugRow, InfoCard
│   ├── Favorites/                FavoritesStore (JSON file), FavoritesView
│   ├── MyMedicines/
│   │   ├── Models/               CalendarDay, ExpiryDate, DrugSnapshot, Medicine, ExpiryGroup + rules
│   │   ├── Persistence/          MedicineRepository, SwiftData record and repository, in-memory one
│   │   ├── Reminders/            Reminder, ReminderPlanner, ReminderScheduler, notification scheduler
│   │   ├── Views/                List, row, form, saved drug screen
│   │   └── MedicineServices      Repository + scheduler + clock, shared by the screens
│   └── Settings/                 SettingsViewModel, SettingsView
└── Resources/                    Assets, Localizable.xcstrings
```

## What the API spec changed compared with DemoShop

| Spec says | What the app does |
| --- | --- |
| Bearer token on every call | `LiveAPIClient` adds it once. It is a plain value, so there is no login, no `SessionManager` and no `TokenStore`. |
| Error body `{ "error": { code, message } }` | `APIErrorBody` reads it. The message goes to the screen. |
| `429` with `Retry-After` | `APIError.rateLimited` shows "Try again in N seconds". |
| Unknown or repeated query parameters get `400` | `SearchDrugsRequest` only sends what is set, and never twice. |
| `q` must be 1 to 100 characters | The text is trimmed, cut at 100, and left out when empty. |
| Dates are `yyyy-MM-dd` | One decoder reads them as `Date` (midnight GMT). They are shown in GMT, so the day never moves. |
| Every key is present, empty values are `null` | Optional properties for the nullable fields. |
| Enums may grow | `Dispensing` and `ProductType` have an `unknown` case, so one new value cannot break a page. |
| `Cache-Control: private, max-age=300` | `URLSession` uses it, so repeating a search within 5 minutes is cheap. |
| Rate limit 120 per minute per IP | Debounce (300 ms) plus cancelling old requests keeps typing well below that. |

## How search works

1. `.task(id: viewModel.query)` runs again whenever the text or a filter changes. SwiftUI
   cancels the old run. An empty query shows the home screen and sends no request.
2. `reload()` waits 300 ms first. If the user types again, it is cancelled during the wait.
   That is the debounce.
3. Each search has a `generation` number. A slow answer from an old search is ignored.
4. Next pages use the query that produced the current list, not the text field.
5. After an error, rows do not trigger new requests by themselves. The user taps "Try Again".

## Not built on purpose

- **Full offline register.** Add a `DrugRepository` then. The API serves the whole
  register as one file (`/data/drug-register.json`, 7.7 MB, 0.9 MB gzipped, no token).
- **Refreshing all favorites at once.** `DrugService.drug(id:)` exists (My medicines uses it);
  favorites are still refreshed only when you open the same drug from search.
- **Dosage form and manufacturer filters.** The API cannot filter by them.
