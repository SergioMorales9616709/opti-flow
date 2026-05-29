# Design: RSVP Pro — Chunking + ORP Rendering

**Fecha:** 2026-05-28
**Rama:** feat/fastReading
**Estado:** Aprobado

---

## Contexto

El motor RSVP muestra palabras individuales a velocidad controlada por WPM con pausas dinámicas. Esta iteración añade dos técnicas de neuro-lectura:

1. **Chunking** — agrupa palabras cortas (≤ 3 chars) con la siguiente para reducir parpadeos a alta velocidad.
2. **ORP (Optimal Recognition Point)** — ancla una letra específica de cada chunk en el centro físico de la pantalla, sincronizando el eje de fijación ocular del lector.

---

## Archivos nuevos / modificados

| Archivo | Acción |
|---|---|
| `features/speed_reading/domain/neuro_reading_utils.dart` | **NUEVO** — `chunkWords()` + `getOrpParts()` |
| `features/speed_reading/presentation/viewmodels/rsvp_viewmodel.dart` | Modificar `_loadText()`: aplicar `chunkWords()` tras cargar |
| `features/speed_reading/presentation/views/rsvp_view.dart` | Reemplazar `Text` central por `OrpTextDisplay` |
| `pubspec.yaml` | Añadir dependencia `google_fonts` |
| `test/domain/neuro_reading_utils_test.dart` | **NUEVO** — tests de `chunkWords` y `getOrpParts` |

---

## 1. Capa de Dominio — `neuro_reading_utils.dart`

### 1.1 `chunkWords(List<String> words) → List<String>`

Pasa izquierda a derecha **una sola vez**. Si la palabra actual tiene ≤ 3 caracteres (incluyendo puntuación adjunta) y NO termina en puntuación mayor, la une con la siguiente mediante un espacio y salta la siguiente.

**Puntuación mayor** (impide el chunk): `.` `?` `!` `;` `:`

**Casos de borde:**
- Última palabra sin siguiente: se guarda sola aunque sea corta.
- Palabra corta que termina en `,`: la coma NO es puntuación mayor → sí se agrupa. La pausa dinámica (×1.5) sigue funcionando porque `pauseMsFor` evalúa el string completo del chunk.
- Dos palabras cortas consecutivas: solo la primera dispara el merge; el resultado (ya ≥ 4 chars) no vuelve a procesarse.

```dart
// Ejemplo
chunkWords(['La', 'casa', 'de', 'papel'])
// → ['La casa', 'de papel']

chunkWords(['yo', 'no', 'sé'])
// → ['yo no', 'sé']        // 'sé' queda sola (última)

chunkWords(['Fin.', 'El', 'mar'])
// → ['Fin.', 'El mar']     // 'Fin.' no se agrupa (termina en '.')
```

### 1.2 `getOrpParts(String chunk) → ({String left, String orp, String right})`

Calcula el índice ORP ignorando espacios (longitud de caracteres no-espacio), luego mapea ese índice de vuelta al string completo (con espacios) para preservar el espaciado entre palabras en el display.

**Tabla de índice ORP (0-based):**

| Longitud sin espacios | Índice |
|---|---|
| 1 | 0 |
| 2 – 5 | 1 |
| 6 – 9 | 2 |
| 10 – 13 | 3 |
| > 13 | 4 |

**Algoritmo:**
1. Contar chars no-espacio → `effectiveLen`
2. Buscar `orpIdx` en la tabla
3. Recorrer el string completo; contar solo no-espacio; cuando el contador llega a `orpIdx`, ese es el ORP
4. Devolver `left = chunk[0..orpPos-1]`, `orp = chunk[orpPos]`, `right = chunk[orpPos+1..]`

```dart
// Ejemplos
getOrpParts('palabra')   // 7 chars → idx 2 → pos 2 → 'l'
// → (left: 'pa', orp: 'l', right: 'abra')

getOrpParts('La casa')   // sin espacio: 6 → idx 2 → 3ª letra no-espacio = 'c' (pos 3)
// → (left: 'La ', orp: 'c', right: 'asa')

getOrpParts('de papel,') // sin espacio: 8 → idx 2 → 3ª no-espacio = 'p' (pos 3)
// → (left: 'de ', orp: 'p', right: 'apel,')

getOrpParts('él')        // 2 chars → idx 1 → pos 1 → 'l'
// → (left: 'é', orp: 'l', right: '')
```

**Retorno tipado con record Dart:**
```dart
typedef OrpParts = ({String left, String orp, String right});
OrpParts getOrpParts(String chunk) { ... }
```

