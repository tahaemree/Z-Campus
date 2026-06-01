# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Secure authentication and profile management via Supabase.
- Venue discovery, details screens, and location-based experiences.
- Event creation, viewing, favoriting, and location selection.
- Role-based admin panel for permissions, venues, notifications, and feedback.
- In-app notifications and Firebase Cloud Messaging (FCM) integration.
- Supabase Edge Functions for staff account creation and push dispatch.
- Robust Supabase RLS policies and migration-based schema updates.
- iOS compatibility pipeline setup.

### Changed
- Refactored `dispatch-notification-push` Edge Function to use Vault secrets instead of JWT for service authorization.
- Upgraded Android build configuration to support multiple environments and ABIs.

### Fixed
- Addressed security vulnerabilities with `022_professional_hardening.sql`, `025_notification_read_rpc_and_explore_schedule_hardening.sql`, and `026_push_dispatch_secret_only.sql`.
