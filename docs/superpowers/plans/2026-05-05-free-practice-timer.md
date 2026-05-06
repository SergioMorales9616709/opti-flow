# Free Practice Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir un temporizador de cuenta regresiva (∞ / 30s / 60s / 2m) a los dos ejercicios de visión, con auto-guardado y sonido de éxito al expirar.

**Architecture:** `ExerciseDuration` es un enhanced enum definido en el ViewModel de Saltos Sacádicos e importado por Smooth Pursuit (igual que `ExerciseStatus` hoy). Cada ViewModel gestiona su propio `Timer? _countdownTimer` separado del timer de animación. Las Vistas añaden un HUD flotante y un `SegmentedButton` de duración en la Fila 3 del panel.

**Tech Stack:** Flutter Desktop, Dart, flutter_riverpod 2.x (Notifier), audioplayers ^6.x, flutter_test + fakeAsync para tests de timer.

---

## Mapa de archivos

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `lib/core/utils/audio_cue.dart` | Modificar | Añade cue `success` |
| `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart` | Modificar | Añade `ExerciseDuration`, campos de estado, `_countdownTimer`, `setDuration()` |
| `lib/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart` | Modificar | Importa `ExerciseDuration`, añade campos, `_countdownTimer`, `setDuration()` |
| `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart` | Modificar | HUD `_CountdownHud`, selector en Fila 3, label "Práctica Libre" |
| `lib/features/vision_training/presentation/views/smooth_pursuit_view.dart` | Modificar | Mismos cambios de UI |
| `test/viewmodels/saccadic_jumps_vm_test.dart` | Modificar | Tests de `ExerciseDuration` y countdown |
| `test/viewmodels/smooth_pursuit_vm_test.dart` | Modificar | Tests de countdown |
| `PROJECT_STATE.md` | Modificar | Documenta Paso 11 |

---

## Task 1: AudioCue — añadir cue `success`

**Files:**
- Modify: `lib/core/utils/audio_cue.dart`

- [ ] **Step 1: Añadir `success` al enum**

Reemplaza el contenido completo de `lib/core/utils/audio_cue.dart`:

```dart
enum AudioCue {
  click('audio/click.mp3', isBgm: false),
  bgmFlow('audio/bgm_flow.mp3', isBgm: true),
  success('audio/success.mp3', isBgm: false);

  const AudioCue(this.path, {required this.isBgm});

  final String path;
  final bool isBgm;
}
```

- [ ] **Step 2: Verificar que `success.mp3` existe en assets**

```bash
ls assets/audio/
```

Esperado: ver `success.mp3` en la lista. Si no existe, este archivo debe ser provisto antes de continuar.

- [ ] **Step 3: Verificar análisis estático**

```bash
flutter analyze lib/core/utils/audio_cue.dart
```

Esperado: `No issues found!`

> **Nota:** `AudioService.init()` pre-carga automáticamente todos los cues con `isBgm: false` mediante su loop `for (final cue in AudioCue.values.where((c) => !c.isBgm))`. No se requiere ningún cambio en `audio_service.dart`. El `success` cue se reproduce con el método `play()` existente.

- [ ] **Step 4: Commit**

```bash
git add lib/core/utils/audio_cue.dart
git commit -m "feat(audio): add success AudioCue"
```

---

## Task 2: `ExerciseDuration` enum y campos en `SaccadicJumpsState`

**Files:**
- Modify: `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart`
- Modify: `test/viewmodels/saccadic_jumps_vm_test.dart`

- [ ] **Step 1: Escribir los tests que deben fallar**

Abre `test/viewmodels/saccadic_jumps_vm_test.dart` y añade el siguiente grupo al final del `main()`, antes del cierre `}`:

```dart
  group('ExerciseDuration state', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default selectedDuration is s60', () {
      expect(
        container.read(saccadicJumpsProvider).selectedDuration,
        ExerciseDuration.s60,
      );
    });

    test('default timeLeftSeconds is null', () {
      expect(container.read(saccadicJumpsProvider).timeLeftSeconds, isNull);
    });

    test('setDuration changes selectedDuration when idle', () {
      container.read(saccadicJumpsProvider.notifier).setDuration(ExerciseDuration.s30);
      expect(
        container.read(saccadicJumpsProvider).selectedDuration,
        ExerciseDuration.s30,
      );
    });
  });
```

