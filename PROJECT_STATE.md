# OptiFlow — Estado del Proyecto

## Descripción
Software de entrenamiento cognitivo y lectura rápida para escritorio (Windows/Linux).
Construido con Flutter Desktop + Dart.

---

## Arquitectura

### Stack
- **Frontend:** Flutter Desktop (Dart)
- **Gestión de estado:** `flutter_riverpod` (MVVM)
- **Almacenamiento local:** SQLite via `sqflite_common_ffi` (soporte nativo escritorio)
- **Audio:** `audioplayers` ^6.x — `AudioService` global con precarga en `main.dart`

### Patrón: Feature-First + MVVM
```
lib/
├── core/
│   ├── database/       # Inicialización SQLite, repositorios, providers
│   ├── theme/          # Sistema de temas dinámico (Dark/Light/Cyber) — AppThemes, ThemeNotifier
│   └── utils/          # AudioCue (Enhanced Enum), AudioService + audioServiceProvider
├── features/
│   └── vision_training/
│       ├── data/       # Modelos de datos, DTOs
│       ├── domain/     # Entidades, contratos de repositorio
│       └── presentation/
│           ├── viewmodels/   # Riverpod Notifiers (lógica de UI)
│           └── views/        # Widgets / pantallas
└── main.dart
```

---

## Esquema de Base de Datos

### Tabla: `user_progress`
| Columna        | Tipo    | Descripción                              |
|----------------|---------|------------------------------------------|
| id             | INTEGER | PRIMARY KEY AUTOINCREMENT                |
| date           | TEXT    | Fecha ISO 8601 del registro              |
| exercise_type  | TEXT    | Identificador del ejercicio (ej. "saccadic_jumps") |
| max_speed_ms   | INTEGER | Velocidad máxima alcanzada en milisegundos |

---

## Módulos

### Módulo 1: Visión

**Navegación:** `VisionDashboardView` es el home de la app. Presenta tres Hero cards en layout `Wrap` responsivo (gradiente + icono fantasma + acento cyan) que navegan con `Navigator.push` a cada ejercicio. Cada ejercicio tiene `TextButton.icon` de retroceso integrado en el panel de control (sin AppBar, sin overlays flotantes).

**Ejercicio: Saltos Sacádicos**
- Patrones: Horizontal, Vertical, Patrón Z, Patrón N, Cruz, Diagonal X (enum `SaccadicPattern` en `domain/`).
  - Horizontal/Vertical: convergencia wide → mid → narrow (6 posiciones).
  - Patrón Z: top-left → top-right → bottom-left → bottom-right (4 posiciones).
  - Patrón N: top-left → bottom-left → top-right → bottom-right (4 posiciones).
  - Cruz: convergencia en eje vertical luego horizontal, wide → mid → narrow (12 posiciones).
  - Diagonal X: convergencia en ambas diagonales, wide → mid → narrow (12 posiciones).
- Velocidad: 400 ms – 2000 ms por salto; valor por defecto 1200 ms.
- Control: Slider de velocidad + `SegmentedButton` de selección de patrón + botón mute.
- Persistencia: guarda `max_speed_ms` al finalizar el ejercicio.
- **Auditory Entrainment (Metrónomo opcional):** click sincronizado con cada salto visual. `AudioCue.click` precargado con `PlayerMode.lowLatency`. Mute persistente entre sesiones desactivado (se resetea a `true` al pulsar "Nuevo Ejercicio", mantenido durante la sesión activa).

**Ejercicio: Seguimiento Ocular (Smooth Pursuit)**
- Patrones: Círculo (`cos/sin`), Infinito (Lissajous: `sin(t) / sin(2t)/2`), Horizontal (`sin(t)`). Enum `PursuitPattern` en `domain/`.
- Animación: `AnimationController` en la View (`ConsumerStatefulWidget with SingleTickerProviderStateMixin`). Solo el círculo se reconstruye en cada frame via `AnimatedBuilder`. Controles y selección de patrón son estáticos.
- Velocidad: 2000 ms – 12000 ms por ciclo; valor por defecto 5000 ms. Slider actualiza la duración del `AnimationController` en tiempo real.
- Estímulo: círculo sólido 32×32px color `#00E5FF` con glow (`BoxShadow`, blur 16, spread 2, opacidad 60%).
- **BGM (Música de Fondo):** `AudioCue.bgmFlow` mapeado a `assets/audio/bgm_flow.mp3`. `AudioService._bgmPlayer` dedicado con `ReleaseMode.loop`. Métodos `playBgm({volume})` / `stopBgm()` en `AudioService`. La música inicia al presionar INICIAR y se detiene al parar, volver al menú, o mutar. Botón mute en la UI (Icons.volume_off / Icons.volume_up).
- Persistencia: guarda `exercise_type = 'smooth_pursuit'` y `max_speed_ms` al finalizar.

