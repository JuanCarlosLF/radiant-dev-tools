# Ruby Producer Plan — Scanner Slice 1

> [!note] Working plan, English, first person
> Parent tracking document: [[scanner-progresion]] (§7 T4-K0, T4-R0–T4-R3, §10). This file holds the reviewable detail; the ODD holds the checklist and evidence. Repo-relative locator: `radiant-platinum-docs/plans/Evolución del sistema de escaneo y progresión/odd/plans/ruby-producer-plan.md`.

## Review status

| Checkpoint                                  | State          | Commit    |
| ------------------------------------------- | -------------- | --------- |
| T4-K0 — Materialize the progression catalog | complete       | `b4884a7` |
| T4-R0 — Isolate legacy code | approved (moves + in-game check) | `c5d5a9d2` |
| T4-R1 — Reusable map access and traversal | approved by user | `5c1d2a1` |
| T4-R2 — Annotations and first item detector | approved by user | — |
| T4-R2a — Extend item delivery detection | approved by user/runtime verified | `e1f18891` (`feat(scanner): publish verified scan artifacts (T4-R3)`) |
| T4-R3 — Coordinate and publish the result   | approved by user/runtime verified | `e1f18891` (`feat(scanner): publish verified scan artifacts (T4-R3)`) |

## Outcome

I will build the smallest Ruby pipeline that scans the deliberately annotated map 002 and publishes a valid `radiant-devtools/artifacts/scan-results.json`.

I will implement and review the work in five independent checkpoints:

1. **T4-K0:** materialize and validate the progression catalog.
2. **T4-R0:** isolate legacy code.
3. **T4-R1:** build reusable map access and traversal.
4. **T4-R2:** parse annotations and detect `pbReceiveItem` and `pbItemBall`.
5. **T4-R3:** coordinate the scan and publish the JSON atomically.

I will stop after every checkpoint so its structure, behavior, comments, and diff can be reviewed before I continue.

I will not start the Kotlin adapter until T4-R3 produces a real artifact.

## Architecture

```text
Debug menu (:radiant_scan_slice1)
    ↓
ScannerCoordinator
    ├── Maps (001_Maps)
    ├── Scanner domain (002_Scanner)
    └── Infrastructure (003_Infrastructure)
```

I will namespace all new constants, mirroring the folder structure:

```ruby
RadiantDevTools::Maps::MapRepository
RadiantDevTools::Maps::MapWalker
RadiantDevTools::Maps::PageContext

RadiantDevTools::Scanner::AnnotationParser
RadiantDevTools::Scanner::AnnotationValidator
RadiantDevTools::Scanner::ItemDetector
RadiantDevTools::Scanner::Source
RadiantDevTools::Scanner::Diagnostic
RadiantDevTools::Scanner::ItemFinding
RadiantDevTools::Scanner::ScannerCoordinator

RadiantDevTools::Infrastructure::AtomicJsonWriter
RadiantDevTools::Integration::Scanner::ScannerDebugMenu
```

This namespace, rather than English naming alone, protects the plugin from collisions with Essentials and other plugins. I will keep a generally applicable capability at its root. I will nest only scanner-specific code below `scanner/` inside a technical capability, such as `Integration/scanner/`. If a second feature needs a scanner-specific implementation, I will promote only the genuinely shared part instead of duplicating it.

## Proposed plugin structure

```text
Plugins/[Z_CUSTOM_008] Radiant Dev Tools/
├── legacy/
│   ├── 001_Dynamic_tms.rb
│   ├── 002_Item_ubication_scanner.rb
│   └── 003_Spiritomb_souls_scanner.rb
│
├── 001_Maps/
│   ├── 001_MapRepository.rb
│   ├── 002_PageContext.rb
│   └── 003_MapWalker.rb
│
├── 002_Scanner/
│   ├── 001_Annotations/
│   │   ├── 001_ParsedAnnotation.rb
│   │   ├── 002_AnnotationParser.rb
│   │   └── 003_AnnotationValidator.rb
│   ├── 002_Results/
│   │   ├── 001_Source.rb
│   │   ├── 002_Diagnostic.rb
│   │   └── 003_ItemFinding.rb
│   ├── 003_Detectors/
│   │   └── 001_ItemDetector.rb
│   └── 004_ScannerCoordinator.rb
│
├── 003_Infrastructure/
│   └── 001_AtomicJsonWriter.rb
│
└── 004_Integration/
    └── scanner/
        └── 001_ScannerDebugMenu.rb
```

