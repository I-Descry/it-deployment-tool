# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

This is a single-machine interactive PowerShell deployment tool used by IT technicians to install applications and configure new Windows devices.

* Plain `.ps1` files only.
* No build system, package manager, CI pipeline, or compiled output.
* `Start.ps1` is the entry point.
* Modules are dot-sourced explicitly from `Start.ps1`.
* Application definitions live in `Config\Applications.json`.
* Offline installer binaries live under `Installers\` and are gitignored.

## Non-negotiables

1. Never log, print, commit, or persist secrets, credentials, CrowdStrike CID/token values, account passwords, or Office product keys.
2. Validation, availability, readiness, and detection functions must remain read-only.
3. `Config\Applications.json` is the source of truth for application configuration. Do not duplicate catalog data in PowerShell modules.
4. New installation types must be added to both dispatch switches in `InstallationRouter.ps1`.
5. New module files must be explicitly added to `$ModulePaths` in `Start.ps1` in dependency order.
6. Do not add dependencies, frameworks, abstractions, or configuration layers unless the requested change requires them.
7. Do not refactor unrelated code while implementing a focused change.
8. Do not leave TODOs, stubs, fake success results, debug code, or placeholder implementations and present the work as complete.
9. Do not bump `$AppVersion` unless explicitly instructed.
10. Preserve existing behavior and configuration compatibility unless the requested change explicitly requires a breaking change.

## Commands

Run normally:

```powershell
.\Start.ps1
```

Read-only startup validation:

```powershell
.\Start.ps1 -ValidateOnly
```

`-ValidateOnly`:

* does not request elevation;
* does not open the main menu;
* loads all configured modules;
* verifies required functions;
* verifies `Config\Applications.json`;
* exits with code `0` or `1`.

Run it after changes involving:

* module loading;
* module paths;
* public function names;
* public function signatures;
* startup dependencies.

There is no automated test framework or linter configuration.

`TESTING.md` is the manual acceptance checklist. Update the relevant section when behavior changes. Hardware-dependent tests may intentionally remain unchecked until tested on an authorized Windows device.

## Working rules

Before modifying code:

1. Read the relevant module.
2. Read neighboring modules that perform similar work.
3. Search for existing helpers before creating a new one.
4. Follow the repository's existing naming, logging, error handling, parameter, and return-value conventions.

Prefer the smallest change that correctly implements the request.

Do not create a new abstraction for logic used in only one place unless doing so materially improves correctness or maintainability.

Comments should explain non-obvious reasons, Windows behavior, compatibility requirements, or workarounds. Do not add comments that simply narrate the code.

Use only PowerShell commands, .NET APIs, functions, registry paths, exit codes, and application behavior that are known from the repository or can be verified. Do not invent commands, parameters, identifiers, or package behavior.

## Architecture

### Module loading

`Start.ps1` loads modules through the explicit `$ModulePaths` array.

Loading order represents dependencies.

Examples:

* `Core\Logging.ps1` must load before modules that log.
* `Installation\InstallationResult.ps1` must load before installer modules using result normalization.
* Individual installer modules must load before `InstallationRouter.ps1`.

There is no dynamic module discovery.

A `.ps1` file placed under `Modules\` is not available unless it is listed in `$ModulePaths`.

When adding a module:

1. Put it under the appropriate `Modules\<Category>\` directory.
2. Add it to `$ModulePaths` at the correct dependency position.
3. Add important new public entry points to `$RequiredFunctions` when startup validation should require them.

### Installation routing

Application installation is dispatched by:

`Modules\Installation\InstallationRouter.ps1`

Applications define an `InstallType`, such as:

* `Winget`
* `Exe`
* `MSI`
* `ZIP`
* `CrowdStrike`
* `OfficeISO`
* `Office2021IMG`
* `Teams`

The router contains two parallel dispatch paths:

`Test-ApplicationInstallerAvailable`

* read-only;
* verifies that the required installer/package is available and usable.

`Install-ApplicationByType`

* performs the actual installation;
* delegates to the appropriate installer module.

When adding an installation type:

1. Create its installer module under `Modules\Installation\`.
2. Implement an availability check.
3. Implement the installation function.
4. Add the type to `Test-ApplicationInstallerAvailable`.
5. Add the type to `Install-ApplicationByType`.
6. Add the module to `$ModulePaths`.
7. Run `.\Start.ps1 -ValidateOnly`.

Never make an availability check install, download, modify, or configure anything.

### Installation results

Result normalization is handled by:

`Modules\Installation\InstallationResult.ps1`

Primary functions:

* `New-ApplicationInstallationResult`
* `ConvertTo-ApplicationInstallationResult`

Installer modules may return:

* a raw `[bool]`; or
* an object containing `{ Status, Message }`.

Installer results are normalized to:

* `Installed`
* `Skipped`
* `Failed`

`InstallationQueue.ps1` may assign two additional states before invoking an installer:

* `Blocked` — a configured blocking process is running.
* `Not Found` — the required installer package is unavailable.

Do not introduce new installation result states without updating all consumers, summaries, and logging that depend on them.

Do not bypass result normalization.

### Application configuration

`Config\Applications.json` is the application catalog and source of truth.

Common fields include:

* `Name`
* `DetectionName`
* `InstallType`
* `Winget`
* `InstallerPath`
* `SilentArguments`
* `SuccessExitCodes`
* `RebootExitCodes`
* `Category`
* `Description`
* `Recommended`
* `RequiredForIssuance`
* `WingetScope`
* `BlockingProcesses`

`RequiredForIssuance` defaults to `false`.

`DeploymentValidation.ps1` uses it for the generic required-application check.

CrowdStrike and Office use dedicated validation and are excluded from the generic required-application check.

Do not hard-code configuration in installer modules when it belongs in `Applications.json`.

Preserve compatibility with existing entries when adding optional configuration fields.

### Installer storage

Offline packages are stored under `Installers\` by primary type:

```text
Installers\
├── EXE\
├── MSI\
├── ISO\
├── IMG\
├── ZIP\
└── Scripts\
```

Applications requiring multiple files should keep them together in an application-specific subdirectory.

Example:

```text
Installers\EXE\SAP\
```

Installer binaries are gitignored:

```text
Installers/*
```

except tracked directory placeholders such as `.gitkeep`.

`Modules\Installation\InstallerDirectories.ps1` provides:

`Initialize-InstallerDirectories`

Normal startup recreates missing installer directories without modifying existing files.

`-ValidateOnly` must not create them.

Package readiness is handled by:

`Modules\Validation\InstallerPackageReadiness.ps1`

It provides a read-only `READY` / `MISSING` report for configured offline packages.

### Logging

Logging is centralized in:

`Modules\Core\Logging.ps1`

Use only:

* `Initialize-DeploymentLog`
* `Write-DeploymentLog`
* `Complete-DeploymentLog`

Session logs are written to:

```text
Logs\Deployment_<ComputerName>_<timestamp>.log
```

Use `Write-DeploymentLog` instead of writing directly to log files.

Supported levels:

* `INFO`
* `SUCCESS`
* `WARNING`
* `ERROR`

Console output and persistent logging are separate concerns. Do not replace repository logging with `Write-Host`.

### Secrets

Never expose secrets through:

* deployment logs;
* console output;
* error messages;
* tracked configuration;
* committed files.

Sensitive values include, but are not limited to:

* CrowdStrike Customer ID;
* CrowdStrike installation token;
* account passwords;
* Office product keys.

CrowdStrike credentials may exist in:

```text
Installers\EXE\CrowdStrike\Readme.txt
```

This file is gitignored and may contain real credentials.

Read sensitive values only where required and keep them in memory only as long as necessary.

Never include their values in diagnostic output.

## PowerShell behavior

For new functions, follow existing repository naming and parameter conventions.

Prefer PowerShell `Verb-Noun` naming for new public functions.

Use explicit parameters and named arguments where positional calls would be unclear.

Check existing helpers before duplicating:

* path handling;
* installed-application detection;
* process checks;
* logging;
* result conversion;
* installer execution.

Construct repository-relative paths from the tool/repository root where appropriate. Do not introduce machine-specific absolute paths.

When executing external installers:

* capture the process exit code;
* evaluate configured `SuccessExitCodes`;
* evaluate configured `RebootExitCodes`;
* do not assume only exit code `0` means success.

Do not silently swallow exceptions.

Either:

* handle the failure meaningfully;
* log it safely and return the expected result; or
* allow it to propagate to the layer responsible for handling it.

Never include secrets when logging exception context.

## Versioning

`$AppVersion` is defined in `Start.ps1`.

Development versions follow:

```text
X.Y.Z-dev
```

A version becomes:

```text
X.Y.Z
```

only after every applicable item for that version in `TESTING.md` has been validated on authorized hardware.

Do not change the version as part of an unrelated code change.

Do not remove the `-dev` suffix unless explicitly instructed.

## Completion check

Before considering a change complete:

* Confirm the requested behavior is fully implemented.
* Confirm unrelated behavior was not intentionally changed.
* Confirm configuration remains backward-compatible where required.
* Confirm validation/check functions remain read-only.
* Confirm installer results use the existing normalization path.
* Confirm no secrets can enter logs or console output.
* Confirm no debug output, placeholders, TODOs, or dead code were introduced.
* Confirm new modules are present in `$ModulePaths`.
* Confirm new install types are handled by both router paths.
* Run `.\Start.ps1 -ValidateOnly` when module loading or public function contracts changed.
* Update the relevant `TESTING.md` section when observable behavior changed.
* Do not modify `$AppVersion` unless explicitly instructed.