Añade también el import necesario al encabezado del archivo (ya existe el import del viewmodel, solo verifica que esté):
```dart
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart';
```

- [ ] **Step 2: Correr los tests — deben fallar**

```bash
flutter test test/viewmodels/saccadic_jumps_vm_test.dart
```

Esperado: error de compilación — `ExerciseDuration` no existe todavía.

- [ ] **Step 3: Implementar `ExerciseDuration` y actualizar el estado**

Abre `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart`.

**3a.** Añade el enum `ExerciseDuration` y una clase helper para el patrón copyWith de campos nullable, justo antes de `enum ExerciseStatus`:

```dart
enum ExerciseDuration {
  infinite('∞', null),
  s30('30s', 30),
  s60('60s', 60),
  m2('2m', 120);

  const ExerciseDuration(this.label, this.seconds);
  final String label;
  final int? seconds;
}

// Sentinel privado para distinguir "no se pasó el parámetro" de null en copyWith
class _Absent {
  const _Absent();
}
const _absent = _Absent();
```

**3b.** Actualiza `SaccadicJumpsState` para añadir los dos campos nuevos y actualizar `copyWith`. Reemplaza la clase completa:

```dart
class SaccadicJumpsState {
  const SaccadicJumpsState({
    required this.pattern,
    required this.stepIndex,
    required this.symbolIndex,
    required this.status,
    required this.speedMs,
    required this.minSpeedMs,
    required this.maxSpeedMs,
    required this.isSoundEnabled,
    this.selectedDuration = ExerciseDuration.s60,
    this.timeLeftSeconds,
  });

  final SaccadicPattern pattern;
  final int stepIndex;
  final int symbolIndex;
  final ExerciseStatus status;
  final int speedMs;
  final int minSpeedMs;
  final int maxSpeedMs;
  final bool isSoundEnabled;
  final ExerciseDuration selectedDuration;
  final int? timeLeftSeconds;

  Alignment get currentAlignment => pattern.sequence[stepIndex];

  SaccadicJumpsState copyWith({
    SaccadicPattern? pattern,
    int? stepIndex,
    int? symbolIndex,
    ExerciseStatus? status,
    int? speedMs,
    bool? isSoundEnabled,
    ExerciseDuration? selectedDuration,
    Object? timeLeftSeconds = _absent,
  }) {
    return SaccadicJumpsState(
      pattern: pattern ?? this.pattern,
      stepIndex: stepIndex ?? this.stepIndex,
      symbolIndex: symbolIndex ?? this.symbolIndex,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      timeLeftSeconds: timeLeftSeconds is _Absent
          ? this.timeLeftSeconds
          : timeLeftSeconds as int?,
    );
  }
}
```

**3c.** Añade `setDuration()` al Notifier `SaccadicJumpsNotifier`, después del método `setSpeed()`:

```dart
void setDuration(ExerciseDuration d) {
  if (state.status != ExerciseStatus.idle) return;
  state = state.copyWith(selectedDuration: d, timeLeftSeconds: null);
}
```

**3d.** Actualiza `reset()` para preservar `selectedDuration`. Reemplaza el método:

```dart
void reset() {
  _cancelTimer();
  state = SaccadicJumpsState(
    pattern: SaccadicPattern.horizontal,
    stepIndex: 0,
    symbolIndex: 0,
    status: ExerciseStatus.idle,
    speedMs: _defaultSpeedMs,
    minSpeedMs: _minSpeedMs,
    maxSpeedMs: _maxSpeedMs,
    isSoundEnabled: state.isSoundEnabled,
    selectedDuration: state.selectedDuration,
  );
}
```

- [ ] **Step 4: Correr los tests — deben pasar**

```bash
flutter test test/viewmodels/saccadic_jumps_vm_test.dart
```

Esperado: todos los tests pasando, incluyendo los 3 nuevos.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart \
        test/viewmodels/saccadic_jumps_vm_test.dart
git commit -m "feat(saccadic): add ExerciseDuration enum and state fields"
```

---

## Task 3: Lógica del countdown en `SaccadicJumpsNotifier`

**Files:**
- Modify: `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart`
- Modify: `test/viewmodels/saccadic_jumps_vm_test.dart`

- [ ] **Step 1: Escribir los tests que deben fallar**

Abre `test/viewmodels/saccadic_jumps_vm_test.dart`. Añade estos dos imports al inicio si no están:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
```