I will keep the map package outside the scanner package because map access and traversal can support other development tools later.

Numbering is sequential (`001`, `002`, …), following the convention already used by the legacy plugin files and MakerStudio. It exists to fix plugin load order: `001_Maps` must load before anything referencing it. I will not use tens (`010`, `020`); inserting a future folder is a rare rename, while matching the repo convention pays off daily.

## T4-K0: Materialize the progression catalog

### Purpose

I will materialize the approved progression catalog as the first Kotlin-repository dependency before Ruby annotation validation. The file remains versioned source, not a generated artifact.

### Exact file

```text
radiant-devtools/catalogs/progression.json
```

### Validation invariants

I will verify that the JSON parses and that it contains exactly the approved catalog shape: root keys `schema_version`, `stages`, and `capabilities`; schema version `1`; 19 ordered stages; 3 unique stage IDs; 3 unique capability IDs; every unlock references a declared capability; each capability is unlocked exactly once; and the exact assignments are `rock_smash` → `stg_c4h1` (stage 3), `cut` → `stg_f7n2` (stage 6), and `bike` → `stg_f7n2` (stage 6). No deferred capability is included.

### Out of scope

I will not add a JSON Schema, a general catalog framework, the Kotlin adapter/application/CLI, Ruby map or scanner code, a Ruby runtime loading boundary, or a new Kotlin test class.

### Rollback

I can remove `radiant-devtools/catalogs/progression.json` and the T4-K0 tracking entries without affecting the existing Kotlin contract skeleton or the planned Ruby checkpoints.

### Review gate

The implementation and checks are complete. The catalog is committed as `b4884a7`. T4-R0 remains the next Ruby checkpoint.

## Comment policy

I will use comments where they explain:

- the general purpose of a file;
- what the component owns;
- what it deliberately does not own;
- relationships with adjacent components;
- RPG Maker-specific behavior;
- invariants and failure policies.

I will not comment obvious accessors, assignments, or ordinary loops.

Every new Ruby file will start with the compact boxed header style already used by MakerStudio and the existing Radiant DevTools files. I will use dashed dividers only for substantial internal sections.

```ruby
#===============================================================================
# RPG Maker map access for Radiant DevTools.
# Loads map metadata and map files without walking events or interpreting content.
#===============================================================================
```

## T4-R0: Isolate legacy code

### Purpose

I will move the existing files into `legacy/` without modifying their contents.

### Files

```text
001_Dynamic_tms.rb
    → legacy/001_Dynamic_tms.rb

002_Item_ubication_scanner.rb
    → legacy/002_Item_ubication_scanner.rb

003_Spiritomb_souls_scanner.rb
    → legacy/003_Spiritomb_souls_scanner.rb
```

### Implementation

1. I will create `legacy/`.
2. I will move the three files unchanged.
3. I will not translate identifiers or add headers inside the moved files.
4. I will verify that the plugin still loads nested Ruby files.
5. I will verify that the two existing debug entries remain registered (`:radar_radiant_completo`, `:radar_radiant_almas`).

### Important removal condition

I will not delete `legacy/` merely because the new scanner works.

`001_Dynamic_tms.rb` also contains runtime behavior related to saves, item handling, and `pbPokemonMart`. The folder can only be removed after every remaining responsibility has a verified replacement.

### Verification

- Git recognizes the changes as pure renames.
- The old debug entries still appear.
- Existing legacy behavior remains unchanged.
- No new scanner entry exists yet.
- No new JSON artifact is produced.

### Rollback

I can move the three files back to the plugin root without reverting unrelated work.

### Commit

```text
chore(devtools): isolate legacy plugin code
```

### Review gate

I will stop after this commit so the move-only diff and runtime loading can be reviewed.

## T4-R1: Reusable map access and traversal

### Purpose

I will expose RPG Maker map data through a reusable boundary and normalize every event page into a `PageContext`.

### Components

#### `MapRepository`

I will make `MapRepository` the only component that knows how to access:

- `Data/MapInfos.rxdata`;
- `Data/MapNNN.rxdata`;
- map names and references;
- file metadata required by future cache behavior.

It will not walk events, interpret commands, parse annotations, run detectors, or write JSON.

I retain the name `MapRepository` because it hides map persistence details behind a stable boundary. It behaves like a repository in Clean Architecture, even though its data source is `.rxdata` rather than a database.

#### `MapWalker`

I will make `MapWalker` receive an already loaded map and visit events ordered by `event_id`, pages in their original order, and commands in their original order. It will reconstruct RPG Maker multiline commands (`108 + 408` → one logical comment block, `355 + 655` → one logical script block).

