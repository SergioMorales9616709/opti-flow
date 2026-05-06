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

**Navegación:** `VisionDashboardView` es el home de la app. Presenta dos Hero cards (gradiente + icono fantasma + acento cyan) que navegan con `Navigator.push` a cada ejercicio. Cada ejercicio tiene botón flotante de retroceso (`Stack + Positioned + IconButton`) sin AppBar para máxima inmersión.

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

---

## Módulo 1 — Versión 7 ✅

`flutter analyze` reporta **0 issues**. 38 tests pasando.
Navegación: Dashboard Hero → ejercicios con botón flotante (sin AppBar).
Saltos Sacádicos: 6 patrones, metrónomo sincronizado, persiste en SQLite. Extremos a `±0.95`. Velocidad: 300–1200 ms (default 800 ms).
Seguimiento Ocular: 3 patrones, animación 60fps con AnimatedBuilder, radio al 90% del área. BGM en loop, persiste en SQLite. Velocidad: 1500–5000 ms (default 3000 ms).
BGM: `AudioService._bgmPlayer` dedicado con `ReleaseMode.loop`. Se detiene al salir/pausar.
Temas: Sistema dinámico Dark/Light/Cyber-Focus seleccionable en el Dashboard (IconButtons 🌙/☀️/⚡). Todos los colores de las vistas usan `Theme.of(context).colorScheme` — cero colores hardcoded en vistas. Panel inferior compacto (3 filas: selector+ms+mute / slider / botón).
Práctica Libre: ambos ejercicios soportan duración configurable (∞ / 30s / 60s / 2m, default 60s). Countdown HUD flotante al 50% de opacidad centrado en el área de ejercicio. Auto-guardado + `AudioCue.success` al expirar. Panel compacto: selector de duración en Fila 3 junto al botón de acción (SizedBox 16px de separación). Label "Práctica Libre" junto al botón de retroceso.
Fecha: 2026-05-05
