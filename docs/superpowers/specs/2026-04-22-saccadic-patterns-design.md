# Saccadic Patterns Refactor — Design Spec

**Date:** 2026-04-22  
**Scope:** Módulo 1 — Visión / Saltos Sacádicos  
**Status:** Approved

---

## Goal

Refactorizar el ejercicio de Saltos Sacádicos para que soporte múltiples patrones de movimiento geométrico (Horizontal, Vertical, Z, Cruz), sea cómodo de usar con velocidades humanas, y mantenga la persistencia SQLite existente sin cambios.

---

## Out of Scope

- Internacionalización (i18n) — tarea separada posterior.
- Cambios al esquema de base de datos.
- Otros módulos de la app.

---

## Architecture

**Patrón:** Feature-First + MVVM con Riverpod 2.x.  
**Enfoque elegido:** Option B — `SaccadicPattern` vive en `domain/`, el ViewModel lo importa.

### Archivos afectados

| Acción | Archivo |
|--------|---------|
| Crear | `lib/features/vision_training/domain/saccadic_pattern.dart` |
| Modificar | `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart` |
| Modificar | `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart` |
| Modificar | `PROJECT_STATE.md` |

---

## Section 1: Domain Layer

**Archivo:** `lib/features/vision_training/domain/saccadic_pattern.dart`

```dart
import 'package:flutter/material.dart';

enum SaccadicPattern {
  horizontal,
  vertical,
  zPattern,
  crossPattern;

  List<Alignment> get sequence => switch (this) {
    SaccadicPattern.horizontal   => [Alignment(-0.88, 0),    Alignment(0.88, 0)],
    SaccadicPattern.vertical     => [Alignment(0, -0.88),    Alignment(0, 0.88)],
    SaccadicPattern.zPattern     => [Alignment(-0.88, -0.88), Alignment(0.88, -0.88),
                                     Alignment(-0.88, 0.88),  Alignment(0.88, 0.88)],
    SaccadicPattern.crossPattern => [Alignment(0, -0.88),    Alignment(0, 0.88),
                                     Alignment(-0.88, 0),     Alignment(0.88, 0)],
  };

  String get label => switch (this) {
    SaccadicPattern.horizontal   => 'Horizontal',
    SaccadicPattern.vertical     => 'Vertical',
    SaccadicPattern.zPattern     => 'Patrón Z',
    SaccadicPattern.crossPattern => 'Cruz',
  };
}
```

El enum es la única fuente de verdad para coordenadas y etiquetas. No tiene dependencias de Riverpod ni de la capa de presentación. `label` queda en español hasta que se implemente i18n.

---

## Section 2: ViewModel

**Archivo:** `lib/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart`

### Estado

`StimulusPosition` se elimina. El nuevo estado:

```dart
class SaccadicJumpsState {
  final SaccadicPattern pattern;
  final int stepIndex;
  final ExerciseStatus status;
  final int speedMs;
  final int minSpeedMs;
  final int maxSpeedMs;

  Alignment get currentAlignment => pattern.sequence[stepIndex];

  const SaccadicJumpsState({...});
  SaccadicJumpsState copyWith({...});
}
```

### Valores de velocidad

| Parámetro | Antes | Después |
|-----------|-------|---------|
| Default | 800 ms | 1200 ms |
| Mínimo (rápido) | 200 ms | 400 ms |
| Máximo (lento) | 1000 ms | 2000 ms |

### Notifier — cambios

- **Tick del timer:** `stepIndex = (stepIndex + 1) % state.pattern.sequence.length`
- **Método nuevo:** `void setPattern(SaccadicPattern p)` — solo activo en estado `idle`; hace reset del `stepIndex` a 0.
- **Estado inicial:** `pattern: SaccadicPattern.horizontal`, `stepIndex: 0`
- **Flujo INICIAR → DETENER Y GUARDAR → NUEVO EJERCICIO:** sin cambios.
- **Persistencia:** `_persist()` sigue guardando `max_speed_ms` a SQLite sin cambios.

---

## Section 3: Vista

**Archivo:** `lib/features/vision_training/presentation/views/saccadic_jumps_view.dart`

### Layout (Column, top → bottom)

1. `_ExerciseArea` — `Expanded`
2. `Divider`
3. `_PatternSelector` — **nuevo widget privado**
4. `_ControlPanel` — sin cambios estructurales, solo valores de slider

### _ExerciseArea

- **Crosshair eliminado** (pantalla limpia).
- `AnimatedAlign` reemplazado por `Align` simple — salto instantáneo, sin duración de animación.
- El `Alignment` proviene de `state.currentAlignment` (getter del estado).
- `AnimatedSwitcher` para el cambio de símbolo se mantiene.

### _PatternSelector (nuevo)

```dart
SegmentedButton<SaccadicPattern>(
  segments: SaccadicPattern.values.map((p) =>
    ButtonSegment(value: p, label: Text(p.label))
  ).toList(),
  selected: {state.pattern},
  onSelectionChanged: isSelectable ? (s) => notifier.setPattern(s.first) : null,
)
```

`isSelectable` es `true` solo cuando `status == ExerciseStatus.idle`.

### _ControlPanel

Solo actualiza las constantes del Slider:
- `min: 400`, `max: 2000`, `divisions: 32`

### Widgets sin cambios

`_StimulusWidget`, `_IdleOverlay`, `_SavedOverlay`.

---

## Section 4: PROJECT_STATE.md

Actualizar la tabla de estado del Módulo 1 para reflejar que los saltos sacádicos ahora soportan patrones múltiples (Horizontal, Vertical, Z, Cruz) y rango de velocidad 400–2000 ms.

---

## Testing

- `flutter analyze` debe reportar 0 issues.
- El smoke test existente (`App launches smoke test`) debe seguir pasando sin cambios.
- Validación manual: probar los 4 patrones, cambiar velocidad, completar ejercicio y verificar que el guardado en SQLite funcione.
