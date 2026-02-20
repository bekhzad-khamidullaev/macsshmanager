# Mac SSH Manager (MVP)

Native macOS (Apple Silicon) SSH manager with:
- multi-tab sessions
- saved hosts
- auth via private key or password
- password storage in macOS Keychain

## Build

```bash
cd /Users/sysadmin/Downloads/putty-master/mac-ssh-manager
swift build -c release
```

Binary:
- `.build/release/MacSSHManager`

## Build `.app` bundle

```bash
cd /Users/sysadmin/Downloads/putty-master
./scripts/build-mac-ssh-manager-app.sh
```

Bundle path:
- `/Users/sysadmin/Downloads/putty-master/dist/MacSSHManager.app`

## Notes

- Password mode uses `/usr/bin/expect` to pass the stored password to `ssh`.
- Host list is stored at:
  `~/Library/Application Support/MacSSHManager/hosts.json`
- Passwords are stored in Keychain service `MacSSHManager`.
