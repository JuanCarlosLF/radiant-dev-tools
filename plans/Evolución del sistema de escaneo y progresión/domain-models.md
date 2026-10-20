---
createdAt: 2026-09-16
updatedAt: 2026-09-19
type: domain-models
status: evolving
tags:
aliases:
  - Modelos de dominio del sistema de escaneo y progresión
---

# Domain models

> [!abstract] Propósito
> Registro incremental de los modelos de dominio aceptados de [[Evolución del sistema de escaneo y progresión]]. Solo se añade una entrada después de consensuarla.

## Aceptados

### stage

Segmento amplio y ordenado de la progresión utilizado para ubicación, disponibilidad agregada, informes y balance.

```json
{
  "id": "stg_a1f3",
  "name": "Pueblo Hojaverde - Ciudad Jubileo",
  "description": "Abarca el recorrido desde que empieza el juego hasta la entrada en Ciudad Jubileo.",
  "unlocks": ["surf"]
}
```

| Campo | Decisión |
|---|---|
| `id` | Obligatorio, único, estable y no posicional; no codifica límites mutables. |
| `name` | Obligatorio, no vacío, editable y no necesariamente único. |
| `description` | Opcional, texto libre que delimita el inicio y fin narrativo del tramo. |
| `unlocks` | Lista opcional, sin duplicados, de capacidades concedidas durante el stage. |

Decisiones:

- La posición canónica es el índice dentro de `stages`; no se persiste `order`.
- `number` y `progress` se derivan de la posición y del total de stages.
- La precisión es por stage: un desbloqueo puede ocurrir en cualquier momento de ese segmento.
- Cada capacidad aparece en `unlocks` de exactamente un stage.
- No se incluyen `aliases`, `entry_requires`, límites ni orden intrastage.
- `description` es opcional y no afecta al orden canónico ni a la disponibilidad.
- Añadir, retirar, reordenar y retaggear contenido son ediciones manuales; las herramientas localizan y validan referencias, pero no reescriben eventos.

### Capability

Capacidad de acceso adquirida por el jugador que puede condicionar cuándo un contenido resulta obtenible.

```json
{
  "id": "surf",
  "name": "Surf"
}
```

| Campo | Decisión |
|---|---|
| `id` | Obligatorio, único, estable y apto para autoría manual; usa `lower_snake_case`. |
| `name` | Obligatorio, no vacío y editable; se usa en informes y mensajes. |

Decisiones:

- La capacidad representa un efecto de acceso, no la MO, el movimiento, la medalla ni el evento que la concede.
- `stage.unlocks` y `ItemFinding.requires` referencian el mismo `id` validable.
- Cada capacidad aparece en `unlocks` de exactamente un stage.
- Un ID retirado no se reutiliza con otro significado.
- `Capability` no contiene `stage_id` ni `unlocked_at`; `stage.unlocks` es la única autoridad sobre el stage que la concede.
- La primera versión no incluye tipo, categoría, fuente de concesión, dependencias, aliases, descripción ni reglas booleanas.

### ItemFinding

Registro derivado y regenerable de una obtención concreta de un objeto detectada por el scanner. Se crea en memoria, se serializa en la colección `items` de `scan-results.json` y posteriormente puede ser consumido por la CLI.

Una MT también es un objeto: `dar_mt(:SCALD)` y una tienda que ofrezca `SCALD` se resuelven al `item_id` canónico de su máquina. Las almas y las estaciones de tutor no son `ItemFinding`; tienen colecciones y contratos propios.

```json
{
  "item_id": "TM_SCALD",
  "quantity": 1,
  "stage_id": "stg_a1f3",
  "requires": ["surf"],
  "source": {
    "kind": "event",
    "map_id": 8,
    "map_name": "Lago Veraz",
    "event_id": 15,
    "event_name": "MT Escaldar",
    "page_index": 0,
    "command_index": 12,
    "command": "dar_mt",
    "x": 17,
    "y": 41
  },
  "tags": ["hidden"],
  "notes": "Al otro lado del lago"
}
```

| Campo | Decisión |
|---|---|
| `item_id` | ID canónico del objeto. En una MT se resuelve desde el movimiento o referencia detectados. |
| `quantity` | Cantidad detectada; vale `1` por defecto. |
| `stage_id` | Stage declarado mediante `#stage:<stage_id>`; es obligatorio. |
| `requires` | IDs de `Capability` obligatorios, sin duplicados y sin orden significativo. |
| `source` | Procedencia suficiente para distinguir `event` o `shop` y localizar mapa, evento, página, comando y coordenadas. |
| `tags` | Clasificaciones de autoría no expresadas por los campos anteriores. |
| `notes` | Texto libre de autoría. |

Decisiones:

- Varios eventos que entregan el mismo objeto producen varios `ItemFinding`.
- Cada objeto enumerado por una tienda anotada produce un `ItemFinding` con `source.kind = "shop"`; las demás entregas usan `source.kind = "event"`.
- No se distingue entre objeto del suelo y recompensa de evento.
- Una página con `#addToRadar` sin `#stage:<stage_id>` no produce un `ItemFinding` y genera el warning `missing_stage`; un stage declarado pero desconocido sigue siendo un error de diagnóstico.
- No se persiste un `ItemFinding.id` sintético en la primera versión; `source` aporta la trazabilidad necesaria.
- No se almacena disponibilidad calculada, `stage_number`, `effective_stage_id`, `delayed_by` ni estado del jugador.
- `source` y las anotaciones permanecen como estructuras internas de `ItemFinding`, no como modelos independientes.

### SoulFinding

Registro derivado y regenerable de una aparición concreta de un alma de Spiritomb declarada mediante `#addToRadar #alma`. Se serializa en la colección `souls` de `scan-results.json`.

```json
{
  "stage_id": "stg_a1f3",
  "requires": ["surf"],
  "source": {
    "map_id": 2,
    "map_name": "Pueblo Hojaverde",
    "event_id": 32,
    "event_name": "Alma de la chimenea",
    "page_index": 0,
    "command_index": 4,
    "x": 17,
    "y": 41
  },
  "notes": "Oculta en la chimenea"
}
```

| Campo | Decisión |
|---|---|
| `stage_id` | Stage declarado mediante `#stage:<stage_id>`; es obligatorio. |
| `requires` | Lista opcional de IDs de `Capability`; si existen, todos son obligatorios, sin duplicados y sin orden significativo. |
| `source` | Procedencia suficiente para localizar mapa, evento, página, comentario y coordenadas. |
| `notes` | Texto libre restante de la anotación. |

Decisiones:

- No es un objeto de inventario y no contiene `item_id`, `quantity`, `source.kind` ni categorías de objetos.
- `#addToRadar` autoriza el registro y `#alma` determina que el resultado pertenece a `souls`; no se exige una llamada de script.
- Cada evento representa como máximo una alma; varias páginas con `#addToRadar #alma` en el mismo evento producen un error.
- No se persiste un ID sintético; `source` aporta la trazabilidad de la aparición.
- Su disponibilidad se obtiene con el resolvedor genérico a partir de `stage_id` y `requires`.

### ResolvedAvailability

Resultado derivado que expresa el primer stage durante el que un contenido puede obtenerse, considerando su `stage_id` declarado y las capacidades obligatorias de `requires`.

```ruby
ResolvedAvailability.new(
  effective_stage_id: "stg_k9m2",
  delayed_by: ["surf"]
)
```

| Campo | Decisión |
|---|---|
| `effective_stage_id` | ID del stage más tardío entre el declarado por el hallazgo y los que desbloquean sus requisitos. |
| `delayed_by` | Capacidades que desplazan la disponibilidad a ese stage más tardío; queda vacío si ningún requisito la retrasa. |

Decisiones:

- Es un resultado temporal calculado a partir de `stage_id`, `requires` y `progression.json`; no se persiste en `scan-results.json`.
- No depende de un tipo concreto de contenido. Puede utilizarse con `ItemFinding`, `SoulFinding` u otro registro que declare esos datos.
- Si varios requisitos retrasan el objeto hasta el mismo stage efectivo, `delayed_by` los incluye todos.
- No contiene `stage_number`, `progress`, ubicación, procedencia, estado del jugador ni un booleano `available`.
- Su precisión es por stage: expresa disponibilidad durante ese segmento, no necesariamente al comienzo.

### MachineGroup

Grupo explícito utilizado para ordenar MTs y asignar el precio de compra predeterminado de sus objetos generados.

```json
{
  "id": "advanced",
  "name": "MT avanzada",
  "order": 3,
  "default_buy_price": 6000
}
```

| Campo | Decisión |
|---|---|
| `id` | Obligatorio, único y estable; una `MachineDefinition` lo referencia mediante `group_id`. |
| `name` | Obligatorio, no vacío y editable; explica el significado del grupo en informes. |
| `order` | Entero positivo y único que establece la prioridad del grupo en la generación. |
| `default_buy_price` | Entero no negativo que proporciona el precio de compra cuando una MT del grupo no declara una excepción. |

Decisiones:

- Sustituye al `tier` numérico legacy sin reinterpretar sus seis grupos: básicas, intermedias, avanzadas, climas, campos y movimientos finales.
- El precio se declara explícitamente por grupo; no se deriva mediante un multiplicador.
- No representa disponibilidad narrativa. El momento obtenible se calcula desde los hallazgos de eventos y tiendas.
- No contiene movimientos ni referencias a stages.

### MachineDefinition

Definición persistente de una MT. El movimiento es su identidad canónica y permite derivar de forma determinista el ID interno del objeto, aunque cambien su número visible y su posición generada.

```json
{
  "move": "SCALD",
  "group_id": "advanced",
  "override_default_price": 7500
}
```

| Campo | Decisión |
|---|---|
| `move` | ID obligatorio, único y estable del movimiento que enseña la máquina. El `item_id` se deriva como `TM_<MOVE_ID>`. |
| `group_id` | Referencia obligatoria a un `MachineGroup.id` existente. |
| `override_default_price` | Entero no negativo opcional que sustituye el precio predeterminado del grupo para esta máquina. |

