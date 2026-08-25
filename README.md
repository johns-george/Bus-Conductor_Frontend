# Bus Conductor

Premium Flutter bus ticketing app frontend. Fully mocked end-to-end flows, ready for backend integration.

## Getting started

1. Install Flutter (>= 3.19).
2. From the project root:
   ```bash
   flutter create .        # generate platform folders (android/ios/web) on first run
   flutter pub get
   flutter run
   ```

## Architecture

```
lib/
├── main.dart              app bootstrap
├── app.dart               MaterialApp + router wiring
├── core/
│   ├── theme/             colors, typography, spacing, theme
│   ├── router/            go_router config
│   ├── constants/
│   └── utils/
├── domain/
│   ├── entities/          strongly typed models
│   └── repositories/      pure interfaces (backend-agnostic)
├── data/
│   ├── mock/              seeded demo data
│   └── repositories/      mock implementations of domain interfaces
└── presentation/
    ├── providers/         Riverpod providers
    ├── widgets/           reusable design-system widgets
    └── features/          feature screens (splash, onboarding, search, results, ...)
```

State: `flutter_riverpod`. Navigation: `go_router`.

## Phase status

- [x] Phase 1 — architecture, design system, splash, onboarding, search, route results
- [ ] Phase 2 — route details, auth flows, main shell navigation
- [ ] Phase 3 — booking, payment, tickets, QR, transactions, profile

## Backend integration

All repositories are pure interfaces in `lib/domain/repositories/` with mock implementations in `lib/data/repositories/`. To plug in a real backend, implement the interfaces against your HTTP client and swap the providers in `lib/presentation/providers/repository_providers.dart`. Search for `// TODO(api):` markers across the codebase for integration points.
