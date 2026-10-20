# Radiant DevTools plans migration — Phases 1–2

## Objective

Move the complete contents of `radiant-platinum-docs/plans/` into `radiant-devtools/plans/` without changing the plan content, while establishing a reviewable ODD record for the documentation migration.

## Problem

Radiant DevTools implementation plans currently live in the documentation vault rather than beside the tool repository. Phase 1 centralizes those plans mechanically so later documentation corrections and canonical references can be reviewed in the repository that owns the implementation.

## Scope and constraints

- **M1:** move exactly the eight authorized source files, preserving relative paths and current bytes.
- Leave the rest of the vault untouched: `.obsidian/`, research, `other/`, and all unrelated files are out of scope.
- Preserve existing Spanish plans verbatim; do not translate or rewrite incoming content.
- Keep the pre-existing destination `plans/scan-result-reader-tests.md` unchanged.
- No code, feature, `AGENTS.md`, README, link, or gate correction in Phase 1.
- No tests, builds, temporary harnesses, commits, staging, pushes, branches, or native review in this phase.
- Parent owns Git delivery and any later Engram/native migration work.

## Stable IDs and route

- **M1 — Byte-preserving eight-file move:** import the complete authorized plans slice unchanged.
- **M2 — Features and documentation corrections:** later update feature documentation, canonical `AGENTS` references, and related corrections only after M1 review.
- **M3 — Engram migration:** later perform a supported backup/native migration, or record an honest blocker; no memory ownership/configuration migration is authorized here.
- **M4 — Delivery:** later create atomic work-unit commits, push the GitHub PR, and handle GitLab removal delivery under the parent-owned workflow.
- **Route:** delegated because the authorized change spans multiple files; this phase remains one-writer and has no subtasks.
- **Strategy:** `ask-on-risk`; the mechanical line forecast is 2,205 existing lines moved. Authored tracking content and later guidance updates are forecast separately.
- **Phase 2 route:** direct one-writer documentation work; no code, Kotlin, Ruby, test, build, or harness changes.

## Checks and evidence

- Read all eight complete source files before the move.
- Record normalized Git blob hashes and raw `--no-filters` hashes before deletion and after import.
- Verify every destination file is readable and complete, every source file is absent, and the pre-existing destination plan is unchanged.
- Record any line-ending normalization explicitly; do not claim byte identity when raw hashes differ.
- **Code-fix conditional: NOT MET.** The current Ruby producer only emits `items` and leaves `tutor_stations` empty; its legacy tutor API is `pbMoveTutorScreen(tier)` with integer tiers, not a future `TutorFinding` producer. No Kotlin or Ruby change is authorized here; the user conditional fix is not triggered. The tier-to-`TutorFinding` alignment remains a genuine future migration, and no nonempty Ruby tutor behavior is claimed as validated.

## M1 status and evidence

- State: M1 mechanically complete and committed in the destination as `3174ae64a54bb6165076d07a98e02e3daaf07e0e` (`3174ae6`). The parent reviewed boundary is that commit; the passive native assessment over `0e9bb88..3174ae6` is not an approval receipt.
- Source inventory: eight files, 2,205 existing lines in total (actual count matches forecast).
- All eight source paths are absent after the move. All eight destination paths were read completely after the move.
- Normalized Git blob hashes and raw `--no-filters` hashes matched before and after for every file; no raw line-ending normalization occurred.

