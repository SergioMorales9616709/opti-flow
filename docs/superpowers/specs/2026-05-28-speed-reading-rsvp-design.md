# Design: Módulo 2 — Motor de Lectura Veloz + Modo RSVP

**Fecha:** 2026-05-28  
**Rama:** feat/fastReading  
**Estado:** Aprobado

---

## Contexto

OptiFlow tiene el Módulo 1 (Visión) completo. Este diseño cubre la primera iteración del Módulo 2: un Motor de Textos y el modo RSVP (Rapid Serial Visual Presentation). El Dashboard actual (`VisionDashboardView`) se convierte en el hub principal de la app (`MainDashboardView`).

---

## Estructura de Archivos

### Nuevos

```
lib/
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       └── views/
│   │           └── main_dashboard_view.dart   ← movido y renombrado
│   └── speed_reading/
│       ├── data/
│       │   └── text_repository.dart
│       └── presentation/
│           ├── viewmodels/
│           │   └── rsvp_viewmodel.dart
│           └── views/
│               └── rsvp_view.dart
assets/
└── texts/
    └── cuento_1.txt                           ← ya existe (886 palabras)
```

### Modificados

| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | Agregar `- assets/texts/` a la sección `assets:` |
| `main.dart` | Actualizar import del home a `MainDashboardView` |
| `features/vision_training/.../vision_dashboard_view.dart` | Eliminar (contenido movido) |

---

## Capa de Datos — `TextRepository`

```dart
abstract interface class TextRepository {
  Future<List<String>> loadWords(String assetPath);
}

class TextRepositoryImpl implements TextRepository {
  @override
  Future<List<String>> loadWords(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
  }
}

final textRepositoryProvider = Provider<TextRepository>(
  (_) => TextRepositoryImpl(),
);
```

- Usa `rootBundle` de `flutter/services.dart` (sin dependencias externas)
- Limpia saltos de línea y espacios dobles antes de tokenizar
- Devuelve `List<String>` donde cada elemento es una palabra (puede incluir puntuación pegada, ej. `"casa,"`)

---

## Lógica de Negocio — `RsvpViewModel`

### Estado

```dart
class RsvpState {
  final List<String> words;      // vacío hasta que cargue
  final int currentIndex;        // índice de la palabra actual
  final int currentWpm;          // velocidad en WPM (rango 200–1200, default 300)
  final bool isPlaying;
  final bool isMuted;
  final bool isLoaded;           // false durante la carga inicial del asset
}
```

### Matemática WPM

```
ms_base = 60000 ~/ currentWpm
```

### Pausas Dinámicas (Neuro-Lectura)

Antes de cada `Future.delayed`, se inspeccionan los últimos caracteres de la palabra actual:

| Condición | Multiplicador | Ejemplos |
|---|---|---|
| Termina en `,` | `× 1.5` | `"casa,"` `"rojo,"` |
| Termina en `.` `:` `?` `!` `;` | `× 2.5` | `"fin."` `"¿bien?"` `"valor:"` |
| Palabra normal | `× 1.0` | `"el"` `"perro"` |

> **Razón:** A velocidades >500 WPM el cerebro necesita micro-pausas al detectar fronteras de idea. Sin ellas, la comprensión se degrada.

### Async Loop

```dart
bool _running = false;

Future<void> startReading() async {
  _running = true;
  state = state.copyWith(isPlaying: true);
  if (!state.isMuted) audioService.playBgm(AudioCue.bgmFlow);

  while (_running && state.currentIndex < state.words.length) {
    final word = state.words[state.currentIndex];
    final ms = _pauseFor(word, state.currentWpm);
    await Future.delayed(Duration(milliseconds: ms));
    if (!_running) break;                             // guard post-await
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  if (_running) _onFinished();
}

int _pauseFor(String word, int wpm) {
  final base = 60000 ~/ wpm;
  if (word.endsWith(',')) return (base * 1.5).round();
  final stops = {'.', ':', '?', '!', ';'};
  if (stops.any((s) => word.endsWith(s))) return (base * 2.5).round();
  return base;
}
```

### Lifecycle

