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

### Módulo 1: Visión (MVP)
**Ejercicio: Saltos Sacádicos**
- Mecánica: un símbolo/letra alterna entre el extremo izquierdo y derecho de la pantalla.
- Control: Slider de velocidad (1000ms → 200ms por salto).
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

---

## MVP Módulo 1 — COMPLETADO ✅

`flutter analyze` reporta **0 issues**.
Fecha de cierre: 2026-04-15
