# IT Deployment Tool Testing

## Current Test Version

`1.1.0-dev`

The development version must remain unchanged until all required acceptance tests pass on an authorized clean Windows device.

---

## Current Testing Limitation

Local, non-destructive testing is complete.

The remaining acceptance tests require an authorized clean Windows test device. These tests are currently pending because no suitable test device is available.

Pending real-device tests include:

- Fresh WinGet application installation
- SAP GUI 7.70 installation (8.00 verified on a real device 2026-08-13)
- CrowdStrike installation
- WinGet, EXE, MSI, and AppX application uninstallation
- Microsoft Office 2024 installation
- Microsoft Office 2021 LOP installation
- Computer rename
- Local standard user creation and group verification
- Actual power and sleep configuration changes
- `Start.ps1 -Gui` elevation flow (single UAC prompt, elevated relaunch opens the GUI, not a console)
- GUI-based install/uninstall via the background runspace added 2026-08-20 (window responsiveness during a real install, correct completion, CrowdStrike/Office installs no longer failing under `$ConfirmPreference = "None"`)
- GUI-based Rename Computer, Create Local Standard User, and Apply Power Settings (Windows Configuration screen, added 2026-08-20)
- GUI-based Temp Cleanup (Temp Cleanup screen, added 2026-09-02): Windows Temp/Prefetch scan and deletion under real elevation, and a live click-through of the new screen (nav, checkboxes, Clean Selected, confirmation, completion modal)

These items are pending, not failed. Version `1.1.0-dev` will remain unchanged until the required tests are completed.

---

## Test Environment

Record the device used for testing:

- Computer name:
- Manufacturer:
- Model:
- Windows edition:
- Windows version:
- Tester:
- Test date:

---


## Deployment Tool Validation Mode

- [x] `Start.ps1 -ValidateOnly` loads all 45 modules
- [x] Validation checks the required deployment functions
- [x] Validation confirms `Config\Applications.json` exists
- [x] Successful validation returns exit code `0`
- [x] Validation mode does not open the main menu
- [x] Validation mode does not request administrator elevation
- [x] Normal `Start.ps1` startup continues to work after validation mode was added

---

## Startup and Interface

- [x] Tool requests administrator elevation when required
- [x] Main menu loads automatically
- [x] Empty menu input does not show an invalid-selection error
- [x] Returning from a submenu clears the previous screen
- [x] System information displays correctly
- [x] Administrator, internet, and WinGet checks display correctly

---

## Application Selection

- [x] Individual application selection works
- [x] Select All works
- [x] Select Recommended works
- [x] Clear All works
- [x] Selected applications preview displays correctly
- [x] Installation cancellation works
- [x] Empty application selection is handled correctly
- [x] Conflicting Office selections are blocked before the queue starts

---

## Installed Application Detection Cache

- [x] Registry-installed applications are collected once per status refresh
- [x] Machine and user registry scopes are preserved
- [x] Application installed status remains accurate
- [x] Special detection for WinGet, Teams, CrowdStrike, and Microsoft Office remains unchanged
- [x] Explicit `DetectionPath` overrides all other detection methods when configured
- [x] `DetectionPath` correctly reports `Installed` for a real file placed by a Script installer (WinMTR, 2026-08-13)
- [x] Applications without `DetectionPath` continue using registry detection unchanged (no regression)

---

## Application Installation

- [ ] Google Chrome installation works
- [ ] Viber installation works
- [ ] UltraViewer installation works
- [ ] AnyDesk installation works
- [ ] SAP GUI 7.70 installation works
- [x] SAP GUI 8.00 installation works (verified on a real device, 2026-08-13; real registry `DisplayName` confirmed as `SAP GUI for Windows 8.00 32bit  (Patch 0)`, matching the configured `DetectionName`)
- [x] WinMTR Script-type installation verified on a real device (2026-08-13) — file copied to target location and correctly detected via `DetectionPath`
- [ ] WhatsApp installation works
- [x] Installed applications are skipped correctly
- [x] Missing installers are reported correctly
- [x] Installation summary displays correct results
- [x] Fixed a latent gap: `Get-WingetScopeArguments` throws for an invalid `WingetScope` value, and `Test-WingetPackage` (used by the installer-availability check) called it with no try/catch, so a mistyped `WingetScope` in `Applications.json` would have thrown an unhandled exception that terminated the entire install queue instead of failing just that one application. `Test-WingetPackage` now wraps argument construction in a try/catch and reports the package as unavailable rather than throwing. All current catalog entries already use valid `"machine"` values, so this was never triggered in practice (2026-08-25).

> Local, non-destructive acceptance testing is complete. The remaining installation and system-change tests require an authorized clean deployment device. Version `1.1.0-dev` will remain unchanged until those tests pass.

---

## Application Uninstallation

- [x] Uninstallation router correctly prioritizes `AppxPackageName` over `InstallType` (verified: a WhatsApp-like object with `InstallType: Exe` and `AppxPackageName` set routes to the AppX uninstaller, not the EXE uninstaller)
- [x] WinGet uninstallation dispatch was validated using a mocked `Start-Process`/`winget` call
- [x] EXE uninstallation was validated against a real registry `UninstallString` (7-Zip) using a mocked `Start-Process`
- [x] MSI uninstallation argument construction (`/x "<path>" /qn /norestart`) and dispatch were validated using a mocked `Start-Process`
- [x] AppX uninstallation was validated end-to-end against the real WhatsApp catalog entry and real `Get-AppxPackage` lookup, using a mocked `Remove-AppxPackage`
- [x] ZIP-installed applications route through the same registry-based EXE uninstaller regardless of `ExtractedInstallType`, since the original ZIP-extracted installer file no longer exists after install (verified via mocked dispatch)
- [x] Microsoft Teams uninstallation removes both the provisioned package (`Remove-AppxProvisionedPackage -Online`) and the current-user package (`Remove-AppxPackage`), verified with both packages mocked as present
- [x] Microsoft Teams uninstallation correctly reports failure when a provisioned package is still detected after removal (verified with a simulated incomplete-removal case)
- [x] `Uninstall-ApplicationWithScript` reuses `Test-ScriptInstallerFile`/`Get-ScriptInstallerPath`/`Get-ScriptInstallerType` unchanged via a synthetic `InstallerPath = UninstallerPath` object, verified with real (non-destructive) script execution against success, failure, missing-path, and wrong-extension cases
- [x] WinMTR `UninstallerPath` wiring verified end-to-end against the real catalog entry and real `C:\Tools\WinMTR` installation, with only `Start-Process` mocked; confirmed the real installation was left untouched
- [x] `Start-Office2024Uninstallation` correctly skips with `Skipped` when Office 2024 is not installed (verified for real, no admin/mount required)
- [x] `Start-Office2024Uninstallation` correctly aborts before mounting anything when `office-remove.xml` is missing, and correctly aborts at the administrator check once the file exists (both verified for real, in a non-elevated session)
- [x] `office-remove.xml` (`<Remove All="TRUE" />`) created locally at `Installers\ISO\Office2024\office-remove.xml` and confirmed resolvable by `Get-Office2024UninstallConfigurationPath`
- [x] Office 2021 LOP uninstallation routes through the same registry-based EXE uninstaller as ZIP applications, relying on the classic `Uninstall` registry entry Click-to-Run itself registers rather than an invented `OfficeClickToRun.exe` command (verified via mocked dispatch)
- [x] Fixed: `Uninstall-ApplicationWithExe` previously ran the registry `UninstallString`/`QuietUninstallString` through `cmd.exe /c "..."`, so any shell metacharacter in that value (`&`, `|`, `^`, `%VAR%`) would have been interpreted by `cmd.exe` instead of passed through literally to the uninstaller. Added `Split-UninstallCommandLine` to parse the executable path (quoted or unquoted) and its arguments, and now calls `Start-Process` directly with no shell in between -- the same pattern `Install-ApplicationWithExe` already uses. Verified the parser against a quoted path with arguments, an unquoted path with arguments, and a quoted path with none, 2026-08-25; a real uninstall through the new code path was not exercised live.
- [x] Unsupported installation types (CrowdStrike) return a clean `Failed` result instead of crashing
- [x] Per-application confirmation prompt correctly gates uninstallation (Y proceeds, N skips)
- [x] Applications that are not currently installed are skipped automatically without prompting
- [x] Uninstallation queue counts `Uninstalled`, `Skipped`, and `Failed` correctly (verified with a simulated four-application run)
- [x] `[U] - Uninstall Selected` option added to the application menu and refreshes installed-application status afterward
- [x] Deployment validation reports 45 modules and 24 required functions
- [ ] Real WinGet uninstallation on an authorized deployment device
- [ ] Real EXE uninstallation on an authorized deployment device
- [ ] Real MSI uninstallation on an authorized deployment device
- [ ] Real AppX/WhatsApp uninstallation on an authorized deployment device
- [ ] Real ZIP-installed application uninstallation on an authorized deployment device
- [ ] Real Microsoft Teams uninstallation on an authorized deployment device
- [ ] Real WinMTR uninstallation (script execution mocked so far; the script itself was never run for real)
- [ ] Real Office 2024 uninstallation on an authorized, elevated deployment device (the mount -> `setup.exe /configure` -> verify path could not be exercised in a non-elevated local session)
- [ ] Real Office 2021 LOP uninstallation on a device that actually has it installed, to confirm the registry `DisplayName` Click-to-Run registers actually matches and the removal runs silently

> WinGet, EXE, MSI, AppX, ZIP, Teams, Script, Office 2024, and Office 2021 LOP uninstallation are implemented. Real-device uninstallation tests are pending for all of them. Office 2021 LOP relies on the classic registry `Uninstall` entry Click-to-Run registers, rather than an ODT `/configure` command (it installs via `Setup.exe /AUTORUN`, not ODT) or an invented `OfficeClickToRun.exe` command line; the exact registered `DisplayName` has not been confirmed against a real device with it installed. CrowdStrike uninstallation is intentionally out of scope for this tool, not a pending item.

---

## Microsoft Teams

- [x] Microsoft Teams appears in the application catalog
- [x] Microsoft Teams appears under the Communication category
- [x] Select Recommended includes Microsoft Teams
- [x] Current-user Teams MSIX detection works
- [x] Provisioned-package detection works from an elevated session
- [x] Latest Teams bootstrapper downloads successfully
- [x] Bootstrapper Microsoft signature validation passes
- [x] Temporary bootstrapper files are removed after validation
- [x] Teams provisioning preview works without changing the device
- [x] Application-menu preview and cancellation work
- [ ] Microsoft Teams provisions successfully on a clean device
- [ ] Microsoft Teams is available to a newly created local user
- [x] Existing provisioned Microsoft Teams installation is detected correctly
- [x] Existing provisioned Microsoft Teams installation is skipped correctly


> Local detection, package validation, and provisioning preview passed. Actual provisioning remains pending until an authorized clean deployment device is available.

---

## CrowdStrike

- [x] CrowdStrike package is detected
- [x] Customer ID format is validated
- [x] Credentials are not displayed or logged
- [ ] CrowdStrike installer starts correctly
- [x] Existing CrowdStrike installation is skipped
- [x] Falcon service is detected after installation
- [x] Fixed: `Start-CrowdStrikeInteractiveSetup` logged only via `Write-Host`, so a CrowdStrike install attempt (success, skip, "not detected", or failure) left zero entries in the persistent deployment log, unlike every other installer type. Added `Write-DeploymentLog` calls for all four outcomes, without logging the CID or token values (verified: no logged message references `$CustomerId`/`$ProvisioningToken`, only static status text, 2026-08-25).
- [x] **Decided, after researching it, not to automate CrowdStrike uninstallation.** The user's real `Readme.txt` now also carries a maintenance token, which reopened the question since the previous "out of scope" decision was specifically because no such token was available. Found CrowdStrike's real removal path (two independent public sources agreed, a third lower-quality result that disagreed was discounted): a separate utility, `CsUninstallTool.exe`, downloaded from the Falcon console's own Tool Downloads page (not bundled with the sensor installer this tool already has), run as `CsUninstallTool.exe MAINTENANCE_TOKEN=<token> /quiet` (or without the token if Maintenance Protection is disabled). After hearing this, the user chose to keep this manual rather than automate it. Documented instead: `README.md`'s CrowdStrike README format now lists an optional `Maintenance Token:` line as manual-reference-only ("this tool does not read, parse, or act on it"), `CLAUDE.md`'s uninstallation-routing section now explains why CrowdStrike uninstall still falls through to `Uninstall-ApplicationByType`'s `default` case and what the real manual removal command is, and `Maintenance Token` was added to `CLAUDE.md`'s list of sensitive values never to log/persist. No code changed -- `Get-CrowdStrikeDeploymentValues` still only reads `Customer ID`/`Token`, and `Uninstall-ApplicationByType` still has no `CrowdStrike` case (2026-09-02).

> Package preflight passed on the current device. Fresh installation remains untested and requires an authorized clean deployment device.

---

## Microsoft Office 2024

- [x] Office 2024 ISO is detected
- [ ] ISO mounts successfully
- [ ] Office installation starts successfully
- [x] Office 2024 installation is detected afterward
- [ ] ISO is dismounted after processing
- [x] Product activation remains manual

> Package preflight passed on the current device. Fresh installation remains untested and requires an authorized clean deployment device.

---

## Microsoft Office 2021 LOP

