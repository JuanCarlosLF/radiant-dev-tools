---
createdAt: 2026-09-16
updatedAt: 2026-09-19
type: contracts
status: evolving
tags:
  - radiant-platinum
  - architecture
  - progression
aliases:
  - Contratos del sistema de escaneo y progresión
---

# Contracts

> [!abstract] Propósito
> Registro incremental de contratos y decisiones contractuales aceptados de [[Evolución del sistema de escaneo y progresión]]. Solo se añade contenido después de consensuarlo.

## Decisiones aceptadas
### `progression.json`

`radiant-devtools/catalogs/progression.json` es la única fuente persistente de la progresión. Su raíz contiene:

```json
{
  "schema_version": 1,
  "stages": [
    {
      "id": "stg_a1f3",
      "name": "Pueblo Hojaverde - Ciudad Jubileo",
      "description": "Abarca el recorrido desde que empieza el juego hasta la entrada en Ciudad Jubileo.",
      "unlocks": []
    },
    {
      "id": "stg_b2e7",
      "name": "Ciudad Jubileo - Ciudad Pirita: Medalla Lignito (Roco)",
      "description": "Finaliza en el momento exacto del combate contra Roco como evento final del tramo.",
      "unlocks": []
    },
    {
      "id": "stg_c4h1",
      "name": "Ciudad Pirita: Medalla Lignito (Roco) - Pueblo Aromaflor",
      "description": "Empieza justo al vencer a Roco, y acaba al llegar a Pueblo Aromaflor.",
      "unlocks": ["rock_smash"]
    },
    {
      "id": "stg_d8k3",
      "name": "Pueblo Aromaflor - Bosque Vetusto",
      "description": "Empieza al entrar en Aromaflor, hasta combatir contra Malta.",
      "unlocks": []
    },
    {
      "id": "stg_e5m9",
      "name": "Bosque Vetusto - Ciudad Vetusta: Medalla Bosque (Gardenia)",
      "description": "Empieza al derrotar a Malta y su evento final es el combate contra Gardenia.",
      "unlocks": []
    },
    {
      "id": "stg_f7n2",
      "name": "Ciudad Vetusta: Medalla Bosque (Gardenia) - Entrada al Monte Corona",
      "description": "Empieza nada más derrotar a Gardenia, acaba al entrar al Monte Corona por la ruta 207 este.",
      "unlocks": ["cut", "bike"]
    },
    {
      "id": "stg_g3p6",
      "name": "Monte Corona - Ciudad Corazón: Medalla Reliquia (Fantina)",
      "description": "El último evento es el combate contra Fantina.",
      "unlocks": []
    },
    {
      "id": "stg_h9q4",
      "name": "Ciudad Corazón: Medalla Reliquia (Fantina) - Ruta 215",
      "description": "Empieza al derrotar a Fantina y acaba justo al entrar en la ruta 215.",
      "unlocks": []
    },
    {
      "id": "stg_j2r8",
      "name": "Ruta 215 - Ciudad Rocavelo: Medalla Adoquín (Brega)",
      "description": "Acaba en el combate contra Brega.",
      "unlocks": []
    },
    {
      "id": "stg_k7v3",
      "name": "Ciudad Rocavelo: Medalla Adoquín (Brega) - Ciudad Pradera: Medalla Ciénaga (Mananti)",
      "description": "Empieza al vencer a Brega, y acaba combatiendo contra Mananti.",
      "unlocks": []
    },
    {
      "id": "stg_l6t1",
      "name": "Ciudad Pradera: Medalla Ciénaga (Mananti) - Ruta 211",
      "description": "Acaba justo al entrar a Pueblo Caelestis por la Ruta 211.",
      "unlocks": []
    },
    {
      "id": "stg_m4v5",
      "name": "Pueblo Caelestis - Ciudad Canal: Medalla Mina (Acerón)",
      "description": "Desde la entrada al Pueblo Caelestis hasta el combate con Acerón.",
      "unlocks": []
    },
    {
      "id": "stg_n8w3",
      "name": "Ciudad Canal: Medalla Mina (Acerón) - Ruta 217",
      "description": "Desde que vences a Acerón hasta que te adentras por primera vez en la ruta 217.",
      "unlocks": []
    },
    {
      "id": "stg_p1x7",
      "name": "Ruta 217 - Ciudad Puntaneva: Medalla Carámbano (Inverna)",
      "description": "Hasta el combate contra Inverna.",
      "unlocks": []
    },
    {
      "id": "stg_q5y2",
      "name": "Ciudad Puntaneva: Medalla Carámbano (Inverna) - Combate contra Saturno",
      "description": "Al vencer a Saturno acaba.",
      "unlocks": []
    },
    {
      "id": "stg_r9z6",
      "name": "Combate contra Saturno - Mundo Distorsión",
      "description": "Desde que vences a Saturno y tienes que volver al Monte Corona, hasta que sales del Mundo Distorsión.",
      "unlocks": []
    },
    {
      "id": "stg_s3a9",
      "name": "Mundo Distorsión - Ciudad Canal: Medalla Faro (Lectro)",
      "description": "Desde que sales hasta que te enfrentas con Lectro.",
      "unlocks": []
    },
    {
      "id": "stg_t7b4",
      "name": "Ciudad Canal: Medalla Faro (Lectro) - Calle Victoria",
      "description": "Desde que lo vences hasta que sales de la Calle Victoria.",
      "unlocks": []
    },
    {
      "id": "stg_u2c8",
      "name": "Calle Victoria - Liga Pokémon",
      "description": "Desde que sales de la Calle Victoria, hasta que te haces campeón.",
      "unlocks": []
    }
  ],
  "capabilities": [
    {
      "id": "rock_smash",
      "name": "Golpe Roca"
    },
    {
      "id": "cut",
      "name": "Corte"
    },
    {
      "id": "bike",
      "name": "Bicicleta"
    }
  ]
}
```

