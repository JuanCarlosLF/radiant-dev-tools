---
createdAt: 2026-09-19
updatedAt: 2026-09-20
type: implementation-guide
status: draft
aliases:
  - Guía de implementación del sistema de escaneo y progresión
---

# Guía de implementación

> [!abstract] Propósito
> Planificar y verificar la ejecución de [[Evolución del sistema de escaneo y progresión|la propuesta]]. Los campos y las invariantes pertenecen a [[domain-models]] y [[contracts]]; esta guía no los duplica.

## Estructura y límites de código

La aplicación externa es un único proyecto Kotlin/JVM. No se crean módulos Gradle adicionales mientras el primer caso de uso no los justifique.

```text
radiant-devtools/
  settings.gradle.kts
  build.gradle.kts
  catalogs/
    progression.json
    movements.json
  artifacts/
    scan-results.json
  .cache/
    scanner.json
  src/main/kotlin/
    radiant/devtools/cli/Main.kt
    radiant/devtools/application/ScanReport.kt
    radiant/devtools/contract/ScanResults.kt
    radiant/devtools/adapter/json/ScanResultsReader.kt
```

`catalogs/` es fuente versionada. `artifacts/scan-results.json` y `.cache/scanner.json` son derivados, reemplazables e ignorados por Git. El scanner no usa `build/`: Gradle puede limpiarlo sin relación con el ciclo de Essentials.

Ruby dentro de `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/` carga `.rxdata`, recorre páginas, detecta contenido, genera diagnósticos, mantiene la caché y publica el resultado atómicamente. Kotlin/JVM consume el JSON publicado, ejecuta consultas externas y, en fases posteriores, valida catálogos y genera PBS/CSV/Ruby runtime. Nunca abre `.rxdata`.

