---
status: working report
source_plan: radiant-devtools-architecture-audit-plan.md
---

# Radiant DevTools architecture audit

> Purpose: this audit compares the legacy implementation with the proposed architecture in `Evolución del sistema de escaneo y progresión.md`. Its output is the exact change list for that canonical proposal and its implementation guide; it does not implement either flow.

## 1. Current flow and ownership

| Flow/component | Reads and requires | Writes/consumer | Current owner | Evidence |
|---|---|---|---|---|
| Map/item scanner | `Data/MapInfos.rxdata`, `Data/MapNNN.rxdata`; initialized Essentials (`load_data`, `Graphics`, debug menu) | `pokemon_tools/{mts,item}_utilities/ubicaciones*.json` plus cache files | Ruby in-game plugin | `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/002_Item_ubication_scanner.rb:5-142` |
| Soul scanner | Same Essentials map objects and debug-menu environment | `pokemon_tools/soul_utilities/ubicaciones_almas.json` plus cache | Ruby in-game plugin | `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/003_Spiritomb_souls_scanner.rb:5-97` |
| Scanner reports | Legacy location JSON files | Terminal text reports | Standalone Ruby | `pokemon_tools/mts_utilities/gestionar_mts.rb:1-137`; `pokemon_tools/item_utilities/radar_objetos.rb:1-171` |
| MT catalog generation | `mts.json`, `PBS/moves.txt` | Rewrites generated MT blocks in `PBS/items.txt` | Standalone Ruby | `pokemon_tools/mts_utilities/generar_mts.rb:1-95` |
| Tutor catalog and runtime | `tutor_moves.json`; data is duplicated in the plugin | `tutor_moves.json` is edited; `MoveTutorData` is consumed by the in-game UI | Standalone Ruby + in-game Ruby | `pokemon_tools/tutor_utilities/gestionar_tutores.rb:1-181`; `Plugins/[Z_CUSTOM_007] Move Tutor/[000] Platinum Move Tutor.rb:28-236,602-609` |

The only existing scanner paths that read `.rxdata` run inside Pokémon Essentials. No Kotlin/JVM project, Kotlin source, or consumer of `scan-results.json` exists in the inspected scope. The current scanners do **not** produce `scan-results.json`; that artifact is an accepted target contract, not an implementation fact.

## 2. Conflicts found

| Type                                  | Conflict                                                                                                                                             | Required direction                                                                                                                     |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Current code vs. target scan contract | Three legacy outputs and three separate cache locations replace the single normalized result expected by the accepted contract.                      | Ruby scanner publishes one atomic `scan-results.json`; Kotlin reads it only after publication.                                         |
| Duplicate catalog/runtime data        | `tutor_moves.json` and `MoveTutorData` are manually maintained copies.                                                                               | Kotlin treats the editable catalog as input and generates the Ruby runtime data consumed by the existing tutor UI.                     |
| Current generator safety              | `generar_mts.rb` removes blocks by `TM\d+`, calculates numeric identities, and falls back to appending when its marker is absent.                    | Kotlin generation must implement the accepted semantic IDs and the bounded `MachinePbsWriter` behavior before replacing this script.   |
| Architecture document                 | `Evolución del sistema de escaneo y progresión.md` calls the client `ruby pokemon_tools/bin/radiant` and calls the resolver/generator Ruby services. | Reword those client and generation responsibilities as Kotlin/JVM; retain Ruby only for the Essentials adapter and generated runtime.  |
| Research document                     | The current-state research describes observed Ruby-first behavior and legacy outputs.                                                                | Preserve it as historical/current evidence; label its obsolete target-facing conclusions where they are presented as future direction. |

## 3. Proposed minimum architecture

### Ownership and boundary