- `schema_version` identifica la versión del formato; la política de migración se decidirá por separado.
- `stages` es una lista ordenada de `stage`; su posición es el orden canónico.
- `capabilities` enumera las `Capability` disponibles; su orden no tiene significado de dominio.
- `stage.unlocks` solo puede referenciar IDs presentes en `capabilities` y cada capacidad debe aparecer en exactamente un stage.
- No se persisten `order`, `number` ni `progress`; se derivan de la posición en `stages`.
- `description` es opcional y delimita narrativamente el tramo (inicio/fin); no afecta al orden canónico ni a la disponibilidad.
- Kotlin/JVM lee y valida este documento, pero no mantiene una segunda definición de stages o capacidades. El scanner Ruby solo consume una representación validada cuando la necesita para diagnosticar anotaciones.

### Consulta `available-by`

`available-by <stage>` responde: «¿Qué objetos y otros contenidos puede haber conseguido el jugador al terminar este stage?»

Incluye el contenido que pasó a estar disponible durante ese stage o durante cualquiera anterior. Por ejemplo, si un objeto está en el stage 1 pero necesita Surf y Surf se desbloquea durante el stage 10:

- `available-by 9` no incluye el objeto;
- `available-by 10` sí lo incluye;
- `available-by 11` también lo incluye.

La consulta expresa disponibilidad acumulada hasta el final del stage. No indica dónde está situado físicamente el objeto ni garantiza que pueda conseguirse al comienzo del stage.

### Disponibilidad resuelta

La disponibilidad de un contenido se deriva al consultarlo; no se escribe en `scan-results.json`.

```text
effective_stage = stage más tardío entre stage_id y los stages que desbloquean requires
```

El resultado contiene `effective_stage_id` y `delayed_by`. `delayed_by` incluye todos los requisitos que retrasan el objeto más allá de su stage declarado y alcanzan el stage efectivo. Si ningún requisito lo retrasa, queda vacío.

No se persisten `stage_number` ni `progress` en el resultado porque se derivan del orden actual de `stages`. Tampoco se incluye un booleano `available`: ese valor depende del stage contra el que se formule una consulta como `available-by`.

### Resolución de disponibilidad

La operación de resolución recibe exactamente:

- un `stage_id`;
- una colección `requires`;
- los datos validados de `progression.json`.

Devuelve un `ResolvedAvailability`. No recibe un `ItemFinding` completo ni depende de un tipo concreto de contenido; cualquier registro que declare `stage_id` y `requires` puede utilizarla.

La operación resuelve un contenido cada vez, es determinista y no lee archivos, escribe resultados, modifica la entrada ni consulta el estado del jugador. Una operación superior puede aplicarla a una colección cuando sea necesario.

Falla explícitamente, sin devolver `nil` ni inventar un resultado, si el stage declarado o una capacidad requerida no existen, o si una capacidad no tiene exactamente un stage de desbloqueo. Cuando `delayed_by` contiene varias capacidades, se ordenan por ID para estabilizar informes y pruebas.

### Clasificación de objetos y `doctor`

Las categorías intrínsecas de un objeto se derivan de sus metadatos canónicos mediante un mapeo explícito y controlado. El mapeo inicial es:

| Metadato del objeto | Categoría canónica |
|---|---|
| `TypeGem` | `gem` |
| `MegaStone` | `mega_stone` |
| `Mint` | `mint` |
| `Shard` | `shard` |

