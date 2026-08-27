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
- [x] Restyled the Lenovo Asset ID card, per feedback that it "wasn't very good to look at": it had noticeably tighter padding (`12,7` vs. every sibling card's `16`) and an inline title+subtitle crammed onto one line, unlike every other Windows Setup card's title-then-divider-then-description pattern. Increased padding, standardized the field-group margins (previously an inconsistent mix of `0,2,0,3`/`0,2,0,4`), and widened the column gutters slightly (10px/22px -> 12px/26px). This genuinely added height, so it was re-measured against the same off-screen, real-Nunito-font harness used to verify this screen before (real ThinkPad field values, two local users, one with a full name matching its username and one without, to also exercise the local-user-row fix above): first pass overflowed by 106px against the 708.85px viewport, entirely acceptable functionally (the screen already sits in a `ScrollViewer`, so overflow just adds a scrollbar rather than breaking anything) but a bigger regression than intended, so every added margin was trimmed back in several rounds against repeated real measurements down to a **1.5px overflow** -- keeping the padding and consistency fix while landing back within a hair of the previous no-scrollbar state. This is thinner than this screen's own ~50px safe-floor guidance and has not been confirmed on real hardware (2026-08-27). (44 call sites: `GuiWindow.ps1`, `GuiWindowsConfigScreen.ps1`, `GuiApplicationsScreen.ps1`, `GuiDeploymentLogsScreen.ps1`, `GuiDeploymentValidationScreen.ps1`) with a new `Show-GuiDialog` (`Gui\GuiDialog.ps1`, a new module, added to `$ModulePaths` right before `GuiIcons.ps1` since every other Gui module depends on it), per feedback that the plain white native Windows dialog looked out of place against this app's dark theme. Visually it reuses `CompletionModalOverlay`'s own established language (a dimmed backdrop, a centered rounded dark card) and its exact icon glyphs/colors: the circle-check in green for `-Icon Success`, the triangle-exclamation in red for `-Icon Warning` (this app's real semantic palette only has two non-neutral colors -- green for good, red for needs-attention-or-failed, confirmed by grep across `GuiDeploymentValidationScreen.ps1` -- so the same red icon covers both a confirm-before-you-proceed prompt and an outright error, there is no separate amber tone anywhere in this app to invent), and the circle-i already used for every Windows Setup/Device Details card header for `-Icon Info` (the default). `-Buttons OK` (default) or `-Buttons YesNo` returns `"OK"`/`"Yes"`/`"No"` as a plain string. Built as its own WPF `Window` (not an in-window overlay like `CompletionModalOverlay`) specifically so `ShowDialog()` still blocks and returns a result synchronously exactly like `MessageBox.Show` did -- every call site only needed its function name swapped and its result comparison changed from `[System.Windows.MessageBoxResult]::Yes` to `"Yes"`, with no calling code restructured into callbacks. A `$script:GuiMainWindow` reference (set once in `Show-MainWindow`) lets every call site omit an explicit `-Owner`. A `$script:GuiDialogResult` (not a function-local variable) carries the button choice back out of the Click handlers, for the same reason this app's other click handlers are written as plain, non-`.GetNewClosure()`'d scriptblocks: a plain assignment inside a nested handler's own scope would otherwise just shadow a local variable instead of writing back to it. A new `Show-GuiResultDialog` helper (`GuiWindowsConfigScreen.ps1`) maps the common `{Status, Message}` result shape (`Set-DeploymentComputerName`, `New-DeploymentLocalStandardUser`, `Set-DeploymentSleepTimeouts`) to the right icon/title automatically (`Failed` -> red/"Error", `Skipped`/`Preview Only` -> blue/info, anything else -> green/success) instead of repeating that mapping at each of its three call sites. Verified in stages: (1) `Show-GuiDialog` exercised in complete isolation off-screen -- all 4 icon/button combinations rendered correctly (screenshots confirmed the dark card, correct icon/color, correct button layout) and returned the correct string for every button clicked, via the real registered Click handlers; (2) confirmed via `Window.OwnedWindows` that the dialog is sized and positioned to exactly cover its owner, matching `CompletionModalOverlay`'s full-coverage dim-and-center approach; (3) exercised through the real, unmodified app end to end (real `Show-MainWindow`, real click handlers, off-screen) -- clicking Create User with every field empty correctly opened a real, nested `Show-GuiDialog` from inside the main window's own modal loop without deadlocking, was dismissed correctly, and the app kept working afterward (switching screens still worked) (2026-08-26). `-ValidateOnly` passes with 46 modules and 25 required functions (adds `Show-GuiDialog` to the required-functions list). Not yet seen on a real monitor -- the dimmed-backdrop-over-real-content effect specifically (this session's screenshots necessarily show it over a plain grey test background instead of the actual app UI, since the render captures only the dialog's own content) is worth a quick look on real hardware.