#### `PageContext`

I will make `PageContext` a temporary value holding normalized page data: map/event identity and coordinates, zero-based page index, normalized comment and script blocks, and original command indexes. It holds data; it does not load files, parse annotations, detect content, or write results.

### Headers

Example for `MapWalker`:

```ruby
#===============================================================================
# Walks one loaded RPG Maker map and yields one normalized PageContext per page.
# Preserves source order and rebuilds multiline comments and scripts.
# Does not load map files, parse annotations, or create scanner findings.
#===============================================================================
```

I will comment the `108/408` and `355/655` grouping because those command codes are not self-explanatory.

### Verification

- Map 002 loads with its real map name; references are deterministic.
- An indexed but unreadable map fails explicitly.
- Every event page produces one context; order is preserved.
- Multiline comments and scripts are grouped correctly; indexes remain zero-based.
- No JSON is written; no annotations are interpreted.

The automated Ruby test runner remains unresolved. I will not invent a command or claim TDD evidence. Until it is identified, I will use structural inspection and a bounded in-game map inspection.

### Out of scope

Annotations, findings, diagnostics, caches, JSON publication, scanner-specific behavior.

### Rollback

I can remove `001_Maps/` without affecting legacy behavior.

### Commit

```text
feat(devtools): add reusable map traversal
```

### Review gate

I will stop so the map API, ownership boundaries, headers, and normalized output can be reviewed.

## T4-R2: Annotations and first item detector

### Precondition

The approved progression catalog has been materialized at `radiant-devtools/catalogs/progression.json`. Ruby still needs an approved runtime loading and validated-representation boundary before annotation validation is implemented. I will not hardcode stage or capability IDs or recreate the complete progression domain in Ruby.

### Annotation pipeline

```text
PageContext → AnnotationParser → ParsedAnnotation → AnnotationValidator → ItemDetector
```

### Supported annotations

Only `#addToRadar`, `#stage:<stage_id>`, `#requires:<capability>`, accepted free tags, and remaining note text.

### Detector scope

I will recognize `pbReceiveItem` and `pbItemBall`. Both use the same supported static subset: a symbol item ID and an optional numeric quantity, defaulting to `1`. The optional third `outfit_change` argument on `pbItemBall` is irrelevant to finding identity. A valid finding contains `item_id`, `quantity` (defaulting to `1`), `stage_id`, `requires`, `source`, `tags`, and `notes`.

### Diagnostics

- `missing_stage` warning when `#addToRadar` has no stage (no finding);
- `unregistered_content` warning when `pbReceiveItem` or `pbItemBall` has no `#addToRadar` (no finding);
- error when a declared stage or required capability does not exist;
- error when annotated content is not recognized by the available detector.

### Headers

Example for `ItemDetector`:

```ruby
#===============================================================================
# Recognizes annotated pbReceiveItem and pbItemBall deliveries and produces ItemFinding values.
# Receives prepared page data and validated annotations.
# Does not load maps, resolve progression availability, or write JSON.
#===============================================================================
```

### Verification

Using the three deliberately prepared pages in map 002: valid annotation → one finding; missing stage → `missing_stage` and no finding; unannotated `pbReceiveItem` or `pbItemBall` → `unregistered_content`; warnings alone do not imply failure; unknown stages produce errors; source data points to the real map, event, page, command, and coordinates. No JSON is written yet.

## T4-R2a: Extend item delivery detection

### Scope

I will extend the existing `ItemDetector` static pattern to claim `pbItemBall` alongside `pbReceiveItem`. It will preserve the symbol item ID and optional numeric quantity captures, default quantity to `1`, and keep the exact logical script block as the `Source#command`. The optional third outfit argument is ignored because it does not affect finding identity.

### Verification

The temporary regression will verify annotated `pbItemBall` with an explicit quantity, annotated `pbItemBall` with the default quantity, unchanged `pbReceiveItem` behavior, and unannotated `pbItemBall` producing no records plus an `unregistered_content` warning. Ruby syntax checks and existing parser/coordinator provenance regressions remain green.

### Review gate

Approved by user and runtime verified from the real `radiant-devtools/artifacts/scan-results.json`; recorded in commit `e1f18891` (`feat(scanner): publish verified scan artifacts (T4-R3)`).

### Explicitly deferred

Generic `Finding` superclass, detector registry, `SoulFinding`, tutor/machine models, `ResolvedAvailability`, `dar_mt`, `pbPokemonMart`, cache behavior.

