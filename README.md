# ThreadPOS

A boutique point-of-sale app for clothing stores, built with **Flutter**.

Warm cream & terracotta design, elegant serif typography, and a
role-aware workspace for **Sellers** and **Managers**.

[![CI](https://github.com/L3von36/threadpos-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/L3von36/threadpos-flutter/actions/workflows/ci.yml)

## Features

- **Workspace login** — pick Seller or Manager, sign in with any
  credentials (offline demo auth).
- **Sell** — product grid with categories & search, product detail
  bottom sheet (sizes, quantity), cart, payment (cash with change
  calculation, card, mobile) and a receipt screen.
- **Scan** — live barcode scanning via the camera
  (`mobile_scanner`) with graceful fallback on emulators, plus
  manual barcode/name lookup and "add missing product" flow.
- **Add** — new product intake form with barcode generator
  (Ethiopian 629 EAN prefix), categories, pricing and stock.
- **Stock** — inventory overview, low/out-of-stock filters and a
  restock dialog.
- **Sales** — seller view (shift target progress, payment mix,
  recent sales) and manager view (KPIs, hourly revenue chart,
  top products, control center).
- **Control center** — Employees & commissions, Branches with
  revenue targets, weekly Scheduling, seller Performance leaderboard.
- **Persistence** — catalog, sales history and session are stored
  locally with `SharedPreferences` (JSON).

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart 3) |
| State management | Provider + `ChangeNotifier` |
| Persistence | SharedPreferences (JSON) |
| Barcode scanning | mobile_scanner |
| Charts | Custom lightweight widgets |
| Images | Unsplash URLs with offline fallback |

## Getting started

```bash
flutter pub get
flutter run                # on a device or emulator
flutter test               # smoke tests
flutter build apk --release
```

## Releases

The APK is built automatically by GitHub Actions:

- **CI** (`.github/workflows/ci.yml`) runs analyze → test → build on
  every push to `main` and uploads the APK as an artifact.
- **Release** (`.github/workflows/release.yml`) builds and publishes
  a GitHub Release with the APK whenever a version tag is pushed:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## Project structure

```
lib/
├── main.dart               # bootstrap
├── app.dart                # MaterialApp + provider wiring
├── theme/app_theme.dart    # cream / terracotta / serif design system
├── models/models.dart      # Product, CartItem, Sale, Employee...
├── data/seed_data.dart     # demo catalog & analytics data
├── state/store.dart        # app state + persistence
├── utils/format.dart       # currency/time helpers
├── widgets/common.dart     # shared UI primitives
└── screens/
    ├── login_screen.dart
    ├── home_shell.dart     # 5-tab bottom navigation
    ├── sell/               # grid, detail sheet, cart, payment, success
    ├── scan/               # camera scan + manual fallback
    ├── add/                # product intake form
    ├── stock/              # inventory & restock
    ├── sales/              # seller/manager dashboards
    └── manager/            # control center modules
```

## Notes

- The release APK is signed with the debug key so it installs out of
  the box for testing; configure a proper keystore before shipping to
  production.
- Demo data (catalog & sales history) is generated on first launch.
- Product photos load from Unsplash; the UI falls back to a styled
  placeholder when offline.
