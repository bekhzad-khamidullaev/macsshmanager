# Changelog

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
