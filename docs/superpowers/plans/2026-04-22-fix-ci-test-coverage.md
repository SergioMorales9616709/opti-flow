# Fix CI / Test Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `task ci` and `task test:coverage` pass green by fixing a layout overflow, hardening the test setup, and making the coverage HTML step cross-platform.

**Architecture:** Three isolated fixes — layout flex refactor in the view, hermetic test initialization in the test file, and a Taskfile task split. No new abstractions, no new files except the test helper pattern inlined into the existing test file.

**Tech Stack:** Flutter 3.x, Riverpod 2.x, sqflite_common_ffi, Task (Taskfile.dev)

---

## File Map

| Action | File | What changes |
|--------|------|--------------|
| Modify | `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart` | Replace fixed-height `SizedBox` with `Expanded`; remove `availableHeight` prop from `_ExerciseArea`; replace `availableHeight * 0.5` crosshair with `FractionallySizedBox` |
| Modify | `test/widget_test.dart` | Add `setUpAll` with sqflite-ffi in-memory init; override `progressRepositoryProvider` with a stub |
| Modify | `Taskfile.yml` | Extract `genhtml` into a separate `coverage:html` task; `test:coverage` only runs `flutter test --coverage` |

---

## Task 1: Fix RenderFlex overflow in SaccadicJumpsView

**Files:**
- Modify: `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart`

The outer `Column` gives `_ExerciseArea` a fixed height of `constraints.maxHeight * 0.65`, which overflows when the window is small (test uses 800×600, AppBar takes ~56px → body is 544px; 544×0.65 + divider + control panel > 544px). The fix is to use `Expanded` so the exercise area takes whatever space remains after the control panel.

- [ ] **Step 1: Replace fixed-height SizedBox with Expanded and remove LayoutBuilder**

Replace the entire `SaccadicJumpsView.build` method and `_ExerciseArea` class so they read:

```dart
class SaccadicJumpsView extends ConsumerWidget {
  const SaccadicJumpsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Expanded(child: _ExerciseArea()),
        const Divider(height: 1, color: Color(0xFF2A2A2A)),
        const _ControlPanel(),
      ],
    );
  }
}

class _ExerciseArea extends ConsumerWidget {
  const _ExerciseArea({super.key});

  static const _symbols = ['●', 'A', '◆', 'X', '▲', 'Z', '■', 'O'];
  static int _symbolIndex = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(saccadicJumpsProvider.select((s) => s.position));
    final status = ref.watch(saccadicJumpsProvider.select((s) => s.status));

    final bool isActive = status == ExerciseStatus.active;
    final String symbol = isActive
        ? _symbols[_symbolIndex % _symbols.length]
        : '●';
    if (isActive) _symbolIndex++;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Center crosshair guide — 50% of available height via fraction
        Center(
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Container(width: 1, color: const Color(0xFF1A1A1A)),
          ),
        ),
        // Animated stimulus
        AnimatedAlign(
          duration: const Duration(milliseconds: 80),
          alignment: position == StimulusPosition.left
              ? const Alignment(-0.88, 0)
              : const Alignment(0.88, 0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 60),
            child: _StimulusWidget(
              key: ValueKey('$symbol$position'),
              symbol: symbol,
              active: isActive,
            ),
          ),
        ),
        if (status == ExerciseStatus.idle) const _IdleOverlay(),
        if (status == ExerciseStatus.saved) const _SavedOverlay(),
      ],
    );
  }
}
```

- [ ] **Step 2: Run the test to verify the overflow is gone**

```bash
flutter test test/widget_test.dart
```

Expected output:
```
00:02 +1: All tests passed!
```

If it still fails with overflow, check that no `SizedBox` with a fixed height wraps `_ExerciseArea`.

- [ ] **Step 3: Commit**

```bash
git add lib/features/vision_training/presentation/views/saccadic_jumps_view.dart
git commit -m "fix(layout): use Expanded for exercise area to prevent overflow"
```

---

## Task 2: Harden smoke test with in-memory database setup

**Files:**
- Modify: `test/widget_test.dart`

The smoke test skips `DatabaseHelper.initialize()`. If any test interaction triggers `_persist()`, the `assert(_db != null)` in `DatabaseHelper.db` will throw. The fix is to initialize sqflite-ffi with an in-memory database in `setUpAll`, and override `progressRepositoryProvider` with a stub that records saves without touching disk.

