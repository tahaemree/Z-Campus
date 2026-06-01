# Contributing to Z Campus

Thank you for your interest in contributing to Z Campus! This document outlines the process for proposing changes, submitting PRs, and maintaining engineering standards.

## 1. Local Setup

Make sure you have Flutter SDK `3.38.x` and Dart SDK `3.10.x` installed.

```bash
flutter pub get
```

You must run the application with your Supabase credentials:

```bash
flutter run --dart-define=SUPABASE_URL=<your-url> --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

## 2. Feature Branches

Please create a feature branch before making any changes.

```bash
git checkout -b feature/your-feature-name
```

## 3. Database Migrations

If your feature requires schema changes, do not alter existing migrations. Create a new SQL migration file in `supabase_migrations/` following the numerical order (e.g., `027_new_feature.sql`).

## 4. Coding Standards

Before committing, ensure your code passes our quality gates:

```bash
dart format .
flutter analyze
flutter test
```

## 5. Submitting a PR

Push your branch and open a Pull Request. Provide a clear description of the problem solved, testing steps, and ensure all CI checks pass. For significant architectural changes, please open an Issue first to discuss your design.
