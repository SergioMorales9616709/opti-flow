# Saccadic Patterns Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> ⚠️ **COMMIT POLICY:** Do NOT run `git commit` at any point. Stage changes with `git add` but hold all commits until the user validates the changes visually and gives explicit approval.

**Goal:** Refactorizar los Saltos Sacádicos para soportar 4 patrones geométricos (Horizontal, Vertical, Z, Cruz), velocidad humana (400–2000 ms, default 1200 ms), y un selector de patrón en la UI — sin romper la persistencia SQLite existente.

**Architecture:** `SaccadicPattern` enum vive en `domain/` con su secuencia de `Alignment`s como getter. El ViewModel reemplaza `StimulusPosition` por `(pattern, stepIndex)` y avanza el índice en cada tick del timer. La Vista reemplaza `AnimatedAlign` por `Align` simple (salto instantáneo) y añade un `SegmentedButton` de selección de patrón.

**Tech Stack:** Flutter Desktop, Riverpod 2.x (NotifierProvider), sqflite_common_ffi, Dart 3 (switch expressions, enum methods).

---

## File Map

| Acción | Archivo | Responsabilidad |
|--------|---------|-----------------|
| Crear | `lib/features/vision_training/domain/saccadic_pattern.dart` | Enum con secuencias y labels |
| Crear | `test/domain/saccadic_pattern_test.dart` | Unit tests del enum |
| Modificar | `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart` | Estado + Notifier refactorizados |
| Modificar | `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart` | Vista con PatternSelector, sin crosshair, Align instantáneo |
| Modificar | `PROJECT_STATE.md` | Documentar nuevas capacidades |

---

## Task 1: SaccadicPattern domain enum

**Files:**
- Create: `lib/features/vision_training/domain/saccadic_pattern.dart`
- Create: `test/domain/saccadic_pattern_test.dart`

- [ ] **Step 1: Crear el directorio de test y escribir los tests que fallarán**

Crear el archivo `test/domain/saccadic_pattern_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/features/vision_training/domain/saccadic_pattern.dart';

void main() {
  group('SaccadicPattern.sequence', () {
    test('horizontal has 2 positions', () {
      expect(SaccadicPattern.horizontal.sequence.length, 2);
    });

    test('horizontal first position is left-center', () {
      expect(SaccadicPattern.horizontal.sequence.first, const Alignment(-0.88, 0));
    });

    test('horizontal second position is right-center', () {
      expect(SaccadicPattern.horizontal.sequence.last, const Alignment(0.88, 0));
    });

    test('vertical has 2 positions', () {
      expect(SaccadicPattern.vertical.sequence.length, 2);
    });

    test('vertical first position is top-center', () {
      expect(SaccadicPattern.vertical.sequence.first, const Alignment(0, -0.88));
    });

    test('zPattern has 4 positions', () {
      expect(SaccadicPattern.zPattern.sequence.length, 4);
    });

    test('zPattern follows top-left, top-right, bottom-left, bottom-right order', () {
      final seq = SaccadicPattern.zPattern.sequence;
      expect(seq[0], const Alignment(-0.88, -0.88));
      expect(seq[1], const Alignment(0.88, -0.88));
      expect(seq[2], const Alignment(-0.88, 0.88));
      expect(seq[3], const Alignment(0.88, 0.88));
    });

    test('crossPattern has 4 positions', () {
      expect(SaccadicPattern.crossPattern.sequence.length, 4);
    });

    test('crossPattern follows top, bottom, left, right order', () {
      final seq = SaccadicPattern.crossPattern.sequence;
      expect(seq[0], const Alignment(0, -0.88));
      expect(seq[1], const Alignment(0, 0.88));
      expect(seq[2], const Alignment(-0.88, 0));
      expect(seq[3], const Alignment(0.88, 0));
    });
  });

  group('SaccadicPattern.label', () {
    test('horizontal label is Horizontal', () {
      expect(SaccadicPattern.horizontal.label, 'Horizontal');
    });

    test('vertical label is Vertical', () {
      expect(SaccadicPattern.vertical.label, 'Vertical');
    });

    test('zPattern label is Patrón Z', () {
      expect(SaccadicPattern.zPattern.label, 'Patrón Z');
    });

    test('crossPattern label is Cruz', () {
      expect(SaccadicPattern.crossPattern.label, 'Cruz');
    });
  });
}
```

- [ ] **Step 2: Correr los tests y verificar que fallan (archivo no existe aún)**

```bash
flutter test test/domain/saccadic_pattern_test.dart
```

Expected: Error de compilación — `saccadic_pattern.dart` no existe.

- [ ] **Step 3: Crear el enum**

