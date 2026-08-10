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
- SAP GUI installation
- CrowdStrike installation
- Microsoft Office 2024 installation
- Microsoft Office 2021 LOP installation
- Computer rename
- Local standard user creation and group verification
- Actual power and sleep configuration changes

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

- [x] `Start.ps1 -ValidateOnly` loads all 30 modules
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

---

## Application Installation

- [ ] Google Chrome installation works
- [ ] Viber installation works
- [ ] UltraViewer installation works
- [ ] AnyDesk installation works
- [ ] SAP GUI installation works
- [x] Installed applications are skipped correctly
- [x] Missing installers are reported correctly
- [x] Installation summary displays correct results

> Local, non-destructive acceptance testing is complete. The remaining installation and system-change tests require an authorized clean deployment device. Version `1.1.0-dev` will remain unchanged until those tests pass.

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