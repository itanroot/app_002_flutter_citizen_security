# seguridad_ciudadana_app

## Core Principales

- Clean Architecture is mandatory
- Feature-first structure (no type-based folders)
- No business logic in UI layer
- All API calls must go through repository pattern
- Strict separation: presentation / domain / data

## Mandatory Pattern
Clean Architecture + Feature First

Each feature must contain:

- data/
- domain/
- presentation/

## Folder rule

ALWAYS create:
- features/<module>/

## Production-grade mobile application built with:

- Flutter (latest stable)
- Riverpod (state management)
- Dio (HTTP client)
- Laravel API
- Clean Architecture
- GoRouter (navigation)
- Laravel API backend (REST + JWT)

## Features
- Authentication module
- Scalable feature-first structure
- Flutter Secure Storage (token storage)

## Security Rules

- Never store passwords locally
- Store JWT securely only
- Use interceptors for token injection
- Prepare refresh token architecture (future-ready)
- Validate inputs in domain layer

## Code Quality Rules

- Use usecases for all business logic
- DTO ≠ Entity separation mandatory
- Avoid direct API calls from UI
- Centralized error handling required
- Logging must be centralized (no print statements)

# command success app

- flutter pub get
- dart run build_runner build --delete-conflicting-outputs

- flutter run -d chrome
- dart run flutter_launcher_icons

- flutter run --dart-define=ENVIRONMENT=dev --dart-define=API_BASE_URL=https://host-backend/api/v1


# command emulator app
- adb tcpip 5555
- adb connect IP_EMULATOR:5555