| Responsibility                                                                                                                                     | Owner                                                    | Boundary                                                                                                              |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Load `MapInfos.rxdata` and maps; walk Essentials event objects; parse annotations; detect findings; produce diagnostics; cache; atomically publish | Ruby, inside `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/` | Writes `scan-results.json`; Kotlin never opens `.rxdata`.                                                             |
| Deserialize and validate the published result; execute scan queries and render CLI output                                                          | Kotlin/JVM                                               | Reads typed `scan-results.json` objects.                                                                              |
| Read and validate editable movement/progression catalogs; generate PBS and generated Ruby runtime data                                             | Kotlin/JVM                                               | Writes PBS and a generated Ruby artifact in the Radiant DevTools plugin. Ruby consumes it but does not parse catalogs at runtime. |
| In-game delivery/UI behavior and Essentials APIs                                                                                                   | Ruby, existing game plugins                              | Move Tutor depends on Radiant DevTools and consumes its generated runtime data.                                      |
| `scan-results.json` and editable catalog schemas                                                                                                   | Language-independent contracts                           | Versioned JSON; neither language owns the meaning unilaterally.                                                       |

`scan-results.json` is the sole initial cross-process artifact for scanning. It is published by Ruby only after the full result has been written successfully; Kotlin consumes a published document as typed data. This follows the accepted result, cache, and atomic-write contracts (`contracts.md:150-231`) and requires no direct JVM `.rxdata` reader.

### Minimum JVM source structure

```text
radiant-devtools/
  settings.gradle.kts
  build.gradle.kts
  src/main/kotlin/
    radiant/devtools/cli/Main.kt                 # command parsing and exit code
    radiant/devtools/application/ScanReport.kt   # scan use case
    radiant/devtools/contract/ScanResults.kt     # typed JSON boundary
    radiant/devtools/adapter/json/ScanResultsReader.kt
```

Only the scan path is needed for the first functionality. Catalog validation and PBS/Ruby generation belong in the same project later, as application use cases and JSON/PBS/Ruby adapters; no extra Gradle modules are justified yet. `Main.kt` depends on application code, and the JSON adapter depends on the contract; neither domain/application behavior depends on the CLI.

The initial CLI runs through the Gradle Wrapper. Packaging is deferred; it does not shape the application boundary or a future desktop client.

### Generated tutor runtime: approved plugin boundary

The current plugin has one Ruby file, `Plugins/[Z_CUSTOM_007] Move Tutor/[000] Platinum Move Tutor.rb`. It currently contains both `MoveTutorData` (the tier-to-moves and shard-cost data) and the tutor UI/entry point. There is no generated runtime Ruby file today.

The generated Ruby artifact belongs to `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/`, not to Move Tutor. Kotlin/JVM writes it there from the editable catalog. Move Tutor remains responsible only for Essentials UI, payment, and teaching behavior.

`Plugins/[Z_CUSTOM_008] Radiant Dev Tools/meta.txt` must register the plugin as `Radiant DevTools` (it currently registers `Platinum Dynamic TM's`). `Plugins/[Z_CUSTOM_007] Move Tutor/meta.txt` must declare `Requires = Radiant DevTools, 1.0.0` (or the approved compatible version). Essentials then loads every Radiant DevTools script before every Move Tutor script. No explicit Ruby `require` is needed.

The generated file defines the data API that replaces `MoveTutorData::TUTOR_MOVES_BY_TIER` and `MOVE_SHARD_COSTS`; the UI calls that API but never reads JSON. Its filename and public module name remain implementation details to specify when the tutor-generation use case is planned. This does not block the scan vertical slice.

## 4. Blocking decisions

None for the recommended first functionality. The six decisions recorded in the audit plan determine its ownership and boundary sufficiently.

The accepted layout resolves the on-disk locations for `movements.json`, `progression.json`, `scan-results.json`, and the scanner cache. They are four different artifacts:

| Artifact | Content | Writer | Reader | Lifecycle |
|---|---|---|---|---|
| `progression.json` | Editable `stages` and `capabilities`; it describes progression, not scan findings. | Human author | Kotlin/JVM; Ruby scanner only if validation requires it | Source of truth; versioned and committed. |
| `movements.json` | Editable `machine_groups`, `machines`, and `tutors`; tutor offers and costs live here. | Human author | Kotlin/JVM generator | Source of truth; versioned and committed. |
| `scan-results.json` | One scan attempt: `status`, `items`, `souls`, `tutor_stations`, and `diagnostics`. | Essentials-side Ruby scanner | Kotlin/JVM CLI | Derived and replaceable; written atomically. |
| scanner cache | `schema_version`, `scan_signature`, and per-map `mtime_ns`/`size`; it contains no source data or canonical findings. | Essentials-side Ruby scanner | Same Ruby scanner | Derived and disposable; used only to avoid rescanning unchanged maps. |

