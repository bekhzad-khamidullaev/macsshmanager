# Changelog

## v0.1.3 - 2026-03-01
- Added VS Code-style default shortcuts on macOS (for example `⌘B` sidebar, `⌘J` TTY/Files toggle).
- Added compact workspace layout to maximize useful content area.
- Reworked file transfer into dual-pane commander layout (`LOCAL`/`REMOTE`).
- Added commander hotkeys `F3`-`F8` for view, edit, copy, rename, create directory, and delete.
- Added remote create/rename/delete operations for SFTP/SCP/FTP backends.
- Improved file operation safety: local deletes now move to Trash, local rename checks conflicts, downloads avoid overwrite via unique destination naming.
- Hardened keyboard handling so function hotkeys do not intercept text input fields or modified key combinations.
- Removed timing-based remote preview update and replaced it with deterministic async preview loading.

## v0.1.2 - 2026-02-28
- Added OpenSSH `~/.ssh/config` import/export support.
- Added OpenSSH key workflow support with optional explicit key path and default key or `ssh-agent` fallback.
- Fixed subprocess output deadlocks by draining process pipes concurrently.
- Fixed stale file browser async updates when switching hosts, directories, or previews.
- Persisted group host settings and group templates across relaunch and import/export.
- Improved sidebar performance by caching store lookups, reducing tree rebuild costs, and deduplicating file browser activation.
- Fixed sidebar interaction so selection highlight is stable and single click does not unexpectedly open a session.
- Refined the UI toward a more native macOS look and feel.
- Added a custom app icon variant to reduce confusion with the built-in Terminal app.
- Regenerated macOS `.app` and `.dmg` release artifacts.