- [x] Office 2021 IMG is detected
- [ ] IMG mounts successfully
- [x] Microsoft signature validation passes
- [ ] Office 2021 installation starts successfully
- [ ] Office 2021 installation is detected afterward
- [ ] IMG is dismounted after processing
- [x] Conflicting Office installation is blocked
- [x] Product activation remains manual
- [x] Fixed: `Get-Office2021MountedVolume` called `Get-DiskImage =ImagePath $ImagePath` (missing the `-` before `ImagePath`), which PowerShell parsed as a positional argument rather than the named parameter. This threw a `ParameterBindingException` that `-ErrorAction SilentlyContinue` could not suppress (parameter-binding failures happen before a cmdlet's own error action applies), so every real Office 2021 LOP installation attempt failed immediately after mounting, with a confusing internal PowerShell error instead of ever reaching Setup.exe. Corrected to `-ImagePath` (verified: the exact call previously threw `ParameterBindingException` in isolation; the corrected call no longer does, 2026-08-25).

> Package preflight passed on the current device. Fresh installation remains untested and requires an authorized clean deployment device.

---

## Windows Configuration

- [x] Computer rename preview works
- [ ] Computer rename works on an authorized test device
- [x] Local standard user creation works
- [ ] Created account is not an administrator
- [x] Password is not displayed or logged
- [x] Power and sleep configuration works
- [x] Current Windows configuration report displays correctly
- [x] Fixed: `New-DeploymentLocalStandardUser` only logged the success path; validation failures, "already exists" skips, missing-administrator failures, and the catch-all failure path all returned silently with no deployment-log entry. Added `Write-DeploymentLog` calls to all four paths. Also fixed a property-name inconsistency (`Username` vs. `UserName`) and a typo ("uderscores") in `Test-DeploymentLocalUserName`'s invalid-character message, both harmless at runtime but worth correcting (2026-08-25).

> These tests require an authorized clean deployment device and will remain unchecked until a suitable test device is available.

---

## Deployment Validation

- [x] Administrator validation works
- [x] Internet validation works
- [x] WinGet validation works
- [x] Computer-name validation works
- [x] Local-standard-user validation works
- [x] Required-application validation works
- [x] Power-setting validation works
- [x] CrowdStrike validation works
- [x] Microsoft Office validation works
- [x] Pending-restart validation works
- [x] Passed, failed, and total counts are correct

---

## Deployment Logs

- [x] Session log is created
- [x] Application results are logged
- [x] Validation results are logged
- [x] Validation summary is logged
- [x] Credentials and product keys are not logged
- [x] Session completion is logged
- [x] Recent logs can be viewed from the tool

---

## GUI Mode

The WPF GUI (`Start.ps1 -Gui`) is a separate interface layer that wraps the same underlying functions as the console menus above. These checklist items verify the GUI-specific wiring (elevation, layout, background execution); the underlying business logic (validation rules, install/uninstall behavior, computer rename/local user/power-setting mechanics) is covered by the console-mode sections elsewhere in this document and is not re-verified here.

### Cross-Screen Visual Behavior

- [x] Every `Button` (toolbar buttons, primary action buttons, Rename/Create/Apply buttons) uses a custom `ControlTemplate` that keeps its label text painted on top of a subtle hover/press brightness overlay, instead of relying on the default Windows button chrome, which was found to visually override custom Background/Foreground on hover and make the label unreadable (verified via rendered screenshot showing correct text and background in the normal state, and via template/trigger inspection for the hover/press states, 2026-08-24; a live hover was not simulated, since synthetic mouse input was judged unsafe in this environment earlier in the project)
- [x] Switching sidebar tabs fades the new screen's content in (~160ms) instead of an abrupt cut (verified the animation runs without error across all four screens, 2026-08-24)
- [x] The first switch to Deployment Validation or Windows Configuration shows an immediate loading indication (a "Checking deployment readiness..." message, or simply the tab-switch highlight for Windows Configuration) before the underlying checks run, so the click feels acknowledged instead of frozen; the checks themselves still run synchronously and the window is not interactive during that window (verified the mechanism runs without error, 2026-08-24; true non-blocking background loading, like installs already use, was not implemented here)
- [x] Every `ScrollBar` (Applications grid, Deployment Logs list/viewer, Windows Configuration, Deployment Validation) is a thin borderless thumb matching the mockup's scrollbar spec instead of the native Windows gray gripper chrome, faded to low opacity until the pointer is over it (verified via a rendered screenshot showing the restyled thumb; the hover-brightens behavior was confirmed by inspecting the trigger, not by simulating a live hover, 2026-08-24)
- [x] Every `ProgressBar` uses a flat accent-colored fill on a dark track instead of the native Aero-gradient chrome (verified the fill's rendered width actually changes proportionally when `Value` changes, from ~30% to ~80%, in an isolated render test, 2026-08-24)
- [x] Fixed the same hit-testing gap found earlier in the Applications checkbox and Deployment Logs rows, this time in the sidebar navigation: `NavWindowsConfig`, `NavDeploymentLogs`, and `NavDeploymentValidation` had no `Background` set (only the currently-active nav item did), and `Switch-GuiScreen` reset every nav item's `Background` to `$null` on every screen switch -- so for whichever tab wasn't currently selected, clicking anywhere in its padding or icon interior did nothing; only the label text (or an icon's thin stroke) was actually clickable. All three borders now have an explicit `Background="Transparent"` in `MainWindow.xaml`, and the reset loop in `GuiWindow.ps1` now sets `"Transparent"` instead of `$null` (verified the borders and reset now carry a real `Transparent` brush, 2026-08-25; a live mouse click was not simulated, since synthetic mouse input was judged unsafe in this environment earlier in the project).

### Startup and Elevation

- [ ] `Start.ps1 -Gui` requests administrator elevation before the window opens (not bypassed)
- [ ] The elevated relaunch opens the GUI window (not a console session)
- [ ] Declining the UAC prompt exits cleanly without opening a window
- [x] The Internet status check uses an explicit 1-second `System.Net.NetworkInformation.Ping` timeout instead of the uncontrolled WMI-based `Test-Connection` call, so a network that silently drops outbound ICMP cannot stall startup for several seconds waiting on it (verified the check still correctly reports connectivity on a normal network, 2026-08-24; the bounded-timeout benefit itself has not been observed on an actual ICMP-blocking network, since this development machine allows outbound ICMP)
- [ ] The console window is hidden once GUI mode starts, via `GetConsoleWindow`/`ShowWindow`, so `.\Start.ps1 -Gui` does not leave a visible PowerShell console window alongside the GUI (code added 2026-08-24 and parse-checked only; `-ValidateOnly` does not reach this code path, and it has not been exercised via a real `-Gui` launch)
- [x] Fixed: the sidebar column was 184px wide, but "Deployment Validation" (the longest nav label) needs 202.8px including its icon and padding, so it rendered clipped as "Deployment Validat...". Measured every nav label's true unconstrained content width (Applications 145.1px, Windows Setup 161.5px, Device Details 152.4px, Deployment Logs 172.8px, Deployment Validation 202.8px) and widened the sidebar column from 184px to 214px, giving Deployment Validation the widest label a ~40px margin instead of running short. Re-verified both Windows Setup and Device Details still fit with no scrolling after the content area narrowed by 30px (unaffected, since their internal columns are proportional `*` widths, not fixed) (verified via `ActualWidth` measurement and a rendered screenshot showing the full label, 2026-08-25)

### Applications Screen

- [x] Real catalog data loads and displays grouped by category (confirmed on a real device via screenshot)
- [x] Individual selection, Select All, Select Recommended, and Clear All work (confirmed on a real device via screenshot)
- [x] System information bar (computer, user, model, administrator/internet/WinGet status) displays correctly (confirmed on a real device via screenshot)
- [ ] Install Selected completes correctly and the window stays responsive during a real install (background execution added 2026-08-20, not yet re-tested live)
- [x] Toolbar shows a determinate progress bar plus "Installing N of M: AppName..." text while a queue runs, both updating incrementally per app rather than only at completion; the progress bar and text replace the Install/Uninstall Selected buttons and selection count for the duration of the run, reverting back afterward (verified end-to-end via an automated run against an already-installed app, so only the safe "already installed, skip" code path executed; a real install/uninstall was not observed live, 2026-08-24)
- [x] A Cancel button appears in place of Install/Uninstall Selected while a queue runs. Cancelling is cooperative: it lets whichever app is currently mid-install/uninstall finish, then marks every remaining not-yet-started app as "Cancelled" instead of forcibly killing the running installer (which could leave it in a broken state). The completion modal's title and badges reflect the cancellation (verified end-to-end: enqueuing a cancel signal immediately after starting a 16-app queue of already-installed apps correctly marked all 16 "Cancelled" and titled the modal "Installation Complete (Cancelled)", 2026-08-24; cancelling partway through a real multi-app run, where one app is genuinely mid-install when Cancel is clicked, was not observed live)
- [x] Install/uninstall completion is shown in a custom in-window modal styled like the rest of the tool (dark card, success/warning icon, colored count-pill badges per status, a scrollable failure-details card when there are failures) instead of a native `MessageBox` (verified via rendered screenshots of both the failure and all-success states, and via an automated end-to-end run confirming the modal opens automatically with correct counts on queue completion, 2026-08-24)
- [x] Application rows use a custom flat checkbox matching the approved mockup (filled blue square with checkmark when selected, outlined square when not) instead of the native Windows checkbox control, and clicking it toggles selection and the "N selected" count without rebuilding the whole grid (verified via rendered screenshot and a simulated toggle, 2026-08-24)
- [x] The "Not Installed" status indicator uses the mockup's distinct dot color (`#4A4E58`) separate from its label text color (`#6B6F79`) (verified via rendered screenshot, 2026-08-24)
- [x] Fixed: clicking inside an unchecked checkbox's interior did nothing (only its 1.5px border stroke was hit-testable, since it had no `Background`); the whole row and the checkbox interior now use an explicit `Transparent` background so any click within the row's bounds registers, matching the same fix already applied to the title bar buttons (verified by confirming the checkbox and row now carry a real `Transparent` brush rather than `null`, 2026-08-24; a live mouse click was not simulated, since synthetic mouse input was judged unsafe in this environment earlier in the project)
- [x] WinBox's installed-status check uses the standard registry cache instead of an extra `winget list` shell-out, since its WinGet package already registers a matching classic Uninstall entry (verified the registry entry is present with `DisplayName` "WinBox" and that detection still reports correctly, 2026-08-24; saves roughly 500ms per Applications screen load on this device)
- [ ] Uninstall Selected completes correctly for both machine-scope and user-scope WinGet packages (originally reported failing for Google Chrome due to the `-Gui` elevation bypass; elevation fix and winget diagnostics added 2026-08-20, not yet re-tested live)
- [x] Fixed: the deployment validation background load crashed with "Cannot bind argument to parameter 'Rows' because it is an empty array." `ApplicationCatalog.ps1`'s top-level code resets `$script:Applications` to `@()` when dot-sourced; since dot-sourcing does not create a new scope, the background script's own parameter (previously also named `$Applications`) was the same variable and got silently clobbered mid-load, so `Get-InstallerPackageReadiness` always received an empty array. Renamed the parameter to `$ApplicationsParam` to avoid the collision (verified: reproduced the exact crash with the real 19-application catalog through the actual background-runspace mechanism, then confirmed the fix resolves it end-to-end -- Deployment Validation returns "6 passed, 10 failed" with 2 populated section cards instead of crashing, 2026-08-24)
- [x] Uninstall now checks for blocking (running) processes before uninstalling, the same protection Install Selected already had (this gap meant uninstalling an app while it was still open could fail with a vendor-specific error instead of a clear "still running" message). Added to both the console (`UninstallationQueue.ps1`, using the existing interactive Retry/Skip prompt) and GUI (`GuiApplicationsScreen.ps1`'s background queue) uninstall paths; reported as `Skipped` rather than a new state, consistent with the documented `Uninstalled`/`Skipped`/`Failed` contract. `BlockingProcesses: ["brave"]` was added to Brave Browser's catalog entry, since it previously had none configured -- Brave Browser was reported failing to uninstall with exit code -1978335107, a Chromium/Omaha-style updater error consistent with the browser still running during uninstall (verified the detection mechanism itself works correctly against a real running process, 2026-08-24; not confirmed that Brave was actually open during the original failure, so this addresses a real, verified gap rather than a certain root cause)
- [x] Fixed: WhatsApp could not be silently installed because `Installers\EXE\WhatsApp\WhatsApp Installer.exe` was not actually a WhatsApp installer -- its file metadata identified it as Microsoft's generic "Store Installer" stub (`FileDescription`/`ProductName`: "Store Installer", `CompanyName`: "Microsoft Corporation", `OriginalFilename`: "StoreInstaller.exe"), whose only job is to open the Microsoft Store to the app's page (matching the reported symptom exactly). WhatsApp Desktop is Microsoft Store-only now; there is no traditional offline EXE. Switched WhatsApp's catalog entry to `InstallType: Winget` with `Winget: 9NKSQGP7F2NH` and a new optional `WingetSource: msstore` field (defaults to the existing hardcoded `winget` source everywhere it's used -- `Get-WingetInstallArguments`, `Get-WingetUninstallArguments`, `Test-WingetPackage`, `Test-WingetApplicationInstalled` -- so every other Winget-type catalog entry is unaffected). Removed the now-unreferenced Store-Installer stub file. Verified end-to-end: `winget install --id 9NKSQGP7F2NH --source msstore --silent --accept-source-agreements --accept-package-agreements` genuinely installed WhatsApp non-interactively (confirmed via `Get-AppxPackage`), then `winget uninstall` cleanly removed it again; `Test-ApplicationInstallerAvailable` now correctly reports the package as available; confirmed Google Chrome and other existing Winget apps still construct their commands with `--source winget` unchanged, 2026-08-24. Uninstall was already correct without any change, since `Uninstall-ApplicationByType` already prioritizes `AppxPackageName` (already configured for WhatsApp) over `InstallType`.
- [x] Applications within each category now render in alphabetical order by name, instead of whatever order they happen to appear in `Applications.json`. `Update-GuiApplicationGrid` sorts each category's group (`$Group.Group | Sort-Object Name`) before building its card (verified via `-ValidateOnly`; not re-screenshotted this pass)
- [ ] Closing the window while an install/uninstall queue is running is blocked with a warning instead of abandoning the queue
- [ ] CrowdStrike, Microsoft Office 2024, and Microsoft Office 2021 LOP installs complete correctly through the GUI (background execution requires `$ConfirmPreference = "None"` to avoid the native confirmation prompt throwing in a non-interactive runspace; added 2026-08-20, not yet tested live)

### Deployment Validation Screen

- [x] Device Readiness Checks and Installer Package Status sections both render with real data (verified via automated non-destructive testing against this device, 2026-08-20)
- [x] Pass/fail counts and colors are correct (verified via automated non-destructive testing, 2026-08-20)
- [x] Results are written to the deployment log (verified via automated non-destructive testing, 2026-08-20)
- [x] Validation runs automatically the first time the screen is opened; switching away and back does not needlessly re-run all checks (the Re-run Validation button still forces a fresh run on demand) (verified via automated testing of the underlying flag-gated logic, 2026-08-24; this eliminated a measured ~750ms delay on every repeat tab switch)
- [ ] Re-run Validation button refreshes correctly when clicked by a user
- [x] The screen has a page header (icon, title, and description) matching the other screens; each status row shows a small checkmark/X badge icon instead of plain PASS/FAIL text, and each section's pass count is shown as a colored pill badge with a matching header icon, instead of the previous bare-text list (verified via rendered screenshot, 2026-08-24)

### Deployment Logs Screen

- [x] Recent logs list populates and auto-selects the most recent log (verified via automated non-destructive testing, 2026-08-20)
- [x] Clicking a different log switches the content viewer and selection highlight correctly (verified via a simulated click event, 2026-08-20)
- [x] The logs list loads automatically the first time the screen is opened; switching away and back does not needlessly reload it (the Refresh button still forces a fresh reload on demand) (verified via automated testing, 2026-08-24)
- [ ] Refresh button and Open Logs Folder button work when clicked by a user
- [x] The screen has a page header (icon, title, and description); the log list is wrapped in a proper card with a "RECENT SESSIONS" header and a document icon per row, and the log viewer shows a header bar with the selected log's filename instead of being a bare textbox (verified via rendered screenshot, 2026-08-24)
- [x] Fixed the same hit-testing gap found in the Applications checkbox: log list rows had no `Background`, so clicks in gaps between text lines did not always register; rows now use an explicit `Transparent` background (verified by confirming the row background is a real `Transparent` brush rather than `null`, 2026-08-24; a live mouse click was not simulated, since synthetic mouse input was judged unsafe in this environment earlier in the project)

### Temp Cleanup Screen

New screen added per the user's own feature idea ("can we add a tab for deleting the temp cache? the folder of temp, %temp%, prefetch?"), covering the current user's `%TEMP%`, `C:\Windows\Temp`, and `C:\Windows\Prefetch`.

- [x] Three cards (User Temp, Windows Temp, Prefetch), each with a checkbox defaulting to checked, a path line, and a summary line, scan in the background the same way Deployment Validation does (a separate runspace re-dot-sourcing only `Windows\TempCleanup.ps1`, polled via a `DispatcherTimer`) so the tab switch itself never blocks the UI thread (verified via `-ValidateOnly` and an off-screen XAML parse+`FindName` check; not yet exercised through the real end-to-end `Show-MainWindow` harness).
- [x] Clicking a card toggles its selection (filled blue checkbox with checkmark vs. outlined) using the exact same visual toggle already established for the Applications grid's row checkboxes, applied here to a fixed card instead of a dynamically built row.
- [x] "Clean Selected" confirms first (`Show-GuiDialog`, Warning/YesNo, naming exactly which locations and the real total size that will be deleted), then deletes only the checked locations and re-scans afterward; the completion result reuses the same `Show-GuiCompletionModal`/`Get-GuiCompletionSummary`/Copy Results modal already built for install/uninstall, rather than a new UI pattern.
- [x] Fit-tested at 1360x860 with the same off-screen harness used for every other screen this session, populated with realistic real-length values: 117.5px content vs. 686.85px viewport, 569.3px spare -- comfortably fits with no scrolling, expected for a screen that is only three simple cards in a single row.
- [x] **Caught and fixed a real crash while testing the backend module directly, unrelated to the feature logic itself**: `Get-TempCleanupTargets` built its results list with `New-Object System.Collections.Generic.List[object]`, then returned `@($Targets)` to normalize the result to an array -- the same pattern already used successfully elsewhere in this app (`InstallerPackageReadiness.ps1`). On this specific PowerShell 5.1 build, that exact combination throws `"Argument types do not match"` as soon as the list is wrapped in `@()`, reproduced in complete isolation (a fresh, `-NoProfile` process, no other code involved) and narrowed down to the `New-Object`-with-generic-type-parameter construction specifically -- `[System.Collections.Generic.List[object]]::new()` (the exact form `InstallerPackageReadiness.ps1` already happens to use) and `List[string]` via either construction form are both unaffected. Fixed by switching to the `::new()` form, matching the convention `InstallerPackageReadiness.ps1` already established.
- [x] **Caught and fixed a real, user-facing scan-accuracy bug found while testing against this real machine's real `%TEMP%`**: the initial scan used `Get-ChildItem -Recurse -File -Force -ErrorAction Stop`, which throws (and aborts the *entire* location's scan) the moment it hits even one inaccessible nested subfolder -- confirmed for real on this dev machine, where a system-created `WinSAT` results folder inside the current user's own `%TEMP%` is access-denied even to its owning user, which made the whole User Temp card report "Access Denied" and 0 files, hiding the 330+ MB of real, perfectly cleanable files sitting right alongside it. Fixed by switching to `-ErrorAction SilentlyContinue -ErrorVariable ScanErrors`, so one denied subfolder is skipped rather than aborting the whole scan; a location is only ever reported inaccessible when literally nothing came back AND a real scan error was recorded, which still correctly distinguishes "this whole location is denied" from "genuinely empty" or "mostly readable with one odd subfolder walled off." Applied the same fix to `Remove-TempCleanupTarget`'s pre-delete re-scan, for the same reason. Re-verified against this real machine after the fix: User Temp now correctly reports 401 files/330.6 MB accessible, while Windows Temp and Prefetch still correctly report `Accessible = $false` with a real, genuine "Access to the path ... is denied" error (expected and correct in this non-elevated dev shell).
- [x] `Remove-TempCleanupTarget` verified for real against an isolated fake test folder (never the real `%TEMP%`), including a deliberately locked-open file: correctly deleted 6 of 7 files (712 bytes freed), correctly skipped the 1 locked file rather than aborting, and correctly left both the target folder itself and the locked file's parent subfolder in place, never deleting the folder structure -- only files inside it.
- [ ] Windows Temp and Prefetch access has only been confirmed as *denied* in this non-elevated dev shell, matching this tool's own documented expectation that those locations need real elevation. Whether the scan and deletion actually succeed against them under this tool's real elevated GUI session has not been confirmed on a real device.
- [ ] No live click-through test of the real `Show-MainWindow` (nav click, checkbox toggle, Clean Selected, confirmation dialog, completion modal) has been run for this screen yet -- only structural verification (`-ValidateOnly`, XAML parse+`FindName`, the off-screen fit harness, and direct calls to the backend functions) has been done so far.

### Windows Setup and Device Details Screens

The single "Windows Configuration" screen was split into two sidebar tabs on
2026-08-25. Entries below that predate the split describe the combined screen and
are kept for history; the split itself is covered by the last group of entries.

- [x] Device Information, current computer name, local standard users list, and current power settings all populate with real data (verified via automated non-destructive testing against this device, 2026-08-20)
- [x] Re-running the refresh does not clobber in-progress typing in the power-setting input fields (verified via automated non-destructive testing, 2026-08-20)
- [x] Screen layout matches the approved mockup: a full-width Device Information card, a two-column Computer Rename / Local Standard User row, and a full-width Power and Sleep Settings card below, each with an accent-colored header icon, uppercase field labels, and a boxed read-only "current name" field (verified via rendered screenshot compared against the mockup, 2026-08-24)
- [x] Static hardware/OS identity fields (manufacturer, model, serial number, OS edition/version/build/architecture, network type, domain/workgroup, administrator status) are cached after the first query instead of re-querying CIM/BIOS every refresh, while power plan and sleep timeout values are still queried fresh each time (verified: first call ~835ms, cached calls ~63ms with identical cached data, 2026-08-24)
- [x] The screen loads automatically the first time it is opened; switching away and back does not needlessly re-run the refresh (the Refresh button still forces a fresh run on demand) (verified via automated testing, 2026-08-24; this eliminated a measured ~1,200ms delay on every repeat tab switch)
- [x] Fixed: several card-header `TextBlock`s ("Device Information", "Computer Rename", "Local Standard User", "Power and Sleep Settings", plus the completion modal's title) had no explicit `Foreground` set, so they fell back to the system default (black), which is illegible against the dark card background. This was invisible in this session's own rendered-screenshot tests but showed up as black text on a real device screenshot. All 8 now explicitly set `Foreground="#E8E9EC"` (verified: every `TextBlock` in `MainWindow.xaml` now has an explicit `Foreground` attribute; confirmed visually correct on a re-render, 2026-08-24)
- [x] The screen's layout was compressed (3-column Device Information grid instead of a single tall column; tighter card padding, margins, and field spacing throughout) so the full screen fits within the window at 1360x860 without needing to scroll at all, rather than just re-styling the scrollbar that appeared. Verified by measuring the content's true desired height against the visible viewport height (677px content vs. 704px available, a 27px margin) rather than relying on `ActualHeight`, which can misleadingly equal the viewport when a panel stretches to fill it, 2026-08-24. This was verified at exactly the mockup's 1360x860 window size; a differently-sized or maximized window, or a real device's DPI/font-rendering differences, were not tested and could re-introduce a small overflow.
- [x] Device Information redesigned in two passes. First pass grouped the 14 fields under three column headers (IDENTITY, SYSTEM, SESSION & POWER) inside the single existing full-width card and added the "Copy Device Details" toolbar button (copies a formatted plain-text summary via `Get-GuiDeviceDetailsSummary`/`Invoke-GuiCopyDeviceDetails`, verified against clipboard contents). Per follow-up feedback that a single card stretching the full window width "is not good," the card was then split into three independently-sized tiles (Identity / System / Session & Power) laid out side by side, matching the visual weight of the Computer Rename / Local Standard User cards below instead of one long stretched bar. Computer Name stays bolded as the primary identifier and Administrator status stays a colored pill badge; both survived the tile split since `x:Name`-based field references never changed, only their container. The Copy Device Details button and its clipboard output are unaffected by the restructure.
- [x] Every `TextBox` and `PasswordBox` (New Name, Username, Full Name, Password, Confirm Password, both sleep-timeout fields) now uses a custom `ControlTemplate` with rounded corners (matching the existing read-only "current name" display box) and an accent-colored border on focus, instead of the default flat, hard-cornered chrome, per explicit feedback that the fields looked "not soft." First attempt used a `ScrollViewer` as the required `PART_ContentHost`, which silently added ~12px of height to every field (~52px total on this screen) and reintroduced scrolling (726px content vs. 710px viewport) -- caught by re-measuring content height after the change, before it reached a real device. Switched to a `Decorator` for `PART_ContentHost` (an equally valid host per WPF's own contract, appropriate for a non-multiline field that never needs internal scrolling), which measured identically to the original default-styled TextBox (31.29px), fully restoring the 674px/710px budget. Verified end-to-end: rounded corners render correctly, typed text and password dots display normally, and the focus trigger correctly turns the border cyan (checked via `.Focus()` and reading back `IsFocused`/`BorderBrush`, not a simulated click, 2026-08-25).
- [x] Spacing across the four Windows Configuration cards was loosened per feedback that the screen felt "too compactable," then partly rolled back after real-device testing showed the scrollbar had actually returned (measured margin at the time was only 16.2px, well under the ~36-57px this screen has needed in the past to reliably avoid scrolling -- a real miss, not a false alarm). Root cause: the loosened padding/margins (`WindowsConfigScrollViewer` padding, inter-card gaps, per-card padding) combined with the three-tile Device Information split (which needed its own three headers instead of one shared header) added more height than the available buffer covered. Fix: reverted `WindowsConfigScrollViewer` padding to its original `24,2,24,4`, inter-card gaps back to 6px, and per-card padding back to 8, while keeping the wider 26px gutter between Computer Rename/Local Standard User (a width-only change, free of height cost) and the three-tile layout itself. Re-measured: 667px content vs. 710.1px viewport, a 43.2px margin -- close to (though not identical to) the ~50-57px range previously confirmed safe via real device screenshots. This has NOT yet been re-confirmed on real hardware; if any scroll reappears, the next lever is reducing Identity/System from 5 rows each to 4 (e.g. by adding a fourth tile), not another blind padding pass.
- [x] "Windows Configuration" was split into two sidebar tabs, **Windows Setup** and **Device Details**, per feedback that one screen was carrying both the actions and the read-only device report. Windows Setup holds the three action cards (Computer Rename, Local Standard User, Power & Sleep) in a three-column row; Device Details holds the 14 read-only fields in two cards (Identity & System, Session & Power), each card grouping its fields under uppercase subheads separated by a divider. The two-card shape was chosen deliberately: four side-by-side tiles drew "too much container," and a single full-width card had earlier drawn a complaint about its container "stretching its length." Sidebar gained a wrench icon for Windows Setup and kept the existing gear icon for Device Details (verified: XAML parses via `XamlReader.Load` and all 44 named elements resolve via `FindName`, no stale `NavWindowsConfig`/`WindowsConfigToolbar`/`WindowsConfigScrollViewer`/`RefreshWindowsConfigButton` names remain; `.\Start.ps1 -ValidateOnly` passes with 45 modules and 24 functions, 2026-08-25)
- [x] Both new screens fit at 1360x860 with no scrolling, with far more headroom than the combined screen ever had. Measured on a realized (off-screen) window with realistic longest-plausible field values and two existing local users loaded: Windows Setup 444px content vs. 702.1px viewport (258.1px spare), Device Details 352.8px vs. 702.1px (349.3px spare). This replaces the previous 43.2px margin, which had proven too thin to survive small layout changes. Measured via `ScrollViewer.ExtentHeight` against `ViewportHeight` on a shown window, since an unrealized window reports 0 for both (2026-08-25). Not yet confirmed on real hardware, where DPI and font rendering can differ, but the margin is now large enough that a small difference cannot reintroduce scrolling.
- [x] Both screens are fed by one shared device report: whichever tab is opened first performs the background load and the other reuses it, so switching between them never re-runs the CIM/BIOS/powercfg queries. Each screen has its own Refresh button and both run the same full refresh; `Start-GuiWindowsConfigLoad` now takes `-RefreshButtons` (an array) instead of `-RefreshButton` so both are disabled for the duration of a load and re-enabled together in its `finally` block (verified via `-ValidateOnly` and XAML element resolution, 2026-08-25; the shared-load and button-disable behavior has NOT been exercised on a real device yet)
- [x] `Switch-GuiScreen` now collapses every screen up front and then shows only the requested one, instead of repeating the full visibility list in each branch. This was a consequence of going from four screens to five, where the per-branch lists had become the bulk of the function (verified: all five tabs resolve and `-ValidateOnly` passes, 2026-08-25)
- [x] Ran the real, unmodified `Show-MainWindow` end to end (not a hand-built layout probe) to verify the tab split and Hardware fields without touching this development machine's real state: the actual XAML, `Switch-GuiScreen`, `Start-GuiWindowsConfigLoad`, and `Invoke-GuiCopyDeviceDetails` all ran as production wrote them, on a window forced off-screen (`Left/Top = -6000`, `ShowInTaskbar = $false`) so it could never appear on the real desktop, on a background STA runspace so the window's own `ShowDialog()` stayed blocking exactly like production (an earlier attempt swapped in the non-blocking `Show()`, which let the function return and tore down the local-variable scope its plain, non-`GetNewClosure()`'d click handlers depend on -- every handler saw its captured element as null; this is a property of how this app's scriptblocks are written, not a bug, and running the real blocking `ShowDialog()` on its own thread was the fix). Every `MessageBox.Show` across the 5 Gui modules was redirected to record its message instead of popping a real dialog, in case anything went wrong. Result: clicking the real `NavWindowsSetup`/`NavDeviceDetails` handlers correctly ran `Switch-GuiScreen`; the real background load completed and populated every field with this machine's actual data (Computer Name `IT04-JP`, Manufacturer `LENOVO`, Processor `Intel(R) Core(TM) Ultra 5 225U`, Memory `16 GB`, Storage `314 GB free of 475 GB`); switching from Windows Setup to Device Details reused that same load with no re-fetch; the real Copy Device Details button produced the exact 18-line clipboard summary; and zero `MessageBox` calls fired, meaning no runtime error occurred anywhere in this path. Device Details measured 359.4px content vs. 700.8px viewport (341.4px spare) from the actual running window, consistent with the earlier hand-built-probe numbers (2026-08-26).
- [x] Confirmed switching between Windows Setup and Device Details does not re-run the device queries: Device Details showed real data immediately after Windows Setup had already loaded it, with no re-fetch delay (verified via the real end-to-end run above, 2026-08-26). The Refresh-button-disables-together behavior specifically was not exercised in that run (no Refresh click was performed) and remains unverified.
- [ ] Both tabs are visually confirmed on an authorized test device's actual monitor at 1360x860 with no scrollbar on either. Functional correctness (data loads, fields populate, no runtime errors) is now confirmed via the real end-to-end run above; what remains here is purely a physical-hardware check for DPI scaling or font-rendering differences this environment cannot reproduce.
- [x] Added a Restart Later / Restart Now choice to Computer Rename, so renaming the device no longer implicitly defers the restart with no way to ask for it immediately. `Set-DeploymentComputerName` (`ComputerNameConfiguration.ps1`) takes a new `-Restart` switch that maps directly to `Rename-Computer`'s own `-Restart` parameter; left unset (the default), behavior is unchanged from before -- rename now, restart whenever the technician chooses. Restart Now is never the default, since it restarts the machine immediately and is a real, hard-to-reverse action. The console wizard (`Start-ComputerRenameWizard`) now asks "Restart now, or later?" after the existing Y/N rename confirmation, defaulting to Later on blank input. The GUI Computer Rename card gained an "AFTER RENAME" segmented toggle (`RestartLaterOption` / `RestartNowOption`, styled like the existing nav-item active/inactive pattern); `Invoke-GuiComputerRename` now takes `-RestartNow` and its confirmation dialog wording differs by choice, warning to save open work first when Restart Now is selected. Verified via the real end-to-end harness (same technique as the earlier Windows Setup/Device Details verification, off-screen and non-destructive): the toggle's default state is correct (Later highlighted, Now not), clicking Restart Now and then Restart Later flips the highlight correctly both ways via the actual registered click handlers, and zero runtime errors occurred (2026-08-26). Also verified via `-WhatIf` that `-Restart` binds correctly and that invalid-name/same-name short-circuits still return before `Rename-Computer` would ever be called, with or without `-Restart` (2026-08-26).
- [ ] Rename Computer works end-to-end on an authorized test device, in both the Restart Later and Restart Now paths. Deliberately not exercised by the automated tests above: this action renames the real machine and, in the Restart Now path, restarts it immediately, so it was left for a human to run intentionally.
- [ ] Create Local Standard User works end-to-end, including password entry via the masked password fields, on an authorized test device. Deliberately not exercised by the automated test above: this action creates a real local Windows account, so it was left for a human to run intentionally.
- [ ] Create Local Standard User with No Password selected works end-to-end on an authorized test device, and the resulting account can sign in locally at the console (deliberately not exercised by automated tests, for the same reason as above)
- [ ] Password is not displayed, logged, or persisted anywhere during GUI-based user creation
- [x] Added a Set Password / No Password choice to Local Standard User, so an account can be created with a genuinely blank password instead of always requiring one. `New-DeploymentLocalStandardUser` (`LocalUserConfiguration.ps1`) takes a new `-NoPassword` switch that maps to `New-LocalUser`'s own `-NoPassword` parameter (verified real via `(Get-Command New-LocalUser).Parameters.Keys` and its parameter sets before using it -- it is its own parameter set, mutually exclusive with `-Password`, matching how the code now only ever sets one or the other in the splat). Left unset (the default), behavior is unchanged -- a password is required, matching before. The success message and deployment log both note when an account was created without one, and warn that Windows' default policy ("Limit local account use of blank passwords to console logon only") restricts a blank-password account to signing in at the console, not over the network (RDP, file sharing, etc.) -- a real, documented Windows behavior, not specific to this tool, included so a technician isn't surprised later. The console wizard (`Start-LocalStandardUserWizard`) now accepts an empty password entry as "create with no password" and skips the confirmation-match prompt in that case. The GUI Local Standard User card gained a "PASSWORD" segmented toggle (`SetPasswordOption` / `NoPasswordOption`, same visual pattern as the Restart Later/Now toggle); selecting No Password collapses the Password/Confirm Password fields entirely (reclaiming the vertical space rather than just greying them out) and shows a short notice about the console-only restriction above. Verified via the real end-to-end harness: the toggle's default state is correct (Set Password highlighted), clicking No Password collapses the fields and shows the notice, clicking Set Password again restores them, and a rendered screenshot of the real running card confirms the layout (2026-08-26). Also verified via `-WhatIf` that `-NoPassword` binds correctly and that omitting both `-Password` and `-NoPassword` now returns a clean `Failed` result ("A password is required unless creating the account without one.") instead of reaching `New-LocalUser` at all (2026-08-26).
- [x] Fixed a pre-existing crash, found while testing the above: `Test-DeploymentLocalUserName`, `Test-DeploymentComputerName`, and `Test-SleepTimeoutMinutes` all declared their input as `[Parameter(Mandatory)][string]`, with no `[AllowEmptyString()]`. PowerShell's own mandatory-parameter binder rejects an empty string before the function body ever runs, so clicking Create User, Rename Computer, or Apply Power Settings with a field left genuinely empty threw `Cannot bind argument to parameter '...' because it is an empty string` instead of reaching each function's own (correct) "cannot be empty" / "must be a whole number" message -- previously surfacing as a generic "X error: Cannot bind argument..." dialog rather than a helpful one. This predates this session's changes; it was simply never exercised with a truly empty field before. All three now declare `[AllowEmptyString()]` alongside `[Parameter(Mandatory)]`, letting their existing `IsNullOrWhiteSpace`/`TryParse` checks run and return their intended friendly message. Verified directly (bypassing any dialog/window) that all three empty-field paths now produce the correct message instead of throwing: username -> "The username cannot be empty.", computer name -> "The computer name cannot be empty.", power timeout -> "Plugged-in sleep timeout must be a whole number." (2026-08-26)
- [ ] Apply Power Settings works end-to-end on an authorized test device. Deliberately not exercised by the automated test above: this action changes the real machine's power-plan timeouts, so it was left for a human to run intentionally.
- [x] Added a Lenovo Asset ID card to Windows Setup, ThinkPad-only. A new catalog entry ("Lenovo Windows Asset ID Utility", `InstallType: Exe`, `Installers\EXE\ThinkPadAssetID\giaw03ww.exe`, `DetectionPath: C:\DRIVERS\WINAIA\WinAIA64.exe`) installs Lenovo's WinAIA (Windows Asset ID Access) utility, which reads/writes a handful of BIOS asset-tracking fields via a `Sample.txt` template. A new module `Windows\LenovoAssetId.ps1` (added to `$ModulePaths`, module count 46->47) provides `Get-DeploymentAssetIdFields` (reads current values from `Sample.txt`), `Set-DeploymentAssetIdFields` (writes ONLY the 11 supported fields -- Owner Name/Department/Location/Phone/Position, Purchase Date/Last Inventoried/Warranty End/Warranty Duration/Amount/Asset Number -- in the exact key order and owner/blank-line/asset grouping the user had already hand-tested and confirmed works with WinAIA's `-set-from-file`, discarding every other field WinAIA's own template ships with), and `Invoke-DeploymentAssetIdWrite` (launches `WinAIA64.exe -set-from-file Sample.txt`, the exact command confirmed by hand-testing, with the working directory set to `C:\DRIVERS\WINAIA`). `Get-WindowsConfigurationIdentity`/`Get-WindowsConfigurationReport` gained an `IsThinkPad` field, computed as `Manufacturer -eq "LENOVO" -and SystemFamily -match "ThinkPad"` -- verified on this real Lenovo dev machine first that `Win32_ComputerSystem.Model` is only a raw machine-type code ("21SR0038PH"), not a usable product name, while `SystemFamily` correctly holds "ThinkPad E16 Gen 3", before relying on it. Per explicit instruction, the card is fully hidden (not merely disabled) on any non-ThinkPad device, reusing the same `Collapsed`-vs-`Visible` pattern as the Restart/Password toggles elsewhere on this screen. The card is pre-filled with whatever is already in `Sample.txt` when the screen loads (same "show current state before editing" pattern as every other card here), and `Invoke-GuiAssetIdSave` confirms (`Show-GuiDialog`, Warning/YesNo, explicitly stating that WinAIA will open its own separate confirmation window that this tool cannot and does not try to click through on the technician's behalf) before writing the file and launching WinAIA (2026-08-27).
- [x] **Caught and corrected mid-session: an early test accidentally ran the real WinAIA against this real dev machine.** Before the test harness redirected `Get-WinAiaExecutablePath`'s target directory to an isolated fake path, `Invoke-DeploymentAssetIdWrite` was called once with the default `C:\DRIVERS\WINAIA` directory -- which turned out to already have WinAIA genuinely installed on this dev machine, with a real, previously-populated `Sample.txt` (real name, department, asset number, warranty dates). The call ran `WinAIA64.exe -set-from-file Sample.txt` for real, with `-Wait`, against that real (but untouched-by-this-session) file, and returned exit code 0 with no visible dialog. The user confirmed immediately afterward that their asset data still looked correct and that no WinAIA dialog had appeared -- consistent with this sandboxed shell context lacking an interactive desktop session for WinAIA's confirmation window to render on, not with anything having actually been committed to BIOS. No data was at risk regardless, since the file WinAIA read from had not been modified by anything in this session before that call. All testing after this point double-checked that any function able to reach a real path was redirected to an isolated fake directory first.
- [x] **Discovered mid-session: every earlier fit measurement this session under-counted real content height**, because `Show-MainWindow` applies the bundled Nunito variable font (loaded from `Modules\Gui\Fonts`), while every prior `XamlReader.Load`-based fit probe this session (including the ones recorded above for the tab split, Restart toggle, and No Password toggle) implicitly fell back to Segoe UI, which renders shorter. Confirmed directly: the same Windows Setup layout measured 19.1px of spare margin under Segoe UI, but only 7.8px under the real Nunito font with otherwise-identical (empty) content -- and once populated with this machine's actual real field data (a real local user already named "Testing", real 20+ character asset values), the real font plus real content combination briefly reintroduced actual scrolling. The Asset ID card's grouped fields were restructured from 2 sub-columns per group (tallest column 3 fields) to 3 sub-columns per group (tallest column 2 fields) specifically to recover real margin under the real font, not just the fallback. Final measurement, with the real Nunito font, real ThinkPad field data, and the real existing "Testing" user all loaded through the actual `Show-MainWindow` end to end: **686.7px content vs. 708.85px viewport, 22.2px spare.** This is real margin, not a hand-probe estimate, but it is below the ~50px this session has otherwise treated as the safe floor, so this specific screen is the one most likely of everything touched this session to need a further pass if a real device (different DPI, more existing local users, longer real field values) reintroduces scrolling. Every other screen's margin recorded elsewhere in this document was NOT re-verified under the real font; Device Details was spot-checked and remains comfortably safe (341px spare) even under Nunito.
- [ ] Windows Setup, with the Asset ID card visible, renders on an authorized ThinkPad test device with no scrollbar. Given the 22.2px margin above, this is the single most important remaining visual check from this session.
- [ ] Save Asset ID has never been clicked for real, on any device. `Invoke-GuiAssetIdSave`'s own logic was verified directly (with `Set-DeploymentAssetIdFields`/`Invoke-DeploymentAssetIdWrite`/`Show-GuiDialog` all stubbed out, so nothing real was touched): it confirms before doing anything, calls `Set-DeploymentAssetIdFields` with the right data, calls `Invoke-DeploymentAssetIdWrite`, and shows the right result dialog; declining the confirmation stops before either real call. What remains unverified is the real, live sequence: does clicking Save actually produce a correct `Sample.txt`, does WinAIA's own confirmation window appear and accept it, and does the asset data actually end up in BIOS. This needs a real ThinkPad with WinAIA installed and a technician willing to click through the real WinAIA dialog.
- [ ] `giaw03ww.exe`'s `SilentArguments` is left empty (interactive install), matching the existing SAP GUI catalog entries, since its actual silent-install switch (if one exists) was not provided. If Install Selected on this catalog entry should run unattended, this needs a real, confirmed switch, not a guess.
- [ ] `Set-DeploymentAssetIdFields` writes plain ASCII with no BOM, a judgment call (this is an old-style Windows config text format, and a stray UTF-8 BOM is a common way to break a simple line-by-line parser) rather than something confirmed against WinAIA itself. If WinAIA rejects or misreads the file, encoding is the first thing to check.
- [ ] WinAIA's own exit-code semantics were not confirmed by hand-testing (only that admin rights are required). `Invoke-DeploymentAssetIdWrite` currently treats exit code 0 as success and anything else as failure, the conventional default, not a verified fact about this specific tool.
- [ ] TPM readiness (`Ready 2.0` / `Not Ready`) has not been confirmed on an elevated real-device run. The end-to-end test above ran non-elevated (as this environment cannot grant UAC elevation) and correctly showed `Not Available`, matching the code's documented fallback for that case, but the actual `Ready`/`Not Ready` path is unverified.
- [x] Copy Device Details (now on the Device Details toolbar) still copies the full 18-field summary to the clipboard, including the 4 new Hardware fields -- verified via the real end-to-end run above, exact match against `Get-GuiDeviceDetailsSummary`'s format (2026-08-26)
- [x] Added a Hardware group (Processor, Memory, Storage, TPM) to the Session & Hardware card, filling the gap flagged when the tab split first shipped: the mockup's Hardware tile was speculative because none of those fields existed in `Get-WindowsConfigurationReport`. Implemented in `WindowsConfiguration.ps1`: Processor and Memory are added to the existing cached `Get-WindowsConfigurationIdentity` (Win32_Processor.Name, and the sum of `Win32_PhysicalMemory.Capacity` rather than `Win32_ComputerSystem.TotalPhysicalMemory`, since the latter can under-report versus installed capacity) since neither changes during a session; Storage is queried fresh on every report via a new `Get-WindowsConfigurationStorage` (`Win32_LogicalDisk` for `$env:SystemDrive`), since free space changes as this tool installs applications; TPM state comes from `Win32_Tpm` in the `root\cimv2\Security\MicrosoftTpm` namespace, queried with `-ErrorAction SilentlyContinue` since a VM without a virtual TPM, a device with no TPM chip, or an access-denied policy must degrade to "Not Available" rather than throw. TPM renders as a colored pill (green "Ready 2.0" / gray "Not Ready" or "Not Available") matching the existing Administrator pill pattern. Verified against real hardware CIM queries on this dev machine before writing any GUI code (Processor: "Intel(R) Core(TM) Ultra 5 225U"; Memory: 16 GB; Storage: "315 GB free of 475 GB"; TPM: "Not Available" when queried non-elevated, consistent with `Get-CimInstance` returning null rather than throwing under `SilentlyContinue`) (2026-08-25). Re-measured Device Details after adding the group: the Session & Hardware card grew from 352.8px to 354.5px and is now marginally the taller of the two cards, but the screen still fits with 347.6px of spare room (2026-08-25). Real TPM readiness has NOT been confirmed on an elevated real-device run, since this was only tested non-elevated in this environment.
- [x] Fixed: a real device screenshot showed the three Windows Setup cards (Computer Rename / Local Standard User / Power & Sleep) and the two Device Details cards (Identity & System / Session & Hardware) at visibly different heights. Cause: each card's outer `Border` had `VerticalAlignment="Top"`, so it only grew to its own content height inside a Grid row that already auto-sizes to the tallest card in the row, instead of stretching to fill it. Removed `VerticalAlignment="Top"` from all five so they default to `Stretch`; this does not change either row's computed height (still driven by the tallest card's natural content), only how the shorter cards fill it, so it should not affect the fit margins recorded below. Verified via `-ValidateOnly` and an off-screen `XamlReader.Load` parse+`FindName` check; not re-screenshotted on a real device this pass.
- [x] Fixed: the "EXISTING" local-user list reused `New-GuiValidationStatusRow` from the Deployment Validation screen, whose 220px fixed name column and remaining `*`-width detail column were sized for that screen's full-width rows. Squeezed into the much narrower Local Standard User card, a user's full name was left only a few pixels of width and wrapped letter by letter (e.g. "Testi"/"ng"), confirmed by a real device screenshot. Replaced with a new `New-GuiLocalUserRow` (`GuiWindowsConfigScreen.ps1`), purpose-built for this card: an ACTIVE pill and the username on one line, with the detail text (full name) stacked on its own line below using the card's full available width, instead of a fixed column. Verified via `-ValidateOnly` and XAML parse+`FindName`; not yet re-screenshotted on a real device.
- [x] Restyled the "No Password" notice, per feedback that the No Password state "wasn't very good to look at": it was a bare gray `TextBlock` with no visual container, inconsistent with the rest of the app's card language. Replaced with `NoPasswordNoticeBox`, a bordered advisory box (small warning-triangle icon + the same message) using this app's only established warning tone (`#F2555A`, translucent tints), matching `Show-GuiDialog`'s Warning icon. `Set-GuiCreateUserPasswordChoice`'s `-NoticeText` parameter is now typed as a `Border` (was `TextBlock`) and toggles the whole box's `Visibility`. Since No Password mode already removes the Password/Confirm Password fields (~106px) that Set Password mode shows, the new box is still shorter overall than the Set Password state this screen's fit margin was verified against below, so this should not reintroduce scrolling. Verified via `-ValidateOnly` and XAML parse+`FindName`; not re-verified through the real end-to-end harness.
- [x] Fixed: on a real ThinkPad, the Asset ID card did not appear on the first view of Windows Setup, but toggling Set Password/No Password or switching tabs away and back made it appear -- reported directly by the user. Reproduced off-screen against the real, unmodified code: the background load (CIM/BIOS queries, reading `Sample.txt`) took several seconds to complete, and during that whole window the screen was already fully visible with stale "-" placeholders and the ThinkPad-only card sitting `Collapsed` (correct, since `IsThinkPad` isn't known yet) -- indistinguishable from "this isn't a ThinkPad" until the load actually finished. There was no rendering bug: once traced correctly (an earlier attempt wrongly concluded `Visibility` was stuck, before finding the test itself had skipped making `WindowsSetupScrollViewer` visible, unlike the real `Switch-GuiScreen`), `Visibility`, `IsVisible`, and `ActualHeight` all update correctly and immediately the moment the load completes. Fixed by hiding the whole screen (`$ScrollViewer.Opacity = 0`) for the duration of the load instead of showing it immediately with incomplete data, letting the existing `Start-GuiFadeIn` reveal it once, fully populated, rather than flashing hidden-then-visible at the end on top of already-visible stale content. Toggling Set/No Password or switching tabs never actually changed anything about the Asset ID card itself; the user was just naturally waiting long enough between actions for the background load to finish, which made it look like those actions were the cause. Verified via a corrected off-screen repro (real code, real ThinkPad data, `WindowsSetupScrollViewer` properly made visible first): the card now stays hidden throughout the load and appears correctly with real height (181.85px) the moment data arrives, with no regression (2026-08-28).
- [x] Fixed a second, related bug found while investigating the one above: the background-load completion handler (the screen's *first*-load path) still built the "EXISTING" local-user list with the old `New-GuiValidationStatusRow` (the fixed-220px-column row from the Deployment Validation screen), even though the Refresh-button path was already switched to `New-GuiLocalUserRow` earlier. This meant the "Testi"/"ng" letter-by-letter wrapping bug was still fully present on a screen's first load and only fixed after clicking Refresh. Now uses `New-GuiLocalUserRow` in both places (2026-08-28).
- [x] Second design pass on Windows Setup, this time against real screenshots the user sent from their actual device (not just described feedback): (1) the three top cards and the "not equally separated" complaint was really about dead space, not height -- an earlier fix already made all three cards stretch to equal height, but a shorter card (Computer Rename, Power & Sleep) just left a large empty gap between its content and the bottom of the card, which read as unbalanced rather than intentional. Fixed by restructuring each card's `Border` from a single `StackPanel` to a `DockPanel` with its primary button `DockPanel.Dock="Bottom"` and the rest of the content as the fill element above it -- the button now always sits at the same anchored position at the bottom of the card regardless of how much content precedes it, and any leftover space collects as one deliberate gap above the button instead of scattered dead space. (2) A real bug the screenshot caught directly: the No Password notice's red box wrapped its icon and text in a horizontal `StackPanel`, which gives children unconstrained width -- `TextWrapping="Wrap"` on the `TextBlock` never actually had anything to wrap against, so the text ran on and was clipped at the card's edge ("...By default, Wind"). Fixed by switching to a `Grid` with an `Auto` icon column and a `*` text column, which actually constrains the text and lets it wrap. (3) Redesigned the Lenovo Asset ID card again, since the previous pass (below) had been trimmed back hard enough to stay within a ~50px-under-budget margin that no longer matched what the user was asking for: full `16` padding (was `14,8`), larger field-group gaps (padding `8,3` and margin `0,3,0,7`, was `8,2`/`0,2,0,4`), and a real vertical divider line between the OWNER DATA and ASSET DATA groups instead of just a blank gap column, addressing the "spacing of each containers" feedback directly by giving the two groups an actual visual boundary. This cost real height again: re-measured at 40.5px overflow (worst-case: 2 local users, full ThinkPad field data) against the same off-screen harness, trimmed back through a couple of cheap, non-visual-impact margin cuts (header/divider/button spacing only, not the padding or field gutters that were the actual point of the pass) to **34.5px overflow**. Unlike the first pass, this one was deliberately NOT trimmed all the way back to zero -- the user has now asked for genuinely better spacing twice, so a modest scrollbar in the worst case is treated as an acceptable, correct tradeoff rather than something to eliminate at the cost of undoing the redesign. Not yet confirmed on a real device (2026-08-28).
- [x] **Corrected a real mistake from the previous pass**: it had accepted a growing scrollbar (1.5px, then 34.5px, then 44.4px overflow across three rounds) as a fair tradeoff for better spacing, on the assumption that a bit of scroll was harmless since the screen already has a `ScrollViewer`. The user corrected this directly: no-scroll on this screen is a hard requirement, not something to trade away unilaterally. Fixed with a real structural change rather than more margin-trimming: the Owner Data/Asset Data grid went from 2 fields stacked per column (2 rows tall) to 1 field per column (1 row tall, 11 columns total -- 5 for Owner Data, 6 for Asset Data), which roughly halves that grid's height. Asset Data's field labels dropped their repeated `(YYYYMMDD)`/`(MONTHS)` suffixes (folded into the card's existing "All fields optional" subtitle as "dates as YYYYMMDD" instead) and shortened to fit the narrower single-row columns (e.g. "PURCHASE DATE" instead of "PURCHASE DATE (YYYYMMDD)"). This also fixed the "each container has not equal spacing" feedback at its root: with the freed-up budget, Asset ID's header/divider margins were brought to the exact same `0,0,0,10` used by the other three cards (previously `0,0,0,5`/`0,0,0,8`, a real inconsistency), and Local Standard User's field padding/margins (previously `12,5`/`0,2,0,5`, different from Computer Rename and Power & Sleep's `12,6`/`0,3,0,X`) were brought in line with its siblings too. Re-measured through several rounds against the same off-screen, real-font harness: first attempt at the single-row restructure actually made things *worse* (49.4px overflow) because a 6th Asset Data field and a new hint line were pushed into an extra second row, mostly cancelling out the savings -- caught by re-measuring rather than assuming the structural change alone was enough. Fixed by fitting all 6 Asset Data fields into the single row (not 5 plus a leftover 6th on its own row) and removing the extra hint line entirely. That alone got to 708.61px content vs. 708.85px viewport (0.24px spare -- fits, but too thin to trust), so several more small, real trims followed (icon badge 24px->20px, field padding 8,3->8,2, section label margins 4->3, a couple of button/field margins by 1-2px each) landing at 698.61px content, a genuine 10.24px of spare room -- thin by this app's historical ~50px safe-floor standard, but real, verified, and zero-scroll, which is what was actually required (2026-08-28).
- [x] **Reverted the equal-height card stretching** (`VerticalAlignment="Top"` re-added to the three Windows Setup cards, undoing the very first fix made to this screen this session). Real feedback via a screenshot: stretching Computer Rename and Power & Sleep to match Local Standard User's height (the tallest, since it shows the most content) left a large, obviously empty gap between their last field and their bottom-docked button -- the DockPanel button-anchoring from earlier moved that dead space into one place but never actually removed it. Worse, since all three cards were stretched to match whichever one was currently tallest, toggling Local Standard User's Set Password/No Password option (which shows or hides two password fields) visibly resized all three card borders at once, not just the one card whose content actually changed. Both problems trace back to the same cause: forcing unrelated cards to share a height driven by one card's variable content. With `VerticalAlignment="Top"` back, each card sizes to its own natural content again -- no forced dead space, and toggling the password option now only affects Local Standard User's own card. This does mean the three cards can show slightly different heights when their content genuinely differs, which is a normal, acceptable property of a card layout as long as the spacing *conventions* inside each card stay consistent (which the padding/margin audit above already fixed) -- it is not the same problem as the original "not equally separated" complaint, which was really about inconsistent spacing values, not differing natural heights. Confirmed this change is purely a rearrangement, not a height change: the Windows Setup screen's overall fit is unaffected (still 698.61px content vs. 708.85px viewport, the same 10.24px margin measured for the previous fix, since Grid row height is driven by the tallest child's natural size regardless of how the other children are aligned within it) (2026-08-28).
- [x] **Lenovo Asset ID promoted to its own sidebar tab**, per explicit direction: "if the device that uses this is a thinkpad lenovo the lenovo asset id setup wont appear inside the windows setup, instead it will create a new tab for it to edit and save the asset id. And if its not lenovo thinkpad device it wont appear of course." Added a new sidebar nav item (`NavAssetId`), toolbar (`AssetIdToolbar`), and content area (`AssetIdScrollViewer`), following the exact same pattern every other tab already uses. `NavAssetId` starts `Visibility="Collapsed"` in XAML (matching the old card's own starting state) since `IsThinkPad` isn't known until the shared Windows Setup/Device Details background load completes; `Update-GuiAssetIdDisplay` now toggles `NavAssetId.Visibility` instead of a card buried inside another screen. `Switch-GuiScreen`'s Windows Setup/Device Details branch was extended to a third case for `"Asset ID"`, sharing the same background load and Refresh-button-group as before (now three buttons, not two) rather than duplicating the CIM/BIOS/`Sample.txt` query a third time. The card itself dropped its accent-blue border, icon-chip badge, and "THINKPAD" pill from the last redesign pass -- those existed specifically to make it stand out while sharing a screen with three unrelated cards; now that it has its own tab with its own toolbar already saying "Lenovo Asset ID", repeating that identity on the card itself was redundant, so it now matches Device Details' plain card style instead. Verified via `-ValidateOnly`, an XAML parse+`FindName` check (all new elements resolve, no stale `AssetIdCard` references remain anywhere in `Modules\Gui\`), and a real off-screen fit measurement of both affected screens with real ThinkPad field data and two local users: Windows Setup dropped from a razor-thin ~10px margin (when it still had to share its budget with the Asset ID card) to a comfortable 237px now that the card is gone, and the new Asset ID tab measured 176px content against a 687px viewport (510px spare) entirely on its own. A live click-through end-to-end test (real `Show-MainWindow`, clicking `NavAssetId`, confirming the tab actually shows with real data) was attempted via the same off-screen harness used earlier this session but did not complete in a reasonable time in this environment and was abandoned in favor of the structural verification above; the navigation wiring itself (`Switch-GuiScreen`, the new click handler, the shared background-load branch) was not exercised live. This needs a real click-through on a real device.
- [x] **Reverted equal-height card stretching for the second time**, this time deliberately requested back: "what i want is the 3 top card is in equal height wi appropriate button position." Re-removed `VerticalAlignment="Top"` from the three Windows Setup cards (restoring the `Stretch` default), and separately made Local Standard User itself more compact so equal-height stretching creates less dead space in its shorter siblings: Username and Full Name now sit side by side in a 2-column `Grid` instead of stacked, saving one full field-row of height. This directly answers "adjust the local standard user on what is the better way to handle that since it eats a lot of space" -- rather than only redistributing dead space (the DockPanel bottom-anchoring from earlier), the tallest card is now genuinely shorter than it was. Verified via `-ValidateOnly` and XAML parse; the real fit numbers above already reflect this (237px spare on Windows Setup, using the same real-font, real-data harness) (2026-08-28).
- [x] **Fixed a severe performance regression introduced by the entry just below this one**, per direct feedback that the tool's data loading felt slow. Measured directly against this real machine before assuming anything: `Get-PhysicalDisk` took ~4.1s per call, and had been added as a **fresh query inside `Get-WindowsConfigurationReport`**, meaning every single Refresh click (or first navigation into Windows Setup/Device Details/Asset ID) paid an extra ~4 real seconds on top of everything else -- `Win32_Tpm`'s pre-existing ~5s cost was already correctly cached and only paid once, but this new one was not. Fixed by moving it into the cached `Get-WindowsConfigurationIdentity` block alongside Manufacturer/Model/TPM, matching that block's own existing rule ("cannot change while this tool is running") -- disk media type fits that rule exactly as well as everything already there. Re-measured: warm calls (Refresh button, or any repeat query) dropped dramatically, roughly an order of magnitude faster; the cold first-navigation cost (dominated by TPM + the one-time Software Licensing query, real Windows API latency that scripting can't reduce further) is unchanged but is now paid exactly once per session instead of on every refresh. Real values confirmed unchanged after the refactor (Storage still "311 GB free of 475 GB (SSD)", Asset Tag still "NFPI-00000017", Activation still "Licensed"). Verified via `-ValidateOnly` and direct, repeated, real timing of `Get-WindowsConfigurationReport` (not simulated) (2026-08-28).
- [x] **Dropped BitLocker entirely and added Secure Boot, Windows Update, and Battery Health**, per explicit instruction ("just drop the feature on bitlocker since its dead weight ringht now and if you think you can add a few data for it just go") after the open question above about BitLocker's real usefulness. Removed `BitLockerStatus`/`BitLockerStatusPill` from the cached Identity block, the Session & Hardware HARDWARE group (Border pill row), `GuiWindow.ps1`'s field hashtable, both `Update-GuiWindowsConfigDeviceInfo` population paths, and `Get-GuiDeviceDetailsSummary`'s clipboard output -- confirmed via a repo-wide grep that no `BitLockerStatus`/`BitLockerStatusPill` reference remains anywhere in `Modules\`. Added three real replacements, each timed directly against this real machine before writing any code: Secure Boot status (`Confirm-SecureBootUEFI`, cached in Identity alongside TPM -- fails fast at ~180ms on this non-elevated shell with "Access denied", unlike BitLocker's slow ~5.8s failure, so keeping it costs nothing meaningful even when it can't answer; rendered as a pill in the HARDWARE group, reusing BitLocker's old row slot), Windows Update / Last Update Installed (`Get-HotFix | Sort-Object InstalledOn -Descending | Select -First 1`, cached in Identity, ~3s one-time cost; rendered as plain text in the Identity & System SYSTEM group, real value "KB5121003 (2026-08-12)"), and Battery Health (`Win32_Battery` as a fast ~600ms pre-check for "no battery present" on a desktop, then `powercfg.exe /batteryreport /xml /output <path>` via `Start-Process -ArgumentList @(...) -Wait` -- an initial attempt using an inline argument string instead of an argument array produced an unrelated, confusing error about a protected system path being blocked for removal, fixed by switching to `Start-Process` with a proper `-ArgumentList` array -- parsing `DesignCapacity`/`FullChargeCapacity` from the report XML, cached in Identity, ~1.3s one-time cost; rendered as plain text in the HARDWARE group, real value "105% of design capacity" on this machine's battery, displayed as-is rather than clamped to 100% since that is a legitimate reading). All three verified against real hardware via `Get-WindowsConfigurationReport` run standalone before any GUI wiring, and the console-mode report (`Show-WindowsConfigurationReport`) was updated to match. Re-verified the earlier performance fix held with these three new cached fields added: warm calls measured 415ms (previously 320-415ms with BitLocker/PhysicalDisk alone), confirming no new per-refresh cost was introduced -- all three new queries run once per session inside the existing cached Identity block, same as Manufacturer/Model/TPM. Both `Update-GuiWindowsConfigDeviceInfo` population paths (the synchronous refresh path and the background-load completion handler) and the clipboard summary were updated together, since a past entry in this document already found and fixed exactly this kind of two-path drift once before, for the local user list. Re-measured Device Details' fit with the net +2 rows (-1 BitLocker, +1 Secure Boot in HARDWARE, +1 Battery Health in HARDWARE, +1 Last Update in SYSTEM): 535.82px content vs. 700.85px viewport, 165.03px spare -- down slightly from the previous 187px but still comfortably fits with no scrolling. Verified via `-ValidateOnly`, XAML parse+`FindName` (all new element names resolve, no stale BitLocker names remain), and the same off-screen real-font fit harness; not yet seen on a real screen (2026-08-28).
- [x] **Added six new Device Details fields**, per feedback that the screen had "too little details and data": BIOS Version and Asset Tag (Identity & System card, IDENTITY group -- Asset Tag in particular ties naturally to the Lenovo Asset ID tab, and on this real dev machine already shows the real "NFPI-00000017" value WinAIA previously set), a new NETWORK group (IP Address and MAC Address, alongside the existing Network Type) since actual network identity wasn't shown anywhere before, Activation status as a colored pill matching the Administrator pill's pattern (Identity & System card, SYSTEM group -- Windows-only, isolated via the real, documented Software Licensing Application ID `55c92734-d682-4d71-983e-d6ec3f16059f` so a device with Office also installed doesn't pick up its separate Office licensing entry instead), disk type folded into the existing Storage line rather than a new row (`Get-PhysicalDisk`'s `MediaType`, e.g. "311 GB free of 475 GB (SSD)"), and BitLocker protection status as a pill matching TPM's (Session & Hardware, HARDWARE group). All six verified directly against this real machine's real hardware (`Get-WindowsConfigurationReport` run standalone, read-only, no GUI): BIOS Version "R30ET35W(1.09 )", Asset Tag "NFPI-00000017", Activation "Licensed", IP Address "10.61.2.94" (correctly filtered to IPv4 only out of the adapter's combined IPv4+IPv6 address list), MAC Address "38:18:68:37:65:C2", Storage now "311 GB free of 475 GB (SSD)". BitLocker returned "Unknown" on this dev machine -- both `Get-BitLockerVolume` and the underlying `Win32_EncryptableVolume` WMI query returned "Access denied" even though this session reports administrator group membership, which suggests BitLocker queries need a real elevated token (the kind this tool's own real GUI session gets via its UAC elevation prompt) rather than just group membership; degrades to "Unknown" on any failure, the same pattern already established for TPM, so this is a real, working fallback rather than a crash, but the actual "On"/"Off" states have not been observed for real. The synchronous refresh path, the background-load completion handler (a past session already found and fixed one instance of these two paths drifting out of sync, for the local user list), the console-mode report, and the "Copy Device Details" clipboard summary were all updated together so none of the four surfaces are missing the new fields. Re-measured the real fit impact of the new NETWORK section and the 4 extra IDENTITY/SYSTEM rows: Device Details went from its earlier ~340-510px of spare margin down to 187px (513.77px content vs. 700.85px viewport) -- still comfortably fits with no scrolling, just less headroom than before for whatever comes next. Verified via `-ValidateOnly`, XAML parse+`FindName`, and the same off-screen real-font fit harness; not yet seen on a real screen (2026-08-28).
- [x] **Confirmed working on a real device**: the user reported "ok its separated now" after actually running the app -- the new Asset ID tab, its conditional ThinkPad-only visibility, and the navigation wiring (`Switch-GuiScreen`, the click handler, the shared background load) all work for real, closing the one gap flagged in the previous entry (the live click-through test that wouldn't complete in this environment).
- [x] **Redesigned the Asset ID card again**, per a real screenshot from that same device showing three concrete problems: (1) "Lenovo Asset ID" appeared twice, once in the toolbar and identically again as the card's own title, immediately under it -- removed the card's redundant title entirely, since the toolbar already establishes it and this is the only card on the page. (2) The single-row, 11-narrow-column field layout from the previous pass was clipping real values ("VILLACORT" for "VILLACORTA, JOHN PAUL...", "IT ASSISTA" for "IT ASSISTANT", "NFPI-0000" for the full asset number) -- that compression existed specifically to survive Windows Setup's shared, nearly-zero height budget, which no longer applies now that Asset ID has its own dedicated tab with 450px+ to spare; reverted to 3 columns per group (Owner Data 2+2+1 fields, Asset Data an even 2+2+2) with real breathing room (padding 10,7, font size 13, matching the rest of the app's form fields), which gives every field several times the width it had and stops the clipping. (3) A large, oddly empty gap below the fields and above the Save button -- root cause was the same stretch-to-fill-container bug hit twice already this session on Windows Setup's cards, just newly visible here because this page finally has enough spare room to stretch into: the card's `Border` had no explicit `VerticalAlignment`, so it defaulted to `Stretch` and filled the whole `ScrollViewer` viewport instead of sizing to its own content. Fixed with the same `VerticalAlignment="Top"` fix as before. Re-measured through the same off-screen, real-font harness: Asset ID now measures 232px of real content (up from 176px, since two rows are taller than the compressed single row) against a 687px viewport -- 454px of spare canvas below the now-correctly-sized card, not inside it. Verified via `-ValidateOnly` and XAML parse+`FindName` (2026-08-28).
- [x] Third pass on the Lenovo Asset ID card: the second pass (above) only changed internal spacing, and the user clarified directly that the *container itself* needed to look different, not just its contents rearranged -- specifically "the whole card needs a different look" versus every other plain dark card. Gave it a deliberately distinct treatment reusing the app's one existing accent color rather than inventing a new one (this card genuinely is a different kind of thing -- a vendor-specific hardware feature that only exists conditionally, unlike the generic OS-configuration cards around it): a full accent-blue border (`BorderBrush="#5938BDF8"`, `BorderThickness="1.5"`) instead of the neutral gray `#2C2F38`/`1` every other card uses, the header icon moved into a 28x28 rounded chip badge (`Background="#2438BDF8"`, `CornerRadius="7"`) instead of sitting bare, and a small "THINKPAD" pill next to the title (same tinted-background/accent-text pill style already used for status pills elsewhere in this app, e.g. the Administrator/TPM pills on Device Details). This cost another ~10px (the chip badge is taller than the bare 16px icon it replaced): re-measured at 44.4px overflow, up from 34.5px after the second pass. Accepted without further trimming -- the user has now asked for real visual improvement on this card three times, so preserving the previous margin was no longer the right tradeoff. Not yet confirmed on a real device (2026-08-28).
- [x] Restyled the Lenovo Asset ID card, per feedback that it "wasn't very good to look at": it had noticeably tighter padding (`12,7` vs. every sibling card's `16`) and an inline title+subtitle crammed onto one line, unlike every other Windows Setup card's title-then-divider-then-description pattern. Increased padding, standardized the field-group margins (previously an inconsistent mix of `0,2,0,3`/`0,2,0,4`), and widened the column gutters slightly (10px/22px -> 12px/26px). This genuinely added height, so it was re-measured against the same off-screen, real-Nunito-font harness used to verify this screen before (real ThinkPad field values, two local users, one with a full name matching its username and one without, to also exercise the local-user-row fix above): first pass overflowed by 106px against the 708.85px viewport, entirely acceptable functionally (the screen already sits in a `ScrollViewer`, so overflow just adds a scrollbar rather than breaking anything) but a bigger regression than intended, so every added margin was trimmed back in several rounds against repeated real measurements down to a **1.5px overflow** -- keeping the padding and consistency fix while landing back within a hair of the previous no-scrollbar state. This is thinner than this screen's own ~50px safe-floor guidance and has not been confirmed on real hardware (2026-08-27). (44 call sites: `GuiWindow.ps1`, `GuiWindowsConfigScreen.ps1`, `GuiApplicationsScreen.ps1`, `GuiDeploymentLogsScreen.ps1`, `GuiDeploymentValidationScreen.ps1`) with a new `Show-GuiDialog` (`Gui\GuiDialog.ps1`, a new module, added to `$ModulePaths` right before `GuiIcons.ps1` since every other Gui module depends on it), per feedback that the plain white native Windows dialog looked out of place against this app's dark theme. Visually it reuses `CompletionModalOverlay`'s own established language (a dimmed backdrop, a centered rounded dark card) and its exact icon glyphs/colors: the circle-check in green for `-Icon Success`, the triangle-exclamation in red for `-Icon Warning` (this app's real semantic palette only has two non-neutral colors -- green for good, red for needs-attention-or-failed, confirmed by grep across `GuiDeploymentValidationScreen.ps1` -- so the same red icon covers both a confirm-before-you-proceed prompt and an outright error, there is no separate amber tone anywhere in this app to invent), and the circle-i already used for every Windows Setup/Device Details card header for `-Icon Info` (the default). `-Buttons OK` (default) or `-Buttons YesNo` returns `"OK"`/`"Yes"`/`"No"` as a plain string. Built as its own WPF `Window` (not an in-window overlay like `CompletionModalOverlay`) specifically so `ShowDialog()` still blocks and returns a result synchronously exactly like `MessageBox.Show` did -- every call site only needed its function name swapped and its result comparison changed from `[System.Windows.MessageBoxResult]::Yes` to `"Yes"`, with no calling code restructured into callbacks. A `$script:GuiMainWindow` reference (set once in `Show-MainWindow`) lets every call site omit an explicit `-Owner`. A `$script:GuiDialogResult` (not a function-local variable) carries the button choice back out of the Click handlers, for the same reason this app's other click handlers are written as plain, non-`.GetNewClosure()`'d scriptblocks: a plain assignment inside a nested handler's own scope would otherwise just shadow a local variable instead of writing back to it. A new `Show-GuiResultDialog` helper (`GuiWindowsConfigScreen.ps1`) maps the common `{Status, Message}` result shape (`Set-DeploymentComputerName`, `New-DeploymentLocalStandardUser`, `Set-DeploymentSleepTimeouts`) to the right icon/title automatically (`Failed` -> red/"Error", `Skipped`/`Preview Only` -> blue/info, anything else -> green/success) instead of repeating that mapping at each of its three call sites. Verified in stages: (1) `Show-GuiDialog` exercised in complete isolation off-screen -- all 4 icon/button combinations rendered correctly (screenshots confirmed the dark card, correct icon/color, correct button layout) and returned the correct string for every button clicked, via the real registered Click handlers; (2) confirmed via `Window.OwnedWindows` that the dialog is sized and positioned to exactly cover its owner, matching `CompletionModalOverlay`'s full-coverage dim-and-center approach; (3) exercised through the real, unmodified app end to end (real `Show-MainWindow`, real click handlers, off-screen) -- clicking Create User with every field empty correctly opened a real, nested `Show-GuiDialog` from inside the main window's own modal loop without deadlocking, was dismissed correctly, and the app kept working afterward (switching screens still worked) (2026-08-26). `-ValidateOnly` passes with 46 modules and 25 required functions (adds `Show-GuiDialog` to the required-functions list). Not yet seen on a real monitor -- the dimmed-backdrop-over-real-content effect specifically (this session's screenshots necessarily show it over a plain grey test background instead of the actual app UI, since the render captures only the dialog's own content) is worth a quick look on real hardware.

### Deployment Distribution

- [x] `Deploy.ps1` (repo root, not part of `$ModulePaths`) downloads the tracked repo contents (scripts and `Config\Applications.json`, a few MB -- gitignored `Installers\` binaries are never part of this) from the public GitHub repo as a ZIP, extracts it to `Desktop\IT Deployment Tool`, and launches `Start.ps1 -Gui`, so a technician at a remote device can run one `irm ... | iex` line instead of manually copying files. Verified for real: the download returns HTTP 200, extraction produces the expected `Start.ps1`/`Modules`/`Config\Applications.json` layout, and `.\Start.ps1 -ValidateOnly` passes on the freshly downloaded copy.
- [x] Checked whether the final launch line (`& Start.ps1 -Gui`) could fail on a device whose PowerShell execution policy blocks unsigned local scripts -- a real possibility since a genuinely fresh, untouched Windows machine defaults to "Restricted" (blocks all scripts) for `LocalMachine`. First checked whether `Invoke-WebRequest`'s downloaded ZIP (and the files `Expand-Archive` extracts from it) carry Windows' "Mark of the Web" the way a browser download would -- confirmed directly against a real download of this repo's own ZIP that neither the ZIP nor the extracted `Start.ps1` have a `Zone.Identifier` alternate data stream, so that specific concern does not apply to this bootstrap mechanism. The `Restricted`-policy case remains real, though, so the launch line now uses `powershell.exe -ExecutionPolicy Bypass -File ... -Gui` instead of the bare `&` call operator -- this overrides the policy for only that one launched process, without changing the device's actual persistent setting. Verified the new invocation syntax works correctly (arguments forward properly) by running it against the real `Start.ps1 -ValidateOnly` on this dev machine (2026-08-27).
- [x] Added `Import-CloudInstallers.ps1` (repo root, also not part of `$ModulePaths`) to solve the other half of remote deployment: the company OneDrive/SharePoint tenant disables "anyone with the link" sharing, and there is no Azure AD app registration for unattended Microsoft Graph access (confirmed not realistic for this deployment -- would require a company Azure AD admin to register an app, grant it `Sites.Selected` permission, and hand over a client secret/certificate this tool would then have to protect), so per-application automatic fetch-on-selection from OneDrive is not achievable. The realistic flow instead is: a technician signs in once per device (recommended: an incognito/InPrivate browser window, which clears the session on close; a plain sign-out does not reliably clear an Edge/WAM-broker-added Windows account, so decline any "stay signed in to all your apps" prompt), opens the shared folder, and downloads the individually-zipped installer folders (the user's chosen upload convention, one ZIP per app/subfolder rather than one combined ZIP or raw files). `Import-CloudInstallers.ps1` automates everything after that download: it reads `Config\Applications.json` (the same source of truth the app itself uses, so this never duplicates catalog data), builds a match-key lookup from every configured `InstallerPath`/`UninstallerPath` (matching a ZIP's filename against either the installer's own subfolder name, e.g. `CrowdStrike.zip`, or the application's `Name`), special-cases the three applications that have no `InstallerPath` in JSON because their installer modules resolve a hardcoded package directory instead (`CrowdStrike` -> `Installers\EXE\CrowdStrike`, matching `Get-CrowdStrikePackageDirectory`; `OfficeIso` -> `Installers\ISO\Office2024`, matching `OfficeIsoInstaller.ps1`; `Office2021Img` -> `Installers\IMG\Office2021LOP`, matching `Office2021ImgInstaller.ps1`), then extracts each matched ZIP into its correct destination and reports any ZIP it could not match by name so nothing is silently misplaced. A generic top-level type folder (`EXE`/`MSI`/`ISO`/`IMG`/`ZIP`/`Scripts`) is deliberately never used as a match key on its own, since several unrelated applications share those. First version computed the destination as the installer file's own immediate parent folder, which broke for SAP: both SAP GUI catalog entries nest their real `.exe` several vendor-extracted levels below `Installers\EXE\SAP\` (e.g. `.../GUI/Windows/Win32/SapGuiSetup.exe`), so the immediate parent was `Win32`, not `SAP`, and a ZIP named `sap.zip` (the user's real filename) would never have matched -- caught before it shipped, once the user confirmed their actual 4 real filenames (`crowdstrike`, `office2024`, `office2021lop`, `sap`). Fixed by computing the destination from the first path segment under the type folder instead of the file's parent, matching CLAUDE.md's own documented convention that multi-file applications live in one top-level subfolder (`Installers\EXE\SAP\`) regardless of how deeply nested the actual files are inside it. Verified end-to-end against an isolated copy of this repo's real `Config\Applications.json` (never against the real `Installers\` folder) using the user's actual 4 real filenames plus the earlier `WinMTR`/`ThinkPadAssetID` cases: all 6 extracted to the correct subfolder (`sap.zip` -> `Installers\EXE\SAP`, confirmed not the deeper `Win32` path), and an unrelated `RandomStuff.zip` was still correctly reported as unmatched instead of extracted anywhere (2026-08-27). Not yet run against a real company OneDrive download or a real device.
- [x] **Pivoted away from OneDrive entirely** after exhausting every automatic-access option against the company tenant: an Azure AD app registration (confirmed not realistic to obtain), and separately a delegated device-code sign-in using Microsoft's own first-party "Microsoft Graph Command Line Tools" public client (no custom app registration needed) -- tried first with `Files.Read.All`, then retried with the narrower `Files.Read` scope, and the tenant returned "Approval required" both times. This confirms the block is a tenant-wide consent policy, not a scope or client problem, and there is no remaining technical workaround short of company IT approving something. Cloudflare R2 was also evaluated as a replacement (real access control, no per-file size cap unlike GitHub Releases' 2GiB limit) and confirmed technically viable and genuinely free for this project's ~10.6GB of files (10GB/month free storage, permanent and recurring, not a trial; the four real files total files total ~10.6GB so a ~$0.01/month overage would apply) -- but the user chose not to proceed with it once Google Drive worked instead.
- [x] Added automatic per-application cloud fetch, sourced from a personal Google Drive folder shared as "anyone with the link" (confirmed publicly viewable with no sign-in via a live fetch of the real folder link). New module `Modules\Installation\CloudInstallerFetch.ps1` (added to `$ModulePaths`, module count 47->48) provides: `Get-CloudInstallerSources`/`Get-CloudInstallerUrl`/`Test-CloudInstallerConfigured` (read `Config\CloudInstallerSources.json`, a **new file added to `.gitignore`** -- this repo's GitHub remote was confirmed public via the GitHub API before this was built, so the Google Drive share links, which grant download access to anyone who has them, must never live in the already-tracked `Config\Applications.json` the way every other catalog field does); `Get-CloudInstallerDestinationDirectory` (the same top-level-subfolder resolution logic as `Import-CloudInstallers.ps1`, now shared via dot-sourcing instead of duplicated); `Get-GoogleDriveFileIdFromUrl` (parses a file ID out of a `drive.google.com/file/d/...` share URL); `Invoke-GoogleDriveFileDownload` (the two-request virus-scan-interstitial workaround); and `Invoke-CloudInstallerFetch` (orchestrates download + extraction, logs via `Write-DeploymentLog`, returns a `{Status,Message}` shape). Wired into `Install-ApplicationByType` (`InstallationRouter.ps1`) as a single hook at the top: if `Test-CloudInstallerConfigured` is true and `Test-ApplicationInstallerAvailable` (unchanged, still read-only) is false, it fetches first and fails cleanly with a clear message if that fetch fails, before falling through to the existing, completely unmodified per-type switch. `Config\CloudInstallerSources.json` currently maps the 5 catalog entries whose packages don't fit in git (CrowdStrike Windows Sensor, Microsoft Office LTSC Standard 2024, Microsoft Office Professional Plus 2021 - LOP, and both SAP GUI entries, which intentionally share one combined Drive file per the user's choice to keep both versions in one `SAP.zip` rather than splitting them) to their real Google Drive share links.
- [x] Google's download-warning page was found to have changed from the older documented `drive.google.com/uc?export=download&confirm=<token>&id=...` format: it now points a hidden form at a different host, `drive.usercontent.google.com/download`, with `id`, `export`, `confirm` (usually the literal string `t`), and a per-request `uuid` field that must all be extracted from the real HTML response rather than assumed -- discovered by inspecting the actual live page returned for one of the user's real files, not from documentation. `Invoke-GoogleDriveFileDownload` implements the current, verified format.
- [x] Discovered mid-session that every ZIP the user created was made by zipping the application's folder itself (e.g. `SAP.zip` contains a top-level `SAP\` folder), not its contents -- confirmed by asking directly rather than assuming, since guessing wrong here would have silently nested every extracted package one folder too deep (e.g. Office 2024's `ODT2024s.ISO`, which `Get-OfficeIsoPath` expects at an exact fixed path, would have landed at `Installers\ISO\Office2024\Office2024\ODT2024s.ISO` instead). Both `Invoke-CloudInstallerFetch` and `Import-CloudInstallers.ps1` now extract into the *parent* of the resolved destination folder rather than the destination folder itself, letting the ZIP's own wrapper folder recreate the destination exactly. Verified with a realistic fixture (real wrapper-folder-shaped ZIPs for SAP/CrowdStrike/Office2024/Office2021LOP against an isolated copy of the real `Applications.json`): all four landed at the exact expected path with no extra nesting.
- [x] Verified everything that does not require a real, complete network download: `Test-CloudInstallerConfigured`/`Get-CloudInstallerUrl`/`Get-GoogleDriveFileIdFromUrl`/`Get-CloudInstallerDestinationDirectory` were run directly against the real `Config\Applications.json` and the real (gitignored, local-only) `Config\CloudInstallerSources.json` -- all 5 configured applications resolved the correct file ID and destination folder (including both SAP entries correctly sharing one file ID and one destination), and an unconfigured application (Google Chrome) correctly reported not configured. The confirm/uuid-extraction download mechanism was confirmed to genuinely get past Google's virus-scan interstitial and start streaming real binary ZIP content (not another HTML page) against one of the user's real files.
- [ ] **A full, complete real download was not observed end-to-end.** A live test against the real 119MB CrowdStrike file reached ~25MB of real binary data before stalling; a control test downloading an unrelated public file from GitHub in this same session also crawled at roughly 100-150KB/s, which points to this session's own outbound bandwidth rather than anything specific to Google Drive or this code. This needs a real run on an actual deployment device (which should have a normal internet connection) before being trusted for the two largest files (Office 2021 LOP at 4.8GB, SAP at 3.0GB combined).
- [ ] The GUI queue's progress text still only ever says "Installing N of M: AppName..." even while a cloud fetch is happening first -- technically accurate (the fetch is part of installing) but does not visibly distinguish "downloading" from "running the installer," which could look like a hang on a slow connection for the two largest files. Not addressed this pass.

---

## Post-Teams Regression

- [x] All PowerShell files pass syntax validation
- [x] Applications JSON is valid
- [x] Nine applications load successfully
- [x] Microsoft Teams is required for issuance
- [x] Existing provisioned Teams installation is detected
- [x] Existing Teams installation is skipped
- [x] Application preview and cancellation work
- [x] Deployment validation runs successfully
- [x] Validation results are written to the deployment log

The following acceptance tests remain pending until an authorized clean device is available:

- [ ] Microsoft Teams provisions successfully on a clean device
- [ ] Microsoft Teams is available to a newly created local user

---

## Microsoft Teams Clean-Device Acceptance Procedure

Perform this test only on an authorized clean Windows deployment device.

### Preconditions

- [ ] PowerShell is running as Administrator
- [ ] The repository is on the latest development commit
- [ ] Microsoft Teams is not installed for the current user
- [ ] Microsoft Teams is not provisioned on the device
- [ ] Internet connectivity is available

### Initial Detection

- [ ] Current-user Teams detection returns `False`
- [ ] Provisioned Teams detection returns `False`
- [ ] Microsoft Teams appears as not installed in the application menu
- [ ] Required-application validation reports `Missing: Microsoft Teams`

### Installation

- [ ] Microsoft Teams can be selected from the application menu
- [ ] The installation preview displays Microsoft Teams
- [ ] The latest official Teams bootstrapper downloads successfully
- [ ] The bootstrapper Microsoft signature is valid
- [ ] Microsoft Teams provisioning completes successfully
- [ ] Temporary bootstrapper files are removed
- [ ] The deployment log records a successful Teams installation

### Post-Installation Verification

- [ ] Current-user Teams detection returns `True`
- [ ] Provisioned Teams detection returns `True`
- [ ] Microsoft Teams appears as installed in the application menu
- [ ] Required-application validation passes
- [ ] Deployment validation reports Teams as ready for issuance

### New-User Verification

- [ ] A local standard user is created
- [ ] The new local user can sign in successfully
- [ ] Microsoft Teams is available to the new local user
- [ ] Teams launches successfully for the new local user

### Existing-Installation Skip Test

- [ ] Running Teams deployment again returns `Skipped`
- [ ] The bootstrapper is not downloaded unnecessarily
- [ ] The existing Teams installation is not modified
- [ ] The skip result is written to the deployment log

---

## Additional Browsers

- [x] Microsoft Edge WinGet package is available
- [x] Brave Browser WinGet package is available
- [x] Firefox Developer Edition WinGet package is available
- [x] All four browsers appear under the Browsers category
- [x] Application catalog contains twelve applications
- [x] Microsoft Edge, Brave Browser, and Firefox Developer Edition are optional
- [x] Select Recommended does not select the optional browsers
- [x] Browser installation preview works
- [x] Microsoft Edge existing installation is skipped correctly
- [x] Brave Browser installs successfully through the deployment tool
- [x] Brave Browser existing installation is skipped correctly
- [x] Firefox Developer Edition installs successfully through the deployment tool
- [x] Firefox Developer Edition existing installation is skipped correctly
- [x] Browser installation status refreshes after processing

---

## Additional Deployment Tools

- [x] Application catalog contains fifteen applications
- [x] WinBox appears under Network Tools
- [x] Visual Studio Code and Git appear under Development Tools
- [x] WinBox, Visual Studio Code, and Git are optional
- [x] Select Recommended does not select the three applications
- [x] WinGet machine-scope package availability succeeds
- [x] WinBox installs successfully through WinGet
- [x] WinBox portable-package detection works
- [x] WinBox existing installation is skipped correctly
- [x] Visual Studio Code installs successfully at machine scope
- [x] Visual Studio Code existing installation is skipped correctly
- [x] Git machine installation is detected correctly
- [x] Git existing installation is skipped correctly
- [x] Installed-application status refresh completes normally

---

## Running Application Pre-Check

### Configuration and Process Detection

- [x] Visual Studio Code includes `BlockingProcesses: ["Code"]` in `Config/Applications.json`
- [x] `Get-BlockingApplicationProcesses` loads successfully from `ApplicationProcessCheck.ps1`
- [x] Visual Studio Code process detection found 12 running `Code` processes
- [x] Multiple processes belonging to the same configured application are returned
- [x] An application without `BlockingProcesses` returns zero blocking processes
- [x] An application without `BlockingProcesses` does not produce an error

### Installation Queue Isolation Test

- [x] The queue checks blocking processes when the application is not installed
- [x] The queue stops before installer availability checking when a blocking process is found
- [x] The installer function is not called when the application is blocked
- [x] The blocked application displays the configured running process name
- [x] The blocked application displays instructions to close the application and retry
- [x] The blocked application increments `Blocked`
- [x] The blocked application does not increment `Failed`
- [x] The isolated summary displayed `Blocked: 1`
- [x] The isolated summary displayed `Failed: 0`
- [x] The isolated summary displayed `Not Found: 0`

### Full Tool Integration

- [ ] `Start.ps1` automatically loads `ApplicationProcessCheck.ps1`
- [ ] An already-installed Visual Studio Code installation is skipped before process checking
- [ ] Google Chrome continues through normal installed-application detection
- [ ] The real installation summary displays the `Blocked` counter
- [ ] A blocked installation writes a `WARNING` entry to the deployment log
- [ ] Existing applications without `BlockingProcesses` continue working normally

### Retry and Skip Handling

- [x] Blocked application displays Retry and Skip options
- [x] Invalid input is rejected and the prompt is displayed again
- [x] Skip returns a `Blocked` result
- [x] Skip prevents installer availability checking
- [x] Skip increments the `Blocked` counter
- [x] Skip does not increment the `Failed` counter
- [x] Skip writes an application warning to the deployment log
- [x] A summary containing blocked applications is logged as `WARNING`
- [x] Retry checks the configured processes again
- [x] Retry continues after the blocking process is closed
- [x] Retry proceeds to installer availability checking
- [x] Retry proceeds to the normal installation workflow
- [x] A successful retry increments the `Installed` counter
- [x] A successful retry does not increment the `Blocked` counter
- [x] A successful retry summary is logged as `SUCCESS`

## Structured Installation Results

## Detailed Installation Queue Results

- [x] Installed result displays status and reason
- [x] Already-installed application displays `SKIPPED`
- [x] Running application displays `BLOCKED`
- [x] Missing installer displays `NOT FOUND`
- [x] Failed installation displays `FAILED`
- [x] Queue counters remain accurate
- [x] Final summary severity remains correct
- [x] Mocked queue test does not install applications
- [x] Real already-installed application is skipped without launching an installer

## Installer Package Organization

- [x] Standard installer type directories exist
- [x] CrowdStrike package moved to `Installers\EXE\CrowdStrike`
- [x] SAP package moved under `Installers\EXE\SAP`
- [x] Office 2024 package moved to `Installers\ISO\Office2024`
- [x] Office 2021 LOP package moved to `Installers\IMG\Office2021LOP`
- [x] Application package dependencies remain together
- [x] Updated installer paths resolve successfully
- [x] Applications configuration remains valid JSON
- [x] Old installer path references were removed
- [x] PowerShell syntax validation passed
- [x] Deployment validation mode passed
- [x] Installation menu loads successfully after reorganization

## Automatic Installer Directory Initialization

- [x] Installer directory initializer module loads successfully
- [x] Existing installer directories remain unchanged
- [x] Missing installer directories are created automatically
- [x] `Installers\EXE\CrowdStrike` is supported
- [x] `Installers\EXE\SAP` is supported
- [x] `Installers\ISO\Office2024` is supported
- [x] `Installers\IMG\Office2021LOP` is supported
- [x] Empty MSI, ZIP, and Scripts directories are supported
- [x] Repeated initialization does not recreate existing directories
- [x] Normal `Start.ps1` startup performs directory initialization
- [x] `Start.ps1 -ValidateOnly` does not modify installer directories
- [x] Deployment validation reports 31 modules and 7 required functions
- [x] PowerShell syntax validation passes

## Installer Package Readiness Validation

- [x] Readiness module loads successfully
- [x] Offline installer applications are detected
- [x] WinGet and Teams applications are excluded from local package readiness checks
- [x] SAP GUI reports `READY` when its installer exists
- [x] CrowdStrike reports `READY` when its deployment package is valid
- [x] Microsoft Office 2024 reports `READY` when its ISO is available
- [x] Microsoft Office 2021 LOP reports `READY` when its IMG package is available
- [x] Missing SAP installer reports `MISSING`
- [x] Restoring the SAP installer changes status back to `READY`
- [x] Package readiness checks do not launch installers
- [x] `Installer Package Status` is accessible from the main menu
- [x] Package status screen returns to the main menu
- [x] Deployment validation reports 32 modules and 9 required functions
- [x] PowerShell syntax validation passes

## MSI Installer Support

- [x] MSI installer module loads successfully
- [x] Existing `.msi` file is accepted
- [x] Incorrect installer extension is rejected
- [x] Missing MSI file is rejected
- [x] Installation router recognizes MSI applications
- [x] Installation router calls `Install-ApplicationWithMsi`
- [x] MSI installer uses `msiexec.exe`
- [x] MSI installer path is quoted correctly
- [x] Default `/qn /norestart` arguments are supported
- [x] Exit code `0` is handled as success
- [x] Exit code `3010` is handled as success with restart recommended
- [x] Exit code `1603` is handled as failure
- [x] MSI result is normalized through the standard installation result system
- [x] MSI process execution was validated using a mocked `Start-Process`
- [ ] Real MSI installation on an authorized deployment package

### ZIP Package Installation

- [x] ZIP package existence validation
- [x] ZIP file extension validation
- [x] Extracted installer path validation
- [x] Extracted installer type validation
- [x] Extracted EXE/MSI extension validation
- [x] Internal installer discovery inside ZIP archive
- [x] ZIP entry path normalization
- [x] ZIP extraction to temporary deployment directory
- [x] Extracted installer existence validation
- [x] Original ZIP package preserved during extraction
- [x] Extracted MSI delegated to existing MSI installer engine using mocked execution
- [x] ZIP installation routed through InstallationRouter
- [x] Successful ZIP installation result normalized
- [x] Failed ZIP installation result normalized
- [x] Temporary extraction removed after successful installation
- [x] Temporary extraction removed after failed installation
- [x] No real installer executed during ZIP development testing
- [x] `Get-OfflineInstallerPath` `ResolvedInstallerPath` dynamic-property bug fixed and verified (previously every extracted installer path resolved incorrectly, causing `Test-OfflineInstallerFile`/`Test-MsiInstallerFile` to report extracted installers as not found even after successful extraction)
- [x] Extracted EXE re-verified with real extraction and real execution through `Install-ApplicationFromZip` after the fix
- [x] ZIP-to-EXE installation re-verified end-to-end through InstallationRouter using a real catalog entry after the fix
- [ ] Extracted MSI re-verified with real execution after the fix (EXE path confirmed; MSI path shares the same fixed function but was not independently re-tested)
- [ ] Real ZIP package installation on an authorized deployment device

### Script Package Installation

- [x] Script installer module loads successfully
- [x] Existing `.ps1` file is accepted
- [x] Existing `.bat` file is accepted
- [x] Existing `.cmd` file is accepted
- [x] Incorrect installer extension (`.txt`) is rejected
- [x] Missing script file is rejected
- [x] Script type correctly identified as PowerShell, Batch, or Command
- [x] PowerShell scripts execute via `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`
- [x] Batch and Command scripts execute via their registered handler
- [x] Exit code `0` is handled as success
- [x] Non-zero exit code is handled as failure
- [x] Configured `RebootExitCodes` is handled as success with restart recommended
- [x] Script installation routed through InstallationRouter
- [x] Successful Script installation result normalized
- [x] Deployment validation reports 35 modules and 20 required functions
- [ ] Real script package installation on an authorized deployment device

### Result Conversion

- [x] Boolean `true` converts to `Installed`
- [x] Boolean `false` converts to `Failed`
- [x] An installer result with status `Skipped` remains `Skipped`
- [x] Installer messages are preserved during conversion
- [x] Invalid or unsupported installer results convert to `Failed`

### Installation Queue Counting

- [x] An `Installed` result increments `Installed`
- [x] A `Skipped` result increments `Skipped`
- [x] A `Failed` result increments `Failed`
- [x] A skipped installer is not counted as installed
- [x] A skipped installer is not counted as failed
- [x] A skipped result is logged as `INFO`
- [x] A queue containing a failed result logs its summary as `WARNING`
- [x] Combined test displayed `Installed: 1`
- [x] Combined test displayed `Skipped: 1`
- [x] Combined test displayed `Failed: 1`

---

## Application Catalog Additions and Category Reorganization

Ten applications were added to `Config\Applications.json` in a series of individual commits (Power BI Desktop, Outlook, Antigravity, Claude, Laragon, XAMPP, FreeFileSync, Epson L5290 driver, Canon MF421dw driver, HP Smart Tank 500 driver). "Outlook (Classic)" and a Brother P-touch driver were both requested but dropped -- classic Outlook only ever installs bundled with the existing Office LTSC/2021 entries, and the Brother driver was withdrawn by the user before a checkpoint was reached for it.

- [x] All 6 winget-based apps (Power BI Desktop, Outlook, Antigravity, Claude, Laragon, XAMPP) have their winget package IDs confirmed real via a direct `winget search` against this dev machine before being added -- `9NTXR16HNW1T` (msstore source, Power BI Desktop), `Microsoft.Outlook`, `Google.Antigravity`, `Anthropic.Claude`, `LeNgocKhoa.Laragon`, `ApacheFriends.Xampp.8.2`. None of the 6 have actually been run through `winget install` yet -- package existence was verified, not a real installation.
- [x] The 4 offline `Exe`-type additions (FreeFileSync, Epson L5290 driver, Canon MF421dw driver, HP Smart Tank 500 driver) have real installer files in place under `Installers\EXE\` (`FreeFileSync\FreeFileSync_14.10_Windows_Setup.exe`, `EPSON\Epson_L5290_Series_EM_50_Web.exe`, `Canon\MF429MFDriverV5801WPEN.exe`, `HP\HP Installer.exe`), and each `InstallerPath` was confirmed to resolve to that real file. The Canon file is named for an MF429 driver rather than MF421dw -- the user confirmed directly this is the correct installer for their MF421dw despite the filename, so this is trusted rather than assumed. None of the 4 have actually been installed on a real device yet.
- [ ] `DetectionName` for the three printer drivers (`EPSON L5290 Series`, `Canon MF421dw`, `HP Smart Tank 500 series`) are best-guess registry `DisplayName` values, not confirmed against a real installed driver -- the same open gap already documented elsewhere in this file for Office2021Img. Needs correction once each driver is actually installed and its real registry entry can be read.
- [ ] `SilentArguments` is left empty (interactive install) for all 4 offline `Exe` entries, since no vendor-confirmed silent switch is known for any of them. If unattended installation is needed, each one needs its actual silent-install flag confirmed by hand first.
- [x] **Fixed a real detection bug found by the user**: Claude showed as "Not Installed" in the Applications screen despite genuinely being installed on this dev machine (confirmed via `winget list` and real files under `%LOCALAPPDATA%\Claude`). Root cause: Claude's installer doesn't create a normal Add/Remove Programs registry entry, so this tool's default registry-scan detection (`Test-CacheRegistryApplicationInstalled`, scanning `HKLM`/`HKLM\WOW6432Node`/`HKCU` `...\Uninstall` keys for a `DisplayName` starting with the app's `Name`) never finds it -- confirmed directly by scanning every one of those registry paths on this real machine and finding no "Claude" entry anywhere, while Antigravity's entry was found there correctly. Fixed by adding `"DetectionMethod": "Winget"` to Claude's catalog entry, which routes detection through the already-implemented (but previously unused by any entry) `Test-WingetApplicationInstalled` path instead, asking `winget list --id Anthropic.Claude --exact` directly -- confirmed this returns exit code 0 (found) on this real machine, and re-verified `Test-ApplicationInstalled` returns `True` for the real Claude entry after the fix.
- [x] Reviewed every existing catalog entry's `Category` for correctness while adding these. Two real placements were fixed: Power BI Desktop moved out of `Company Applications` (it isn't company-specific, unlike SAP/Office there) into a new `Productivity` category; Antigravity and Claude moved out of `Development Tools` (general AI tools, not strictly coding tools like VS Code/Git/Laragon/XAMPP) into a new `AI Tools` category. Every other existing category placement was reviewed and left as-is.
- [x] Added dedicated category icons (`New-GuiCategoryIcon`, `GuiIcons.ps1`) for `AI Tools` (sparkle), `Productivity` (bar chart), and `Printers` (printer body) -- these three were previously falling through to the generic folder fallback icon since they postdate the mockup's original category set. Verified each renders its own distinct path geometry rather than the fallback.
- [x] Fixed the Applications screen needing to scroll to reach its last category, confirmed by a real screenshot cutting off "Printers" at the bottom. Root cause: category cards are a fixed-width `WrapPanel` (`New-GuiCategoryCard`, `GuiApplicationsScreen.ps1`) that only fit 2 per row at this window's content width, and the catalog grew from 9 categories to 11. Narrowed the card from 360px to 340px and tightened its margin from 14 to 10, fitting 3 per row instead of 2. Verified via a real, off-screen fit-test harness (loading the actual `MainWindow.xaml`, the real Nunito font, and the real 30-app/11-category catalog through `Get-ApplicationCatalog`/`Update-GuiApplicationGrid`, not synthetic data): 601.75px content vs 688.9px viewport, 87.15px spare -- fits with no scrolling. Not yet seen on a real screen.
- [ ] None of the 10 newly added applications have been installed for real on any device. Everything above is schema/wiring-level verification (`-ValidateOnly`, installer-path resolution, winget package existence, layout fit) -- not proof any of them actually install correctly end to end.

---

## Fixed: WinGet Availability Check Gave False "Not Found" Results

Found while the user was testing a fresh device via the `irm ... | iex` remote bootstrap: selecting Google Chrome reported "Not Found" even though winget itself was present and working (`winget --version` returned a version). Diagnosed live against that device by running the exact command `Test-WingetPackage` used (`winget show --id Google.Chrome --exact --source winget --accept-source-agreements --disable-interactivity`), which failed with `0x8a15000f : Data required by the source is missing`.

- [x] Ruled out several causes in order, confirmed real on that device rather than assumed: not a network/firewall/proxy issue (device has normal unrestricted internet); not every winget app failing, only Chrome at first (though this pointed at the source data, not Chrome specifically); `winget source reset --force` did not fix it; manually removing and re-adding the `winget` source (`winget source remove winget` / `winget source add --name winget --arg "https://cdn.winget.microsoft.com/cache" --type "Microsoft.PreIndexed.Package"`) did not fix it either; the installed App Installer version (`v1.29.280`) was confirmed via a live web search to be current, not outdated, ruling out a stale-client explanation; re-registering the App Installer package from its existing files (`Add-AppxPackage -DisableDevelopmentMode -Register ...AppXManifest.xml`) also did not fix it.
- [x] **Root cause confirmed in two parts.** First: the same diagnostic command succeeded when run from a normal, non-elevated PowerShell window on that same device, account, and moment in time -- it only failed when run elevated. A live web search then surfaced the likely explanation: CVE-2026-68821, a WinGet privilege-escalation vulnerability Microsoft fixed specifically in App Installer 1.29.280 -- the exact version on that device -- which strongly suggests the security fix itself now restricts what winget's local source data can do when queried from an elevated process, rather than the device being broken. Second, and decisive: the user confirmed the real `winget install --id Google.Chrome --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity` command **succeeded** on that same device, elevated, despite `winget show` failing. So only this tool's own pre-check was broken; the actual install path winget itself uses was fine all along.
- [x] **Fixed** (`Test-WingetPackage`, `Modules\Installation\WingetInstaller.ps1`): stopped calling `winget show` to verify a specific package ID exists before installing, since that call was proven unreliable in exactly the scenario this tool needs to work in (elevated, on a device patched against CVE-2026-68821). Now only confirms the `winget` command itself is present (`Get-Command -Name winget`), and lets `Install-ApplicationWithWinget`'s own existing, robust exit-code handling be the real source of truth for whether a specific package installs -- a genuinely nonexistent Winget ID now surfaces as a `Failed` result (with winget's real error message) at actual install time instead of a `Not Found` before ever trying, which is a deliberate, approved tradeoff. Verified directly on this dev machine: `Test-WingetPackage` still returns `True` for a real app (Google Chrome) and now also correctly returns `True` for a deliberately fake Winget ID (by design, since that check no longer verifies package existence).
- [x] Re-verified on the actual device that hit this in the first place, after the fix was pushed: the availability check no longer blocks the install with a false "Not Found" -- it now correctly reaches the real `winget install` call.
- [ ] Once the real install ran on that device, it still failed, with the exact same exit code (`-1978335217` / `0x8A15000F`) -- this time from the real install itself, not just the pre-check. The user then confirmed the identical manual `winget install` command, run directly in a fresh elevated PowerShell window on that same device, also failed with the same code, ruling out anything specific to how this tool invokes winget: winget itself was failing for any elevated process on that device at that point, tool or manual command alike. Restarting the device did not fix it.
- [x] **Found the real fix, more precise than anything tried before**: the device had a Windows Update available named "Windows Package Manager Source (winget) V2" -- already installed, but re-registering it directly resolved the issue. The actual broken piece was not the main App Installer package (already tried re-registering that, no effect) but a separate, specific AppX package, `Microsoft.Winget.Source`, which holds the actual source index data. Confirmed on the real device: `Get-AppxPackage -AllUsers Microsoft.Winget.Source | Foreach-Object { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -Verbose }` completed with no errors, and the exact same `winget show --id Google.Chrome ...` diagnostic command that had failed every previous attempt then succeeded, printing Chrome's full real package details. Installing and uninstalling Chrome through the deployment tool both then worked.

---

## Added: Automatic Recovery from the WinGet Source-Data-Missing Error

Built the confirmed fix above directly into the tool, so a future device hitting this same WinGet bug self-heals instead of needing this same manual troubleshooting repeated. Added to `Modules\Installation\WingetInstaller.ps1`:

- [x] `$script:WingetSourceDataMissingExitCode` (`-1978335217`, i.e. `0x8A15000F`) names the specific, confirmed-real exit code this applies to -- deliberately narrow, so this never masks a genuinely different WinGet failure as something it can silently retry past.
- [x] `Repair-WingetSourceDataPackage` re-registers the `Microsoft.Winget.Source` AppX package from its existing files (`Get-AppxPackage -AllUsers Microsoft.Winget.Source` then `Add-AppxPackage -DisableDevelopmentMode -Register`), the exact command confirmed to fix this on the real device that hit it. Read-only in the sense that it never removes or reinstalls anything -- only re-registers files already present locally.
- [x] `Invoke-WingetCommandWithSourceRepair` wraps the actual `winget` invocation: runs the command once, and only if it fails with exactly the known exit code, logs a warning, attempts the repair, and retries the same command exactly once more before giving up. Both `Install-ApplicationWithWinget` and `Uninstall-ApplicationWithWinget` now go through this wrapper instead of calling `winget` directly.
- [x] Verified the normal, unaffected case is unchanged: `Invoke-WingetCommandWithSourceRepair -WingetArguments @("--version")` on this healthy dev machine (which never had this bug) ran the command once, returned exit code `0`, and never triggered the repair path -- confirming this adds no overhead or behavior change for the common case where WinGet is working normally.
- [ ] The repair function itself (`Get-AppxPackage -AllUsers`) requires an elevated process to succeed, which this tool's install/uninstall flow always is -- this was only spot-checked by direct code review and by confirming the exact same command already fixed the real device manually, not by re-triggering the actual bug end-to-end through the tool's own automatic path (that would require deliberately re-breaking a real device's WinGet state, which wasn't done). The manual, already-proven-working command and this automated version are line-for-line the same, so this should hold, but the automatic trigger path itself has not been exercised live.

---

## Added: Copy Results Button and Fixed a Misleading Progress UI on Declined Uninstalls

- [x] Added a "Copy Results" button to the install/uninstall completion modal (`MainWindow.xaml`, next to OK), so the exact status shown (counts plus every failure message with its real exit code) can be copied to the clipboard instead of retyped by hand. `Get-GuiCompletionSummary`/`Invoke-GuiCopyCompletionSummary` (`GuiApplicationsScreen.ps1`) mirror the existing "Copy Device Details" pattern exactly (same clipboard call, same "Copied!" button-feedback timer). Verified directly: the button resolves via `FindName`, and the summary text formats correctly with a real example (counts plus a real exit-code failure message).
- [x] **Fixed a real bug found by the user**: declining the per-application confirmation when uninstalling still visibly ran the "Uninstalling..." progress UI (buttons disabled, progress bar shown) even though nothing was actually being uninstalled, before landing on a `Skipped` result. Root cause: `Start-GuiApplicationQueue` only skipped the whole background-runspace/progress-UI sequence when there was *nothing at all* to report (`Applications.Count -eq 0 AND PreSkippedCount -eq 0`) -- declining a confirmation increments `PreSkippedCount`, so the progress UI still ran for zero real work. Fixed by reporting the result (the completion modal, with correct `Skipped` counts) directly whenever there are no real applications to process, without ever touching the progress panel or disabling the queue buttons. Verified directly: simulating a fully-declined uninstall (`Applications = @()`, `PreSkippedCount = 1`) now leaves `QueueProgressPanel.Visibility` at `Collapsed` throughout, shows the completion modal immediately with the correct `0 Uninstalled / 1 Skipped / 0 Failed`, and leaves the Install/Uninstall buttons enabled the whole time since no real queue ever started.
- [x] **Removed the completion modal entirely for a pure decline/cancel, per direct follow-up feedback**: the fix above still showed an "Uninstallation Complete" popup even when the user's own action (cancelling the confirmation) was the only reason nothing happened -- unwanted, since there's nothing to report when the technician themselves cancelled. `Start-GuiApplicationQueue` now returns silently (no progress UI, no completion modal) whenever there are no real applications to process AND no real failure occurred; a genuine failure that happens before confirmation (a case no current caller triggers, but the check stays correct for one that might) still surfaces the modal, since that is worth reporting regardless of what the user clicked. Verified both paths directly: a pure decline (`Applications = @()`, `PreSkippedCount = 1`, no failure messages) now leaves the completion overlay `Collapsed` the whole time; a simulated pre-confirmation failure (`PreFailureMessages` non-empty) still shows the modal correctly.

---

## Fixed: FreeFileSync's Installer Path Was Still a Placeholder

Found by the user via Deployment Validation showing the newly added offline packages as missing/failed. Root cause: when the user placed the real installer files earlier, only the Epson/Canon/HP driver entries' `InstallerPath` placeholders were updated to the real filenames -- FreeFileSync's was missed, left as the literal `EXE\FreeFileSync\<INSTALLER_FILENAME>.exe` placeholder even though the real file (`FreeFileSync_14.10_Windows_Setup.exe`) was already sitting in that folder and had already been confirmed present by an earlier `Test-Path` check on the file directly. The `<`/`>` characters are illegal in a Windows path, so `Test-Path` (inside `Test-OfflineInstallerFile`) threw an exception instead of just returning false, which `Get-InstallerPackageReadiness`'s per-application `try`/`catch` did correctly catch and report as `MISSING`, but with the raw exception text as the message rather than the normal clean "Installer package is missing or invalid."

- [x] Fixed by updating `Config\Applications.json`'s FreeFileSync entry to the real filename, matching the pattern already used for the other three drivers.
- [x] Re-ran `Get-InstallerPackageReadiness` against the real catalog and real `Installers\` directory on this dev machine: all 10 offline packages (SAP GUI x2, CrowdStrike, Office LTSC, Office 2021 LOP, Lenovo Asset ID, FreeFileSync, Epson, Canon, HP) now report `READY` with no exception, where FreeFileSync previously threw.

---

## Added: Self-Delete on Close for Bootstrapped Devices

Per the user's request: the tool should leave no trace on a device it was deployed to (via the `irm .../Deploy.ps1 | iex` bootstrap) once its window closes, but must never do this on a manually run copy (this dev repo included).

- [x] `Deploy.ps1`'s own launch line now passes a new `-DeleteOnClose` switch to `Start.ps1 -Gui` -- the only place in the repo that ever does. A plain `.\Start.ps1 -Gui` (this dev repo, or any manually cloned/copied instance) never receives it and never self-deletes.
- [x] The switch is threaded through `Start.ps1`'s own elevation relaunch (`Request-Administrator`, `Modules\Core\Elevation.ps1`), since `Start.ps1` re-launches itself elevated via `Start-Process -Verb RunAs` before ever reaching the GUI, and would otherwise silently lose the flag the moment UAC fires. Confirmed directly: `Request-Administrator`'s parameter list includes `DeleteOnClose`, and `Show-MainWindow`'s does too.
- [x] `Show-MainWindow` (`GuiWindow.ps1`) stores the flag in `$script:GuiDeleteOnClose`, read by the existing `$Window.Add_Closing` handler -- the pre-existing guard that blocks closing during an active install/uninstall queue still runs first and unchanged (confirmed by reading the handler back: the queue-running branch `return`s before the delete-confirmation branch is ever reached, so a running queue always wins regardless of `-DeleteOnClose`). When set, closing the window shows a Yes/No warning naming exactly what will be deleted (scripts, config, downloaded installer packages, logs) before anything happens; declining just closes normally.
- [x] `Start-GuiSelfDeleteOnExit` (`GuiWindow.ps1`) writes a small deleter script to `$env:TEMP` (deliberately outside the tool's own folder, since a script can't reliably delete the file it's currently running from) that `Wait-Process`-blocks on this process's PID, then recursively removes the tool's root folder and finally itself, launched detached and hidden so it survives after this process exits. Verified end-to-end against a completely isolated fake folder (never the real repo): built the exact same deleter-script logic targeting a disposable stand-in process instead of this session's own PID, confirmed the fake folder still existed before, launched the deleter, and confirmed both the fake folder and the deleter script itself were gone within a few seconds of the stand-in process exiting.
- [x] **First real-device test showed no close confirmation at all**; a clean retest (re-running the `irm .../Deploy.ps1 | iex` bootstrap fresh) confirmed self-deletion **does** work correctly. Root cause was very likely the suspected stale GitHub Raw CDN cache serving an older, pre-fix `Deploy.ps1` at the moment of the first test (`raw.githubusercontent.com` can cache for a few minutes after a push) -- the code path itself (`Request-Administrator` returning early when already elevated, `$DeleteOnClose` carried through to `Show-MainWindow` with no relaunch involved) was correct all along.

---

## Fixed: Logged User and Download Path Showed the Wrong Account When Elevated as a Different Admin Account

Found by the user during the same real-device test above. A genuine standard local user account cannot self-elevate (Windows requires switching to a different account's credentials to elevate a non-admin user) -- on that device, the only admin account was the Built-in Administrator, so the whole session (including `Deploy.ps1`'s own download step) ran as that account rather than the actual person the device is for. This surfaced two real, separate bugs, not just an unavoidable Windows limitation:

- [x] **`Deploy.ps1`'s download landed in the Built-in Administrator's own Desktop, not the real logged-in user's.** `$DestinationRoot` used `$env:USERPROFILE`, which only ever reflects whichever account the current process is running as. Fixed with a new `Get-InteractiveUserProfilePath` function (`Deploy.ps1`) that resolves the real interactively logged-on user via `Win32_ComputerSystem.UserName` (which reflects the console session's real owner regardless of which account an elevated process is running under) and looks up that user's actual profile path through `Win32_UserAccount`/`Win32_UserProfile` (by SID, not by assuming `C:\Users\<name>`), falling back to `$env:USERPROFILE` if any step fails. Verified directly on this dev machine: resolves to the exact same path as `$env:USERPROFILE` in the normal case (`C:\Users\Admin`), confirming no regression for the common case where elevation doesn't involve switching accounts.
- [x] **The top system-info bar's "User" field showed "Administrator" instead of the real target user.** `Get-SystemInformation` (`SystemInformation.ps1`) used the same `$env:USERNAME` mistake. Device Details' own "Logged User" field had already solved exactly this problem correctly (`WindowsConfiguration.ps1`, via `Win32_ComputerSystem.UserName`) -- brought the top bar in line with that same, already-proven approach, stripped of its `COMPUTERNAME\` prefix to keep matching the compact bar's existing bare-username display. Verified directly on this dev machine: still returns the plain `"IT04"` (matching `$env:USERNAME` exactly) in the normal case, confirming no display regression.
- [ ] Neither fix has been re-verified on the actual real device that surfaced this -- needs a retest alongside the close-confirmation retest above.

---

## Fixed: Confirmation Dialog Buttons Didn't Match the App's Button Style

Found by the user directly: `Show-GuiDialog`'s Yes/No/OK buttons rendered as plain, default WPF button chrome, unlike every other button in the app's own rounded-corner, hover-highlighted look. Root cause: this dialog is its own separate `Window` object (deliberately, so `ShowDialog()` can still block like `MessageBox.Show` did), so it never sees `MainWindow.xaml`'s shared `Window.Resources` Button style -- that style only ever applies to buttons that live inside `MainWindow.xaml`'s own visual tree.

- [x] Added `New-GuiDialogButton` (`GuiDialog.ps1`) that builds a button with the exact same rounded-corner + hover-overlay `ControlTemplate` as `MainWindow.xaml`'s shared Button style, duplicated inline since this separate Window can't reference that shared resource directly. All three buttons (No/Yes/OK) now go through this helper.
- [x] **Caught and fixed a real bug in this same fix before it shipped**: the first version of the inline template XAML used `x:Name="HoverOverlay"` but never declared the `xmlns:x` namespace, so `[xml]` parsing threw ("'x' is an undeclared prefix") -- caught immediately by testing rather than assuming success, since the exception was non-terminating and the button silently fell back to WPF's native default template (produing the exact same "still looks plain" symptom this fix was meant to solve). Fixed by adding the missing `xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"` declaration, matching how `MainWindow.xaml`'s own root element already declares both namespaces.
- [x] Verified correctly this time, with strict error handling (`$ErrorActionPreference = "Stop"`) so a silent fallback couldn't hide a second failure: hosted a real button built via `New-GuiDialogButton` in an off-screen window, forced a template/layout pass, and confirmed the custom template's named part (`HoverOverlay`) resolves and the button's root visual is the template's own `Grid` -- not WPF's native default chrome, which would have a different root visual entirely.

---

## Added Antivirus/Uptime/Firewall to Device Details and Split It into 3 Cards

Follow-up to "is there data we need to show in device details" (Antivirus, uptime, firewall proposed; a fourth candidate, pending Windows Update count, was dropped after real testing showed the `Microsoft.Update.Session` COM search did not return within 60 seconds on this real machine -- unacceptable for this tool's refresh model, even cached once). A real screenshot then showed why: the existing 2-card layout was already uneven (16 rows vs. 10), leaving a large empty gap under the shorter card, and the user asked directly for 3 cards instead of 2.

- [x] Verified all three new fields directly on this real machine before writing any code: `Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct` (~485ms) returned **two** real registered products, "Windows Defender" and "CrowdStrike Falcon Sensor" (confirms the catalog's own CrowdStrike entry shows up here too); `Get-NetFirewallProfile` measured **5.2 seconds** -- too slow to run on every refresh, so it went into the cached identity block, the same lesson already applied to `Get-PhysicalDisk`; Uptime needed no new query at all, since `Get-WindowsConfigurationIdentity` already fetches `Win32_OperatingSystem` for `OSVersion`/`OSBuildNumber` and its `LastBootUpTime` property gives this for free.
- [x] Added `AntivirusStatus` (joined product display names, `"None Detected"` if the query succeeds but finds nothing, `"Unknown"` on any exception e.g. a Server SKU without `SecurityCenter2`), `FirewallStatus` (`"On"`/`"Off"`/`"Partial"` across all profiles, `"Unknown"` on failure), and `Uptime` (`"Xd Yh"` format) to the cached identity block, `Get-WindowsConfigurationReport`, and the console-mode `Show-WindowsConfigurationReport` (`WindowsConfiguration.ps1`). Re-verified real values and warm-call timing after adding all three: `AntivirusStatus="Windows Defender, CrowdStrike Falcon Sensor"`, `FirewallStatus="On"`, `Uptime="17d 3h"`, warm call **387ms** -- no regression from the previously-established ~415ms baseline, confirming Firewall's cost was successfully absorbed into the one-time cached cost rather than the per-refresh cost.
- [x] Split `MainWindow.xaml`'s Device Details from 2 cards to 3 (`Identity & Network` / `System & Session` / `Power & Hardware`), rebalancing what was a 16-row vs. 10-row split into 9/10/10: Identity & Network keeps IDENTITY + NETWORK unchanged; System & Session combines SYSTEM (now with the new Uptime row) with SESSION (moved from the old second card); Power & Hardware combines POWER (also moved) with HARDWARE (now with the new Antivirus and Firewall rows, Firewall as a pill matching TPM/Secure Boot's pattern). Both the synchronous refresh path and the background-load completion handler in `GuiWindowsConfigScreen.ps1` were updated together, since this exact "two paths drift out of sync" mistake has already been made and fixed once this session for the local user list. `Get-GuiDeviceDetailsSummary`'s clipboard output got the same three new lines.
- [x] Re-measured the real fit with the off-screen, real-Nunito-font harness, populated with realistic real-length values (including the two-product Antivirus string, the longest new value and most likely to wrap): **392.2px content vs. 700.85px viewport, 308.65px spare** -- nearly double the previous 2-card layout's 165px spare, despite the 3 new rows, since redistributing rows across 3 columns instead of 2 reduces the tallest column's height by more than the new rows add. Confirmed every new/moved element (`DeviceUptimeText`, `DeviceAntivirusStatusText`, `DeviceFirewallStatusText`/`DeviceFirewallStatusPill`, plus every pre-existing name) still resolves via `FindName` with no stale references left from the old 2-card structure.
- [ ] Not yet seen on a real screen.

---

## Fixed: Deployment Validation's Installer Package Status Showed Every Package as MISSING

Found by the user on both this dev machine and the other test device -- every offline package (SAP GUI x2, CrowdStrike, Office LTSC, Office 2021 LOP, Lenovo Asset ID, FreeFileSync, Epson/Canon/HP drivers) showed `MISSING` in Deployment Validation's "Installer Package Status" section, even though the real files were confirmed present and `Get-InstallerPackageReadiness` called directly (outside the GUI) correctly reported every one of them `READY`.

- [x] **Root cause confirmed by direct reproduction, not assumed**: `GuiDeploymentValidationScreen.ps1` runs its checks in a background PowerShell runspace with its own separate `$ModulePaths` list (re-dot-sourcing everything the checks need, since a fresh runspace starts with no session state) -- that list never included `Installation\InstallationRouter.ps1` (which defines `Test-ApplicationInstallerAvailable`, the function `Get-InstallerPackageReadiness` calls for every application) or any of the individual per-type installer modules it dispatches to (`WingetInstaller.ps1`, `OfflineInstaller.ps1`, `MsiInstaller.ps1`, `AppxInstaller.ps1`, `ScriptInstaller.ps1`, `ZipInstaller.ps1`). Reproduced exactly by loading only this screen's actual module list in isolation and calling `Get-InstallerPackageReadiness` against the real catalog: every single application came back `MISSING`, each with the identical message `"The term 'Test-ApplicationInstallerAvailable' is not recognized..."` -- `Get-InstallerPackageReadiness`'s own per-application `try`/`catch` caught this real error and converted it into a normal-looking `MISSING` status rather than surfacing it as a visible crash, which is exactly why it looked like a device/file problem instead of a missing-module bug, and why it affected every device identically regardless of what files were actually present.
- [x] Fixed by adding the missing modules to `GuiDeploymentValidationScreen.ps1`'s background-runspace `$ModulePaths`, in the same dependency order `Start.ps1`'s own real module list already uses (individual installer type modules, then `InstallationRouter.ps1`, before the validation/readiness modules that call it).
- [x] Verified the fix directly: re-ran the exact same isolated reproduction with the corrected module list and got `READY` for all 10 real offline packages, matching what `Get-InstallerPackageReadiness` already reported when called with the tool's full, correct module set.

---

## Added: Temp Cleanup Tab

Per the user's own feature idea: a new screen to clear the well-known temp/cache locations (the current user's `%TEMP%`, `C:\Windows\Temp`, `C:\Windows\Prefetch`) before handing a device off, since leftover temp files and prefetch cache have no reason to persist on a freshly deployed or reclaimed machine.

- [x] Added `Modules\Windows\TempCleanup.ps1` (new module, added to `$ModulePaths` between `Windows\LenovoAssetId.ps1` and `Validation\DeploymentValidation.ps1`): `Get-TempCleanupTargets` (read-only, matching this app's validation/readiness functions staying read-only) scans all three locations and reports name, path, file count, total size, and whether the location was accessible; `Remove-TempCleanupTarget` (destructive) deletes files individually rather than one recursive `Remove-Item`, so a single locked/in-use file is skipped instead of aborting the whole location, and never deletes the target folder itself, only the files inside it.
- [x] Added `Modules\Gui\GuiTempCleanupScreen.ps1` (new module, added between `GuiWindowsConfigScreen.ps1` and `GuiWindow.ps1`): `Start-GuiTempCleanupScan` runs the scan on a background runspace (the same pattern as Deployment Validation) so opening the tab never blocks the UI thread; `Invoke-GuiTempCleanup` confirms via `Show-GuiDialog` (naming exactly which locations and how much total data will be deleted) before deleting only the checked locations and re-scanning, then reports through the same `Show-GuiCompletionModal`/Copy Results modal already built for install/uninstall rather than a new UI pattern.
- [x] Added a `NavTempCleanup` sidebar tab (trash-can icon), a toolbar (Refresh + Clean Selected), and three cards (User Temp, Windows Temp, Prefetch) to `MainWindow.xaml`, each with a checkbox defaulting to checked, following the same card visual language as every other screen. Wired into `GuiWindow.ps1`: `FindName` for every new element, `NavTempCleanup` added to the shared nav-border/text/icon arrays, a `Switch-GuiScreen` branch that lazy-loads the scan on first visit (matching every other screen's load-once pattern), and click handlers for the nav item, Refresh, Clean Selected, and each card's checkbox toggle.
- [x] `Start.ps1`'s module count check updated from 48 to 50 (2 new modules), and `Get-TempCleanupTargets`/`Remove-TempCleanupTarget` added to `$RequiredFunctions`. `.\Start.ps1 -ValidateOnly` passes with 50 modules and 32 required functions.
- [x] **Caught and fixed a real crash while testing the new backend module directly against this real machine, unrelated to the feature logic itself**: `Get-TempCleanupTargets` built its results list with `New-Object System.Collections.Generic.List[object]`, then returned `@($Targets)` -- the same pattern `InstallerPackageReadiness.ps1` already uses successfully. On this specific PowerShell 5.1 build, that exact combination throws `"Argument types do not match"` the moment the list is wrapped in `@()`; reproduced in complete isolation (a fresh, `-NoProfile` process, nothing else involved) and narrowed to the `New-Object`-with-generic-type-parameter construction specifically -- `[System.Collections.Generic.List[object]]::new()` (the exact form `InstallerPackageReadiness.ps1` happens to already use) and `List[string]` via either construction form are both unaffected. Fixed by switching to the `::new()` form.
- [x] **Caught and fixed a real, user-facing scan-accuracy bug found while testing against this real machine's real `%TEMP%`**: the initial scan used `Get-ChildItem -Recurse -File -Force -ErrorAction Stop`, which aborts the entire location's scan the moment it hits even one inaccessible nested subfolder -- confirmed for real, where a system-created `WinSAT` results folder inside the current user's own `%TEMP%` is access-denied even to its owning user, making the whole User Temp card falsely report "Access Denied" and 0 files, hiding the 330+ MB of real, cleanable files sitting right alongside it. Fixed by switching to `-ErrorAction SilentlyContinue -ErrorVariable ScanErrors` (in both the scan and `Remove-TempCleanupTarget`'s pre-delete re-scan) so one denied subfolder is skipped instead of aborting the whole scan; a location is only reported inaccessible when nothing came back at all AND a real scan error was recorded, correctly distinguishing "this whole location is denied" from "genuinely empty" or "mostly readable with one odd subfolder walled off." Re-verified against this real machine after the fix: User Temp correctly reports 401 files/330.6 MB accessible; Windows Temp and Prefetch correctly report `Accessible = $false` with a genuine access-denied error (expected in this non-elevated dev shell).
- [x] `Remove-TempCleanupTarget` verified for real against an isolated fake test folder (never the real `%TEMP%`), including a deliberately locked-open file: correctly deleted 6 of 7 files (712 bytes freed), correctly skipped the 1 locked file instead of aborting, and correctly left the target folder and the locked file's parent subfolder in place.
- [x] Fit-tested at 1360x860 with the same off-screen harness used for every other screen this session, populated with realistic values: 117.5px content vs. 686.85px viewport, 569.3px spare.
- [ ] Windows Temp and Prefetch access has only been confirmed as *denied* in this non-elevated dev shell; whether the scan and deletion actually succeed under this tool's real elevated GUI session has not been confirmed on a real device.
- [ ] No live click-through test of the real `Show-MainWindow` has been run for this screen yet -- only structural verification and direct backend-function testing has been done so far.

---

## Release Decision

- [ ] All critical tests passed
- [x] Failed tests were corrected and retested
- [x] No credentials or installer packages are tracked by Git
- [x] README documentation is current
- [ ] Version is ready to change from `1.1.0-dev` to `1.1.0`