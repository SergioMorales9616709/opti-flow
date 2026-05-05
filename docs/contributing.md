# Guía de contribución

## Setup

```bash
git clone https://github.com/tu-usuario/opti-flow.git
cd opti-flow
flutter pub get
```

## Comandos

```bash
flutter run -d windows      # Ejecutar en Windows
flutter run -d linux        # Ejecutar en Linux
flutter analyze             # Análisis estático
flutter test                # Todos los tests
flutter test test/foo_test.dart  # Un test específico
```

## Convenciones

**Arquitectura:** Feature-First + MVVM. Toda la lógica de negocio va en viewmodels (`NotifierProvider`). Las vistas (`ConsumerWidget`) solo leen estado y llaman métodos del notifier — sin lógica propia.

**Estado:** Objetos inmutables con `copyWith`. Nunca mutarles directamente.

**Rebuilds:** Usar `ref.watch(provider.select(...))` cuando la vista solo necesita un campo del estado. Evitar suscribirse a todo el estado en widgets que se actualizan frecuentemente.

**Layout:** `LayoutBuilder` o `MediaQuery` para tamaños. Sin píxeles hardcodeados para dimensiones de layout.

**Análisis estático:** El proyecto usa `very_good_analysis`. Ejecutar `flutter analyze` sin warnings antes de abrir un PR.

## Tests

Los tests de integración usan una base de datos en memoria inicializada con `DatabaseHelper.initializeForTesting()`. No mockear la base de datos — los tests deben correr contra SQLite real.

## Commits

Seguir [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(vision): descripción corta
fix(audio): descripción corta
refactor(core): descripción corta
test: descripción corta
docs: descripción corta
```

## Pull Requests

- Un PR por feature o fix
- Incluir descripción del cambio y, si aplica, capturas de pantalla
- `flutter analyze` sin errores
- Tests pasando (`flutter test`)