Añade estas clases helper antes de `main()`:

```dart
class _FakeAudioService extends AudioService {
  final List<AudioCue> played = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> play(AudioCue cue) async => played.add(cue);

  @override
  Future<void> playBgm({double volume = 0.5}) async {}

  @override
  Future<void> stopBgm() async {}
}

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  }) async {}
}

ProviderContainer _makeContainer() => ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(_FakeAudioService()),
        progressRepositoryProvider.overrideWithValue(
          _FakeProgressRepository(),
        ),
      ],
    );
```

Añade el siguiente grupo al `main()`:

```dart
  group('SaccadicJumpsNotifier countdown', () {
    test('startExercise with finite duration sets timeLeftSeconds', () {
      fakeAsync((async) {
        final container = _makeContainer();
        addTearDown(container.dispose);
        container
            .read(saccadicJumpsProvider.notifier)
            .setDuration(ExerciseDuration.s30);
        container.read(saccadicJumpsProvider.notifier).startExercise();

        expect(
          container.read(saccadicJumpsProvider).timeLeftSeconds,
          30,
        );
        async.elapse(const Duration(seconds: 1));
        expect(
          container.read(saccadicJumpsProvider).timeLeftSeconds,
          29,
        );
      });
    });

    test('startExercise with infinite duration keeps timeLeftSeconds null', () {
      fakeAsync((async) {
        final container = _makeContainer();
        addTearDown(container.dispose);
        container
            .read(saccadicJumpsProvider.notifier)
            .setDuration(ExerciseDuration.infinite);
        container.read(saccadicJumpsProvider.notifier).startExercise();

        async.elapse(const Duration(seconds: 5));
        expect(
          container.read(saccadicJumpsProvider).timeLeftSeconds,
          isNull,
        );
      });
    });

    test('countdown auto-stops and plays success at zero', () {
      fakeAsync((async) {
        final audio = _FakeAudioService();
        final container = ProviderContainer(
          overrides: [
            audioServiceProvider.overrideWithValue(audio),
            progressRepositoryProvider
                .overrideWithValue(_FakeProgressRepository()),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(saccadicJumpsProvider.notifier)
            .setDuration(ExerciseDuration.s30);
        container.read(saccadicJumpsProvider.notifier).startExercise();

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(
          container.read(saccadicJumpsProvider).status,
          ExerciseStatus.saved,
        );
        expect(audio.played, contains(AudioCue.success));
      });
    });

    test('selectedDuration preserved after reset', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      container
          .read(saccadicJumpsProvider.notifier)
          .setDuration(ExerciseDuration.m2);
      container.read(saccadicJumpsProvider.notifier).reset();
      expect(
        container.read(saccadicJumpsProvider).selectedDuration,
        ExerciseDuration.m2,
      );
    });
  });
```

- [ ] **Step 2: Correr los tests — deben fallar**

```bash
flutter test test/viewmodels/saccadic_jumps_vm_test.dart
```

Esperado: los tests del grupo `countdown` fallan — `_countdownTimer` y `startCountdown` no existen.

- [ ] **Step 3: Implementar la lógica del countdown**

Abre `saccadic_jumps_viewmodel.dart`.

**3a.** Añade `Timer? _countdownTimer;` como campo en `SaccadicJumpsNotifier`, junto a `Timer? _timer;`:

```dart
class SaccadicJumpsNotifier extends Notifier<SaccadicJumpsState> {
  static const int _defaultSpeedMs = 800;
  static const int _minSpeedMs = 300;
  static const int _maxSpeedMs = 1200;

  Timer? _timer;
  Timer? _countdownTimer;
  // ... resto igual
```

**3b.** Reemplaza `startExercise()`:

```dart
void startExercise() {
  if (state.status == ExerciseStatus.active) return;
  final seconds = state.selectedDuration.seconds;
  state = state.copyWith(
    status: ExerciseStatus.active,
    timeLeftSeconds: seconds,
  );
  _startTimer(state.speedMs);
  if (seconds != null) {
    _startCountdown();
  }
}
```

