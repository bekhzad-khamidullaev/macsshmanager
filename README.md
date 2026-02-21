# Mac SSH Manager
Native macOS SSH manager with saved hosts, multi-session workflow, file transfer support, and PuTTY-compatible host settings.

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support-FFDD00?logo=buymeacoffee&logoColor=000000)](https://buymeacoffee.com/bekhzadkhamidulloh)

## Features
- Multi-tab terminal sessions.
- Saved hosts with SSH key or password auth.
- Password storage in macOS Keychain.
- File transfer panel (SFTP/SCP/FTP modes).
- PuTTY-style advanced host settings.

## Project structure
- `mac-ssh-manager/` - Swift package source for the app.
- `scripts/build-mac-ssh-manager-app.sh` - build script for `.app` bundle.
- `dist/` - built artifacts (`.app`, `.dmg`).

## Build
### Requirements
- macOS (Apple Silicon recommended)
- Xcode Command Line Tools

Install CLT:
```bash
xcode-select --install
```

Build app bundle:
```bash
./scripts/build-mac-ssh-manager-app.sh
```

Output:
- `dist/MacSSHManager.app`

## Release artifact
Current release includes downloadable DMG:
- https://github.com/bekhzad-khamidullaev/putty-master/releases/tag/v0.1.1

## Support
If this project helps you, you can support development:
- Buy Me a Coffee: https://buymeacoffee.com/bekhzadkhamidulloh

## Contributors
- Brian Jiang
- Alan ZHU
