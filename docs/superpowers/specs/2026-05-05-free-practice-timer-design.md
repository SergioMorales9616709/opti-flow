# Diseño: Temporizador de Práctica Libre

**Fecha:** 2026-05-05
**Feature branch:** `feature/timer`
**Contexto:** Paso previo al futuro "Orquestador de Rutinas". Establece el concepto de sesiones con tiempo limitado en los ejercicios individuales.

---

## Resumen

Añadir un sistema de cuenta regresiva (30s / 60s / 2m / ∞) a `SaccadicJumpsView` y `SmoothPursuitView`. Al expirar el tiempo, el ejercicio se detiene, guarda el progreso automáticamente y reproduce un cue de éxito. El modo se denomina "Práctica Libre" para diferenciarlo de las futuras rutinas automáticas.

---

## 1. Modelo de datos — `ExerciseDuration`

Enhanced enum añadido en `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart`, importado por `smooth_pursuit_viewmodel.dart` igual que ya importa `ExerciseStatus`.

```dart
enum ExerciseDuration {
  infinite('∞',   null),
  s30     ('30s',  30),
  s60     ('60s',  60),
  m2      ('2m',  120);

  const ExerciseDuration(this.label, this.seconds);
  final String label;
  final int? seconds; // null = sin límite
}
```

### Campos nuevos en los estados

| Campo | Tipo | Default | Descripción |
|---|---|---|---|
| `selectedDuration` | `ExerciseDuration` | `ExerciseDuration.s60` | Duración elegida por el usuario |
| `timeLeftSeconds` | `int?` | `null` | `null` en idle/infinito; cuenta regresiva en activo |

---

## 2. ViewModels — lógica de countdown

### SaccadicJumpsNotifier

Ya posee `Timer? _timer` (saltos visuales). Se añade `Timer? _countdownTimer` independiente.

**`startExercise()`** — además del timer de saltos:
- Si `selectedDuration != infinite`: inicializa `timeLeftSeconds = selectedDuration.seconds` y arranca `_countdownTimer = Timer.periodic(Duration(seconds: 1), ...)`.
- Cada tick: decrementa `timeLeftSeconds`.
- Cuando `timeLeftSeconds` llega a `0`: llama `stopAndSave()` y `ref.read(audioServiceProvider).play(AudioCue.success)`.

**`setDuration(ExerciseDuration d)`** — solo ejecuta si `status == idle`. Actualiza `selectedDuration` y pone `timeLeftSeconds = null`.

**`_cancelTimer()`** — cancela tanto `_timer` como `_countdownTimer` y los pone en `null`.

**`reset()`** — conserva `selectedDuration` (el usuario no tiene que re-seleccionarlo entre sesiones). Resetea `timeLeftSeconds` a `null`.

**`dispose`** — ya cubierto por `ref.onDispose(_cancelTimer)` en `build()`.

### SmoothPursuitNotifier

Mismo patrón con un único `Timer? _countdownTimer`. El `AnimationController` sigue viviendo en la View (no cambia).

**`stopAndSave()`** — ya detiene BGM. Añadir llamada a `play(AudioCue.success)` después de `stopBgm()` antes de persistir.

**`reset()`** — conserva `selectedDuration`.

---

## 3. AudioService — cue `success`

### `audio_cue.dart`

```dart
enum AudioCue {
  click  ('audio/click.mp3',    isBgm: false),
  bgmFlow('audio/bgm_flow.mp3', isBgm: true),
  success('audio/success.mp3',  isBgm: false); // nuevo
  ...
}
```

El asset `assets/audio/success.mp3` ya existe y está cubierto por la declaración de directorio en `pubspec.yaml` — no requiere cambio en pubspec.

El cue se pre-carga en `AudioService.init()` junto con `click` (mismo código; el loop `for (final cue in AudioCue.values.where((c) => !c.isBgm))` lo incluye automáticamente). Se reproduce con el método `play()` existente.

---

## 4. UI

### HUD del reloj (`_CountdownHud`)

- Widget nuevo, colocado en el `Stack` de `_ExerciseArea` / `_StimulusArea`.
- Alineación: `Alignment.topCenter`, con `Padding(top: 24)` para no solapar el botón de retroceso.
- **Visibilidad:** solo cuando `status == active && selectedDuration != infinite && timeLeftSeconds != null`.
- Formato: `MM:SS` (ej. `01:00` → `00:59` → … → `00:00`).
- Estilo: font monospace, ~32px, `colorScheme.onSurface.withValues(alpha: 0.5)`.
- Usa `ref.watch(provider.select(...))` para solo `timeLeftSeconds`, evitando rebuilds del área de ejercicio.

### Selector de duración — Fila 3 del panel (Opción C)

La Fila 3 actual solo tiene el botón de acción. Pasa a ser un `Row` con `MainAxisAlignment.center`:

```
[ SegmentedButton<ExerciseDuration> ]   SizedBox(width: 16)   [ Botón acción ]
```

- `SegmentedButton` deshabilitado (`onSelectionChanged: null`) durante `active`, `saving`, `saved`.
- No cambia el número de filas del panel.

### Etiqueta "Práctica Libre"

Texto pequeño (12px, `colorScheme.onSurface.withValues(alpha: 0.4)`) colocado en el `Positioned` superior-izquierdo, debajo del `IconButton` de retroceso. Queda agrupado visualmente sin consumir espacio de layout.

```dart
Positioned(
  top: 8, left: 8,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconButton(/* back */),
      Padding(
        padding: EdgeInsets.only(left: 12),
        child: Text('Práctica Libre', style: /* 12px, 40% opacity */),
      ),
    ],
  ),
)
```

---

## 5. Archivos afectados

| Archivo | Cambio |
|---|---|
| `lib/core/utils/audio_cue.dart` | Añade `success` al enum |
| `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart` | Añade `ExerciseDuration` enum, campos al estado, `_countdownTimer`, `setDuration()` |
| `lib/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart` | Importa `ExerciseDuration`, añade campos, `_countdownTimer`, `setDuration()` |
| `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart` | Añade `_CountdownHud`, selector de duración en fila 3, label "Práctica Libre" |
| `lib/features/vision_training/presentation/views/smooth_pursuit_view.dart` | Idem |
| `PROJECT_STATE.md` | Documenta Paso 11 |

---

## 6. Criterios de completitud

- [ ] `flutter analyze` reporta 0 issues.
- [ ] Cuenta regresiva inicia al presionar INICIAR con duración finita.
- [ ] Al llegar a 0: ejercicio se detiene, progreso guardado, suena `success.mp3`.
- [ ] Con ∞: ejercicio corre sin límite; HUD no aparece.
- [ ] Botón "DETENER Y GUARDAR" manual funciona igual que antes (sin cambios de comportamiento).
- [ ] `selectedDuration` se conserva al pulsar "NUEVO EJERCICIO".
- [ ] Selector deshabilitado durante el ejercicio activo.
- [ ] Label "Práctica Libre" visible en ambas vistas.
- [ ] `PROJECT_STATE.md` actualizado.
