
# Jamf-Framework-Redeploy
**This is a fork of the superb original Jamf Framework Redeploy app by [red5coder](https://github.com/red5coder), which you can find [here](https://github.com/red5coder/Jamf-Framework-Redeploy).**
This is a great app which any Mac admin should have, now with a CSV upload for a build redeployment.

With the release of Jamf Pro 10.36, a new API endpoint was added, which allows you to distribute a QuickAdd.pkg to the macOS client to re-deploy the Jamf Framework. Under the hood, its using the InstallEnterpriseApplication MDM command.

The Jamf Framework Redeploy utility provides both **single computer** and **bulk operations** modes to easily call this API and re-deploy the Jamf Framework for selected computers.

## 🖥️ Interface Modes

### Single Computer Mode
Perfect for deploying to individual machines with real-time feedback.

<img src="https://raw.githubusercontent.com/mat-griffin/Jamf-Framework-Redeploy/refs/heads/main/images/single_mode.png" alt="Single Computer Mode" width="600">

### Bulk Operations Mode
Efficiently process multiple computers using CSV import with progress tracking.

<img src="https://raw.githubusercontent.com/mat-griffin/Jamf-Framework-Redeploy/refs/heads/main/images/buk_mode.png" alt="Bulk Operations Mode" width="600">


## 📋 Requirements

- A Mac running macOS Ventura (13.0) or later
- Jamf Pro API Role/Client with the following minimum permissions:
  - Send Computer Remote Command to Install Package
  - Read - Computers
- Jamf Pro Server Settings:
  - Read - Checkin
- The Apple MDM Framework must still be present on the target Mac
- Serial number(s) of the affected Mac(s)

## 📄 CSV File Format

For bulk operations import a .csv.
The CSV can be a simple list of serials no header is required or multiple columns.
See the example CSV files:
[Example CSV folder](https://github.com/mat-griffin/Jamf-Framework-Redeploy/tree/main/example%20csv)

## 🚀 Usage

Download the .pkg. Your Mac may display a warning dialogue.

<img width="300" alt="Open Dialogue warning" src="https://raw.githubusercontent.com/mat-griffin/Jamf-Framework-Redeploy/refs/heads/main/images/dialogue.png">

If so open your System Settings, goto Privacy and scroll down to the Security section and click Open Anyway and follow any other on screen prompts to allow the app to run.

<img width="450" alt="Approve Anyway in System Settings" src="https://raw.githubusercontent.com/mat-griffin/Jamf-Framework-Redeploy/refs/heads/main/images/approveinstall.png">

1. **Configure Authentication**:
   - Enter your Jamf Pro server URL
   - Provide your API Client ID and Secret
   - Optionally save credentials to Keychain

2. **Single Computer Mode**:
   - Enter the Mac's serial number
   - Click "Redeploy" to initiate the process

3. **Bulk Operations Mode**:
   - Click "Import CSV" to select your computer list
   - Review the loaded computers
   - Click "Start Bulk Redeploy" to process all computers
   - Monitor progress with the built-in status tracker

## ✅ Success Verification

If successful, you'll see an `InstallEnterpriseApplication` MDM command in the device's management history:

<img width="1282" alt="Management History" src="https://user-images.githubusercontent.com/29920386/211600803-88c253bc-0ff1-4ced-a753-c6151ceae58c.png">

## 📝 Version History

- **v1.2** - **My Forked update** - Added bulk operations mode, modern macOS UI, dark mode support, and CSV import functionality
- **v1.1** - Authentication now uses API Roles and Clients. Support for basic authentication has been removed.
- **v1.0** - Initial release with single computer deployment capability

**Once again huge thanks to [red5coder](https://github.com/red5coder)** for this app!
