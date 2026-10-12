# BusMate (Bus Conductor) — Flutter App

Flutter client for **BusMate**, a smart transit ticketing system. Passengers search routes, book and pay for tickets and show a QR code; conductors scan tickets; admins manage the system.

- **Live app:** https://bus-conductor.netlify.app/
- **Backend repo (FastAPI):** https://github.com/johns-george/Bus-Conductor_Backend

## Features

- Onboarding, sign-up/login, Google sign-in, OTP and forgot/reset password
- Route search and results, route and bus details
- Booking stepper: passenger details, payment, ticket
- **QR tickets** for passengers and a **conductor scanner** to validate them
- Wallet, payment methods and transaction history
- Notifications, help and admin screens

## Architecture

Clean layering with a repository interface per feature, so the data source can be swapped (live API or in-memory mocks):

```
lib/
├── core/            theme, router (go_router), API client and config, utils
├── domain/          entities and repository interfaces
├── data/            API repositories (HTTP) and Google auth service
└── presentation/    feature screens, Riverpod controllers, shared widgets
```

State management: `flutter_riverpod` · Navigation: `go_router` · QR: `qr_flutter` · Auth: `google_sign_in`

## Run locally

Requires Flutter >= 3.19 and the [backend](https://github.com/johns-george/Bus-Conductor_Backend) running.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Useful flags:

| Flag | Purpose |
|---|---|
| `--dart-define=API_BASE_URL=<url>` | Backend URL (Android emulator: `http://10.0.2.2:8000`) |
| `--dart-define=USE_MOCKS=true` | Use in-memory mock repositories, no backend needed |
| `--dart-define=GOOGLE_CLIENT_ID=<id>` | Google OAuth web client ID |

## Web deployment

`vercel.json` builds the web app with `flutter build web --release`; the current production deployment is on Netlify.

## Author

Johns George (partner project; Flutter frontend by a teammate) · [LinkedIn](https://www.linkedin.com/in/johns-george-3568b8233/) · [GitHub](https://github.com/johns-george)