El clasificador no deduce categorías a partir del nombre o de patrones del ID y no expone flags técnicos ajenos a las consultas.

Si un objeto referenciado por un `ItemFinding` no puede asignarse a ninguna categoría canónica mediante el mapeo configurado, `radiant doctor` emite un warning con su `item_id` y procedencia. `doctor` informa, pero no modifica el PBS ni el hallazgo.

### Registro de objetos obtenibles

El scanner solo crea `ItemFinding` desde una página de evento que contenga `#addToRadar`. Si falta `#stage:<stage_id>`, emite el warning `missing_stage` y no crea el hallazgo de esa página. Si el stage declarado es desconocido, produce un error: no puede resolver una referencia que el catálogo no define.

Las formas reconocidas son `pbItemBall`, `pbReceiveItem`, `dar_mt` y `pbPokemonMart`. Una página anotada que no contenga ninguna entrega reconocible y resoluble produce un error con su procedencia.

Cada objeto enumerado por `pbPokemonMart` genera un `ItemFinding` con `source.kind = "shop"`. Las demás formas generan `source.kind = "event"`; no se distingue entre suelo y recompensa de evento. `dar_mt` identifica la MT que debe resolverse a un `item_id`, pero no define otra clase de procedencia.

Una auditoría exhaustiva de `doctor` emite un warning cuando encuentra una entrega reconocible en una página sin `#addToRadar`. El aviso no registra el objeto ni modifica el evento.

### Registro de almas

Una página de evento registra un `SoulFinding` mediante la puerta de entrada común y el marcador de alma:

```text
#addToRadar #alma #stage:stg_a1f3 #requires:surf Oculta en la chimenea
```

- `#addToRadar` autoriza el registro y `#alma` determina que el resultado pertenece a `souls`; no se requiere una llamada de script.
- La misma página debe declarar exactamente un `#stage:<stage_id>` válido.
- `#requires` es opcional y referencia las mismas capacidades que los objetos; en su ausencia se produce `requires: []`.
- Stage o capacidades desconocidos producen un error.
- `#alma` sin `#addToRadar` genera un warning de contenido no registrado y no produce un `SoulFinding`.
- Cada evento representa como máximo una alma. Si varias de sus páginas contienen `#addToRadar #alma`, el scanner produce un error en vez de escoger una silenciosamente.
- La funcionalidad específica del radar de almas compara la colección completa con las 108 almas esperadas. Esta regla no pertenece al scanner genérico ni forma parte de cada `SoulFinding`.

### Registro de tutores

Una página de evento registra un `TutorFinding` cuando contiene una llamada `pbMoveTutorScreen` y la puerta de entrada común:

```text
#addToRadar #stage:stg_a1f3 #requires:surf Junto a la salida
```

- `#addToRadar` autoriza el registro; el `station_id` se extrae de `pbMoveTutorScreen(:tutor_a1f3)`.
- La misma página debe declarar exactamente un `#stage:<stage_id>` válido.
- `#requires` es opcional y referencia las mismas capacidades que los objetos; en su ausencia se produce `requires: []`.
- Una estación desconocida, un stage o capacidades desconocidos producen un error.
- Un `pbMoveTutorScreen` sin `#addToRadar` genera un warning de contenido no registrado y no produce un `TutorFinding`.
- Cada evento representa como máximo un tutor. Si varias de sus páginas reclaman un tutor, el scanner produce un error en vez de escoger uno silenciosamente.

### Contenedor de resultados

La raíz de scan-results.json tiene exactamente estas seis claves obligatorias:

~~~json
{
  "schema_version": 1,
  "status": "success",
  "items": [],
  "souls": [],
  "tutor_stations": [],
  "diagnostics": []
}
~~~

