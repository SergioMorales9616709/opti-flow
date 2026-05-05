# Arquitectura

## Patrón general

Feature-First + MVVM con `flutter_riverpod` para estado.

```
lib/
├── main.dart                          # Entry point: inicializa DB y AudioService, envuelve en ProviderScope
├── core/
│   ├── database/
│   │   ├── database_helper.dart       # Singleton SQLite (sqflite_common_ffi para desktop)
│   │   └── progress_repository.dart  # Acceso a datos + progressRepositoryProvider
│   ├── theme/
│   │   └── app_theme.dart            # Tema oscuro global (acento: #00E5FF)
│   └── utils/
│       ├── audio_service.dart        # Playback de BGM y efectos de sonido
│       └── audio_cue.dart            # Cue de metrónomo para saltos sacádicos
└── features/
    └── vision_training/
        ├── domain/
        │   ├── saccadic_pattern.dart # Enum de patrones + secuencias de alineación
        │   └── pursuit_pattern.dart  # Enum de patrones + función de posición paramétrica
        └── presentation/
            ├── viewmodels/           # Riverpod Notifiers — toda la lógica de timer y estado
            └── views/               # ConsumerWidgets — sin lógica de negocio
```

Cada feature sigue: `data/` → `domain/` → `presentation/`. Solo `domain/` y `presentation/` están implementados en el MVP actual; `data/` está reservado para expansión futura.

---

## Patrones clave

### Estado
`NotifierProvider` (Riverpod 2.x). Los objetos de estado son inmutables y usan `copyWith`. Los providers se definen al final del archivo del viewmodel.

### Rebuilds selectivos
Las vistas usan `ref.watch(provider.select((s) => s.field))` para suscribirse solo al campo que necesitan, evitando rebuilds completos durante actualizaciones de timer de alta frecuencia.

### Base de datos
`DatabaseHelper` es un singleton estático inicializado una vez en `main()` antes de `runApp`. Los repositorios reciben la instancia `Database` vía `DatabaseHelper.db`. La llamada `sqfliteFfiInit()` es obligatoria para Windows/Linux.

### Layout
`LayoutBuilder` / `MediaQuery` para todo el sizing. Sin valores de píxeles hardcodeados para dimensiones de layout.

---

## Esquema de base de datos

Archivo: `optiflow.db` (directorio de trabajo de la app)

Tabla `user_progress`:

| Columna | Tipo | Notas |
|---|---|---|
| id | INTEGER | PK AUTOINCREMENT |
| date | TEXT | ISO 8601 |
| exercise_type | TEXT | e.g. `"saccadic_jumps"` |
| max_speed_ms | INTEGER | milisegundos por salto/ciclo |

---

## Audio

`AudioService` es un singleton inicializado en `main()` e inyectado vía `audioServiceProvider`. Gestiona:

- **BGM lo-fi** — reproducción en loop durante el ejercicio de seguimiento ocular suave
- **Metrónomo** — cue de audio sincronizado con cada salto sacádico

El servicio se detiene automáticamente al abandonar la vista del ejercicio (en `dispose`).

---

## Flujo de un ejercicio

```
Usuario presiona INICIAR
  → notifier.startExercise()
  → status: idle → active
  → timer inicia / AnimationController.repeat()
  → audio inicia

Usuario presiona DETENER Y GUARDAR
  → notifier.stopAndSave()
  → status: active → saving
  → progressRepository.save(...)
  → status: saving → saved
  → overlay de confirmación

Usuario presiona NUEVO EJERCICIO
  → notifier.reset()
  → status: saved → idle
```