Crear `lib/features/vision_training/domain/saccadic_pattern.dart`:

```dart
import 'package:flutter/material.dart';

enum SaccadicPattern {
  horizontal,
  vertical,
  zPattern,
  crossPattern;

  List<Alignment> get sequence => switch (this) {
    SaccadicPattern.horizontal => [
      const Alignment(-0.88, 0),
      const Alignment(0.88, 0),
    ],
    SaccadicPattern.vertical => [
      const Alignment(0, -0.88),
      const Alignment(0, 0.88),
    ],
    SaccadicPattern.zPattern => [
      const Alignment(-0.88, -0.88),
      const Alignment(0.88, -0.88),
      const Alignment(-0.88, 0.88),
      const Alignment(0.88, 0.88),
    ],
    SaccadicPattern.crossPattern => [
      const Alignment(0, -0.88),
      const Alignment(0, 0.88),
      const Alignment(-0.88, 0),
      const Alignment(0.88, 0),
    ],
  };

  String get label => switch (this) {
    SaccadicPattern.horizontal   => 'Horizontal',
    SaccadicPattern.vertical     => 'Vertical',
    SaccadicPattern.zPattern     => 'Patrón Z',
    SaccadicPattern.crossPattern => 'Cruz',
  };
}
```

- [ ] **Step 4: Correr los tests y verificar que pasan**

```bash
flutter test test/domain/saccadic_pattern_test.dart
```

Expected:
```
+12: All tests passed!
```

- [ ] **Step 5: Stagear (NO commitear)**

```bash
git add lib/features/vision_training/domain/saccadic_pattern.dart \
        test/domain/saccadic_pattern_test.dart
```

---

## Task 2: Refactorizar el ViewModel

**Files:**
- Modify: `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart`

- [ ] **Step 1: Reemplazar el contenido completo del archivo**

El archivo `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart` debe quedar exactamente así:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/progress_repository.dart';
import '../../domain/saccadic_pattern.dart';

enum ExerciseStatus { idle, active, saving, saved }

class SaccadicJumpsState {
  final SaccadicPattern pattern;
  final int stepIndex;
  final ExerciseStatus status;
  final int speedMs;
  final int minSpeedMs;
  final int maxSpeedMs;

  const SaccadicJumpsState({
    required this.pattern,
    required this.stepIndex,
    required this.status,
    required this.speedMs,
    required this.minSpeedMs,
    required this.maxSpeedMs,
  });

  Alignment get currentAlignment => pattern.sequence[stepIndex];

  SaccadicJumpsState copyWith({
    SaccadicPattern? pattern,
    int? stepIndex,
    ExerciseStatus? status,
    int? speedMs,
  }) {
    return SaccadicJumpsState(
      pattern: pattern ?? this.pattern,
      stepIndex: stepIndex ?? this.stepIndex,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
    );
  }
}

class SaccadicJumpsNotifier extends Notifier<SaccadicJumpsState> {
  static const int _defaultSpeedMs = 1200;
  static const int _minSpeedMs = 400;
  static const int _maxSpeedMs = 2000;

  Timer? _timer;

  @override
  SaccadicJumpsState build() {
    ref.onDispose(_cancelTimer);
    return const SaccadicJumpsState(
      pattern: SaccadicPattern.horizontal,
      stepIndex: 0,
      status: ExerciseStatus.idle,
      speedMs: _defaultSpeedMs,
      minSpeedMs: _minSpeedMs,
      maxSpeedMs: _maxSpeedMs,
    );
  }

  void setPattern(SaccadicPattern p) {
    if (state.status != ExerciseStatus.idle) return;
    state = state.copyWith(pattern: p, stepIndex: 0);
  }

  void setSpeed(int ms) {
    if (state.status == ExerciseStatus.active) {
      _startTimer(ms);
    }
    state = state.copyWith(speedMs: ms);
  }

  void startExercise() {
    if (state.status == ExerciseStatus.active) return;
    state = state.copyWith(status: ExerciseStatus.active);
    _startTimer(state.speedMs);
  }

  void stopAndSave() {
    if (state.status != ExerciseStatus.active) return;
    _cancelTimer();
    state = state.copyWith(status: ExerciseStatus.saving);
    _persist();
  }

  Future<void> _persist() async {
    final repo = ref.read(progressRepositoryProvider);
    await repo.saveProgress(
      exerciseType: 'saccadic_jumps',
      maxSpeedMs: state.speedMs,
    );
    state = state.copyWith(status: ExerciseStatus.saved);
  }

