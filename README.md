# Swift Mock Bank

A Flutter proof-of-concept banking app that looks like a mini digital bank, talks to a mock API, and stays friendly to new contributors.

## What You Can Do Here

- Log in with a mock account
- View a responsive dashboard (desktop + mobile layouts)
- See balances, transactions, and supported billers
- Open a customer profile screen
- Pull to refresh data
- Extend API + mapping logic cleanly

## Quick Start

### 1. Prerequisites

- Flutter SDK (stable)
- Dart SDK compatible with `sdk: ^3.10.8` (from `pubspec.yaml`)

Check your setup:

```bash
flutter --version
flutter doctor
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Backend expectation (important)

The app is wired to:

- `http://127.0.0.1:8001`

Configured in [`lib/main.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/main.dart).

Used endpoints:

- `GET /`
- `GET /balance/{accountId}`
- `GET /transactions/{userId}`
- `GET /supported-billers`
- `POST /internal/credit`
- `POST /transfer`

If the API is unavailable, the app still runs and uses graceful fallbacks for some sections (for example: fallback billers and default customer/account values).

### 4. Run the app

```bash
flutter run
```

## Architecture At A Glance

### Runtime flow

```text
LoginPage
  -> builds account identifier (e.g., "001" -> "BPI001")
  -> creates BankRepository
  -> navigates to HomePage

HomePage/ProfilePage
  -> call repository methods
  -> repository calls API services
  -> mapper layer converts raw API payloads to domain models
  -> UI renders typed models
```

### Layer map

- **UI Layer**
  - [`lib/login_page.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/login_page.dart)
  - [`lib/home_page.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/home_page.dart)
  - [`lib/profile_page.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/profile_page.dart)
- **Repository Layer**
  - [`lib/data/bank_repository.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/data/bank_repository.dart)
- **Service Layer**
  - [`lib/api/bpi_api_service.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/api/bpi_api_service.dart)
  - [`lib/api/biller_api_service.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/api/biller_api_service.dart)
- **Mapper Layer**
  - [`lib/data/mappers/bpi_api_mappers.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/data/mappers/bpi_api_mappers.dart)
  - [`lib/data/mappers/biller_api_mappers.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/data/mappers/biller_api_mappers.dart)
- **Domain Models**
  - [`lib/models.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/models.dart)
- **Shared Formatters**
  - [`lib/utils/app_formatters.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/utils/app_formatters.dart)

## Feature Guide (Concise + Specific)

### Login flow

- Entry route is `/` ([`LoginPage.routeName`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/login_page.dart)).
- User inputs account number + password.
- Account number is normalized to start with `BPI` in [`_buildIdentifier`](/Users/christian.r.lazatin/Documents/swift_mock_bank/lib/main.dart).
- Password currently validates non-empty only and is not sent to backend yet (POC behavior).

### Dashboard

Powered by `BankRepository.getDashboardData()`:

- Customer info
- Accounts + computed total balance
- Transaction history (sorted latest first)
- Supported billers list

UI behavior:

- `< 980px` width: mobile scaffold with AppBar + Drawer
- `>= 980px` width: desktop scaffold with persistent sidebar
- Pull-to-refresh reloads data
- Feature CTA buttons show POC snackbars (transfer, bills, card controls)

### Profile page

- Route: `/profile`
- Uses `BankRepository.getProfileData()`
- Shows:
  - customer identity summary
  - customer details (phone, address, age)
  - linked accounts list with formatted balances

### Error and fallback behavior

- API/service errors are caught in repository with logs.
- Fallbacks are returned so UI stays alive:
  - default customer/account when balance payload is missing
  - empty transactions when transaction payload fails
  - predefined billers when biller API fails/returns empty

## Design Language

This app uses a clean “serious banking app, but not scary” style:

- **Color direction**
  - Primary red: `#D32F2F` (BPI-style branding)
  - Light neutral app background: `#F6F7FB`
  - White cards with soft elevation and rounded corners
- **Layout behavior**
  - Responsive split: sidebar desktop, drawer mobile
  - Card-based content sections with consistent spacing
- **Typography and signals**
  - Material 3 typography
  - Bold balance values and clear credit/debit color cues
- **Micro-feedback**
  - Tooltips for affordance
  - Snackbars for not-yet-wired actions
  - Retry buttons and loading states for async calls

## Developer Workflow

### Static checks + tests

```bash
flutter analyze
flutter test
```

Main automated test:

- [`test/widget_test.dart`](/Users/christian.r.lazatin/Documents/swift_mock_bank/test/widget_test.dart): verifies login -> dashboard -> logout flow.

### Adding a new API-backed feature (recommended path)

1. Add/extend endpoint call in `lib/api/*_service.dart`.
2. Add mapper logic in `lib/data/mappers/*_mappers.dart`.
3. Expose data through `BankRepository`.
4. Render it in UI with existing typed models or add new model fields.
5. Add/extend widget test(s).

## Known POC Notes

- Base URL is hardcoded to localhost in `main.dart`.
- Auth is UI-only for now (no token/session flow).
- Some actions intentionally show placeholder snackbars until API wiring is added.

## TL;DR for New Devs

Run backend at `127.0.0.1:8001`, run `flutter pub get`, then `flutter run`, log in with any non-empty values, and start hacking from `BankRepository` + mapper layer if you want to add real banking behavior.