### Deployment Distribution

- [x] `Deploy.ps1` (repo root, not part of `$ModulePaths`) downloads the tracked repo contents (scripts and `Config\Applications.json`, a few MB -- gitignored `Installers\` binaries are never part of this) from the public GitHub repo as a ZIP, extracts it to `Desktop\IT Deployment Tool`, and launches `Start.ps1 -Gui`, so a technician at a remote device can run one `irm ... | iex` line instead of manually copying files. Verified for real: the download returns HTTP 200, extraction produces the expected `Start.ps1`/`Modules`/`Config\Applications.json` layout, and `.\Start.ps1 -ValidateOnly` passes on the freshly downloaded copy.
- [x] Added `Import-CloudInstallers.ps1` (repo root, also not part of `$ModulePaths`) to solve the other half of remote deployment: the company OneDrive/SharePoint tenant disables "anyone with the link" sharing, and there is no Azure AD app registration for unattended Microsoft Graph access (confirmed not realistic for this deployment -- would require a company Azure AD admin to register an app, grant it `Sites.Selected` permission, and hand over a client secret/certificate this tool would then have to protect), so per-application automatic fetch-on-selection from OneDrive is not achievable. The realistic flow instead is: a technician signs in once per device (recommended: an incognito/InPrivate browser window, which clears the session on close; a plain sign-out does not reliably clear an Edge/WAM-broker-added Windows account, so decline any "stay signed in to all your apps" prompt), opens the shared folder, and downloads the individually-zipped installer folders (the user's chosen upload convention, one ZIP per app/subfolder rather than one combined ZIP or raw files). `Import-CloudInstallers.ps1` automates everything after that download: it reads `Config\Applications.json` (the same source of truth the app itself uses, so this never duplicates catalog data), builds a match-key lookup from every configured `InstallerPath`/`UninstallerPath` (matching a ZIP's filename against either the installer's own subfolder name, e.g. `CrowdStrike.zip`, or the application's `Name`), special-cases the three applications that have no `InstallerPath` in JSON because their installer modules resolve a hardcoded package directory instead (`CrowdStrike` -> `Installers\EXE\CrowdStrike`, matching `Get-CrowdStrikePackageDirectory`; `OfficeIso` -> `Installers\ISO\Office2024`, matching `OfficeIsoInstaller.ps1`; `Office2021Img` -> `Installers\IMG\Office2021LOP`, matching `Office2021ImgInstaller.ps1`), then extracts each matched ZIP into its correct destination and reports any ZIP it could not match by name so nothing is silently misplaced. A generic top-level type folder (`EXE`/`MSI`/`ISO`/`IMG`/`ZIP`/`Scripts`) is deliberately never used as a match key on its own, since several unrelated applications share those. First version computed the destination as the installer file's own immediate parent folder, which broke for SAP: both SAP GUI catalog entries nest their real `.exe` several vendor-extracted levels below `Installers\EXE\SAP\` (e.g. `.../GUI/Windows/Win32/SapGuiSetup.exe`), so the immediate parent was `Win32`, not `SAP`, and a ZIP named `sap.zip` (the user's real filename) would never have matched -- caught before it shipped, once the user confirmed their actual 4 real filenames (`crowdstrike`, `office2024`, `office2021lop`, `sap`). Fixed by computing the destination from the first path segment under the type folder instead of the file's parent, matching CLAUDE.md's own documented convention that multi-file applications live in one top-level subfolder (`Installers\EXE\SAP\`) regardless of how deeply nested the actual files are inside it. Verified end-to-end against an isolated copy of this repo's real `Config\Applications.json` (never against the real `Installers\` folder) using the user's actual 4 real filenames plus the earlier `WinMTR`/`ThinkPadAssetID` cases: all 6 extracted to the correct subfolder (`sap.zip` -> `Installers\EXE\SAP`, confirmed not the deeper `Win32` path), and an unrelated `RandomStuff.zip` was still correctly reported as unmatched instead of extracted anywhere (2026-08-27). Not yet run against a real company OneDrive download or a real device.

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