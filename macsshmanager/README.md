# Mac SSH Manager (MVP)

Native macOS (Apple Silicon) SSH manager with:
- multi-tab sessions
- saved hosts
- auth via private key or password
- password storage in macOS Keychain

## Build

```bash
cd /Users/sysadmin/Downloads/macsshmanager/macsshmanager
swift build -c release
```

Binary:
- `.build/release/macsshmanager`

## Build `.app` bundle

```bash
cd /Users/sysadmin/Downloads/macsshmanager
./scripts/build-macsshmanager-app.sh
```

Bundle path:
- `/Users/sysadmin/Downloads/macsshmanager/dist/macsshmanager.app`

## Notes

- Password mode uses `/usr/bin/expect` to pass the stored password to `ssh`.
- Host list is stored at:
  `~/Library/Application Support/macsshmanager/hosts.json`
- Passwords are stored in Keychain service `macsshmanager`.