**3c.** Añade `_startCountdown()` después de `_startTimer()`:

```dart
void _startCountdown() {
  _countdownTimer?.cancel();
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    final left = state.timeLeftSeconds;
    if (left == null) return;
    if (left <= 1) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      ref.read(audioServiceProvider).play(AudioCue.success);
      stopAndSave();
    } else {
      state = state.copyWith(timeLeftSeconds: left - 1);
    }
  });
}
```

**3d.** Reemplaza `_cancelTimer()` para que cancele ambos timers:

```dart
void _cancelTimer() {
  _timer?.cancel();
  _timer = null;
  _countdownTimer?.cancel();
  _countdownTimer = null;
}
```

- [ ] **Step 4: Correr los tests — deben pasar**

```bash
flutter test test/viewmodels/saccadic_jumps_vm_test.dart
```

Esperado: todos los tests pasando.

- [ ] **Step 5: Análisis estático**

```bash
flutter analyze lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart
```

Esperado: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart \
        test/viewmodels/saccadic_jumps_vm_test.dart
git commit -m "feat(saccadic): implement countdown timer with auto-save"
```

---

## Task 4: `SmoothPursuitState` y Notifier — countdown

**Files:**
- Modify: `lib/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart`
- Modify: `test/viewmodels/smooth_pursuit_vm_test.dart`

- [ ] **Step 1: Escribir los tests que deben fallar**

Abre `test/viewmodels/smooth_pursuit_vm_test.dart`. Reemplaza el contenido completo del archivo:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration, ExerciseStatus;
import 'package:optiflow/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart';

class _FakeAudioService extends AudioService {
  final List<AudioCue> played = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> play(AudioCue cue) async => played.add(cue);

  @override
  Future<void> playBgm({double volume = 0.5}) async {}

  @override
  Future<void> stopBgm() async {}
}

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  }) async {}
}

ProviderContainer _makeContainer({AudioService? audio}) => ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(
          audio ?? _FakeAudioService(),
        ),
        progressRepositoryProvider.overrideWithValue(
          _FakeProgressRepository(),
        ),
      ],
    );

void main() {
  group('SmoothPursuitNotifier initial state', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default speedMs is 3000', () {
      expect(container.read(smoothPursuitProvider).speedMs, 3000);
    });

    test('minSpeedMs is 1500', () {
      expect(container.read(smoothPursuitProvider).minSpeedMs, 1500);
    });

    test('maxSpeedMs is 5000', () {
      expect(container.read(smoothPursuitProvider).maxSpeedMs, 5000);
    });
  });

  group('SmoothPursuitNotifier ExerciseDuration', () {
    test('default selectedDuration is s60', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(
        container.read(smoothPursuitProvider).selectedDuration,
        ExerciseDuration.s60,
      );
    });

    test('setDuration changes selectedDuration when idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      container
          .read(smoothPursuitProvider.notifier)
          .setDuration(ExerciseDuration.m2);
      expect(
        container.read(smoothPursuitProvider).selectedDuration,
        ExerciseDuration.m2,
      );
    });

    test('selectedDuration preserved after reset', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      container
          .read(smoothPursuitProvider.notifier)
          .setDuration(ExerciseDuration.s30);
      container.read(smoothPursuitProvider.notifier).reset();
      expect(
        container.read(smoothPursuitProvider).selectedDuration,
        ExerciseDuration.s30,
      );
    });
  });

  group('SmoothPursuitNotifier countdown', () {
    test('startExercise with finite duration sets timeLeftSeconds', () {
      fakeAsync((async) {
        final container = _makeContainer();
        addTearDown(container.dispose);
        container
            .read(smoothPursuitProvider.notifier)
            .setDuration(ExerciseDuration.s30);
        container.read(smoothPursuitProvider.notifier).startExercise();

        expect(
          container.read(smoothPursuitProvider).timeLeftSeconds,
          30,
        );
        async.elapse(const Duration(seconds: 1));
        expect(
          container.read(smoothPursuitProvider).timeLeftSeconds,
          29,
        );
      });
    });

    test('startExercise with infinite duration keeps timeLeftSeconds null', () {
      fakeAsync((async) {
        final container = _makeContainer();
        addTearDown(container.dispose);
        container
            .read(smoothPursuitProvider.notifier)
            .setDuration(ExerciseDuration.infinite);
        container.read(smoothPursuitProvider.notifier).startExercise();

        async.elapse(const Duration(seconds: 5));
        expect(
          container.read(smoothPursuitProvider).timeLeftSeconds,
          isNull,
        );
      });
    });

    test('countdown auto-stops and plays success at zero', () {
      fakeAsync((async) {
        final audio = _FakeAudioService();
        final container = _makeContainer(audio: audio);
        addTearDown(container.dispose);
        container
            .read(smoothPursuitProvider.notifier)
            .setDuration(ExerciseDuration.s30);
        container.read(smoothPursuitProvider.notifier).startExercise();

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(
          container.read(smoothPursuitProvider).status,
          ExerciseStatus.saved,
        );
        expect(audio.played, contains(AudioCue.success));
      });
    });
  });
}
```

