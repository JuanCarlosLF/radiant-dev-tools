# Engram memory migration status

**Outcome:** preparation is complete, but the historical memories were **not merged** into `radiant-devtools`.

## Verified snapshot

- Engram CLI: `2.0.0` (the CLI reported an available `3.4.0` update; no upgrade was performed).
- Source project: `radiant-platinum` — `327` observations, `9` sessions, and `216` prompts at export time.
- Backup: `engram-radiant-platinum-migration-20261020-103201012.json`.
- Backup Git object hash (`git hash-object --no-filters`): `e013758da0c3917e24348e19e31b5ef9d5c55809`.
- Restore verification: a fresh isolated `ENGRAM_DATA_DIR` imported `327` observations, `9` sessions, and `216` prompts; `engram stats` and `engram projects list` reported only `radiant-platinum`.

The backup is retained outside the repository. Its full local path is intentionally not recorded here.
The source store may grow after the snapshot; the snapshot counts are not a live-equality claim.

## Target namespace

- `radiant-devtools/.engram/config.json` now declares `project_name: radiant-devtools`.
- Target bootstrap memory: `#839`, `Memory migration status` (`discovery`).
- Target stats after bootstrap: `1` observation, `1` session, and `0` prompts.
- The bootstrap is only a pointer to the source history and canonical plans (`plans/README.md`, `plans/features.md`); it is not a copy or ownership transfer.

## Blocker and safe procedure

Engram `2.0.0` exposes backup/export and restore/import, but no supported generic cross-project transfer for unrelated project names. The public rescue path is for unowned observations, and the deprecated HTTP `migrate` alias has the same rescue purpose; neither authorizes reassignment of the owned `radiant-platinum` history. Therefore M3 is **partial/blocked**, not migrated.

Source history remains in `radiant-platinum`, with its ownership and cloud sync state untouched. The verified backup and isolated restore provide recovery, not unified history. The checked CLI did not expose a reliable relation or pin count, so those metrics remain unknown rather than inferred.

For future sessions started in `radiant-devtools`, use the repository config and explicit project filters. While the current MCP process remains attached to the parent root, recover old history explicitly:

```text
engram search <query> --project radiant-platinum
```

Use a future Engram release only if it documents and supports a generic, ownership-preserving transfer; otherwise keep this backup/restore procedure and the explicit cross-project pointer.
