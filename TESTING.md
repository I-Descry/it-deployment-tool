# IT Deployment Tool Testing

## Current Test Version

`1.1.0-dev`

The development version must remain unchanged until all required acceptance tests pass on an authorized clean Windows device.

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

## CrowdStrike

- [ ] CrowdStrike package is detected
- [ ] Customer ID format is validated
- [ ] Credentials are not displayed or logged
- [ ] CrowdStrike installer starts correctly
- [ ] Existing CrowdStrike installation is skipped
- [ ] Falcon service is detected after installation

> Package preflight passed on the current device. Fresh installation remains untested and requires an authorized clean deployment device.

---

## Microsoft Office 2024

- [ ] Office 2024 ISO is detected
- [ ] ISO mounts successfully
- [ ] Office installation starts successfully
- [ ] Office 2024 installation is detected afterward
- [ ] ISO is dismounted after processing
- [ ] Product activation remains manual

> Package preflight passed on the current device. Fresh installation remains untested and requires an authorized clean deployment device.

---

## Microsoft Office 2021 LOP

- [ ] Office 2021 IMG is detected
- [ ] IMG mounts successfully
- [ ] Microsoft signature validation passes
- [ ] Office 2021 installation starts successfully
- [ ] Office 2021 installation is detected afterward
- [ ] IMG is dismounted after processing
- [ ] Conflicting Office installation is blocked
- [ ] Product activation remains manual

> Package preflight passed on the current device. Fresh installation remains untested and requires an authorized clean deployment device.

---

## Windows Configuration

- [x] Computer rename preview works
- [ ] Computer rename works on an authorized test device
- [x] Local standard user creation works
- [ ] Created account is not an administrator
- [ ] Password is not displayed or logged
- [ ] Power and sleep configuration works
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

## Release Decision

- [ ] All critical tests passed
- [ ] Failed tests were corrected and retested
- [x] No credentials or installer packages are tracked by Git
- [ ] README documentation is current
- [ ] Version is ready to change from `1.1.0-dev` to `1.1.0`