Decisiones:

- El número visible `MTxx` no forma parte del modelo; se deriva de la posición generada.
- `item_id` no se persiste en el catálogo: `SCALD` siempre deriva `TM_SCALD`.
- Renombrar un `move` cambia también el `item_id` derivado y se considera un cambio de identidad explícito, no una edición inocua.
- El generador escribe los bloques PBS en el orden resultante, pero la posición nunca interviene en el `item_id`.
- No contiene `available_from`: la disponibilidad procede de `ItemFinding` y del resolvedor de disponibilidad.
- Si `override_default_price` está presente, el generador lo escribe como `Price`; si se omite, utiliza `MachineGroup.default_buy_price`.
- El precio particular no modifica el grupo, el orden, la disponibilidad, `move` ni el `item_id` derivado.

### TutorStation

Estación persistente de tutor que sustituye al `tier` numérico legacy. Agrupa las ofertas que enseña un NPC y su orden visible en la UI.

```json
{
  "id": "tutor_a1f3",
  "name": "Cueva Extravío",
  "offers": [
    {
      "move": "VACUUMWAVE",
      "cost": {
        "red_shard": 2
      }
    },
    {
      "move": "MACHPUNCH",
      "cost": {
        "red_shard": 2
      }
    }
  ]
}
```

| Campo | Decisión |
|---|---|
| `id` | Obligatorio, único y estable; usa `tutor_<suffix_opaco>`, sin codificar lugar ni orden. |
| `name` | Obligatorio, no vacío y editable; se usa en informes y no necesita ser único. |
| `offers` | Lista ordenada de `TutorOffer`; su índice es el orden visible en la UI. |

Decisiones:

- La posición canónica de cada oferta es su índice dentro de `offers`; no se persiste `order`.
- `offers` puede estar vacía para estaciones reservadas sin oferta, como el tier 5 legacy.
- Cada `move` aparece como máximo una vez dentro de la misma estación; puede repetirse en estaciones distintas con distinto `coste`.
- No contiene `stage_id`, `requires` ni disponibilidad calculada, igual que `MachineDefinition` no contiene `available_from`.
- Un ID retirado no se reutiliza con otro significado.

### TutorOffer

Oferta persistente dentro de una `TutorStation`. Expresa qué movimiento enseña y su coste en partes.

```json
{
  "move": "VACUUMWAVE",
  "cost": {
    "red_shard": 2
  }
}
```

| Campo | Decisión |
|---|---|
| `move` | ID obligatorio y estable del movimiento en mayúsculas; debe existir en `PBS/moves.txt`. |
| `cost` | Objeto disperso con claves opcionales `green_shard`, `red_shard`, `blue_shard` y `yellow_shard`; valores enteros no negativos. Se omiten los ceros y `{}` significa gratis. |

Decisiones:

- Las claves corresponden a los objetos canónicos `GREENSHARD`, `REDSHARD`, `BLUESHARD` y `YELLOWSHARD`; no se aceptan claves desconocidas ni valores negativos.
- Renombrar un `move` se considera un cambio de identidad explícito, no una edición inocua.
- El coste no modifica la estación, el orden, la disponibilidad ni la identidad del movimiento.

### TutorFinding

Registro derivado y regenerable de un NPC tutor concreto detectado por el scanner. Se serializa en la colección `tutor_stations` de `scan-results.json`. No es la `TutorStation` del catálogo; es su avistamiento en un mapa.

```json
{
  "station_id": "tutor_a1f3",
  "stage_id": "stg_a1f3",
  "requires": ["surf"],
  "source": {
    "map_id": 12,
    "map_name": "Cueva Extravío",
    "event_id": 4,
    "event_name": "Tutor",
    "page_index": 0,
    "command_index": 8,
    "command": "pbMoveTutorScreen",
    "x": 10,
    "y": 14
  },
  "notes": "Junto a la salida"
}
```

| Campo | Decisión |
|---|---|
| `station_id` | Referencia obligatoria a una `TutorStation.id` existente en `movements.json`. |
| `stage_id` | Stage declarado mediante `#stage:<stage_id>`; es obligatorio. |
| `requires` | Lista opcional de IDs de `Capability`; si existen, todos son obligatorios, sin duplicados y sin orden significativo. |
| `source` | Procedencia suficiente para localizar mapa, evento, página, comando `pbMoveTutorScreen` y coordenadas. |
| `notes` | Texto libre restante de la anotación. |

Decisiones:

- El coste no se duplica en el hallazgo; vive solo en el catálogo.
- Su disponibilidad se obtiene con el resolvedor genérico a partir de `stage_id` y `requires`, igual que `ItemFinding` y `SoulFinding`.
- Cada evento representa como máximo un tutor; varias páginas con tutor reclamado en el mismo evento producen un error en vez de escoger una silenciosamente.
- No se persiste un ID sintético; `source` aporta la trazabilidad del NPC.