- [ ] **Step 1: Rewrite `test/widget_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:optiflow/core/database/database_helper.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/main.dart';

// Stub repository — records calls without hitting disk.
class _FakeProgressRepository implements ProgressRepository {
  final List<Map<String, dynamic>> saved = [];

  @override
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  }) async {
    saved.add({'exerciseType': exerciseType, 'maxSpeedMs': maxSpeedMs});
  }
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.initializeForTesting();
  });

  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final fakeRepo = _FakeProgressRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const OptiFlowApp(),
      ),
    );

    expect(find.text('OptiFlow — Entrenamiento Visual'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Add `initializeForTesting()` to `DatabaseHelper`**

Open `lib/core/database/database_helper.dart` and add the method after `initialize()`:

```dart
/// Opens an in-memory database for widget/unit tests.
static Future<void> initializeForTesting() async {
  _db = await openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: _onCreate,
  );
}
```

Full file after the change:

```dart
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await openDatabase('optiflow.db', version: 1, onCreate: _onCreate);
  }

  /// Opens an in-memory database for widget/unit tests.
  static Future<void> initializeForTesting() async {
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Database get db {
    assert(_db != null, 'DatabaseHelper.initialize() must be called first.');
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_progress (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        date          TEXT    NOT NULL,
        exercise_type TEXT    NOT NULL,
        max_speed_ms  INTEGER NOT NULL
      )
    ''');
  }
}
```

- [ ] **Step 3: Verify `ProgressRepository` is an interface (or make it one)**

Check `lib/core/database/progress_repository.dart`. If `ProgressRepository` is a concrete class (not abstract), the stub in the test won't compile. If needed, extract the interface:

```dart
abstract interface class ProgressRepository {
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  });
}
```

Then rename the current implementation to `ProgressRepositoryImpl implements ProgressRepository` and update `progressRepositoryProvider` to return `ProgressRepositoryImpl`. *(Check the file first — if it's already abstract, skip this step.)*

- [ ] **Step 4: Run full test suite**

```bash
flutter test
```

Expected:
```
00:02 +1: All tests passed!
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/database_helper.dart \
        lib/core/database/progress_repository.dart \
        test/widget_test.dart
git commit -m "test: initialize in-memory DB and stub repository for hermetic tests"
```

---

## Task 3: Make `task test:coverage` cross-platform

**Files:**
- Modify: `Taskfile.yml`

`genhtml` is a Linux/macOS tool. On Windows it is not available. The `test:coverage` task should only run `flutter test --coverage`; HTML report generation moves to a separate opt-in task.

- [ ] **Step 1: Update `Taskfile.yml` coverage tasks**

Replace the existing `test:coverage` task and add `coverage:html`:

```yaml
  test:coverage:
    desc: Run tests and collect lcov coverage data (coverage/lcov.info)
    cmds:
      - flutter test --coverage

  coverage:html:
    desc: "Generate HTML report from lcov.info (requires lcov: brew install lcov / apt install lcov)"
    cmds:
      - genhtml coverage/lcov.info -o coverage/html
```

- [ ] **Step 2: Run `task ci` to confirm the full pipeline passes**

```bash
task ci
```

Expected output (all three steps green):
```
task: [format:check] dart format --output=none --set-exit-if-changed lib/ test/
Formatted N files (0 changed) in X.XXs.
task: [analyze] flutter analyze
No issues found!
task: [test] flutter test
+1: All tests passed!
```

- [ ] **Step 3: Run `task test:coverage` to confirm it exits cleanly**

```bash
task test:coverage
```

Expected: exits 0, produces `coverage/lcov.info`.

- [ ] **Step 4: Commit**

```bash
git add Taskfile.yml
git commit -m "chore(taskfile): split coverage HTML into opt-in task for cross-platform compat"
```

---

## Self-Review

**Spec coverage:**
- Layout overflow → Task 1 ✓
- Fragile test DB init → Task 2 ✓
- `genhtml` cross-platform → Task 3 ✓

**Placeholder scan:** No TBDs. All code blocks are complete. Task 2 Step 3 has a conditional note — it checks the current file before acting, which is correct behaviour.

**Type consistency:** `ProgressRepository` is used as the interface type in both the stub and the provider override. `_FakeProgressRepository implements ProgressRepository` — consistent. `DatabaseHelper.initializeForTesting()` is defined in Task 2 Step 2 and called in the test in Step 1 — consistent (Step 1 must be read alongside Step 2, order is correct).