```dart
@override
RsvpState build() {
  ref.onDispose(() {
    _running = false;          // mata el loop si el usuario pulsa Atrás
    audioService.stopBgm();
  });
  _loadText();
  return const RsvpState();
}
```

### Persistencia

Al finalizar (natural o pausa):
```dart
await progressRepository.saveProgress(
  exerciseType: 'speed_reading_rsvp',
  maxSpeedMs: state.currentWpm,   // reutiliza columna; guarda WPM
);
```

### Métodos públicos

| Método | Descripción |
|---|---|
| `startReading()` | Inicia/reanuda el loop, arranca BGM |
| `pause()` | `_running = false`, detiene BGM, persiste |
| `setWpm(int)` | Actualiza `currentWpm`; el loop lo lee en la próxima iteración |
| `toggleMute()` | Sincroniza BGM si `isPlaying` |

---

## Vista — `RsvpView`

### Layout

```
┌────────────────────────────────────────┐
│                                        │
│          [Área Central — Flexible]     │
│                                        │
│         PALABRA  (fontSize: 64)        │
│                                        │
│ ════════════ Panel Inferior ═══════════│
│ Fila 1:  "300 WPM"          [🔊 Mute] │
│ Fila 2:  Slider  200 ────●──── 1200   │
│ Fila 3:  [← Atrás] [████░░░░] [▶/⏸] │
└────────────────────────────────────────┘
```

### Reglas de implementación

- **Sin AppBar** — patrón idéntico al Módulo 1
- **Área central:** `Flexible/Expanded` con la palabra en `Theme.of(context).textTheme.displayLarge` o `fontSize: 64`, centrada vertical y horizontalmente
- **Barra de progreso:** `LinearProgressIndicator(value: currentIndex / max(1, words.length))`
- **Slider:** `min: 200, max: 1200, divisions: null`; llama a `setWpm()` en `onChanged` — el loop ajusta velocidad sin interrupción
- **Botón atrás:** `TextButton.icon(icon: Icons.arrow_back_ios, label: Text('ATRÁS'))` — igual al Módulo 1
- **Colores:** 100% de `Theme.of(context).colorScheme` — cero hardcoded
- **Sin `ConsumerStatefulWidget`:** no hay `AnimationController`; la vista es `ConsumerWidget` puro

---

## Dashboard — `MainDashboardView`

Dos secciones visuales separadas por labels de sección:

```
┌────────────────────────────────────────┐
│ ENTRENAMIENTO VISUAL      [Temas]      │  ← header existente
├────────────────────────────────────────│
│                                        │
│  [Sacádicos] [Seguimiento] [Periférica]│  ← Wrap existente
│                                        │
│ LECTURA VELOZ                          │  ← nuevo label
│                                        │
│  [RSVP Velocidad]                      │  ← nueva Hero Card
│                                        │
└────────────────────────────────────────┘
```

- El widget `_ExerciseCard` se reutiliza sin cambios
- Icon sugerido: `Icons.speed` o `Icons.auto_stories`
- Subtitle: `'RSVP · lectura serial'`
- La clase se renombra `MainDashboardView`; el archivo se mueve a `features/dashboard/presentation/views/`
- `main.dart` actualiza el import

---

## Decisiones Arquitectónicas Tomadas

| Decisión | Elección | Razón |
|---|---|---|
| Ubicación del Dashboard | `features/dashboard/` (nueva carpeta) | Feature-First limpio; el hub ya no pertenece a visión |
| Mecanismo del loop | Async loop + `Future.delayed` | Ajuste en tiempo real sin cancelar timers; sin stutters |
| Pausas dinámicas | Multiplicadores por puntuación | Neuro-lectura: micro-pausas cognitivas en fronteras de idea |
| Audio | `AudioCue.bgmFlow` (no metrónomo) | A 800 WPM el metrónomo es contraproducente |
| Persistencia | Columna `max_speed_ms` con valor WPM | Reutiliza tabla existente; semánticamente anotado en doc |

---

## Fuera de Alcance (Esta Iteración)

- Múltiples textos / selector de textos
- Estadísticas de sesión (velocidad promedio, palabras leídas)
- Modo Chunk (2–3 palabras por flash)
- Resaltado de palabras clave