- [ ] **Step 2: Correr los tests — deben fallar**

```bash
flutter test test/viewmodels/smooth_pursuit_vm_test.dart
```

Esperado: error de compilación — `selectedDuration`, `setDuration`, `timeLeftSeconds` no existen en `SmoothPursuitState`.

- [ ] **Step 3: Implementar los cambios en `SmoothPursuitState` y Notifier**

Abre `lib/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart`.

**3a.** Añade `dart:async` al import al inicio del archivo:

```dart
import 'dart:async';
```

**3b.** Actualiza el import de `saccadic_jumps_viewmodel.dart` para incluir `ExerciseDuration`:

```dart
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration, ExerciseStatus;
```

**3c.** Añade el sentinel privado antes de `class SmoothPursuitState`:

```dart
class _Absent {
  const _Absent();
}
const _absent = _Absent();
```

**3d.** Reemplaza la clase `SmoothPursuitState` completa:

```dart
class SmoothPursuitState {
  const SmoothPursuitState({
    this.pattern = PursuitPattern.circle,
    this.status = ExerciseStatus.idle,
    this.speedMs = _defaultSpeedMs,
    this.isMuted = false,
    this.minSpeedMs = _minSpeed,
    this.maxSpeedMs = _maxSpeed,
    this.selectedDuration = ExerciseDuration.s60,
    this.timeLeftSeconds,
  });

  static const int _defaultSpeedMs = 3000;
  static const int _minSpeed = 1500;
  static const int _maxSpeed = 5000;

  final PursuitPattern pattern;
  final ExerciseStatus status;
  final int speedMs;
  final bool isMuted;
  final int minSpeedMs;
  final int maxSpeedMs;
  final ExerciseDuration selectedDuration;
  final int? timeLeftSeconds;

  SmoothPursuitState copyWith({
    PursuitPattern? pattern,
    ExerciseStatus? status,
    int? speedMs,
    bool? isMuted,
    ExerciseDuration? selectedDuration,
    Object? timeLeftSeconds = _absent,
  }) {
    return SmoothPursuitState(
      pattern: pattern ?? this.pattern,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      isMuted: isMuted ?? this.isMuted,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      timeLeftSeconds: timeLeftSeconds is _Absent
          ? this.timeLeftSeconds
          : timeLeftSeconds as int?,
    );
  }
}
```

**3e.** Reemplaza `SmoothPursuitNotifier` completo:

