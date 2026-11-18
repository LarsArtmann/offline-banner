# go-filewatcher × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-filewatcher` (github.com/LarsArtmann/go-filewatcher) |
| **Reviewed version** | `v2.5.0-6-g26459ba` — latest local tag (HEAD `26459ba`, 2026-11-17; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group C (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — offline-banner's consumers deliberately POLL the state file (stateless sh processes + a staleness heartbeat); file watching requires a resident process the consumers don't have, and cannot express the liveness signal polling gives them for free |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | a *resident* consumer of the state file appears that needs sub-second reaction (e.g. a Go notification daemon or compositor-integrated helper) — a process that exists continuously anyway and can own a watch |

## 1. What the library is

A high-performance, composable file system watcher for Go, built on fsnotify. Raw fsnotify gives you events and nothing else; go-filewatcher adds recursive gitignore-aware walking, 20 filters with AND/OR/NOT composition, 19 middleware (logging, recovery, throttling, batching, circuit breaker, metrics, OpenTelemetry), global and per-path debouncing, ENOSPC resilience, self-healing watch registration, an NFS/FUSE polling fallback backend, and Prometheus/OTel observability. Tested with `-race` and fuzzing; ships `API_STABILITY.md` and `MIGRATION.md`.

Submodules (from local go.mod files):

| Module | Purpose/role |
|---|---|
| `github.com/larsartmann/go-filewatcher/v2` (root, single module) | The watcher: functional options, event pipeline (filter → middleware → channel), `Event{Path, Op, Timestamp, Size, ModTime, Hash}`, polling fallback, self-heal, content hashing (deps: fsnotify, gogenfilter, go-gitignore, x/text, x/time; Go 1.26.7 **and `GOEXPERIMENT=jsonv2`** — the README documents that a build without the experiment fails outright) |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| inotify event delivery | `Watch(ctx)` → read-only event channel; ops Create/Write/Remove/Rename with priority coalescing | Not Applicable | No consumer keeps a resident process: waybar custom modules are exec-per-interval (`interval: 5`), so there is nothing alive to hold a watch |
| Polling backend (`WithPolling`) | Snapshot of modTime/size on a ticker (`watcher_poll.go`), explicitly for NFS/FUSE/Docker volumes where inotify misses | Not Applicable — *but the concept is the consumer's whole design* | The waybar consumer polls by design (see §4); the library itself treats polling as a first-class strategy, validating the choice |
| Liveness detection | Not offered — events only fire when the file changes | Not Applicable — *structural gap that polling beats at* | A dead writer emits no events; the consumer's `updatedAt` heartbeat + `OFFLINE_BANNER_MAX_AGE` (15 s) turns a poll into a positive liveness check, which no watch-based design provides |
| Debounce (global + per-path) | Coalesce editor-style event bursts | Not Applicable | The state file is rewritten atomically once per probe transition/heartbeat; there is no burst to coalesce |
| Filters + combinators | 20 filters (extensions, ops, size, age, gitignore, generated-code) with AND/OR/NOT | Not Applicable | The watch set would be exactly one file; filtering one path needs no pipeline |
| Middleware chains | 19 middleware incl. recovery, throttle, dedupe, metrics, OTel | Not Applicable | No event stream to process; consumers do a single `jq` read per interval |
| Self-heal + ENOSPC resilience | Auto-retry failed watch registrations; survive inotify watch exhaustion | Not Applicable | No watch registrations exist to heal; the poller's failure mode (file unreadable → "banner?" stale marker) is already fail-closed |
| Content hashing / observability | SHA-256 event hashes, Prometheus counters, OTel tracing, health endpoint | Not Applicable | Consumers compare `updatedAt` epoch seconds — cheaper and sufficient |

## 3. Usage evidence in offline-banner

```
rg -in "filewatcher" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  → 0 matches
rg -n "fsnotify|inotify" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' → 0 matches
find /home/lars/projects/offline-banner \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) -not -path '*/.git/*' → 0 files
```

(The `!docs/review/**` exclusion skips this audit's own reports, which necessarily name the libraries.)

Conclusion: zero references; no Go runtime exists in the consumer (verified 2026-11-18). The polling evidence instead:

- `/home/lars/projects/offline-banner/contrib/offline-banner-waybar` — waybar config block declares `"interval": 5`; the script reads `$XDG_RUNTIME_DIR/offline-banner/state`, compares `.updatedAt` against `OFFLINE_BANNER_MAX_AGE` (default 15 s, documented as ~three probe intervals), and emits a `{"class":"stale","text":"banner?"}` marker when the heartbeat ages out — *"a stale heartbeat means the unit is effectively dead, so the consumer must say so instead of staying silent."*
- `/home/lars/projects/offline-banner/flake.nix` — the CI harness polls the same file the same way (`assert_state_jq` loops up to 40 × 0.25 s), for the documented reason that the state write is a spawned sh process that can lag and *"single reads of this file are therefore never evidence — poll."*

## 4. Should offline-banner adopt it?

**SHOULD NOT — and the polling-vs-watching decision is the interesting part, because offline-banner chose polling deliberately and the library's own design agrees.**

**Why polling was chosen:** every consumer is a stateless POSIX sh process spawned on a cadence — a waybar custom module is exec-and-parse per `interval`, and DMS widgets are the same shape. inotify is a *subscription* API: it needs a process that stays alive between events, holds a watch descriptor, and drains a fd. Giving each of these consumers a persistent watcher daemon would mean a new long-running unit per consumer, which is precisely the "silently died last Tuesday" failure mode the README's observability section rejects. Polling keeps each consumer's failure domain to one short-lived process.

**What watching could not deliver anyway:** the decisive requirement is liveness, not change notification. The state file's `updatedAt` is a heartbeat — rewritten every probe, asserted by CI (`state file was not rewritten between probes (heartbeat broken)`). A watch fires only on change; a dead writer produces no change, so an inotify consumer would sit on a healthy-looking file while the unit rots. The polling consumer computes `now - updatedAt > max_age` and fails closed. Watching answers "did something happen"; polling-plus-heartbeat answers "is the producer alive" — and only the second question matters for a fail-closed banner.

**What watching would degenerate into here:** the state file is rewritten atomically on every probe (~seconds) forever. An inotify consumer would receive a Write event at roughly the probe cadence — i.e. it would be polling with extra syscalls, plus watch-management complexity. Notably, go-filewatcher itself ships `WithPolling` because inotify *misses things* (NFS/FUSE/overlayfs) — the library's own architecture treats periodic snapshotting as a legitimate backend, not a hack, which is as close to a peer review of offline-banner's choice as a Go library can give.

**Cost of a forced adoption:** a Go toolchain (the module additionally demands `GOEXPERIMENT=jsonv2` on its Go 1.26.7 floor — real friction even for willing Go consumers), a resident process per consumer, and still no liveness signal without inventing the heartbeat that already exists. Zero runtime benefit; pure bug-fix surface — the exact net-negative the owner's fleet constraint says to refuse.

## 5. Fleet perspective

The verdict encodes a reusable decision rule for the whole fleet: *watch when a resident process wants push latency; poll when consumers are ephemeral and need liveness proof.* offline-banner is the fleet's worked example of the second branch, and it got the details right — the heartbeat timestamp, the fail-closed stale marker, and CI that polls rather than single-reads. The transferable doctrine back toward go-filewatcher's domain: any fleet watcher should pair its event stream with a producer-side heartbeat so "no events" can be distinguished from "producer dead"; the library's middleware family has a slot for exactly that check (a staleness middleware) if it ever wants it. No dependency moves in either direction; both sides keep their wins.

## 6. If the flip trigger fires

1. **A resident helper needs sub-second reaction to state changes** (e.g. a Go daemon driving compositor effects or notifications on transition): use `filewatcher.New([]string{stateDir}, WithFilter(FilterOperations(Write)), WithDebounce(...))` on the state file, and — critically — keep the max-age check: treat an event burst that stops while `updatedAt` ages out as producer death.
2. **Watch the directory, not just the file** — the writer is `mv -f tmp state` (rename), so a file-scoped raw watch misses the swap; go-filewatcher's recursive watch + `FilterOperations(Rename, Write)` on `$XDG_RUNTIME_DIR/offline-banner/` handles the atomic-rename pattern out of the box.
3. **Start with defaults, add middleware only under evidence** — logging + recovery middleware at most; reach for metrics/OTel only if the helper itself becomes a service worth observing.
4. **Keep the sh poller as the reference consumer regardless** — `contrib/offline-banner-waybar` remains the contract any watcher-based consumer must match (including the stale marker).

## 7. Verify block

```bash
git -C /home/lars/projects/go-filewatcher describe --tags                           # v2.5.0-6-g26459ba (or newer)
rg -in "filewatcher|fsnotify|inotify" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  # 0 matches
find /home/lars/projects/offline-banner \( -name '*.go' -o -name 'go.mod' \) -not -path '*/.git/*'  # 0 files
rg -n "OFFLINE_BANNER_MAX_AGE|interval" /home/lars/projects/offline-banner/contrib/offline-banner-waybar | head -4  # the polling consumer + heartbeat threshold
rg -n "assert_state_jq|heartbeat broken" /home/lars/projects/offline-banner/flake.nix | head -4    # CI polls too; heartbeat is asserted
```
