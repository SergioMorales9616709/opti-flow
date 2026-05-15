# OptiFlow

Aplicación de escritorio para entrenamiento visual cognitivo. Diseñada para desarrollar y mantener la agilidad ocular mediante tres ejercicios del Módulo de Visión: saltos sacádicos, seguimiento ocular suave y expansión periférica.

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

- 3 patrones de trayectoria (círculo, infinito, horizontal)
- Velocidad de ciclo ajustable
- Música lo-fi de fondo para el ambiente de entrenamiento
- Registro del progreso al finalizar

### Expansión Periférica

El usuario fija la vista en un punto central mientras figuras geométricas se expanden o contraen desde y hacia los bordes de la pantalla. Entrena la amplitud del campo visual periférico.

- 3 patrones (anillos expansivos, marcos contractivos, pulso central)
- Figura única por ciclo para evitar fatiga visual por efecto túnel
- Música lo-fi de fondo + metrónomo sincronizado con el ciclo
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
| UI                | Flutter (Material 3, temas Dark/Light/Cyber) |
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
