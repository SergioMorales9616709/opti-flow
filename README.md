# OptiFlow

Aplicación de escritorio para entrenamiento visual cognitivo. Diseñada para desarrollar y mantener la agilidad ocular mediante ejercicios de saltos sacádicos y seguimiento ocular suave.

Construida con Flutter para Windows y Linux.

---

## Ejercicios

### Saltos Sacádicos

El ojo salta entre estímulos visuales distribuidos en patrones geométricos. Entrena la velocidad y precisión del movimiento sacádico.

- 6 patrones de salto (horizontal, vertical, diagonal, cruzado y secuencias convergentes)
- Velocidad ajustable desde milisegundos por salto
- Metrónomo auditivo sincronizado con cada salto
- Registro del progreso al finalizar

### Seguimiento Ocular Suave

Un estímulo se desplaza de forma continua siguiendo trayectorias geométricas. Entrena la suavidad y estabilidad del seguimiento.

- 3 patrones de trayectoria (circular, elíptico, figura 8)
- Velocidad de ciclo ajustable
- Música lo-fi de fondo para el ambiente de entrenamiento
- Registro del progreso al finalizar

---

## Requisitos

- Flutter SDK `>=3.11.4`
- Windows 10+ o Linux (desktop)

## Instalación

```bash
git clone https://github.com/tu-usuario/opti-flow.git
cd opti-flow
flutter pub get
```

## Ejecución

```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

---

## Stack

| Capa              | Tecnología                               |
| ----------------- | ---------------------------------------- |
| UI                | Flutter (Material 3, tema oscuro)        |
| Estado            | flutter_riverpod 2.x                     |
| Base de datos     | sqflite_common_ffi (SQLite para desktop) |
| Audio             | audioplayers                             |
| Análisis estático | very_good_analysis                       |

---

## Contribuir

Las contribuciones son bienvenidas. Lee [`docs/contributing.md`](docs/contributing.md) para conocer las convenciones del proyecto antes de abrir un PR.

Para entender la arquitectura interna, revisa [`docs/architecture.md`](docs/architecture.md).

---

## Licencia

Distribuido bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.