This does not block a scan-only vertical slice if its output location is passed/configured by the Ruby adapter.

The accepted artifact layout is:

```text
radiant-devtools/
  catalogs/
    progression.json
    movements.json
  artifacts/
    scan-results.json
  .cache/
    scanner.json
```

`catalogs/` is versioned source. `artifacts/scan-results.json` and `.cache/scanner.json` are derived and should be ignored by Git. `build/` is not used for scanner output because Gradle may remove it independently of the Essentials-side scanner.

## 5. Exact documentation changes (approval required)

| Document | Section | Change |
|---|---|---|
| `Evolución del sistema de escaneo y progresión.md` | `Decisión arquitectónica` and `Cómo se comunican los componentes` (lines 56-104) | Replace the shared Ruby core / `CLI radiant` wording with Kotlin/JVM application and CLI ownership; preserve Essentials-only `.rxdata` access and file exchange. |
| Same | `Flujo de escaneo` and `Flujo de generación` (lines 105-153) | Rename the CLI participant to Kotlin/JVM; state that Ruby publishes `scan-results.json` and Kotlin generates PBS/Ruby artifacts from catalogs. |
| Same | `Arquitectura objetivo` through `Dependencias permitidas` (lines 249-283) | Make language ownership explicit: Ruby is the Essentials adapter/runtime integration; Kotlin/JVM owns external application use cases; contracts remain language-independent. |
| Same | `CLI propuesta` and its command examples (lines 813-925) | Replace `ruby pokemon_tools/bin/radiant` with the Kotlin/JVM CLI run through the Gradle Wrapper; do not preserve Ruby as the external CLI. Packaging remains deferred. |
| Same | `Generación de MTs`, `Evolución de los tutores`, and migration phases (lines 927-1402) | Transfer catalog validation, generator, and writer implementation ownership from Ruby to Kotlin/JVM; generated tutor Ruby belongs to Radiant DevTools, while Move Tutor consumes it through a declared plugin dependency. |
| `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/meta.txt` and `Plugins/[Z_CUSTOM_007] Move Tutor/meta.txt` | Plugin registrations | Register the DevTools plugin as `Radiant DevTools`; declare Move Tutor's `Requires` dependency on that exact registered name and compatible version. |
| `contracts.md` | `Resolución de máquinas`, `Generación de MTs`, `Escritura de MTs en PBS` (lines 462-543) | Reword Ruby-specific service ownership as Kotlin/JVM application services while preserving accepted inputs, invariants, and artifact contracts. |
| `Guía de implementación.md` | Sections 1-4 (currently pending) | Add only the approved source placement, artifact layout, and ownership above; do not fill it before approval. |
| Same | New `First implementation slice` section | State the approved slice's input scenario, exact contract subset, CLI command/output, exclusions, and acceptance checks before implementation begins. |
| `Sistema de escaneo y progresión - Estado actual.md` | Executive summary/current-state diagrams (lines 49-148) | Preserve observed behavior; add a limited historical/legacy note if later wording makes it appear to describe the target architecture. |

## 6. Recommended first functionality and required scope

Implement one scan vertical slice:

1. A Ruby debug-menu action scans a deliberately annotated map through Essentials and atomically publishes a valid `scan-results.json` with findings and diagnostics.
2. A Kotlin/JVM CLI command reads that file as typed objects and prints a concise summary plus diagnostics.

This proves the only new language boundary, preserves `.rxdata` ownership, and establishes the JVM project without migrating catalog utilities or changing gameplay runtime behavior.

### First-slice scope required before implementation

The audit deliberately does not choose the map, event, annotation form, finding family, CLI command, or acceptance data for this slice. The implementation plan must define them before code starts, together with:

- the one authoring scenario to scan;
- the exact `scan-results.json` collections and diagnostics exercised;
- the Gradle Wrapper command and the CLI output to verify;
- explicit exclusions (catalog generation, tutor migration, Desktop/KMP, broad utility migration, and unrelated scanner families);
- observable acceptance checks across Ruby publication and Kotlin consumption.

This is an implementation-planning prerequisite, not a reason to extend the audit into a broad design exercise.

## Non-blocking questions collected
