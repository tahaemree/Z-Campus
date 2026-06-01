# 🎓 Z Campus (Campus Online)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.10-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-Edge_Functions-43A047?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase" alt="Firebase">
</p>

## 📋 Overview

Z Campus is a production-ready, enterprise-grade Flutter application engineered for university campus management. It handles complex workflows including venue discovery, event management, real-time push notifications, and role-based administration. 

The architecture is built upon a secure Supabase backend with extensive Row-Level Security (RLS) policies, Riverpod for scalable state management, and Firebase Cloud Messaging (FCM) for reliable push infrastructure.

---

## ⚡ Core Capabilities

- **Secure Authentication:** Complete user profile management powered by Supabase Auth.
- **Location-Based Experiences:** Venue discovery, detail screens, favoriting, and coordinate-based mapping using `flutter_map`.
- **Event Management:** Create, view, and favorite events with geospatial venue attachments.
- **Role-Based Admin Panel:** Full control over permissions, venues, push notifications, and feedback.
- **Enterprise Push Notifications:** Integrated in-app notification center paired with an FCM push delivery pipeline.
- **Database Hardening:** Migration-based schema management with rigorous RLS and RPC (Remote Procedure Call) security policies.

---

## 🏗️ Technology Stack

- **Client Framework:** `Flutter` (Dart 3, Material UI)
- **State Management:** `flutter_riverpod`
- **Backend & Database:** `supabase_flutter` (Auth, Postgres DB, Storage, Edge Functions)
- **Push Infrastructure:** `firebase_core` & `firebase_messaging` (FCM)
- **Geospatial Processing:** `flutter_map` & `latlong2`

---

## 📂 Architecture Snapshot

```text
lib/
├── models/                   # Domain data models (Event, Venue, Admin)
├── providers/                # Riverpod state layer (Auth, Events, Venues)
├── services/                 # Supabase/Firebase business logic
├── screens/                  # Feature-based UI routing
├── widgets/                  # Reusable UI components
└── config/                   # Environment configuration overrides

supabase/
├── functions/                # Deno-based Edge Functions
└── config.toml               # Supabase CLI configuration

supabase_migrations/          # Versioned SQL schemas & security policies
```

---

## 🚀 Local Development

### Prerequisites

- Flutter SDK `3.38.x` (Stable)
- Dart SDK `3.10.x`
- Active Supabase & Firebase Projects
- Android Studio / VS Code

### 1. Setup

```bash
git clone https://github.com/tahaemree/campus_online.git
cd campus_online
flutter pub get
```

### 2. Environment Configuration

To run the application securely without hardcoding keys, inject your Supabase credentials at build/run time:

```bash
flutter run --dart-define=SUPABASE_URL=<your-url> --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

### 3. Database Migrations

For a fresh setup, execute the SQL files in `supabase_migrations/` sequentially, starting with `000_base_schema.sql`. These migrations contain the complete schema, RLS policies, indexing, and storage buckets.

### 4. Edge Functions

Deploy the Deno Edge Functions using the Supabase CLI:

```bash
supabase functions deploy create-staff-account
supabase functions deploy dispatch-notification-push --no-verify-jwt
```
*Note: The push dispatch function is secured via a Vault secret (`push_dispatch_secret`) rather than a standard JWT to allow secure server-to-server invocations.*

---

## 🍏 iOS Compatibility

This repository includes a fully configured iOS build chain:

1. CocoaPods integration via `ios/Podfile`.
2. Hardware permission declarations in `Info.plist` (Camera, Gallery).
3. Firebase APNs configuration ready in `firebase_options.dart`.

**To build for iOS (macOS required):**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

---

## 🛡️ Security Notes

- **Never embed the Service Role Key in the client.** It is strictly reserved for Edge Functions.
- All database mutations must pass through strict **Row-Level Security (RLS)** policies.
- Push tokens and administrative flows adhere to the **Principle of Least Privilege**.

---

## 🤝 Contributing

We welcome contributions! Please follow our [Contributing Guidelines](CONTRIBUTING.md). Create a feature branch, ensure `dart format .` and `flutter analyze` pass, and open a PR with detailed testing notes.

---

## 📄 License

This software is strictly for **educational and portfolio demonstration purposes**. It is licensed under a custom **Non-Commercial License** (All Rights Reserved).

You are **NOT authorized** to use, sell, or distribute this software for any commercial purposes without explicit prior written permission. Please see the [LICENSE](LICENSE) file for complete details.
