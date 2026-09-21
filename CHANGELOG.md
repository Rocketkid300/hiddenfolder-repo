# Hidden Folder — Changelog

## [2.3.3] — 2026-09-21

### Fixed
- **Main-Thread LaunchServices Deadlock**: Resolved UI hang caused by synchronous `allApplications` lookups and icon decoding on the main runloop by moving fetch operations to background queues with a loading state (`HV2Apps`).
- **Safe KVC Evaluation**: Added `HV2SafeValue` safety checks around `valueForKey:` calls to prevent SIGABRT crashes on unrecognized app keys.

---

## [2.0.9] — 2026-09-21

### Fixed
- banner removal (all calls, logs kept)
- hide-every-instance traversal
- relaunch re-sanitize
- protected-ID refusal + self-heal
- removed unevidenced search/share/widget filter hooks (no fake coverage claimed)