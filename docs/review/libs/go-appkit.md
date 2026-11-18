# go-appkit × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-appkit` (github.com/LarsArtmann/go-appkit) |
| **Reviewed version** | `preset/v0.1.1-19-g98875e8` — latest local tag (HEAD `98875e8`, 2026-11-15; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group E (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — go-appkit kits a Go HTTP service; offline-banner's "app" is a QML render loop supervised by systemd, with no Go process to kit |
| **Score** | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural) |
| **Flip trigger** | A Go application joins the repo — or the fleet consumes appkit in a sibling project whose patterns offline-banner mirrors |

## 1. What the library is

From its README: "Production-ready HTTP service framework for Go. Composes httputil, charmbracelet/log, and go-error-family into one coherent service lifecycle." One `appkit.NewService(ServiceConfig{...})` call yields an HTTP server with graceful drain/shutdown on SIGINT/SIGTERM, a default middleware stack (ServerTiming → Recovery → RequestID → Logging → Timeout → SecurityHeaders), `/health`, `/health/live`, `/health/ready` endpoints, pretty structured logging, and error classification via go-error-family. Each sub-module is independently versioned and opt-in; the `security` module contributes nothing to the default stack.

Module families (15 go.mod files in the repo):

| Family (module path) | Purpose/role |
|---|---|
| root / core (`go.mod`) | Service lifecycle, default middleware stack, health endpoints, logging |
| `preset` | One-call bootstrap composing the family: the always-on spine (core Service, sd_notify, health dashboard, error pages, error classification, version stamp) plus opt-in legs (OTel, security profiles, realtime SSE) |
| `systemd` | sd_notify for `Type=notify` units: READY=1 post-listen, STOPPING=1 at drain start, `WatchdogSec/2` keepalive |
| `health` | go-health probes (critical/non-critical, startup latch) + real-time health dashboard, one wiring call |
| `realtime` | SSE hub + handler: broadcast, replay, heartbeat, Last-Event-ID resume |
| `cqrs` | CQRS/event-sourcing over go-cqrs-lite's `system` engine — event store, projections, DLQ, command/query facade, metrics |
| `docs` | Auto-generated OpenAPI/AsyncAPI/D2 docs from Go types |
| `errorpages` | Pretty classified error pages (HTML) and contracts (JSON) |
| `httpx` | JSON error contract matching the errorpages taxonomy — one taxonomy, two surfaces |
| `config` | YAML/JSON file layer flattened into the same key space the env parser consumes |
| `otel` | Opt-in OpenTelemetry: provider setup, otelhttp tracing/metrics middleware, trace-correlated logs |
| `flightrecorder` | On-demand runtime/trace capture middleware + snapshot endpoint |
| `flightrecorderhealth` | Bridges flight recorder with go-health: dashboard visibility + auto-capture on health failures |
| `security` | Opt-in hardening middleware: CSRF, rate limiting, body limits, sanitization, CSP nonce, security headers |
| `integration` | Contract-parity tests (e.g. exactly one OTel `Setup` per process across appkit + go-cqrs-lite stacks) |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Service lifecycle (`NewService`/`Run`/`Close`, graceful drain) | Start/stop/drain lifecycle for a Go HTTP server | Not Applicable | The runtime process is Quickshell (QML); its lifecycle is owned by systemd, not a Go main |
| HTTP middleware stack (ServerTiming→Recovery→RequestID→Logging→Timeout→SecurityHeaders) | Composable request middleware | Not Applicable | No HTTP server exists; the only HTTP-adjacent artifact is a static website built by Astro |
| Health endpoints (`/health`, `/health/live`, `/health/ready`) | Liveness/readiness surfacing | Fully Leveraged (as doctrine) | The same posture exists in systemd shape: `Restart = "always"` + `RestartSec = 5s` + `MemoryMax` (module.nix ~:1160-1164), and the `vm-smoke` check asserts the unit's health by inspecting `ExecMainStatus`/journal after a real boot |
| `systemd` module (sd_notify for `Type=notify`) | READY/STOPPING notification + watchdog keepalive | Not Applicable | The unit is deliberately `Type = "simple"` (module.nix ~:1160) and its main process is quickshell; sd_notify requires the supervised process itself to speak the protocol — a Go module cannot notify for a QML process |
| `realtime` SSE hub (broadcast, replay, heartbeat, Last-Event-ID) | Push fan-out of live state | Not Applicable | The consumer channel question was already settled in favor of a polled atomic state file (`contrib/offline-banner-waybar` + the DMS plugin read `%h/.local/state/offline-banner/history.jsonl`'s sibling state file); no server process exists to host SSE |
| `health` probes + dashboard | Startup latch, critical/non-critical probes, real-time dashboard | Not Applicable | Health is asserted by flake checks (probe-transitions, unit-verify, vm-smoke), not by a runtime dashboard |
| `cqrs` module (event store, projections, DLQ) | go-cqrs-lite composition for appkit services | Not Applicable | No Go process and the domain is a single-writer QML state machine (see go-cqrs-lite.md) |
| `docs` (OpenAPI/AsyncAPI/D2 from Go types) | Auto-generated API docs | Not Applicable | No API surface; docs-drift is handled by a dedicated flake check comparing rendered docs to the module |
| `config` (YAML/JSON + env flat key space) | Unified config loading | Not Applicable | Configuration is NixOS module options → systemd env vars; Nix already provides the typed config layer |
| `errorpages`/`httpx` (classified error HTML/JSON) | One taxonomy, two renderings | Not Applicable | Errors surface as systemd journal lines and QML state, not HTTP responses |
| `otel`/`flightrecorder`(health) | Tracing, metrics, trace capture | Not Applicable | Structured journal lines are the observability surface; no Go runtime to instrument |
| `security` middleware | CSRF, rate limits, CSP nonce | Not Applicable | The unit's sandbox (ProtectSystem etc., module.nix) is the security posture, enforced by systemd |

## 3. Usage evidence in offline-banner

Exact commands run (all include the reports-exclusion glob):

- `rg -n "go-appkit" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (not even a prose mention — the repo does not reference appkit at all).
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod'` → **0 files**.
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go'` → **0 files**.

Conclusion: zero references; no Go runtime exists in the consumer. offline-banner's "app" is a second Quickshell instance rendering a QML banner strip, supervised by a systemd user unit (`Type = "simple"`, `Restart = "always"`, `RestartSec = "5s"`, `MemoryMax = "256M"`, module.nix ~:1160-1164) — there is no Go service to kit.

## 4. Should offline-banner adopt it?

SHOULD-NOT. go-appkit composes exactly the concerns a Go HTTP service has — request middleware, health endpoints, SSE, OpenAPI, otel, error pages — and offline-banner has none of those concerns: it serves no HTTP requests, hosts no endpoints, and its lifecycle/sandbox/health story is already *better* handled by the unit it actually has. systemd IS the appkit of this repo: `Restart = "always"` is the supervisor, `MemoryMax` is the resource guard, `RuntimeDirectory`/`StateDirectory` are the provisioning layer, and the ten flake checks (including the boot-level `vm-smoke` that asserts the unit never dies with a namespace/exec failure) are the integration test suite. Swapping any of that for appkit would require first inventing a Go service that does a job quickshell already does.

The one genuinely interesting comparison is the `systemd` module: appkit processes can speak sd_notify (`Type=notify`, watchdog keepalive), which is strictly more supervisable than `Type=simple`. But offline-banner's supervised process is quickshell, and the module's own history explains why `simple` + `Restart = always` was chosen (the 226/NAMESPACE incident class, pinned by vm-smoke's negative proof). Retrofitting a Go shim just to emit READY=1 would add a process boundary for no behavioral gain. Under the owner's fleet constraint, adoption here is net-negative in every direction: no capability gained, one toolchain added.

The honest takeaway is doctrinal, and it is already implemented: appkit's claim to fame is "one coherent service lifecycle with health you can see." offline-banner's equivalent — a supervised QML loop whose health is machine-asserted at boot by vm-smoke and in CI by unit-verify — is the same principle in systemd/Nix clothing, and it earned that posture through live incidents rather than library import.

## 5. Fleet perspective

This is the fleet at its most efficient: go-appkit is the composition root for the owner's Go services, and offline-banner is proof-by-counterexample of where its boundary lies — a project whose supervision, health, and config layers are *already* first-class (systemd + NixOS options) gains nothing from a Go service framework, and the audit documents that boundary so no future session "helpfully" suggests it. Two concrete doctrine channels flow the other way: (1) appkit's health-dashboard idea (visibility of liveness/readiness) has a real analog worth watching — if the banner ever grows more units, systemd's own `systemctl --user status` + journal lines remain the zero-dependency dashboard, and vm-smoke is the assertion layer; (2) if a sibling fleet project adopts appkit's preset spine, its patterns (sd_notify readiness, health endpoints) become the reference offline-banner should mirror *only when it grows a Go process*, which is precisely what the flip trigger encodes.

## 6. If the flip trigger fires

1. **Start with the `preset` spine, not raw `NewService`.** Where: a new Go helper package (e.g. a banner-state API daemon) wired as its own systemd user unit in module.nix. Why: preset composes sd_notify + health dashboard + error classification in one call, matching the unit posture (Type=notify upgrade, watchdog) the repo already understands deeply.
2. **Adopt the `systemd` module for sd_notify readiness.** Why first among modules: it directly upgrades the unit from `Type=simple` to `Type=notify` with STOPPING-aware drain — the single capability offline-banner's supervision story would genuinely benefit from, and the one its incidents have already shaped.
3. **Use `config`'s env flat-key-space loader.** The banner's env-var contract (`OFFLINE_BANNER_*`, contract-asserted per CHANGELOG) maps 1:1 onto appkit's env parser, keeping NixOS options as the source of truth.
4. **Skip `realtime`/`cqrs` unless consumers demand push.** The polled state file settled the consumer-channel question; reintroducing SSE needs a concrete consumer that polling fails.

## 7. Verify block

A fresh reviewer re-derives the verdict with:

```sh
# 1. Library identity (expect: preset/v0.1.1-19-g98875e8)
git -C /home/lars/projects/go-appkit describe --tags

# 2. Module-family count (expect: 15)
find /home/lars/projects/go-appkit -name go.mod -not -path '*/.git/*' | wc -l

# 3. Consumer references (expect: 0 matches anywhere, prose included)
rg -n "go-appkit" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'

# 4. No Go runtime in the consumer (expect: 0 and 0)
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod' | wc -l
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go' | wc -l
```

All four commands were executed by the reviewer on 2026-11-18 and produced exactly the stated results.