  void reset() {
    _cancelTimer();
    state = const SaccadicJumpsState(
      pattern: SaccadicPattern.horizontal,
      stepIndex: 0,
      status: ExerciseStatus.idle,
      speedMs: _defaultSpeedMs,
      minSpeedMs: _minSpeedMs,
      maxSpeedMs: _maxSpeedMs,
    );
  }

  void _startTimer(int ms) {
    _cancelTimer();
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      final seq = state.pattern.sequence;
      state = state.copyWith(stepIndex: (state.stepIndex + 1) % seq.length);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final saccadicJumpsProvider =
    NotifierProvider<SaccadicJumpsNotifier, SaccadicJumpsState>(
      SaccadicJumpsNotifier.new,
    );
```

- [ ] **Step 2: Correr flutter analyze para verificar que compila sin errores**

```bash
flutter analyze
```

Expected: `No issues found!`

Si hay errores — la vista todavía referencia `StimulusPosition` o `position`, lo cual es normal hasta que se refactorice en Task 3. En ese caso, ignorar los errores de la vista por ahora y continuar.

- [ ] **Step 3: Correr el smoke test para verificar que el ViewModel no rompe la app**

```bash
flutter test test/widget_test.dart
```

Expected: `+1: All tests passed!`

Si falla porque la vista aún referencia `StimulusPosition`, continuar igualmente con Task 3.

- [ ] **Step 4: Stagear (NO commitear)**

```bash
git add lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart
```

---

## Task 3: Refactorizar la Vista

**Files:**
- Modify: `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart`

- [ ] **Step 1: Reemplazar el contenido completo del archivo**

El archivo `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart` debe quedar exactamente así:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/saccadic_pattern.dart';
import '../viewmodels/saccadic_jumps_viewmodel.dart';

class SaccadicJumpsView extends ConsumerWidget {
  const SaccadicJumpsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        Expanded(child: _ExerciseArea()),
        Divider(height: 1, color: Color(0xFF2A2A2A)),
        _PatternSelector(),
        _ControlPanel(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise area — rebuilds only when alignment or status changes
// ---------------------------------------------------------------------------
class _ExerciseArea extends ConsumerWidget {
  const _ExerciseArea();

  static const _symbols = ['●', 'A', '◆', 'X', '▲', 'Z', '■', 'O'];
  static int _symbolIndex = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignment = ref.watch(
      saccadicJumpsProvider.select((s) => s.currentAlignment),
    );
    final status = ref.watch(
      saccadicJumpsProvider.select((s) => s.status),
    );

    final bool isActive = status == ExerciseStatus.active;
    final String symbol = isActive
        ? _symbols[_symbolIndex % _symbols.length]
        : '●';
    if (isActive) _symbolIndex++;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: alignment,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 60),
            child: _StimulusWidget(
              key: ValueKey('$symbol$alignment'),
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

class _StimulusWidget extends StatelessWidget {
  const _StimulusWidget({
    super.key,
    required this.symbol,
    required this.active,
  });

  final String symbol;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
            : Colors.transparent,
        border: Border.all(
          color: active ? const Color(0xFF00E5FF) : const Color(0xFF444444),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: active ? const Color(0xFF00E5FF) : const Color(0xFF555555),
        ),
      ),
    );
  }
}

class _IdleOverlay extends StatelessWidget {
  const _IdleOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: const Text(
        'Presiona INICIAR para comenzar\nel ejercicio de saltos sacádicos',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 18, height: 1.6),
      ),
    );
  }
}

class _SavedOverlay extends StatelessWidget {
  const _SavedOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF00E5FF), size: 56),
          SizedBox(height: 16),
          Text(
            '¡Progreso guardado!',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pattern selector — SegmentedButton, only enabled when idle
// ---------------------------------------------------------------------------
class _PatternSelector extends ConsumerWidget {
  const _PatternSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pattern = ref.watch(
      saccadicJumpsProvider.select((s) => s.pattern),
    );
    final status = ref.watch(
      saccadicJumpsProvider.select((s) => s.status),
    );
    final notifier = ref.read(saccadicJumpsProvider.notifier);

    final bool isSelectable = status == ExerciseStatus.idle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: SegmentedButton<SaccadicPattern>(
        segments: SaccadicPattern.values
            .map((p) => ButtonSegment(value: p, label: Text(p.label)))
            .toList(),
        selected: {pattern},
        onSelectionChanged:
            isSelectable ? (s) => notifier.setPattern(s.first) : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control panel — speed slider + action buttons
// ---------------------------------------------------------------------------
class _ControlPanel extends ConsumerWidget {
  const _ControlPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saccadicJumpsProvider);
    final notifier = ref.read(saccadicJumpsProvider.notifier);

    final bool isActive = state.status == ExerciseStatus.active;
    final bool isSaving = state.status == ExerciseStatus.saving;
    final bool isSaved = state.status == ExerciseStatus.saved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Velocidad del estímulo',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              Text(
                '${state.speedMs} ms / salto',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Lento',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: state.speedMs.toDouble(),
                  min: state.minSpeedMs.toDouble(),
                  max: state.maxSpeedMs.toDouble(),
                  divisions: (state.maxSpeedMs - state.minSpeedMs) ~/ 50,
                  onChanged: isSaving || isSaved
                      ? null
                      : (v) => notifier.setSpeed(v.round()),
                ),
              ),
              const Text(
                'Rápido',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isActive && !isSaved) ...[
                ElevatedButton.icon(
                  onPressed: isSaving ? null : notifier.startExercise,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('INICIAR'),
                ),
              ],
              if (isActive) ...[
                ElevatedButton.icon(
                  onPressed: notifier.stopAndSave,
                  icon: const Icon(Icons.stop),
                  label: const Text('DETENER Y GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4444),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              if (isSaved) ...[
                ElevatedButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('NUEVO EJERCICIO'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Correr flutter analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Correr la suite de tests completa**

```bash
flutter test
```

Expected:
```
+13: All tests passed!
```

(12 unit tests de SaccadicPattern + 1 smoke test de la app)

- [ ] **Step 4: Stagear (NO commitear)**

```bash
git add lib/features/vision_training/presentation/views/saccadic_jumps_view.dart
```

---

## Task 4: Actualizar PROJECT_STATE.md

**Files:**
- Modify: `PROJECT_STATE.md`

- [ ] **Step 1: Actualizar la sección de Módulos y Estado**

Reemplazar la sección `### Módulo 1: Visión (MVP)` con:

```markdown
### Módulo 1: Visión
**Ejercicio: Saltos Sacádicos**
- Patrones: Horizontal, Vertical, Patrón Z, Cruz (enum `SaccadicPattern` en `domain/`).
- Velocidad: 400 ms – 2000 ms por salto; valor por defecto 1200 ms.
- Control: Slider de velocidad + `SegmentedButton` de selección de patrón.
- Persistencia: guarda `max_speed_ms` al finalizar el ejercicio.
```

Y agregar una fila a la tabla de estado:

```markdown
| 6    | Refactorización: patrones múltiples sacádicos        | ✅ Completado |
```

Y actualizar el bloque de cierre del MVP:

```markdown
## Módulo 1 — Versión 2 ✅

`flutter analyze` reporta **0 issues**.  
Patrones soportados: Horizontal, Vertical, Z, Cruz.  
Fecha: 2026-04-22
```

- [ ] **Step 2: Stagear (NO commitear)**

```bash
git add PROJECT_STATE.md
```

- [ ] **Step 3: Verificar estado del staging area**

```bash
git status
```

Expected — todos los archivos staged, ninguno committed:
```
Changes to be committed:
  new file:   lib/features/vision_training/domain/saccadic_pattern.dart
  new file:   test/domain/saccadic_pattern_test.dart
  modified:   lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart
  modified:   lib/features/vision_training/presentation/views/saccadic_jumps_view.dart
  modified:   PROJECT_STATE.md
```

---

## Self-Review

**1. Spec coverage:**
- Domain enum con secuencias y labels → Task 1 ✓
- Estado con `pattern` + `stepIndex` + `currentAlignment` getter → Task 2 ✓
- Velocidad 400–2000 ms, default 1200 ms → Task 2 ✓
- `setPattern` solo en idle, reset stepIndex → Task 2 ✓
- Timer avanza stepIndex en módulo de la longitud de secuencia → Task 2 ✓
- Crosshair eliminado → Task 3 ✓
- `Align` instantáneo en lugar de `AnimatedAlign` → Task 3 ✓
- `_PatternSelector` con `SegmentedButton` → Task 3 ✓
- Slider actualizado (min 400, max 2000, divisiones 32) → Task 3 ✓
- Persistencia SQLite intacta → Task 2 (`_persist` sin cambios) ✓
- `PROJECT_STATE.md` actualizado → Task 4 ✓

**2. Placeholder scan:** Ninguno. Cada step tiene código completo.

**3. Type consistency:**
- `SaccadicPattern` definido en Task 1, usado en Tasks 2 y 3 ✓
- `currentAlignment` getter definido en Task 2, consumido en Task 3 vía `select` ✓
- `ExerciseStatus` definido en Task 2, usado en Task 3 ✓
- `saccadicJumpsProvider` definido en Task 2, consumido en Task 3 ✓
- Import paths consistentes: `../../domain/saccadic_pattern.dart` desde `presentation/viewmodels/` y `presentation/views/` ✓