**Ejercicio: Expansión Periférica**
- Patrones: Anillos Expansivos (`expandingCircles`), Marcos Contractivos (`contractingSquares`), Pulso Central (`pulsingTarget`). Enum `PeripheralPattern` en el viewmodel.
  - Anillos: 4 anillos circulares desfasados (fase 0/0.25/0.5/0.75) nacen del centro y se expanden hacia los bordes, desvaneciéndose.
  - Marcos: 4 marcos cuadrados desfasados nacen en los bordes y se contraen hacia el centro con fade in/out.
  - Pulso: un único círculo que crece y se contrae suavemente (`repeat(reverse: true)`).
- Animación: `AnimationController` en la View (`ConsumerStatefulWidget with SingleTickerProviderStateMixin`). `CustomPainter` atado a `AnimatedBuilder` para renderizado 60fps sin reconstruir el árbol de widgets. Punto de fijación central (punto + cruz suave) dibujado en todas las vistas.
- Velocidad: 500 ms – 3000 ms por ciclo; valor por defecto 1500 ms. Slider actualiza la duración del `AnimationController` en tiempo real.
- **Auditory Entrainment (Metrónomo):** `AudioCue.click` en cada `AnimationStatus.completed` (fin de ciclo para anillos/marcos, pico de expansión para pulso). Botón mute en la UI.
- Persistencia: guarda `exercise_type = 'peripheral_expansion'` y `max_speed_ms` al finalizar.
- Práctica Libre: soporta duración configurable (∞ / 30s / 60s / 2m, default 60s). Auto-guardado + `AudioCue.success` al expirar.

---

## Estado Actual

| Paso | Descripción                                        | Estado        |
|------|----------------------------------------------------|---------------|
| 1    | Inicialización del proyecto Flutter                | ✅ Completado |
| 2    | Estructura Feature-First + dependencias            | ✅ Completado |
| 3    | Capa de datos SQLite                               | ✅ Completado |
| 4    | Ejercicio Saltos Sacádicos (VM + Vista)            | ✅ Completado |
| 5    | Validación final (`flutter analyze`)               | ✅ Completado |
| 6    | Refactorización: patrones múltiples sacádicos      | ✅ Completado |
| 7    | Auditory Entrainment: metrónomo + AudioService     | ✅ Completado |
| 8    | Dashboard + Seguimiento Ocular + BGM (Iteración 4) | ✅ Completado |
| 9    | UX Polish: colores, rangos de velocidad, área visual, panel compacto | ✅ Completado |
| 10   | Sistema de Temas Dinámico (Dark, Light, Cyber-Focus) con Riverpod    | ✅ Completado |
| 11   | Temporizador de Práctica Libre: countdown + auto-guardado + success cue | ✅ Completado |
| 12   | Expansión Periférica: CustomPainter + metrónomo por ciclo + Dashboard Wrap | ✅ Completado |

---

## Módulo 1 — Versión 8 ✅

`flutter analyze` reporta **0 issues**. 38 tests pasando.
Navegación: Dashboard Hero → ejercicios con `TextButton.icon` de retroceso en panel de control (sin AppBar, layout `Column` sin overlays). Dashboard usa `Wrap` responsivo (3 tarjetas).
Saltos Sacádicos: 6 patrones, metrónomo sincronizado, persiste en SQLite. Extremos a `±0.95`. Velocidad: 300–1200 ms (default 800 ms).
Seguimiento Ocular: 3 patrones, animación 60fps con AnimatedBuilder, radio al 90% del área. BGM en loop, persiste en SQLite. Velocidad: 1500–5000 ms (default 3000 ms).
BGM: `AudioService._bgmPlayer` dedicado con `ReleaseMode.loop`. Se detiene al salir/pausar.
Expansión Periférica: 3 patrones (Anillos/Marcos/Pulso), animación 60fps con CustomPainter, punto de fijación central siempre visible. Metrónomo (`AudioCue.click`) en cada ciclo/pico. Velocidad: 500–3000 ms (default 1500 ms). Persiste `exercise_type='peripheral_expansion'`.
Temas: Sistema dinámico Dark/Light/Cyber-Focus seleccionable en el Dashboard. Todos los colores usan `Theme.of(context).colorScheme` — cero colores hardcoded en vistas. Panel inferior compacto (3 filas: selector+ms+mute / slider+selector-duración / back-nav+timer-chip+botón).
Práctica Libre: todos los ejercicios soportan duración configurable (∞ / 30s / 60s / 2m, default 60s). Timer inline como pill chip en Fila 3 del panel (visible solo durante sesión activa con duración finita). Auto-guardado + `AudioCue.success` al expirar.
Fecha: 2026-05-14