### Rollback

I can remove the annotation, result, and item-detector files while preserving T4-R0 and T4-R1.

### Commit

```text
feat(scanner): detect annotated item deliveries
```

### Review gate

I will stop so annotation semantics, warning/error behavior, names, comments, and the three map scenarios can be reviewed.

## T4-R3: Coordinate and publish the result

### `ScannerCoordinator`

I will make the coordinator receive a list of `map_id`s from its integration, then own map loading and traversal, annotation parsing and validation, detector invocation, accumulation of findings and diagnostics, and final `success`/`failed` status. The slice-1 debug action supplies `[002]`; a later full scan supplies every map without touching the coordinator. The coordinator requests references from `MapRepository` and filters them to the requested ids, so enumeration stays covered even for a single map. It will not write files directly.

### Minimal result shape

Exactly `schema_version`, `status`, `items`, `souls`, `tutor_stations`, `diagnostics`: these six fields are all root fields permitted and required by `scan-results.json` schema version 1, not a temporary subset. In this slice, only `items` can have content; `souls` and `tutor_stations` must still be present as empty arrays. I will implement only `ItemFinding`, `Diagnostic`, and `Source` in Ruby and publish those empty arrays without implementing their Ruby models.

### `AtomicJsonWriter`

Serialize the entire result, write a temporary file in the destination directory, replace the destination only after successful serialization and writing, and preserve the previous artifact on failure. The writer will not decide scan status or reinterpret diagnostics.

### Debug interface

New key `:radiant_scan_slice1` calling only namespaced new code (`RadiantDevTools::Scanner::ScannerCoordinator`). It will not call `pbEscanearMapasGlobal` or `pbEscanearAlmas`.

### Headers

```ruby
#===============================================================================
# Coordinates the scanner pipeline from map selection to an in-memory result.
# Owns diagnostic aggregation and final status without publishing files.
#===============================================================================
```

```ruby
#===============================================================================
# Publishes a complete scan result through same-directory temporary replacement.
# Preserves the previous artifact when serialization or replacement fails.
# Does not decide scan status or interpret diagnostics.
#===============================================================================
```

```ruby
#===============================================================================
# Exposes scanner slice 1 through a dedicated debug-menu action.
# Calls only the new namespaced pipeline and remains independent from legacy actions.
#===============================================================================
```

### Verification

New debug action appears alongside legacy actions without referencing legacy methods. Map 002 produces one valid item finding plus both expected warnings with `status: "success"`; errors produce `status: "failed"`. Root contains exactly six keys; `souls` and `tutor_stations` are empty. Repeated scans use deterministic ordering. Writer failure preserves the previous artifact. No PBS or game data is modified; no legacy `pokemon_tools` output is modified. Output lands at `radiant-devtools/artifacts/scan-results.json`.

### Rollback

I can remove the coordinator, writer, and debug integration while retaining all independently reviewed lower-level components.

### Commit

```text
feat(scanner): publish scan results from debug menu
```

### Review gate

The real artifact was observed and accepted by the user/runtime: `schema_version: 1`, `status: "success"`, two item findings, expected warnings only, and empty `souls`/`tutor_stations`. Recorded in commit `e1f18891` (`feat(scanner): publish verified scan artifacts (T4-R3)`). Kotlin T5 begins against this real artifact.

## Deferred work

Scanner cache, full-map scans, `SoulFinding`, tutor and machine models, additional item delivery forms, availability resolution, PBS writes, legacy deletion, generalized detector registration, Kotlin adapter, application, and CLI.

## Review sequence

```text
1. Review the proposed API and file placement.
2. Implement only that checkpoint.
3. Run its applicable checks.
4. Review the diff, headers, behavior, and evidence.
5. Commit the accepted work unit.
6. Update the ODD document and Engram mirror.
7. Continue only after approval.
```

## Open implementation questions

- Ruby-side source for the validated stage/capability lookup: injected minimal data, the published progression catalog, or another approved representation.
- Exact plugin loader behavior for nested subfolders (to confirm in T4-R0).
- Which `pbReceiveItem` argument forms are required now: symbols only, strings, quantities, or supported dynamic expressions.
- Whether the atomic writer creates `radiant-devtools/artifacts/` or reports a controlled failure when the directory is absent.
- The repository's Ruby automated test runner and exact command (until then: structural and observable in-game checks only).
- Whether `scan_result.rb` stays a separate object or folds into the coordinator.
