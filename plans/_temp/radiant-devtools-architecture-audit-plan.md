# Radiant DevTools architecture audit plan

> [!note] Historical snapshot
> This temporary plan preserves its original questions and design history. The current index is [[../README|the plans index]]; use the proposal, contracts, models, and implementation guide for active decisions.

Status: temporary working plan

## Goal

Verify the current implementation and documentation only far enough to define the minimum Kotlin/JVM and Ruby architecture required for the first useful functionality.

This is a short preparation step, not a general tooling audit or a long-term platform design.

## Decisions already closed

The audit applies these decisions unless repository evidence makes one impossible:

1. **Radiant DevTools** is the umbrella identity for Radiant Platinum development tools.
2. The external application is primarily **Kotlin/JVM**.
3. The CLI is the first client; domain and application logic remain independent from it.
4. Ruby owns integration that requires the initialized Pokémon Essentials environment.
5. Kotlin/JVM does not read `Data/*.rxdata` directly in the initial architecture.
6. The Ruby integration publishes `scan-results.json`; Kotlin consumes it as typed objects.
7. KMP, Compose Desktop and wholesale utility migration are future possibilities, not current scope.

## Scope

The audit covers only the components and documentation directly involved in these two flows:

```text
Data/*.rxdata ──► Ruby scanner ──► scan-results.json ──► Kotlin/JVM
Editable catalogs ───────────────► Kotlin/JVM ──► generated PBS/Ruby
```

Starting points:

- `Plugins/[Z_CUSTOM_008] Radiant Dev Tools/`
- `Plugins/[Z_CUSTOM_007] Move Tutor/`
- the accepted progression, scanner and movement contracts;
- utilities or scripts referenced directly by either flow.

Other `pokemon_tools`, plugins, scripts and future capabilities are excluded unless concrete evidence shows that they duplicate or constrain one of these flows.

The audit does not implement code, migrate utilities, design Desktop/KMP, investigate direct external `.rxdata` reading or perform unrelated cleanup.

## Questions to answer

1. Which existing components directly participate in, duplicate or constrain the two flows?
2. What does each component read, write and require from its execution environment?
3. Which responsibilities belong to Ruby, Kotlin/JVM or a language-independent contract?
4. Which existing documents contradict those boundaries or retain obsolete Ruby-first assumptions?
5. What is the smallest JVM project structure needed for the first functionality?
6. Which decisions, if any, must be approved before implementation begins?

## Work

### 1. Inspect the current flows

Trace only the relevant entry points, inputs, outputs and consumers. Record enough evidence to establish ownership and identify duplication or hidden dependencies.

Stop following a reference once it no longer affects either flow.

### 2. Define the minimum target

Propose:

- the responsibility of the Essentials-side development plugin;
- the boundary and artifact exchange between Ruby and Kotlin/JVM;
- the minimum JVM source structure, without speculative modules;
- the placement and consumer of generated runtime data;
- the first useful functionality that proves the architecture.

Every responsibility must have one owner. Anything not needed by the first functionality remains undesigned.

### 3. Identify documentation changes

List only the exact sections that should be preserved, reworded, revised or removed. Do not edit canonical documentation until the proposed architecture and change list are approved.

### 4. Resolve blockers and continue

Present genuine blocking decisions one at a time. Once the architecture is sufficient to plan the first functionality, stop the audit and prepare the documentation update and implementation plan.

## Deliverable

Produce a single concise working report:

```text
radiant-platinum-docs/plans/_temp/radiant-devtools-architecture-audit.md
```

It contains only:

1. current flow and ownership;
2. conflicts found in code or documentation;
3. proposed minimum Kotlin/JVM and Ruby architecture;
4. blocking decisions;
5. exact documentation changes;
6. recommended first functionality.

Prefer tables and references over narrative repetition. The report should remain short enough to review in one sitting and is not a new source of truth.

## Completion criteria

The audit ends when:

- Ruby and Kotlin/JVM responsibilities are unambiguous for both flows;
- the required artifact boundaries and owners are known;
- the minimum JVM structure is justified by the first functionality;
- blocking decisions and exact documentation changes are identified;
- implementation can be planned without another broad repository investigation.

## Immediate next action

Inspect the two current flows read-only and record their components, inputs, outputs and execution environments in the single audit report.
