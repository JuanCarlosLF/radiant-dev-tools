# Development distribution

PR1 produces a validated, per-run development artifact for `radiant`. PR2 adds a local-only Windows installer and stable launcher; it does not download artifacts, modify `PATH`, publish a release, or implement update behavior.

## CI producer

The visible `CI - Development Distribution` workflow runs tests and `installDist` on pull requests and on pushes to `develop` using Java 24. Trusted `develop` pushes upload the contents of `build/install/radiant` as one artifact named `radiant-dev`; the Gradle ZIP is not uploaded. Pull requests build and validate without publishing a trusted artifact.

The workflow grants only `contents: read`. It derives the version from Gradle project metadata and passes the trusted full commit SHA to the manifest generator.

## Maintained flow diagrams

These diagrams are the compact producer/consumer map for humans and agents. They describe the current files and boundaries; the Windows installer test is manual and is **not** a CI step.

### CI producer

```mermaid
sequenceDiagram
    actor Trigger as GitHub pull_request or push
    participant Workflow as .github/workflows/ci-distribution.yml
    participant Gradle as build.gradle + Gradle wrapper
    participant ManifestTests as scripts/tests/write-distribution-manifest.tests.ps1
    participant Manifest as scripts/write-distribution-manifest.ps1
    participant Tree as build/install/radiant/
    participant Artifact as GitHub artifact radiant-dev

    Trigger->>Workflow: target develop
    Workflow->>ManifestTests: pwsh producer checks
    Workflow->>Gradle: bash ./gradlew --no-daemon clean test installDist
    Gradle-->>Tree: bin/, lib/, generated launchers
    Workflow->>Gradle: read project version
    Gradle-->>Workflow: version metadata
    Workflow->>Manifest: GITHUB_SHA + version + Java 24
    Manifest-->>Tree: manifest.json with inventory hashes
    alt pull_request event
        Workflow-->>Trigger: tests/build validation only; no upload
    else push to develop after merge
        Workflow->>Artifact: upload Tree contents per run
        Artifact-->>Trigger: radiant-dev artifact
    end
```

### Explicit local consumer

```mermaid
sequenceDiagram
    actor User as Human or local agent
    participant Installer as scripts/install-radiant.ps1
    participant Source as extracted DistributionPath
    participant Root as explicit InstallRoot or %LOCALAPPDATA%/Radiant
    participant Stable as installed bin/radiant.cmd
    participant Child as versions/<commit>/bin/radiant.bat
    participant JVM as JVM CLI

    User->>Installer: DistributionPath + independent ExpectedCommitSha
    Installer->>Root: acquire exclusive lock
    Installer->>Source: validate schema, paths, inventory, size/hash, Java, reparse points
    Installer->>Root: stage; revalidate; preserve old active
    Installer->>Root: rename immutable versions/<commit>; atomically replace active.txt
    User->>Stable: invoke from caller CWD with arguments
    Stable->>Root: PowerShell-validate active pointer before CMD interpolation
    Stable->>Child: forward arguments and caller CWD
    Child->>JVM: launch application
    JVM-->>User: output and unchanged child exit code
```

The manifest SHA-256 values provide integrity checks only; they do not authenticate a distribution. The trusted full `ExpectedCommitSha` is supplied independently by the caller. The CI artifact must be manually downloaded and extracted before invoking the installer; no automatic consumer or updater exists in PR2.

## Responsibility map

