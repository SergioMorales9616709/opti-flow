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

### Patrón: Feature-First + MVVM
```
lib/
├── core/
│   ├── database/       # Inicialización SQLite, repositorios, providers
│   ├── theme/          # Tema global de la app
│   └── utils/          # Utilidades compartidas
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
**Ejercicio: Saltos Sacádicos**
- Patrones: Horizontal, Vertical, Patrón Z, Patrón N, Cruz, Diagonal X (enum `SaccadicPattern` en `domain/`).
  - Horizontal/Vertical: convergencia wide → mid → narrow (6 posiciones).
  - Patrón Z: top-left → top-right → bottom-left → bottom-right (4 posiciones).
  - Patrón N: top-left → bottom-left → top-right → bottom-right (4 posiciones).
  - Cruz: convergencia en eje vertical luego horizontal, wide → mid → narrow (12 posiciones).
  - Diagonal X: convergencia en ambas diagonales, wide → mid → narrow (12 posiciones).
- Velocidad: 400 ms – 2000 ms por salto; valor por defecto 1200 ms.
- Control: Slider de velocidad + `SegmentedButton` de selección de patrón.
- Persistencia: guarda `max_speed_ms` al finalizar el ejercicio.

---

## Estado Actual

| Paso | Descripción                                 | Estado     |
|------|---------------------------------------------|------------|
| 1    | Inicialización del proyecto Flutter          | ✅ Completado |
| 2    | Estructura Feature-First + dependencias      | ✅ Completado |
| 3    | Capa de datos SQLite                         | ✅ Completado |
| 4    | Ejercicio Saltos Sacádicos (VM + Vista)      | ✅ Completado |
| 5    | Validación final (`flutter analyze`)         | ✅ Completado |
| 6    | Refactorización: patrones múltiples sacádicos        | ✅ Completado |

---

## Módulo 1 — Versión 3 ✅

`flutter analyze` reporta **0 issues**. 19 tests pasando.
Patrones soportados: Horizontal, Vertical, Z, N, Cruz, Diagonal X.
Fecha: 2026-04-22