```dart
class SmoothPursuitNotifier extends Notifier<SmoothPursuitState> {
  Timer? _countdownTimer;

  @override
  SmoothPursuitState build() {
    ref.onDispose(_cancelCountdown);
    return const SmoothPursuitState();
  }

  void setPattern(PursuitPattern p) {
    if (state.status != ExerciseStatus.idle) return;
    state = state.copyWith(pattern: p);
  }

  void setSpeed(int ms) => state = state.copyWith(speedMs: ms);

  void setDuration(ExerciseDuration d) {
    if (state.status != ExerciseStatus.idle) return;
    state = state.copyWith(selectedDuration: d, timeLeftSeconds: null);
  }

  void startExercise() {
    if (state.status == ExerciseStatus.active) return;
    final seconds = state.selectedDuration.seconds;
    state = state.copyWith(
      status: ExerciseStatus.active,
      timeLeftSeconds: seconds,
    );
    if (!state.isMuted) {
      ref.read(audioServiceProvider).playBgm();
    }
    if (seconds != null) {
      _startCountdown();
    }
  }

  void stopAndSave() {
    if (state.status != ExerciseStatus.active) return;
    _cancelCountdown();
    ref.read(audioServiceProvider).stopBgm();
    state = state.copyWith(status: ExerciseStatus.saving);
    _persist();
  }

  Future<void> _persist() async {
    await ref.read(progressRepositoryProvider).saveProgress(
          exerciseType: 'smooth_pursuit',
          maxSpeedMs: state.speedMs,
        );
    state = state.copyWith(status: ExerciseStatus.saved);
  }

  void toggleMute() {
    final muted = !state.isMuted;
    state = state.copyWith(isMuted: muted);
    final audio = ref.read(audioServiceProvider);
    if (state.status == ExerciseStatus.active) {
      muted ? audio.stopBgm() : audio.playBgm();
    }
  }

  void reset() {
    _cancelCountdown();
    ref.read(audioServiceProvider).stopBgm();
    state = SmoothPursuitState(selectedDuration: state.selectedDuration);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = state.timeLeftSeconds;
      if (left == null) return;
      if (left <= 1) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        ref.read(audioServiceProvider).play(AudioCue.success);
        stopAndSave();
      } else {
        state = state.copyWith(timeLeftSeconds: left - 1);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
}
```

> **Nota:** `SmoothPursuitNotifier` no tiene `import` de `AudioCue` actualmente. Añade al inicio del archivo:
> ```dart
> import 'package:optiflow/core/utils/audio_cue.dart';
> ```

- [ ] **Step 4: Correr los tests — deben pasar**

```bash
flutter test test/viewmodels/smooth_pursuit_vm_test.dart
```

Esperado: todos los tests pasando.

- [ ] **Step 5: Correr la suite completa para detectar regresiones**

```bash
flutter test
```

Esperado: todos los tests pasando.

- [ ] **Step 6: Análisis estático**

```bash
flutter analyze lib/features/vision_training/presentation/viewmodels/
```

Esperado: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart \
        test/viewmodels/smooth_pursuit_vm_test.dart