| Path or actor | Responsibility and communication |
|---|---|
| [`ci-distribution.yml`](../.github/workflows/ci-distribution.yml) | Runs producer tests/builds for pull requests and `develop` pushes; uploads only the merged-`develop` `radiant-dev` artifact. |
| [`build.gradle`](../build.gradle) | Defines the `radiant` application and Java 24 Gradle build consumed by `installDist`. |
| [`write-distribution-manifest.ps1`](../scripts/write-distribution-manifest.ps1) | Receives explicit commit/version/Java inputs and writes `build/install/radiant/manifest.json`. |
| [`write-distribution-manifest.tests.ps1`](../scripts/tests/write-distribution-manifest.tests.ps1) | Exercises producer manifest behavior; currently run by CI. |
| [`install-radiant.ps1`](../scripts/install-radiant.ps1) | Consumes an extracted tree plus trusted SHA, validates and stages it, then activates an immutable version. |
| [`install-radiant.tests.ps1`](../scripts/tests/install-radiant.tests.ps1) | Manual Windows proof for installer, pointer, launcher, rollback, and packaged CLI behavior; CI does not run it. |
| [`radiant.cmd`](../scripts/radiant.cmd) | Stable wrapper copied to the installation `bin`; validates `active.txt` and delegates to the selected generated launcher. |
| `build/install/radiant/bin/`, `lib/`, `manifest.json` | Generated producer output and manifest inventory; not hand-authored source. |
| `radiant-dev` artifact / manual user | Artifact is per-run CI output; a human or agent downloads/extracts it and supplies `ExpectedCommitSha` explicitly. |

Maintenance rule: update this diagram and table in the same change whenever triggers, producer/consumer paths, manifest fields, activation, or launcher flow changes. PR3 must update them when an updater is actually added; no `scripts/update-radiant.ps1` file exists today.

## Manifest

`manifest.json` is generated inside the install tree after packaging. It records schema version `1`, application `radiant`, the full 40-character commit, project version, required Java major `24`, and every shipped regular file except itself. Inventory paths use `/`, are sorted deterministically, and include byte size plus lowercase SHA-256.

The producer rejects an incomplete distribution, missing `bin/radiant` or `bin/radiant.bat`, missing `lib/*.jar`, invalid commit identity, and reparse points before traversal. Re-running generation does not add the previous manifest to its own inventory.

## Local verification

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/tests/write-distribution-manifest.tests.ps1 -TempRoot 'C:\path\to\existing\temp'
pwsh -NoProfile -File scripts/tests/write-distribution-manifest.tests.ps1 -TempRoot 'C:\path\to\existing\temp'
```

CI omits `-TempRoot` because the workflow runner provides `RUNNER_TEMP`; local execution must supply an existing temporary directory. The second command is used only when `pwsh` is already installed.

## Local installation (PR2)

The installer consumes an already extracted distribution and requires the expected full commit SHA from a trusted caller. The manifest is not trusted by itself:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-radiant.ps1 `
  -DistributionPath 'C:\path\to\extracted\radiant' `
  -ExpectedCommitSha '0123456789abcdef0123456789abcdef01234567'
```

The default layout is `%LOCALAPPDATA%\Radiant\versions\<commit>` with `%LOCALAPPDATA%\Radiant\bin\radiant.cmd` as the stable entry point. Use `-InstallRoot` only for a sandbox or explicit deployment root; the installer validates the complete source inventory, stages and revalidates it, and switches a hashed commit pointer atomically. Existing versions are never replaced or deleted, and a failed install preserves the previous active version.

The stable launcher resolves its root from its own location, not the caller's current directory. It validates the pointer, forwards quoted arguments and the caller CWD to the packaged `bin\radiant.bat`, and returns the child exit code. Missing, tampered, unsafe, or incomplete installations fail closed. The installer does not execute commands from the manifest.

To use the launcher manually, add `%LOCALAPPDATA%\Radiant\bin` to the user `PATH` once through the normal Windows environment UI. PR2 documentation does not perform that mutation. A future PR3 updater will handle trusted artifact discovery; authenticated GitHub access, downloads, cleanup, and release/CD behavior remain deferred.

## Installer verification

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/tests/install-radiant.tests.ps1 -TempRoot 'C:\path\to\existing\temp'
```

Tests use only an explicit existing temporary root and never perform a default host installation. They cover malformed metadata, trusted-commit mismatch, inventory/path/hash/size failures, reparse rejection where available, rollback, spaces, argument/CWD/exit-code preservation, and packaged CLI smoke.
