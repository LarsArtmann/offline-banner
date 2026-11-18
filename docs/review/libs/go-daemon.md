# go-daemon × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-daemon` (github.com/LarsArtmann/go-daemon) |
| **Reviewed version** | `v0.4.0-38-gb6af9f1` — latest local tag (HEAD `b6af9f1`, 2026-11-18; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group D (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — offline-banner's daemon story is systemd itself; no Go process exists to host a socket-server toolkit, and the library's own non-goals assign supervision to systemd |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | offline-banner grows a real Go long-lived process with its own IPC socket (e.g. the ROADMAP's "live retuning" control daemon) — until then the unit file + QML Process cover everything go-daemon offers |

## 1. What the library is

`go-daemon` is a "mechanism, not policy" toolkit for **long-lived daemons served over unix domain sockets**, extracted from project-discovery-daemon. It owns the socket lifecycle (stale-socket cleanup, directory creation, `0600` permissions, removal on every exit path), `sd_notify` integration (READY/STOPPING/WATCHDOG, silent no-ops without systemd), graceful drain with ordered `Lifecycle` hooks, unix-socket HTTP transports, JSON/CBOR content negotiation, spec-pinned SSE framing, and an execution-trace flight recorder.

**Important correction to a common expectation:** this is *not* a classic fork/daemonize library — there are no PID files, no double-fork detach, no signal-handling scaffolding in the API. It is a socket-server/transport toolkit for daemons that are **expected to run in the foreground under a service manager**. Its own README non-goals say it plainly: *"it does not package, deploy, or supervise your daemon (systemd owns that — but see docs/supervision.md for recommended unit settings)"*.

Single module: `github.com/LarsArtmann/go-daemon` (go 1.27.2; deps: `coreos/go-systemd/v22`, `go-codec`, `go-flightrecorder`, `go-sse/sseparse`, `prometheus/client_golang`).

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Socket server lifecycle (`SocketServer`/`NewServer`) | Stale-socket cleanup, dir creation, `0600` perms, socket removal on every exit path, ordered `Lifecycle` hooks | Not Applicable | No Go daemon exists; the only long-lived process is Quickshell started by systemd from the unit's `ExecStart` |
| sd_notify integration (`NotifyReady`/`NotifyStopping`/`Watchdog`) | `READY=1`/`STOPPING=1`, watchdog keepalive at `WatchdogSec/2` per `sd_watchdog_enabled(3)`, notify counters | Not Applicable | Unit is `Type = "simple"` (module.nix:1160); Quickshell has no sd_notify seam, and the banner's "readiness" is user-visible rendering, not a start handshake |
| Graceful drain & shutdown ordering | Explicit `Startup` → `OnListen` → `OnShutdown` hook contract, drain inside `TimeoutStopSec` | Fully Leveraged (as doctrine) | The same "ordered teardown" principle is enforced by systemd: `Restart = "always"` + `RestartSec = "5s"` + journal-visible transitions; QML timers are torn down by the compositor exit path |
| Stale-runtime-file hygiene (`CleanStaleSocket`, `IsSocketAlive`) | Probe-and-remove a dead predecessor's socket before listening | Fully Leveraged (as doctrine) | The 2026-11-18 smoke hazard (shared `RuntimeDirectory` deleted on transient stop, orphaning the live unit's bind, fixed by `busctl RestartUnit`) is exactly the class of bug this capability exists for — offline-banner solves it at the systemd layer (per-instance `RuntimeDirectory=` shapes, the TODO_LIST smoke fix) rather than in a Go process |
| Unix-socket HTTP client/server transports | Pooled keep-alive transports, no-timeout SSE variant | Not Applicable | Banner IPC is a polled JSON state file + journal lines; there is no RPC channel to carry a transport |
| Content negotiation (`ResolveRequestCodec`/`WriteJSON`/JSON v2) | JSON/CBOR media-type matching, q-value ranking, `Vary: Accept` | Not Applicable | The state file is a fixed hand-shaped JSON written by `printf`+`mv` inside QML's spawned `sh`; consumers (jq in POSIX sh) have no Accept dimension |
| SSE framing (`ParseSSEData`) | WHATWG-spec multi-line data, heartbeats, size limits | Not Applicable | No event-stream surface; the heartbeat is the `updatedAt` field rewritten on every probe |
| Flight recorder (`FlightRecorder`, TraceHandler) | Slow-request auto-trigger, Prometheus metrics, `go tool trace` streaming | Not Applicable | Performance debugging here is journal greps (`journalctl \| grep "banner state="`) and `systemd-analyze security` — a 4.7 Hz probe loop has no request path to trace |
| Supervision & resource policy (docs/supervision.md) | Recommended unit settings (`Type=notify`, `WatchdogSec`, `Nice`, `CPUSchedulingPolicy=idle`) — explicitly *not* code | Fully Leveraged (as doctrine) | module.nix:1159-1164 already implements the supervisor side natively (`Type = "simple"`, `Restart = "always"`, `RestartSec = "5s"`, `MemoryMax = "256M"`, full sandbox posture, systemd-analyze security 5.8 MEDIUM accepted); the library itself states this layer belongs to the unit file |

## 3. Usage evidence in offline-banner

The EXACT commands run (all exclude the reports directory):

- `rg -n "go-daemon" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (exit 1)
- `find /home/lars/projects/offline-banner -name 'go.mod' -not -path '*/.git/*'` → **0 files**
- `find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*'` → **0 files**
- `rg -n -i "golang|go build|go test|\bgo 1\.|go toolchain" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' -g '!flake.lock'` → **0 matches** (exit 1)

Conclusion: zero references; no Go runtime or toolchain exists anywhere in the consumer (including `website/`, which is Astro + TypeScript). The only "daemon" in offline-banner is the systemd **user unit** that module.nix derives — supervision lives in the unit file, not in a library.

## 4. Should offline-banner adopt it?

**SHOULD-NOT — and go-daemon agrees.** The unit-file-derived supervision stack already provides everything go-daemon's README *defers to systemd*: `Restart = "always"` + `RestartSec = "5s"` gives restart-on-death; `MemoryMax = "256M"` gives the resource ceiling; `RuntimeDirectory=`/`StateDirectory=` give FHS-correct runtime/state paths with cleanup on stop (the exact niche `/run` + stale-socket cleanup serves in Go daemons); journald captures the banner's structured `banner state=` tokens; the sandbox (ProtectSystem=strict, ProtectHome=read-only, 5.8 MEDIUM security score) is supervisor policy go-daemon's own docs/supervision.md tells Go operators to reach for.

Adding go-daemon would require a Go daemon *process* first — a second supervisor layer wrapped around a process systemd already supervises. That is the classic double-supervision anti-pattern: two components each believing they own restart policy (`Restart=on-failure` in the unit vs. in-process watchdog/retry), divergent liveness opinions, and extra failure modes with zero new capability for a banner whose whole job is to render QML and append JSONL. Even the ROADMAP's "live retuning without restart" idea (an IPC channel or watched file) is better served by the existing state-file/env contract or a watched-file flag than by a unix-socket HTTP server with content negotiation.

The honest conceptual read: go-daemon and offline-banner independently converged on the same doctrine — *the service manager supervises; the application speaks the manager's protocol*. go-daemon implements the application side of that split (sd_notify, socket hygiene); offline-banner implements the unit side of it and doesn't need the application side because Quickshell, not Go, is the process.

**Owner constraint:** adopting here buys a dependency for a process that cannot exist. Net-negative; the desired outcome is exactly this NOT-APPLICABLE.

## 5. Fleet perspective

This verdict costs the owner nothing: go-daemon's value lands in fleet projects that *have* Go daemons (go-credentials-store's server, for instance, depends on go-daemon v0.4.0 — the intra-fleet dependency already flows where it is useful). What *does* transfer from go-daemon to offline-banner is doctrine, and offline-banner already holds it: supervisor-owned lifecycle, FHS runtime directories provisioned by the manager, structured journal tokens for post-hoc debugging, and stale-runtime-file hygiene — the 2026-11-18 smoke-transient hazard (shared `RuntimeDirectory` orphaning) is the exact bug class go-daemon's `CleanStaleSocket` prevents in Go, and offline-banner is fixing it with the right tool (distinct per-instance `RuntimeDirectory=` shapes). No pattern transfer is needed; the two repos agree by construction.

## 6. If the flip trigger fires

1. **A Go retuning/control daemon** (if "live retuning without restart" is ever built in Go): host it as `cmd/` in a Go-enabled fork or sibling repo, use `SocketServer` with `Lifecycle` hooks + `NotifyReady`, run it as a *second* systemd user unit (`Type=notify`, `WatchdogSec`), and let it own the socket path under `%t/offline-banner/`. Keep the banner itself unsupervised by Go.
2. **sd_notify for the banner unit, Go-free**: if startup accuracy ever matters, the cheaper move is not go-daemon but systemd's own `Type=notify` on a wrapper that can speak sd_notify — or simply keeping `Type=simple` since a dead QML engine is caught by the `updatedAt` staleness heartbeat anyway.
3. **Socket-file hygiene codification**: port the *lesson* of `CleanStaleSocket` into the smoke-runbook check (already planned in TODO_LIST: distinct `RuntimeDirectory=offline-banner-smoke`), so no transient can delete the live unit's namespace bind.

## 7. Verify block

```sh
# 1. Library version facts
git -C /home/lars/projects/go-daemon describe --tags   # v0.4.0-38-gb6af9f1
git -C /home/lars/projects/go-daemon log -1 --format='%h %ad' --date=short  # b6af9f1 2026-11-18
find /home/lars/projects/go-daemon -name go.mod -not -path '*/.git/*' | wc -l  # 1

# 2. Zero usage in the consumer (reports excluded)
rg -n "go-daemon" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  # no output, exit 1
find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*' | wc -l  # 0

# 3. The supervision layer that makes the library moot
grep -n 'Type = "simple"\|Restart = "always"\|MemoryMax' /home/lars/projects/offline-banner/module.nix  # lines 1160, 1162, 1164
```

All three blocks were executed on 2026-11-18 and reproduce the stated results.