git commit -m "feat(smooth-pursuit): implement countdown timer with auto-save"
```

---

## Task 5: `SaccadicJumpsView` — HUD, selector de duración, label

**Files:**
- Modify: `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart`

- [ ] **Step 1: Añadir `_CountdownHud` al Stack de `_ExerciseArea`**

Abre `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart`.

**1a.** En la clase `_ExerciseArea`, en el `Stack` que contiene `Align`, `_IdleOverlay` y `_SavedOverlay`, añade `const _CountdownHud()` como último hijo:

```dart
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
    const _CountdownHud(),
  ],
);
```

**1b.** Añade la clase `_CountdownHud` al final del archivo, antes del cierre del archivo:

```dart
class _CountdownHud extends ConsumerWidget {
  const _CountdownHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      saccadicJumpsProvider.select((s) => s.status),
    );
    final duration = ref.watch(
      saccadicJumpsProvider.select((s) => s.selectedDuration),
    );
    final timeLeft = ref.watch(
      saccadicJumpsProvider.select((s) => s.timeLeftSeconds),
    );

    if (status != ExerciseStatus.active ||
        duration == ExerciseDuration.infinite ||
        timeLeft == null) {
      return const SizedBox.shrink();
    }

    final minutes = timeLeft ~/ 60;
    final seconds = timeLeft % 60;
    final label =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Positioned(
      top: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Actualizar `_ControlPanel` — Fila 3 con selector de duración**

En el método `build` de `_ControlPanel`, localiza la sección `// Row 3: action button` y reemplaza el `Row` de los botones:

```dart
// Row 3: duration selector + action button
const SizedBox(height: 4),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SegmentedButton<ExerciseDuration>(
      segments: ExerciseDuration.values
          .map((d) => ButtonSegment(value: d, label: Text(d.label)))
          .toList(),
      selected: {ref.watch(saccadicJumpsProvider.select((s) => s.selectedDuration))},
      onSelectionChanged: isActive || isSaving || isSaved
          ? null
          : (s) => notifier.setDuration(s.first),
    ),
    const SizedBox(width: 16),
    if (!isActive && !isSaved)
      ElevatedButton.icon(
        onPressed: isSaving ? null : notifier.startExercise,
        icon: const Icon(Icons.play_arrow),
        label: const Text('INICIAR'),
      ),
    if (isActive)
      ElevatedButton.icon(
        onPressed: notifier.stopAndSave,
        icon: const Icon(Icons.stop),
        label: const Text('DETENER Y GUARDAR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Colors.white,
        ),
      ),
    if (isSaved)
      ElevatedButton.icon(
        onPressed: notifier.reset,
        icon: const Icon(Icons.refresh),
        label: const Text('NUEVO EJERCICIO'),
      ),
  ],
),
```

> **Nota:** `ExerciseDuration` ya está en scope porque se importa transitivamente desde `saccadic_jumps_viewmodel.dart`. No se requiere import adicional.

- [ ] **Step 3: Añadir label "Práctica Libre" al `Positioned` del botón de retroceso**

Localiza el `Positioned` con el `IconButton` de retroceso en `SaccadicJumpsView.build()` y reemplázalo:

```dart
Positioned(
  top: 8,
  left: 8,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconButton(
        tooltip: 'Volver al menú',
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Text(
          'Práctica Libre',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    ],
  ),
),
```

- [ ] **Step 4: Análisis estático**

```bash
flutter analyze lib/features/vision_training/presentation/views/saccadic_jumps_view.dart
```

Esperado: `No issues found!`

- [ ] **Step 5: Correr los tests**

```bash
flutter test
```

Esperado: todos los tests pasando.

- [ ] **Step 6: Commit**

```bash
git add lib/features/vision_training/presentation/views/saccadic_jumps_view.dart
git commit -m "feat(saccadic-view): add countdown HUD, duration selector, Práctica Libre label"
```

---

## Task 6: `SmoothPursuitView` — HUD, selector de duración, label

**Files:**
- Modify: `lib/features/vision_training/presentation/views/smooth_pursuit_view.dart`

- [ ] **Step 1: Actualizar import para incluir `ExerciseDuration`**

Abre `lib/features/vision_training/presentation/views/smooth_pursuit_view.dart`.

Localiza el import de `saccadic_jumps_viewmodel.dart` (está cerca de la línea 8) y actualiza la cláusula `show`:

```dart
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration, ExerciseStatus;
```

> **Motivo:** Los imports de Dart no son transitivos. `ExerciseDuration` vive en `saccadic_jumps_viewmodel.dart` y debe importarse explícitamente en el archivo de la vista.

- [ ] **Step 2: Añadir `_CountdownHud` al Stack de `_StimulusArea`**

En `_StimulusArea.build()`, añade `const _SmoothCountdownHud()` como último hijo del `Stack`:

```dart
return Stack(
  children: [
    if (status == ExerciseStatus.active)
      AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value * 2 * math.pi;
          final (dx, dy) = pattern.position(t);
          return Align(
            alignment: Alignment(dx * 0.90, dy * 0.90),
            child: child,
          );
        },
        child: const _StimulusCircle(),
      )
    else
      const Center(child: _StimulusCircle()),
    if (status == ExerciseStatus.idle) const _IdleOverlay(),
    if (status == ExerciseStatus.saving) const _SavingOverlay(),
    if (status == ExerciseStatus.saved) const _SavedOverlay(),
    const _SmoothCountdownHud(),
  ],
);
```

**1b.** Añade la clase `_SmoothCountdownHud` al final del archivo:

```dart
class _SmoothCountdownHud extends ConsumerWidget {
  const _SmoothCountdownHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      smoothPursuitProvider.select((s) => s.status),
    );
    final duration = ref.watch(
      smoothPursuitProvider.select((s) => s.selectedDuration),
    );
    final timeLeft = ref.watch(
      smoothPursuitProvider.select((s) => s.timeLeftSeconds),
    );

    if (status != ExerciseStatus.active ||
        duration == ExerciseDuration.infinite ||
        timeLeft == null) {
      return const SizedBox.shrink();
    }

    final minutes = timeLeft ~/ 60;
    final seconds = timeLeft % 60;
    final label =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Positioned(
      top: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
```

> **Nota:** `ExerciseDuration` está disponible gracias al import actualizado en Step 1.

- [ ] **Step 3: Actualizar `_ControlPanel` — Fila 3 con selector de duración**

En `_ControlPanel.build()`, localiza la sección `// Row 3: action button` y reemplaza el `Row`:

```dart
// Row 3: duration selector + action button
const SizedBox(height: 4),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SegmentedButton<ExerciseDuration>(
      segments: ExerciseDuration.values
          .map((d) => ButtonSegment(value: d, label: Text(d.label)))
          .toList(),
      selected: {state.selectedDuration},
      onSelectionChanged: isActive || isSaving || isSaved
          ? null
          : (s) => notifier.setDuration(s.first),
    ),
    const SizedBox(width: 16),
    if (!isActive && !isSaved)
      ElevatedButton.icon(
        onPressed: isSaving ? null : notifier.startExercise,
        icon: const Icon(Icons.play_arrow),
        label: const Text('INICIAR'),
      ),
    if (isActive)
      ElevatedButton.icon(
        onPressed: notifier.stopAndSave,
        icon: const Icon(Icons.stop),
        label: const Text('DETENER Y GUARDAR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Colors.white,
        ),
      ),
    if (isSaved)
      ElevatedButton.icon(
        onPressed: notifier.reset,
        icon: const Icon(Icons.refresh),
        label: const Text('NUEVO EJERCICIO'),
      ),
  ],
),
```

- [ ] **Step 4: Añadir label "Práctica Libre" al `Positioned` del botón de retroceso**

En `_SmoothPursuitViewState.build()`, localiza el `Positioned` con el `IconButton` de retroceso y reemplázalo:

```dart
Positioned(
  top: 8,
  left: 8,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconButton(
        tooltip: 'Volver al menú',
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onPressed: () {
          notifier.reset();
          Navigator.pop(context);
        },
      ),
      Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Text(
          'Práctica Libre',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    ],
  ),
),
```

- [ ] **Step 5: Análisis estático completo**

```bash
flutter analyze
```

Esperado: `No issues found!`

- [ ] **Step 6: Correr todos los tests**

```bash
flutter test
```

Esperado: todos los tests pasando.

- [ ] **Step 7: Commit**

```bash
git add lib/features/vision_training/presentation/views/smooth_pursuit_view.dart
git commit -m "feat(smooth-pursuit-view): add countdown HUD, duration selector, Práctica Libre label"
```

---

## Task 7: Actualizar `PROJECT_STATE.md`

**Files:**
- Modify: `PROJECT_STATE.md`

- [ ] **Step 1: Añadir Paso 11 a la tabla de estado**

Localiza la tabla `## Estado Actual` y añade la fila:

```markdown
| 11   | Temporizador de Práctica Libre: countdown + auto-guardado + success cue | ✅ Completado |
```

- [ ] **Step 2: Actualizar el bloque de resumen de versión**

Localiza el bloque `## Módulo 1 — Versión 6 ✅` y actualiza:
- Cambia el número a `Versión 7 ✅`
- Añade al final del bloque:

```
Práctica Libre: ambos ejercicios soportan duración configurable (∞ / 30s / 60s / 2m, default 60s). Countdown HUD flotante al 50% de opacidad. Auto-guardado + AudioCue.success al expirar. Panel compacto: selector de duración en Fila 3 junto al botón de acción.
Fecha: 2026-05-05
```

- [ ] **Step 3: Commit final**

```bash
git add PROJECT_STATE.md
git commit -m "docs: update PROJECT_STATE to v7 with free-practice timer"
```

---

## Checklist de criterios de completitud

- [ ] `flutter analyze` reporta 0 issues
- [ ] `flutter test` pasa todos los tests (incluyendo los nuevos)
- [ ] HUD muestra cuenta regresiva cuando activo + duración finita
- [ ] HUD oculto con duración ∞ o cuando en idle
- [ ] Al llegar a 0: ejercicio se detiene, progreso guardado, suena `success.mp3`
- [ ] Con ∞: ejercicio corre sin límite de tiempo
- [ ] Botón "DETENER Y GUARDAR" manual funciona igual que antes
- [ ] `selectedDuration` se conserva al pulsar "NUEVO EJERCICIO"
- [ ] Selector de duración deshabilitado durante ejercicio activo/guardando/guardado
- [ ] Label "Práctica Libre" visible en ambas vistas
- [ ] `PROJECT_STATE.md` actualizado a Versión 7
