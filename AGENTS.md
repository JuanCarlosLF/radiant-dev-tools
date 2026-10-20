# Radiant DevTools contributor guidance

## Documentation-first changes

Before changing a feature or domain/model behavior:

1. Read `plans/features.md`.
2. Read the relevant accepted owner document: `plans/Evolución del sistema de escaneo y progresión/contracts.md`, `domain-models.md`, and/or `Guía de implementación.md`.
3. Read the task scope and ODD checkpoint that authorize the change.

Keep one owner for each contract or model. If implementation and an accepted document conflict, report the conflict and stop; do not silently change the contract to fit code. When behavior changes, update the feature status and record concrete implementation and verification evidence separately.

`plans/_temp/` contains historical snapshots, not active authority. Memory is context, not a contract. If a required document or decision is missing, stop and ask for its location rather than inventing it. Do not impose a blanket requirement to reread every plan file for a narrow change.

## Scope and verification

Keep changes limited to the requested repository and work unit. Preserve unrelated parent game-repository changes, but honor an explicitly authorized cross-repository documentation migration or correction when the human task names the parent documentation paths; do not modify unrelated generated/data files or global OpenCode configuration. Follow the task's explicit test/build policy; documentation-only changes require structural readback and link checks rather than fabricated runtime proof.

## Engram memory while migration is pending

Historical Engram memories remain owned by the `radiant-platinum` project. The `radiant-devtools` namespace contains only a bootstrap pointer; do not describe this as a merged or completed migration. See [`plans/memory-migration.md`](plans/memory-migration.md) for the verified backup/restore facts. Search old history explicitly with `engram search <query> --project radiant-platinum` until a supported ownership-preserving transfer exists.