---

## 2. ViewModel — `rsvp_viewmodel.dart`

Único cambio en `_loadText()`:

```dart
Future<void> _loadText() async {
  final rawWords = await ref.read(textRepositoryProvider).loadWords(_kAssetPath);
  final chunked = chunkWords(rawWords);          // ← nueva línea
  state = state.copyWith(words: chunked, isLoaded: true);
}
```

`pauseMsFor` no requiere cambios: evalúa el último carácter del chunk entero, que sigue siendo la puntuación original.

---

## 3. Widget `OrpTextDisplay`

Widget stateless extraído en `rsvp_view.dart`. Recibe el string del chunk actual y llama internamente a `getOrpParts`.

**Layout:**

```
Column(
  mainAxisSize: min,
  children: [
    Container(width:2, height:10, color: guide),      // mira superior
    Row(
      children: [
        Expanded(child: Text(left,  align: right, style: monoStyle)),
        Text(orp, style: monoStyle.copyWith(color: primary)),
        Expanded(child: Text(right, align: left,  style: monoStyle)),
      ],
    ),
    Container(width:2, height:10, color: guide),      // mira inferior
  ],
)
```

**Tipografía:**
```dart
GoogleFonts.robotoMono(
  fontSize: 64,
  fontWeight: FontWeight.w800,
  color: cs.onSurface,
)
```

**Color guía:** `cs.onSurface.withValues(alpha: 0.3)` — sutil, no distrae.

**Color ORP:** `cs.primary` (cyan `#00E5FF` en Dark/Cyber, adaptable al tema).

**`white-space` invariante:** el campo `left` puede terminar en espacio (ej. `"La "`). Flutter renderiza este espacio dentro de `Expanded`, manteniendo el anclaje visual del ORP incluso para chunks multi-palabra. No requiere ningún tratamiento especial.

---

## 4. Compatibilidad con `pauseMsFor`

La función existente en `rsvp_viewmodel.dart` no cambia. Verifica el último carácter del string completo del chunk:

```
pauseMsFor('La casa', wpm)    → base ×1.0  (sin puntuación)
pauseMsFor('de papel,', wpm)  → base ×1.5  (endsWith ',')
pauseMsFor('al fin.', wpm)    → base ×2.5  (endsWith '.')
```

---

## 5. Dependencia `google_fonts`

Añadir a `pubspec.yaml`:

```yaml
dependencies:
  google_fonts: ^6.x  # versión exacta: flutter pub add google_fonts
```

`google_fonts` cachea las fuentes localmente tras la primera descarga. Para uso offline garantizado, se puede bundlear la fuente como asset; en esta iteración se asume conectividad en la primera ejecución.

---

## 6. Tests

Nuevo archivo `test/domain/neuro_reading_utils_test.dart`:

### `chunkWords`
- Agrupa dos palabras cortas consecutivas
- No agrupa cuando la primera termina en `.`
- No agrupa cuando la primera termina en `?`, `!`, `;`, `:`
- Sí agrupa cuando termina en `,` (no es puntuación mayor)
- La última palabra corta se guarda sola
- Palabras largas (> 3 chars) no se tocan

### `getOrpParts`
- Longitud 1 → índice 0
- Longitud 2-5 → índice 1 (casos: 2, 3, 5)
- Longitud 6-9 → índice 2 (casos: 6, 9)
- Longitud 10-13 → índice 3
- Longitud > 13 → índice 4
- Chunk con espacio: el espacio queda en `left`, ORP en letra correcta
- `right` vacío cuando el ORP es el último carácter

---

## Decisiones de Diseño

| Decisión | Elección | Razón |
|---|---|---|
| Ubicación de lógica de dominio | `domain/neuro_reading_utils.dart` | I/O puro en data layer; reglas de neuro-lectura en domain |
| ORP en chunks | Contar solo chars no-espacio | El espacio en `left` preserva el anclaje visual sin desplazar el ORP |
| Font | `GoogleFonts.robotoMono` `w800` | Diseñada para pantalla, máxima legibilidad a 64px |
| Puntuación mayor (no agrupa) | `.?!;:` | Las comas permiten chunk porque la pausa ×1.5 ya las maneja |
| `pauseMsFor` sin cambios | Evalúa último char del chunk entero | Compatible by design: el chunk conserva la puntuación original al final |

---

## Fuera de Alcance

- Selector de textos (multi-archivo)
- Bundled font asset para offline garantizado
- Configuración del umbral de chunking (actualmente fijo en 3)
- Highlight de palabras clave
