# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For architecture details and contributing guidelines, see [`docs/`](docs/).

## Commands

```bash
# Run on Windows desktop
flutter run -d windows

# Run on Linux desktop
flutter run -d linux

# Lint / static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get/update dependencies
flutter pub get
```

## Architecture

**Feature-First + MVVM** using `flutter_riverpod` for state management.

```
lib/
├── main.dart                        # Entry point: initializes DB, wraps app in ProviderScope
├── core/
│   ├── database/
│   │   ├── database_helper.dart     # Singleton SQLite init (sqflite_common_ffi for desktop)
│   │   └── progress_repository.dart # Data access + progressRepositoryProvider
│   └── theme/
│       └── app_theme.dart           # Global dark theme (accent: #00E5FF)
└── features/
    └── vision_training/
        └── presentation/
            ├── viewmodels/          # Riverpod Notifiers — all timer/state logic lives here
            └── views/               # ConsumerWidgets — no business logic
```

Each feature follows the same layering: `data/` → `domain/` → `presentation/`. Only `presentation/` exists for the current MVP; `data/` and `domain/` are reserved for future expansion.

## Key Patterns

**State management:** Use `NotifierProvider` (Riverpod 2.x). State objects are immutable with `copyWith`. Providers are defined at the bottom of their viewmodel file.

**Selective rebuilds:** Views use `ref.watch(provider.select((s) => s.field))` to subscribe only to the specific state field they need, avoiding full-tree rebuilds during high-frequency timer updates.

**Database:** `DatabaseHelper` is a static singleton initialized once in `main()` before `runApp`. All repositories receive the `Database` instance via `DatabaseHelper.db`. The `sqfliteFfiInit()` call is required for Windows/Linux — do not remove it.

**Layout:** Use `LayoutBuilder` / `MediaQuery` for all sizing. No hardcoded pixel values for layout dimensions.

## Database Schema

Table `user_progress` (file: `optiflow.db`, stored in the app's working directory):

| Column | Type | Notes |
|---|---|---|
| id | INTEGER | PK AUTOINCREMENT |
| date | TEXT | ISO 8601 |
| exercise_type | TEXT | e.g. `"saccadic_jumps"` |
| max_speed_ms | INTEGER | milliseconds per jump |