| Source-relative path | Destination-relative path | Lines | Git blob / raw hash before = after |
|---|---|---:|---|
| `_temp/radiant-devtools-architecture-audit.md` | `plans/_temp/radiant-devtools-architecture-audit.md` | 139 | `9db97af9db3837a18597ec7cc7a3a82b7c86a200` |
| `_temp/radiant-devtools-architecture-audit-plan.md` | `plans/_temp/radiant-devtools-architecture-audit-plan.md` | 111 | `4bd4089bf5188b04b09f7324b725e4bf2170ce5c` |
| `Evolución del sistema de escaneo y progresión/Evolución del sistema de escaneo y progresión.md` | `plans/Evolución del sistema de escaneo y progresión/Evolución del sistema de escaneo y progresión.md` | 104 | `783086a5c028ae357b75bff348da351de921d3c7` |
| `Evolución del sistema de escaneo y progresión/Guía de implementación.md` | `plans/Evolución del sistema de escaneo y progresión/Guía de implementación.md` | 187 | `162fbb56676b6179430269e4e2ae9ece07c9f284` |
| `Evolución del sistema de escaneo y progresión/domain-models.md` | `plans/Evolución del sistema de escaneo y progresión/domain-models.md` | 338 | `b5b15f24b5fa5fa849b45aaa8c6c93af675aa4ee` |
| `Evolución del sistema de escaneo y progresión/contracts.md` | `plans/Evolución del sistema de escaneo y progresión/contracts.md` | 672 | `9be02af42378c829bfc6863c87179faeaabe94bb` |
| `Evolución del sistema de escaneo y progresión/odd/scanner-progresion.md` | `plans/Evolución del sistema de escaneo y progresión/odd/scanner-progresion.md` | 216 | `a556e094de452b4497cf242ffe6c5d5a81991f35` |
| `Evolución del sistema de escaneo y progresión/odd/plans/ruby-producer-plan.md` | `plans/Evolución del sistema de escaneo y progresión/odd/plans/ruby-producer-plan.md` | 438 | `a26a743bfde525e72aa7de00423ef297f243a881` |

- Pre-existing `plans/scan-result-reader-tests.md` remains unchanged.
- At the M1 boundary, the exact change outside the byte-preserving plans move was this tracking document only; Phase 2 changes are listed in the manifest below.

## M2 scope and evidence

- Scope: add the canonical `plans/README.md` index and `plans/features.md` status catalog; add destination and root `AGENTS.md`; correct stale gates, historical labels, locators, cross-repository research link, detector diagnostic wording, tutor gap documentation, and latest ODD status. Phase 2's exact file manifest is the two AGENTS files, `plans/README.md`, `plans/features.md`, this task file, and the seven tracked plan documents listed below.
- Checks: read back every new/modified document, verify links against the canonical files and actual code paths, run `git diff --check` in both repositories, and report unrelated pre-existing warnings separately.
- Exclusions: no changes to Kotlin/Ruby/tests/builds, no changes to local Git excludes or `.gitignore`, no research move, no publication of the untracked reader-test plan, and no claim of recent automated CLI tests.
- Forecast: approximately 200–350 authored lines beyond the mechanical M1 import; final count is reported from the diff.

### Phase 2 file manifest

- Created: parent `AGENTS.md`; nested `radiant-devtools/AGENTS.md`; `radiant-devtools/plans/README.md`; `radiant-devtools/plans/features.md`; `radiant-devtools/odd/tasks/devtools-plans-migration.md`.
- Modified: seven tracked plan documents — the proposal, implementation guide, contracts, Ruby producer plan, scanner ODD, and the two `plans/_temp/` audit snapshots.
- Preserved: `plans/scan-result-reader-tests.md` remains unchanged and excluded from publication.
- The Phase 2 correction also records that commits `b4884a7` and `e1f18891` are source-game GitLab commits, not commits in this GitHub repository.

## M3 and M4 status

- **M3 — Engram migration:** partial/blocked. M1 remains verified as committed in `3174ae6`; M2 is complete in the working tree and remains pending Git delivery. A source export and isolated restore were verified with `327` observations, `9` sessions, and `216` prompts. The target `radiant-devtools` namespace was created and bootstrap memory `#839` records a pointer only. No supported generic ownership-preserving transfer exists in the installed public CLI, so the `radiant-platinum` history remains untouched and no merge is claimed. See [`plans/memory-migration.md`](../../plans/memory-migration.md).
- **M4 — delivery:** pending. Parent owns staging, commits, GitHub PR publication, source removal delivery, and any later GitLab URL update.

## Next step

Hand off the uncommitted Phase 2 documentation changes to the parent for delivery. M3 and M4 remain pending.
