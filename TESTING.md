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
- [ ] Both tabs render correctly on an authorized test device at 1360x860 with no scrollbar on either
- [ ] Switching between Windows Setup and Device Details does not re-run the device queries, and both Refresh buttons grey out together during a load
- [ ] Rename Computer works end-to-end on an authorized test device
- [ ] Create Local Standard User works end-to-end, including password entry via the masked password fields, on an authorized test device
- [ ] Password is not displayed, logged, or persisted anywhere during GUI-based user creation
- [ ] Apply Power Settings works end-to-end on an authorized test device
- [ ] Copy Device Details (now on the Device Details toolbar) still copies the full 18-field summary to the clipboard
- [x] Added a Hardware group (Processor, Memory, Storage, TPM) to the Session & Hardware card, filling the gap flagged when the tab split first shipped: the mockup's Hardware tile was speculative because none of those fields existed in `Get-WindowsConfigurationReport`. Implemented in `WindowsConfiguration.ps1`: Processor and Memory are added to the existing cached `Get-WindowsConfigurationIdentity` (Win32_Processor.Name, and the sum of `Win32_PhysicalMemory.Capacity` rather than `Win32_ComputerSystem.TotalPhysicalMemory`, since the latter can under-report versus installed capacity) since neither changes during a session; Storage is queried fresh on every report via a new `Get-WindowsConfigurationStorage` (`Win32_LogicalDisk` for `$env:SystemDrive`), since free space changes as this tool installs applications; TPM state comes from `Win32_Tpm` in the `root\cimv2\Security\MicrosoftTpm` namespace, queried with `-ErrorAction SilentlyContinue` since a VM without a virtual TPM, a device with no TPM chip, or an access-denied policy must degrade to "Not Available" rather than throw. TPM renders as a colored pill (green "Ready 2.0" / gray "Not Ready" or "Not Available") matching the existing Administrator pill pattern. Verified against real hardware CIM queries on this dev machine before writing any GUI code (Processor: "Intel(R) Core(TM) Ultra 5 225U"; Memory: 16 GB; Storage: "315 GB free of 475 GB"; TPM: "Not Available" when queried non-elevated, consistent with `Get-CimInstance` returning null rather than throwing under `SilentlyContinue`) (2026-08-25). Re-measured Device Details after adding the group: the Session & Hardware card grew from 352.8px to 354.5px and is now marginally the taller of the two cards, but the screen still fits with 347.6px of spare room (2026-08-25). Real TPM readiness has NOT been confirmed on an elevated real-device run, since this was only tested non-elevated in this environment.

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

## Release Decision

- [ ] All critical tests passed
- [x] Failed tests were corrected and retested
- [x] No credentials or installer packages are tracked by Git
- [x] README documentation is current
- [ ] Version is ready to change from `1.1.0-dev` to `1.1.0`