| Campo | Tipo | Regla |
|---|---|---|
| schema_version | entero | Versión del contrato raíz; la primera versión es 1. |
| status | success o failed | Es failed si diagnostics contiene al menos un diagnóstico con severity error; es success aunque existan warnings. |
| items | array de ItemFinding | Hallazgos de objetos; su contrato está en [[domain-models#ItemFinding]]. |
| souls | array de SoulFinding | Hallazgos de almas; su contrato está en [[domain-models#SoulFinding]]. |
| tutor_stations | array de TutorFinding | Avistamientos de tutores; su contrato está en [[domain-models#TutorFinding]]. |
| diagnostics | array de Diagnostic | Errores y warnings del intento; su contrato está en [[contracts#Diagnósticos del scanner]]. |

No se admiten claves raíz adicionales en la primera versión. ResolvedAvailability, la disponibilidad acumulada y los informes no forman parte de este documento: se calculan en memoria por la CLI a partir de un resultado success.

`scan-results.json` es un artefacto derivado y regenerable que describe el último intento de escaneo. `status` vale `success` cuando no existen errores y `failed` cuando existe al menos uno. `items` contiene `ItemFinding`, `souls` contiene `SoulFinding`, `tutor_stations` contiene `TutorFinding` y `diagnostics` conserva los errores y warnings del intento. No existe un `Finding` universal ni un campo discriminador común `kind`.

- Un resultado `success` puede contener warnings y puede utilizarse en las consultas normales de la CLI.
- Las colecciones de un resultado `failed` pueden estar incompletas y no se utilizan en consultas normales; `doctor` sí puede leer sus diagnósticos.
- Los diagnósticos se mantienen en la raíz porque algunos no tienen un hallazgo válido al que asociarse y otros pertenecen a una página que produce varios hallazgos.

### Acceso a mapas

`MapRepository` es el límite de infraestructura que obtiene los mapas de RPG Maker para el scanner. Lee el índice `Data/MapInfos.rxdata`, enumera las referencias a cada `Data/MapNNN.rxdata` y carga únicamente los mapas que el scanner necesita procesar.

```ruby
map_repository.each_map_reference do |map_id, map_name, path, mtime_ns, size|
  next unless scan_cache.stale?(map_id, mtime_ns, size, scan_signature)

  rpg_map = map_repository.load(map_id)
  map_walker.walk(map_id, map_name, rpg_map)
end
```

- Enumera los mapas en orden determinista por `map_id`.
- Separa la enumeración y los metadatos de la carga completa para que la caché pueda decidir primero.
- Un mapa presente en el índice que no pueda cargarse produce un fallo explícito; no se omite silenciosamente.
- No recorre eventos o páginas, crea `PageContext`, ejecuta detectores, calcula disponibilidad ni escribe resultados.
- No decide qué mapas puede reutilizar la caché.
- La interfaz y los objetos cargados solo viven durante la ejecución de Ruby; no añaden ningún contrato JSON.

### Recorrido de mapas

`MapWalker` recibe un mapa ya cargado y produce un `PageContext` por cada página de evento.

```ruby
map_walker.each_page(map_id, map_name, rpg_map) do |page_context|
  scanner.inspect(page_context)
end
```

- Recorre los eventos en orden determinista por `event_id`, las páginas en su orden original y los comandos en su orden original.
- `page_index` y `command_index` son índices basados en cero dentro de los arrays originales de RPG Maker.
- Recorre todas las páginas, con independencia de sus condiciones de activación; el análisis estático no simula un estado concreto de la partida.
- Reconstruye correctamente los comentarios y scripts de varias líneas antes de construir el contexto. Internamente, RPG Maker guarda la primera línea y sus continuaciones con códigos distintos (`108 + 408` para comentarios y `355 + 655` para scripts).
- No carga archivos, interpreta anotaciones, reconoce contenido, ejecuta detectores, crea hallazgos, consulta la caché ni escribe resultados.
- El recorrido y los `PageContext` producidos solo viven durante la ejecución de Ruby.

### Caché del scanner

`ScanCache` evita volver a escanear mapas sin cambios. Es un artefacto derivado y eliminable; nunca es una fuente de verdad.

```json
{
  "schema_version": 1,
  "scan_signature": "item:2|soul:1|tutor:1|inputs:abc123",
  "maps": {
    "8": {
      "mtime_ns": 1789470000000000000,
      "size": 123456
    }
  }
}
```

- `scan_signature` representa las versiones del parser, el validador y los detectores, además de los datos globales que afectan al resultado, como los catálogos utilizados durante el escaneo.
- Un mapa nuevo o cuyo `mtime_ns` o `size` haya cambiado se vuelve a escanear.
- Un mapa sin cambios y con firma compatible reutiliza los registros del `scan-results.json` anterior mediante `source.map_id`.
- Un mapa eliminado desaparece tanto de la caché como de los resultados reutilizados.
- Una caché ausente o incompatible y la opción `--full` provocan un escaneo completo.
- Un `scan-results.json` anterior con `status: "failed"` impide reutilizar la caché y provoca un escaneo completo.
- Un mapa con errores no se marca como procesado correctamente.
- La primera versión no calcula hashes de contenido; solo se añadirán si aparecen falsos negativos reales con `mtime_ns + size`.
- La caché guarda metadatos, no copias de los hallazgos, y no decide la política de publicación de archivos cuando existen errores.

### Escritura atómica de resultados

`AtomicJsonWriter` serializa completamente un documento JSON en un archivo temporal situado en el mismo directorio y solo entonces reemplaza el destino.

```ruby
atomic_json_writer.replace(path, data)
```

- Si la serialización, escritura o sustitución falla, el archivo de destino anterior permanece intacto.
- Todo intento de escaneo que termine se publica atómicamente en `scan-results.json`, con `status: "success"` o `status: "failed"` y sus diagnósticos en la raíz; no existe un `scan-report.json` separado.
- Los warnings no impiden publicar un resultado `success`.
- Los errores publican un resultado `failed`, cuyas colecciones pueden estar incompletas y que la CLI no utiliza para consultas normales.
- La caché solo se reemplaza después de publicar un resultado `success`. Los resultados se escriben antes que la caché, de modo que una interrupción intermedia provoque como máximo trabajo adicional en el siguiente escaneo.
- Cuando se publica un resultado `failed`, la caché no se actualiza y el siguiente intento ignora la caché anterior.
- El writer no decide el estado del escaneo ni interpreta diagnósticos; recibe datos ya preparados y ejecuta la sustitución segura.

### Contexto de página del scanner

`PageContext` es la representación interna y temporal de una página de evento ya preparada por el recorrido común del scanner. Permite que todos los detectores examinen la misma página sin volver a interpretar por separado la lista de comandos de RPG Maker.

```ruby
PageContext.new(
  source: {
    map_id: 8,
    map_name: "Lago Veraz",
    event_id: 15,
    event_name: "Alma oculta",
    page_index: 0,
    x: 17,
    y: 41
  },
  comment_blocks: [
    {
      command_index: 4,
      text: "#addToRadar #alma #stage:stg_a1f3 #requires:surf"
    }
  ],
  script_blocks: []
)
```

- Cada instancia representa exactamente una página y contiene su procedencia, sus bloques lógicos de comentarios y sus bloques lógicos de scripts.
- Un comentario de varias líneas forma un único `comment_block`; internamente corresponde al comando inicial `108` y sus continuaciones `408`.
- Un script de varias líneas forma un único `script_block`; internamente corresponde al comando inicial `355` y sus continuaciones `655`.
- Los bloques permanecen separados y conservan el `command_index` en el que comienzan; no se concatena toda la página en un solo texto.
- `comment_blocks` o `script_blocks` pueden estar vacíos. Esto permite representar, por ejemplo, un alma declarada enteramente mediante anotaciones.
- Puede construirse para cualquier página recorrida. La presencia de `#addToRadar`, la clase de contenido y los diagnósticos los determinan los detectores posteriores.
- No interpreta anotaciones, detecta contenido, calcula disponibilidad ni escribe JSON.
- Solo existe en memoria durante el escaneo. No forma parte de `scan-results.json`, no es una fuente de verdad y no es un modelo de dominio persistente.

### Anotación interpretada

`AnnotationParser` transforma un único bloque lógico de comentario en un `ParsedAnnotation` temporal que los detectores pueden consumir sin volver a interpretar el texto.

```ruby
ParsedAnnotation.new(
  command_index: 4,
  add_to_radar: true,
  stage_id: "stg_a1f3",
  requires: ["surf"],
  tags: ["alma"],
  notes: "Oculta en la chimenea"
)
```

- Las claves reservadas canónicas se escriben en minúsculas: `#stage:` y `#requires:`. `#addToRadar` permanece como marcador especial.
- `tags` recoge, normalizado a minúsculas, cada `#identificador` independiente que no sea el marcador ni una clave reservada. Por ejemplo, `#alma` produce `"alma"` y `#hidden` produce `"hidden"`.
- Una construcción con forma de clave desconocida, como `#unknown:value`, no se convierte silenciosamente en un tag.
- `#TramoN` puede reconocerse para producir un diagnóstico de migración, pero su número no se almacena en `ParsedAnnotation`.
- El parser procesa cada bloque lógico por separado; no combina comentarios independientes de una página.
- No comprueba que el stage o las capacidades existan, no decide qué detector reclama la página y no crea hallazgos.
- `ParsedAnnotation` solo vive en memoria durante el escaneo y no se serializa en `scan-results.json`.

### Validación semántica de anotaciones

`AnnotationValidator` comprueba el contenido de un `ParsedAnnotation` contra los datos ya validados de `progression.json` y devuelve objetos Ruby `Diagnostic`.

```ruby
diagnostics = annotation_validator.validate(
  parsed_annotation,
  progression
)
```

Para una anotación con `#addToRadar` comprueba que:

- existe exactamente un `stage_id`;
- el stage referenciado existe;
- `requires` no contiene duplicados;
- todas las capacidades requeridas existen.

Los tags libres no se validan de forma genérica. Cada detector interpreta los que pertenecen a su familia, como `#alma` en `SoulDetector` o `#hidden` en `ItemDetector`.

`AnnotationValidator` no analiza texto, reconoce scripts, selecciona un detector, crea hallazgos, calcula disponibilidad ni aplica reglas de funcionalidades específicas. Si devuelve algún diagnóstico con severidad `error`, no se crea un hallazgo válido. Un warning no bloquea el escaneo completo; un detector puede aun así omitir su hallazgo cuando falte un dato obligatorio, como el stage. El validador solo vive en Ruby; únicamente sus diagnósticos pueden serializarse posteriormente.

### Contrato común de detector

Un detector inspecciona un `PageContext` y decide si la página pertenece a la familia de contenido que reconoce. Devuelve un resultado temporal con tres datos:

```ruby
DetectionResult.new(
  claimed: true,
  records: [],
  diagnostics: [diagnostic]
)
```

| Campo | Decisión |
|---|---|
| `claimed` | Indica que el detector reconoce la página como perteneciente a su ámbito, aunque contenga errores. |
| `records` | Registros tipados producidos; puede contener cero, uno o varios. |
| `diagnostics` | Errores y warnings encontrados durante la inspección. Su contrato se define por separado. |

Reglas de coordinación:

- Si exactamente un detector reclama la página, se recogen sus registros y diagnósticos.
- Si ninguno la reclama y existe `#addToRadar`, el scanner produce un error de contenido no reconocido.
- En el comportamiento del slice, una página anotada con `#addToRadar` pero sin un detector aplicable produce el diagnóstico `unrecognized_content` con severidad `error`; esto es distinto de `unregistered_content`, que es el warning para contenido reconocible sin `#addToRadar`.
- Si más de uno la reclama, el scanner produce un error de detección ambigua y no elige uno silenciosamente.
- Si ninguno la reclama y no hay contenido relevante, la página se ignora.
- Un detector puede reclamar contenido reconocido sin `#addToRadar` para emitir el warning correspondiente, pero no genera registros.
- Un detector puede producir varios registros; una tienda, por ejemplo, genera un `ItemFinding` por cada objeto enumerado.

El detector no recorre mapas, escribe el archivo final ni calcula disponibilidad. Tanto el detector como `DetectionResult` son elementos internos de Ruby que solo viven durante el escaneo; no se serializan en `scan-results.json`.

### Diagnósticos del scanner

Un `Diagnostic` representa un error o warning encontrado durante el escaneo. Los detectores lo crean en Ruby y el scanner serializa sus datos en la colección `diagnostics` de `scan-results.json`.

```json
{
  "code": "missing_stage",
  "severity": "warning",
  "message": "The annotated page does not declare a stage.",
  "source": {
    "map_id": 8,
    "map_name": "Lago Veraz",
    "event_id": 15,
    "event_name": "Alma oculta",
    "page_index": 0,
    "command_index": 4,
    "x": 17,
    "y": 41
  }
}
```

| Campo | Decisión |
|---|---|
| `code` | Identificador estable en `lower_snake_case` para que CLI y pruebas reconozcan el problema sin depender del mensaje. |
| `severity` | `error` o `warning`. |
| `message` | Explicación legible destinada a la persona que ejecuta el scanner o la CLI. |
| `source` | Procedencia estructurada cuando el problema puede localizarse en el contenido escaneado; se omite si no existe una ubicación precisa. |

- Mejorar o traducir `message` no cambia la identidad del diagnóstico; las herramientas dependen de `code`.
- Cuando el diagnóstico procede de una página, `source` incluye `map_name` y `event_name` además de sus IDs, por lo que la CLI puede mostrar nombres sin volver a cargar el mapa.
- Los diagnósticos no son hallazgos válidos y no se mezclan con `items`, `souls` o `tutor_stations`.
- La comprobación de que existen exactamente 108 almas pertenece a la funcionalidad específica del radar de almas, no al contrato genérico de diagnósticos del scanner.
- Un error produce `status: "failed"`; los warnings son compatibles con `status: "success"`.
- La primera versión no añade categorías, timestamps, IDs sintéticos ni trazas internas.

### Catálogo de MTs

El catálogo persistente de MTs contiene `machine_groups` y `machines` dentro de `radiant-devtools/catalogs/movements.json`. Esta sección fija únicamente la estructura ya aceptada.

```json
{
  "schema_version": 1,
  "machine_groups": [
    { "id": "basic", "name": "MT básica", "order": 1, "default_buy_price": 2000 },
    { "id": "intermediate", "name": "MT intermedia", "order": 2, "default_buy_price": 4000 },
    { "id": "advanced", "name": "MT avanzada", "order": 3, "default_buy_price": 6000 },
    { "id": "weather", "name": "Climas", "order": 4, "default_buy_price": 8000 },
    { "id": "terrain", "name": "Campos", "order": 5, "default_buy_price": 10000 },
    { "id": "final_moves", "name": "Movimientos finales", "order": 6, "default_buy_price": 12000 }
  ],
  "machines": [
    {
      "move": "SCALD",
      "group_id": "advanced",
      "override_default_price": 7500
    }
  ]
}
```

- Cada `MachineDefinition.group_id` referencia exactamente un `MachineGroup.id` existente.
- Cada `MachineDefinition.move` es único y deriva su `item_id` como `TM_<MOVE_ID>`; el catálogo no persiste esa duplicación.
- Los IDs de grupo son únicos y estables; `order` es único y determina la prioridad entre grupos.
- `default_buy_price` es un entero no negativo y proporciona el `Price` predeterminado de las máquinas del grupo.
- Los seis precios se declaran explícitamente en los grupos. No se calculan con `order * 2000`.
- `MachineDefinition.override_default_price` es un entero no negativo opcional. Cuando existe, el generador lo escribe como `Price`; cuando se omite, utiliza el `default_buy_price` del grupo.
- Dentro de cada grupo, el orden conserva las claves legacy: primero movimientos con `Power > 0`; después movimientos físicos o especiales con `Power = 0`; finalmente los demás. A continuación se compara potencia ascendente y tipo; `move` es el desempate final estable.
- El número visible `MTxx` y la posición del bloque se derivan del orden completo; el `item_id` permanece estable porque solo depende de `move`.
- La disponibilidad no pertenece a este catálogo. Se calcula desde los `ItemFinding` detectados en eventos y tiendas.
- Un precio particular no altera el grupo, el orden, la disponibilidad ni las identidades estables de la máquina y el movimiento.

### Catálogo de movimientos

`movements.json` es la única fuente persistente de lo enseñable. Su raíz contiene `machine_groups`, `machines` y `tutors`. `tutor_stations` queda reservado para avistamientos en `scan-results.json` y no se usa en este archivo.

```json
{
  "schema_version": 1,
  "machine_groups": [
    { "id": "advanced", "name": "MT avanzada", "order": 3, "default_buy_price": 6000 }
  ],
  "machines": [
    {
      "move": "SCALD",
      "group_id": "advanced"
    }
  ],
  "tutors": [
    {
      "id": "tutor_a1f3",
      "name": "Cueva Extravío",
      "offers": [
        {
          "move": "VACUUMWAVE",
          "cost": {
            "red_shard": 2
          }
        }
      ]
    }
  ]
}
```

- `schema_version` identifica la versión del formato; la política de migración se decidirá por separado.
- La raíz contiene exactamente `schema_version`, `machine_groups`, `machines` y `tutors`; sin claves extra. Las tres listas son obligatorias aunque sea `[]`.
- `order` en `MachineGroup` es solo prioridad entre grupos y sustituye al número de `tier` legacy (`1`-`6` en `pokemon_tools/mts_utilities/mts.json`); no es identidad, precio ni disponibilidad. El `id` es la identidad estable y el precio va en `default_buy_price`.
- Cada `MachineDefinition.move` es único en `machines` y su `group_id` referencia un `MachineGroup.id` existente.
- Cada `TutorStation.id` es único con formato `tutor_<suffix_opaco>` y cada `move` es único dentro de su propio `offers`.
- Un mismo `move` puede estar en dos tutores distintos y en `machines` y `tutors` a la vez; son vías independientes.
- `Tutors[]` no tiene orden de dominio; `offers[]` sí: su índice es el orden visible en la UI.
- Cada `TutorOffer.cost` solo admite `green_shard`, `red_shard`, `blue_shard` y `yellow_shard` con enteros no negativos; se omiten ceros y `{}` significa gratis.
- No contiene `available_from`, `stage_id`, `requires` ni disponibilidad calculada.
- Cualquier violación invalida todo el catálogo sin resultado parcial.

### Resolución de máquinas

`MachineResolver` es un servicio de aplicación Kotlin/JVM que proporciona una única regla estricta para traducir entre el movimiento de una MT y el `item_id` semántico de su objeto.

```kotlin
resolver.itemIdForMove("SCALD")
// => "TM_SCALD"

resolver.moveForItemId("TM_SCALD")
// => "SCALD"
```

- Recibe una colección previamente normalizada de `MachineDefinition`; `group_id` no interviene en la resolución.
- La consulta directa valida que `move` exista en el catálogo y deriva `TM_<MOVE_ID>`; no busca ni asigna un ID almacenado.
- La consulta inversa exige el prefijo `TM_`, extrae el movimiento y valida que exista en el catálogo antes de devolverlo.
- Renombrar un `move` cambia el `item_id` derivado y exige tratarlo como un cambio de identidad deliberado.
- La búsqueda es bidireccional: movimiento a `item_id` e `item_id` a movimiento.
- Un movimiento inexistente o un `item_id` inexistente produce un error explícito de máquina no encontrada.
- Un movimiento repetido o una entrada incompleta produce un error explícito de catálogo inválido al construir el resolvedor.
- Nunca selecciona silenciosamente la primera coincidencia.
- No lee archivos ni depende directamente de JSON o `GameData`; el adaptador correspondiente le entrega datos normalizados.
- No genera PBS, calcula orden, precio, número visible o disponibilidad, modifica la mochila, muestra mensajes ni decide cómo debe reaccionar cada consumidor ante un error.
- `dar_mt` y las tiendas utilizan la consulta por movimiento. `doctor` utiliza la consulta inversa para interpretar referencias directas a `item_id`.
- Solo existe en memoria; no forma parte del catálogo persistente ni de `scan-results.json`.

### Retirada de IDs numéricos

- La conversión sustituye todo el catálogo `TMxx` por IDs `TM_<MOVE_ID>` y no conserva aliases numéricos.
- Las referencias existentes en mapas se convierten sobre datos deserializados mediante la correspondencia anterior `TMxx → movimiento`; no se editan binarios con reemplazos de texto.
- Tras la conversión, `doctor` considera cualquier referencia `:TMxx` un error de contenido pendiente.
- No se soportan partidas anteriores a la conversión y no se implementa migración de saves.
- Se retiran `$game_variables[500]`, el hook de `PokemonBag#add` y la reconstrucción de la mochila en `SaveData.load_all_values`.

### Generación de MTs

`MachineGenerator` es un servicio de aplicación Kotlin/JVM que transforma grupos, definiciones de MT y metadatos de movimientos ya validados en el texto completo de los bloques PBS generados.

```kotlin
val pbsText = machineGenerator.generate(
  groups = machineGroups,
  machines = machineDefinitions,
  moves = moveMetadata
)
```

- No lee el catálogo, `PBS/moves.txt` ni `PBS/items.txt`; recibe datos ya interpretados por los adaptadores correspondientes.
- Ordena por `MachineGroup.order`, subgrupo técnico legacy, potencia ascendente, tipo y `move`. Este último es el desempate final y evita depender del orden accidental del array JSON.
- El subgrupo técnico vale primero para movimientos con potencia positiva, después para movimientos físicos o especiales con potencia cero y finalmente para los demás.
- La posición ordenada produce el nombre visible `MTxx` y la posición del bloque; el encabezado se deriva siempre como `TM_<MOVE_ID>`.
- `Price` utiliza `MachineDefinition.override_default_price` cuando está presente y `MachineGroup.default_buy_price` cuando se omite.
- El nombre y los metadatos del movimiento permiten construir el bloque y su descripción; la salida es texto PBS, no JSON.
- Si falta un grupo o movimiento, se repite un movimiento o algún dato necesario es inválido, la generación completa falla y no devuelve un resultado parcial.
- No asigna IDs mediante contadores ni estado, modifica el catálogo, escribe archivos, inserta bloques en `items.txt`, compila PBS ni resuelve entregas o disponibilidad.
- Dos ejecuciones con las mismas entradas producen texto idéntico byte a byte.

### Escritura de MTs en PBS

`MachinePbsWriter` es el único componente Kotlin/JVM que inserta en `PBS/items.txt` el texto producido por `MachineGenerator`. Gestiona una región explícitamente delimitada:

```ini
# BEGIN GENERATED MACHINES
# WARNING: This section is generated automatically. Do not edit it manually.
[TM_SCALD]
Name = MT17
Price = 7500
Move = SCALD
# END GENERATED MACHINES
```

- Exige exactamente un marcador inicial y uno final, en ese orden. Si falta alguno, está duplicado o aparece desordenado, falla sin modificar el archivo.
- La advertencia en inglés aparece inmediatamente después del marcador inicial y forma parte del encabezado gestionado.
- Sustituye únicamente el contenido de la región. Todo lo situado fuera permanece idéntico byte a byte.
- Escribe primero un archivo temporal en el mismo directorio y reemplaza el destino solo cuando la escritura completa termina correctamente.
- No elimina bloques por coincidir con un patrón de ID de máquina, no utiliza desplazamientos fijos de líneas y no añade el contenido al final como alternativa silenciosa.
- Recibe texto PBS ya generado; no lee ni valida catálogos, ordena máquinas, calcula precios o nombres, compila PBS ni resuelve entregas.