Los límites exactos del scanner están en [[contracts#Acceso a mapas]], [[contracts#Recorrido de mapas]], [[contracts#Caché del scanner]] y [[contracts#Escritura atómica de resultados]].

## Primer slice

El primer slice prueba solo el límite nuevo entre procesos:

1. Una acción Ruby del menú debug escanea un mapa anotado y publica un `scan-results.json` válido.
2. La CLI Kotlin/JVM, ejecutada con Gradle Wrapper, deserializa ese archivo y muestra un resumen conciso más diagnósticos.

El mapa deliberadamente anotado, la forma de evento, la familia de hallazgo, las colecciones y diagnósticos ejercitados, el comando exacto, la salida esperada y las comprobaciones observables quedaron registrados antes de implementar el slice. Este bloque conserva la definición aprobada; el estado de implementación y la prueba disponible se resumen en [[features]].

#### Escenario registrado 2026-09-22

- Mapa: 002 Pueblo Hojaverde, anotado deliberadamente (decisión de usuario).
- Forma de evento: `pbReceiveItem`; familia: objetos (`items`) (decisión de usuario).
- Colecciones con contenido en la prueba: `items` (hallazgo) + `diagnostics` (avisos); `souls` y `tutor_stations` quedan vacías (propuesto).
- Casos cubiertos: (a) evento bien anotado (`#addToRadar` + `#stage`) → `ItemFinding`, estado `success`; (b1) página con `#addToRadar` sin `#stage` → warning `missing_stage`, sin hallazgo, el estado sigue `success`; (b2) contenido reconocible mediante `pbReceiveItem` sin `#addToRadar` → warning `unregistered_content`, sin hallazgo, distinto de `missing_stage` (aprobado; ver [[contracts#Contrato común de detector]]).
- Comando concreto: `./gradlew run --args="scan --map <map_id>"` (flag `--map`, sin prefijo `radiant` — decisión de usuario).
- Salida esperada (estructura aprobada, no fixture ejecutable): `status: "success"` con 1 `ItemFinding` (`pbReceiveItem`, `stage_id: "stg_a1f3"`, `requires: []`), warnings `missing_stage` y `unregistered_content`, `souls`/`tutor_stations` vacías. Los valores de localización del mapa anotado se suministrarán después; no se inventan IDs de evento, coordenadas, nombres ni mensajes. Esqueleto (campos según [[contracts#Contenedor de resultados]], [[domain-models#ItemFinding]], [[contracts#Diagnósticos del scanner]]):
```json
{
  "schema_version": 1,
  "status": "success",
  "items": [
    {
      "item_id": "<OBJETO_ANOTADO>",
      "quantity": 1,
      "stage_id": "stg_a1f3",
      "requires": [],
      "source": {
        "kind": "event",
        "map_id": 2,
        "map_name": "Pueblo Hojaverde",
        "event_id": "<actual event id>",
        "event_name": "<actual event name>",
        "page_index": "<actual zero-based page index>",
        "command_index": "<actual zero-based command index>",
        "command": "pbReceiveItem",
        "x": "<actual event x>",
        "y": "<actual event y>"
      },
      "tags": [],
      "notes": ""
    }
  ],
  "souls": [],
  "tutor_stations": [],
  "diagnostics": [
    { "code": "missing_stage", "severity": "warning", "message": "<actual message>", "source": {
      "map_id": "<actual map id>", "map_name": "<actual map name>", "event_id": "<actual event id>",
      "event_name": "<actual event name>", "page_index": "<actual zero-based page index>",
      "command_index": "<actual zero-based command index>", "x": "<actual event x>", "y": "<actual event y>"
    } },
    { "code": "unregistered_content", "severity": "warning", "message": "<actual message>", "source": {
      "map_id": "<actual map id>", "map_name": "<actual map name>", "event_id": "<actual event id>",
      "event_name": "<actual event name>", "page_index": "<actual zero-based page index>",
      "command_index": "<actual zero-based command index>", "x": "<actual event x>", "y": "<actual event y>"
    } }
  ]
}
```
- Código `unregistered_content` aceptado para este slice.
- El bloque anterior es un ejemplo estructural aprobado: `source` siempre es un objeto de localización de página, nunca un placeholder string. Los valores `<actual ...>` se fijan al anotar el mapa 002.
- Comprobaciones observables previstas: exit `0`; `status == "success"`; `items.length == 1` con `item_id` igual al anotado; `diagnostics` con `missing_stage` + contenido no registrado y cero `error`; `souls`/`tutor_stations` vacías; la CLI muestra resumen + diagnósticos. La prueba funcional negativa de T7 —resultado `failed` no utilizable y código de salida correspondiente— permanece pendiente. No se afirma una ejecución automatizada reciente de la CLI.

Quedan fuera: generación de catálogos, migración de tutores, Desktop/KMP, migración masiva de utilidades y familias de scanner no incluidas en el escenario elegido.

## CLI

Durante la primera fase, el cliente se ejecuta mediante Gradle Wrapper:

```text
./gradlew run --args="<área> <acción> [opciones]"
```

El nombre conceptual del cliente es `radiant`. Sus áreas previstas son `doctor`, `progression`, `scan`, `items`, `machines`, `tutors` y `souls`; los subcomandos concretos solo se implementan cuando su contrato y caso de uso estén aprobados.

Las primeras consultas justificadas son `items located-in`, `items available-by`, `items requires`, `items newly-available-in` y `progression affected-by`. `doctor` es no mutador: revisa datos publicados, referencias legacy, hallazgos ambiguos o duplicados, coherencia de catálogos y artefactos generados, caché y exportación de progresión. No vuelve a cargar `.rxdata` ni reescribe contenido por defecto.

Los códigos de salida se mantienen estables: `0` operación válida, `1` error de datos/validación, `2` uso incorrecto y `3` error de lectura, escritura o dependencia. Las salidas `--json` no llevan decoración.

Los formatos y reglas que utiliza cada comando se consultan en [[contracts]], especialmente las secciones de disponibilidad, `doctor`, retirada de IDs numéricos y contenedor de resultados.

## MTs

La migración conserva el orden prioritario y los nombres visibles `MTxx`, pero sustituye la identidad posicional por `TM_<MOVE_ID>`. El catálogo no persiste ese ID derivado; una modificación de orden no cambia la identidad del movimiento.

Kotlin/JVM valida `movements.json`, usa [[contracts#Resolución de máquinas|MachineResolver]] para las conversiones estrictas, produce texto con [[contracts#Generación de MTs|MachineGenerator]] y sustituye exclusivamente la región delimitada mediante [[contracts#Escritura de MTs en PBS|MachinePbsWriter]]. Ninguno de esos servicios resuelve disponibilidad, modifica el catálogo o migra mapas como efecto secundario.

La conversión de eventos usa mapas deserializados, nunca sustitución de texto en binarios. `doctor` informa referencias `TMxx`; un paso mutador separado y revisable las migra después. No habrá aliases numéricos ni migración de partidas al retirar la compatibilidad legacy.

## Tutores

`movements.json` es la fuente editable de máquinas y tutores. [[domain-models#TutorStation|TutorStation]] define una estación, [[domain-models#TutorOffer|TutorOffer]] sus ofertas ordenadas y [[domain-models#TutorFinding|TutorFinding]] su avistamiento en un mapa; no se mezclan.

Kotlin/JVM genera el artefacto Ruby de datos dentro de `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/`. El nombre de archivo y el módulo público se eligen al implementar el caso de uso, no antes. Move Tutor conserva UI, pago y enseñanza, y consume el artefacto mediante `Requires = Radiant DevTools, 1.0.0`; no lee JSON ni usa `require` Ruby explícito.

El detector reconoce las llamadas de tutor y el contrato de anotaciones produce los diagnósticos correspondientes; véase [[contracts#Registro de tutores]]. La verificación cruza estaciones declaradas, ofertas generadas y NPCs detectados.

## Progresión y Excel

`progression.json` conserva la identidad y el orden de stages. El Excel de escalado consume una exportación derivada (`progression.csv`), nunca define otra fuente de verdad. La primera fase no modifica automáticamente el `.xlsx`; una comprobación informa desincronización.

El ordinal exportado sirve para tablas y fórmulas existentes. El progreso normalizado sirve para fórmulas que no deban asumir exactamente 18 stages. Ninguno sustituye el ID estable descrito en [[domain-models#stage]].

## Fases de entrega

| Fase | Resultado | Puerta de aceptación |
|---|---|---|
| 0. Caracterización | Fixtures y medición del sistema legacy, sin cambio funcional | La evidencia no se confunde con diseño nuevo |
| 1. Progresión | Catálogo de stages y capacidades; exportación CSV | Las referencias inválidas se diagnostican |
| 2. Scanner | Recorrido compartido, detectores y resultado normalizado | Un resultado localiza cada hallazgo y se publica de forma segura |
| 3. CLI Kotlin/JVM | Proyecto Gradle y consultas sobre el resultado publicado | Mover un desbloqueo recalcula los informes sin editar eventos |
| 4. MTs | IDs semánticos y PBS determinista | Cambiar orden/grupo no cambia `TM_<MOVE_ID>` |
| 5. Tutores | Datos Ruby generados y detección de estaciones | El artefacto runtime coincide con el catálogo |
| 6. Limpieza | Retirada de compatibilidades verificadas | No quedan referencias legacy ni runtime duplicado |

Cada fase conserva compatibilidad solo mientras exista una comprobación que la necesite. No se adelanta una fase porque su código parezca sencillo.

## Validación

La validación usa datos realistas y separa cuatro niveles:

1. **Contratos:** parser de anotaciones, IDs desconocidos, duplicados, requisitos y publicación atómica.
2. **Dominio:** disponibilidad efectiva, orden de stages, identidad semántica de MT y orden visible de tutor.
3. **Adaptadores:** lectura de resultados JSON, generación PBS acotada, Ruby runtime generado y exportación CSV.
4. **Integración:** mapas reales, `doctor`, catálogos y artefactos coherentes.

Una ejecución limpia no deja diagnósticos residuales, un resultado fallido no habilita consultas normales y todo contenido generado conserva trazabilidad hasta su origen. Los casos concretos se añaden junto al contrato que validan, no como una lista duplicada en el plan.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Un cambio del detector reutiliza resultados obsoletos | Firma de scanner, caché versionada y escaneo completo cuando no coinciden |
| Una publicación se interrumpe | Escritura temporal y reemplazo atómico |
| Un catálogo y el runtime divergen | Generación determinista y comprobación de artefacto |
| Una MT cambia de significado al reordenar | ID semántico derivado del movimiento |
| Excel y progresión se separan | Exportación derivada y diagnóstico de sincronía |
| La migración de mapas corrompe binarios | Operar datos deserializados y revisar con `doctor` |

## Límites deliberados

No se implementan todavía base de datos, servidor, API, reglas booleanas arbitrarias, probabilidades, simulación de eventos, rutas óptimas, edición automática del Excel, Desktop/KMP, ejecución headless de RPG Maker ni una migración masiva de utilidades. Cada uno requiere una necesidad demostrada y un contrato propio.

> [!important] Regla de cierre
> Un archivo, campo o flujo no listado en su documento propietario no existe para implementación. Si una nueva necesidad afecta al significado de un modelo o contrato, se acepta allí antes de codificarla.
