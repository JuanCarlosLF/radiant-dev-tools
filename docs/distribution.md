# Development distribution

PR1 produces a validated, per-run development artifact for `radiant`. It does not install the tool, modify `PATH`, publish a release, or implement local update behavior.

## CI producer

The visible `CI - Development Distribution` workflow runs tests and `installDist` on pull requests and on pushes to `develop` using Java 24. Trusted `develop` pushes upload the contents of `build/install/radiant` as one artifact named `radiant-dev`; the Gradle ZIP is not uploaded. Pull requests build and validate without publishing a trusted artifact.

The workflow grants only `contents: read`. It derives the version from Gradle project metadata and passes the trusted full commit SHA to the manifest generator.

## Manifest

`manifest.json` is generated inside the install tree after packaging. It records schema version `1`, application `radiant`, the full 40-character commit, project version, required Java major `24`, and every shipped regular file except itself. Inventory paths use `/`, are sorted deterministically, and include byte size plus lowercase SHA-256.

The producer rejects an incomplete distribution, missing `bin/radiant` or `bin/radiant.bat`, missing `lib/*.jar`, invalid commit identity, and reparse points before traversal. Re-running generation does not add the previous manifest to its own inventory.

## Local verification

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/tests/write-distribution-manifest.tests.ps1 -TempRoot 'C:\path\to\existing\temp'
pwsh -NoProfile -File scripts/tests/write-distribution-manifest.tests.ps1 -TempRoot 'C:\path\to\existing\temp'
```

CI omits `-TempRoot` because the workflow runner provides `RUNNER_TEMP`; local execution must supply an existing temporary directory. The second command is used only when `pwsh` is already installed. Installer, stable launcher, updater, authenticated GitHub access, and release/CD behavior are deferred to PR2/PR3.
