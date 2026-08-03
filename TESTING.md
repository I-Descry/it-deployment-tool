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
- [ ] Installed applications are skipped correctly
- [ ] Missing installers are reported correctly
- [ ] Installation summary displays correct results

---

## CrowdStrike

- [ ] CrowdStrike package is detected
- [ ] Customer ID format is validated
- [ ] Credentials are not displayed or logged
- [ ] CrowdStrike installer starts correctly
- [ ] Existing CrowdStrike installation is skipped
- [ ] Falcon service is detected after installation

---

## Microsoft Office 2024

- [ ] Office 2024 ISO is detected
- [ ] ISO mounts successfully
- [ ] Office installation starts successfully
- [ ] Office 2024 installation is detected afterward
- [ ] ISO is dismounted after processing
- [ ] Product activation remains manual

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

---

## Windows Configuration

- [ ] Computer rename preview works
- [ ] Computer rename works on an authorized test device
- [ ] Local standard user creation works
- [ ] Created account is not an administrator
- [ ] Password is not displayed or logged
- [ ] Power and sleep configuration works
- [ ] Current Windows configuration report displays correctly

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
- [ ] Application results are logged
- [x] Validation results are logged
- [x] Validation summary is logged
- [x] Credentials and product keys are not logged
- [x] Session completion is logged
- [x] Recent logs can be viewed from the tool

---

## Release Decision

- [ ] All critical tests passed
- [ ] Failed tests were corrected and retested
- [ ] No credentials or installer packages are tracked by Git
- [ ] README documentation is current
- [ ] Version is ready to change from `1.1.0-dev` to `1.1.0`