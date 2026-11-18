# go-health-dashboard × offline-banner — Library Utilization Review

| Field                | Value                                                                                                                                                                                                                                                                   |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Library repo**     | `/home/lars/projects/go-health-dashboard` (github.com/LarsArtmann/go-health-dashboard)                                                                                                                                                                                  |
| **Reviewed version** | `v0.13.3-77-gb608db0` — latest local tag (HEAD `b608db0`, 2026-11-15; remotes NOT fetched)                                                                                                                                                                              |
| **Review date**      | 2026-11-18                                                                                                                                                                                                                                                              |
| **Reviewed by**      | Fleet-run Group D (library-deep-dive runbook)                                                                                                                                                                                                                           |
| **Verdict**          | NOT-APPLICABLE — the outage ledger is exactly the dataset this dashboard renders, but the library requires a running go-health probe inside a Go HTTP server, and offline-banner's plausible dashboard path (an Astro page reading the JSONL) is already the better fit |
| **Score**            | 0/0 (n/a — no applicable surface; structural)                                                                                                                                                                                                                           |
| **Flip trigger**     | A requirement for a _live, served_ status UI fed by go-health probes — i.e., a fleet Go service adopting go-health that also wants a status page; for offline-banner's own history, a static Astro ledger page would win the comparison before this library entered     |

## 1. What the library is

`go-health-dashboard` is a real-time status dashboard for `go-health`, powered by Datastar SSE: it drops into an HTTP mux with one call (`dashboard.New(probe)` + `RegisterRoutes`) and serves a live page with green/yellow/red badges, severity grouping, and sub-second updates, while keeping kubelet JSON probes JSON-only via content negotiation. It lives in its own module deliberately — pulling templ, Datastar, and SSE into go-health would destroy go-health's single-dependency value proposition.

Single module: `github.com/larsartmann/go-health-dashboard` (go 1.27; deps include `a-h/templ`, `chromedp`, `go-datastar`, `go-health v0.10.0`, `go-sse`, `templ-components`, Prometheus client). Ships two binaries (`cmd/health-hub` federation hub, `example/`).

## 2. Capability inventory

| Capability                                              | What the library offers                                                   | Status in offline-banner      | Reason                                                                                                                                                                                                        |
| ------------------------------------------------------- | ------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Live HTML status page (`/health`, templ + Datastar SSE) | Green/yellow/red badges, severity-grouped tables, sub-second push updates | Not Applicable                | The "status UI" already exists and is superior for the purpose: the banner strip itself IS a live full-screen status display, rendered by Quickshell with zero HTTP involved                                  |
| Content negotiation (HTML vs JSON on `/health`)         | Browsers get the dashboard, `Accept: application/json` gets probe JSON    | Not Applicable                | No HTTP server exists in the unit (sandbox has no listen surface; observability is state file + journal)                                                                                                      |
| History & transitions (`/health/trend`)                 | Status history + transition list as JSON                                  | Fully Leveraged (as doctrine) | The outage ledger records precisely this — `{from, to, durationSec, reasons: [...], probeFailures: {...}}` appended on every recovery, with the state file's `since` field as its live twin                   |
| History export (`/health/export`, JSON/CSV)             | Downloadable outage history                                               | Fully Leveraged (as doctrine) | The ledger is already an export: plain JSONL at `%h/.local/state/offline-banner`, written through the unit's only writable path (StateDirectory-provisioned), readable by any tool without an HTTP round-trip |
| Prometheus metrics (`/health/metrics`)                  | Latency histogram + status exposition                                     | Not Applicable                | No Prometheus scrape target on a desktop banner; the fleet's metric needs (if any) would live server-side                                                                                                     |
| Webhook notifications (`webhook.go`)                    | Push status changes to external systems                                   | Fully Leveraged (as doctrine) | Consumer push is solved differently: waybar/DMS widgets poll the state file, and any future subscriber can do the same — file-as-API instead of webhook                                                       |
| Change detection (`changedetector.go`)                  | Diff-based SSE patching                                                   | Fully Leveraged (as doctrine) | The state file's atomic tmp+`mv -f` rename (CI-proven, never an empty read) plus `updatedAt` gives consumers the same "did anything change" signal via a heartbeat age check                                  |
| OIDC auth (`oidc.go`, `oidc_jwt.go`, `oidc_session.go`) | Session/jwt guards for the dashboard                                      | Not Applicable                | The repo holds zero secrets and exposes no auth surface; the state file is user-owned (`/run/user/<uid>`), guarded by the OS, not a login                                                                     |
| Rate limiting & CSP (`ratelimit.go`, `csp.go`)          | Flood and header hardening for the served page                            | Not Applicable                | No HTTP endpoint exists to limit or harden; the systemd sandbox (5.8 MEDIUM systemd-analyze score) is the attack-surface story                                                                                |
| Federation hub (`cmd/health-hub`)                       | Aggregate many go-health instances into one dashboard                     | Not Applicable                | Single host, single unit — nothing to federate                                                                                                                                                                |
| Embedded assets & favicon                               | Self-contained single-binary page                                         | Not Applicable                | The banner's visuals are QML in the store path (`pkgs.writeTextDir "shell.qml"`), already hermetically deployed by Nix                                                                                        |

## 3. Usage evidence in offline-banner

The EXACT commands run (all exclude the reports directory):

- `rg -n "go-health-dashboard" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (exit 1)
- `rg -n "go-health" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (exit 1; this broader pattern also covers the dashboard's parent library)
- `find /home/lars/projects/offline-banner -name 'go.mod' -not -path '*/.git/*'` → **0 files**
- `find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*'` → **0 files**

Conclusion: zero references; no Go runtime exists in the consumer. The nearest renderers on the consumer side are the waybar/DMS widget (`contrib/offline-banner-waybar`, POSIX sh + jq, emits the live indicator) and the static Astro website (`website/` — astro ^7.4.12, typescript ^6.0.3, deployed to Firebase Hosting), plus the outage ledger JSONL they could both read.

## 4. Should offline-banner adopt it?

**SHOULD-NOT — with the honest caveat that this is the set's most tempting flip.** The dataset match is real: `/health/trend` and `/health/export` exist to render exactly what the outage ledger accumulates (`from`/`to`/`durationSec`/`reasons`/`probeFailures`), and a local "when was my network down and why" page is a genuinely plausible future feature. The tempting move would be to stand up go-health-dashboard and feed it the ledger.

It fails on three counts. (1) **It cannot consume the ledger**: the dashboard's data source is a _live go-health probe_ (it wraps `health.Probe` directly — `dashboard.New(probe)`), not an append-only JSONL file; adopting it would mean standing up a go-health probe in a Go process that re-implements the QML probe ladder — a second health engine supervising the first. (2) **It needs a served runtime**: a Go HTTP server with SSE, templ rendering, OIDC guards and rate limits — for a desktop whose status surface (the banner) is already always-on-screen, and whose history readers (waybar widget, human, website) are better served by a file. (3) **The better tool is already in the repo**: an Astro page (the website stack exists, deploys via Firebase) reading the ledger JSONL — either at build time for a public outage page, or as a tiny local generator — gives a timeline UI with no daemon, no port, no second supervisor, and no Go toolchain in a Nix flake. Per the owner's constraint, the Go dashboard would be a pure bug-fix surface against a need a static page meets.

## 5. Fleet perspective

The right division of labor: go-health-dashboard serves fleet projects that already run go-health probes server-side (where "one mux call, live status page" is a genuine win), while offline-banner's history story stays file-native. The doctrine exchange is already complete — the ledger is offline-banner's `/health/trend`, and its fail-closed heartbeat is the dashboard's changedetector in shell form. If the owner ever wants a public uptime page for the banner, the Astro-ledger path keeps one language (TypeScript) across the website and adds zero runtime services; the Go dashboard should be reserved for contexts where a probe-backed live server already exists.

## 6. If the flip trigger fires

1. **Astro outage-history page (recommended first move if a history UI is ever wanted)**: a build-time (or small scheduled) step in `website/` reads `~/.local/state/offline-banner/*.jsonl` and renders a timeline — no new runtime, reuses the Firebase Hosting pipeline, keeps offline-banner Go-free.
2. **Fleet Go service with go-health probes**: adopt the dashboard _there_ — `dashboard.Register(injector, probe)` alongside go-health gives the live status page for free; offline-banner remains a consumer of nothing.
3. **Local ledger viewer (desktop)**: if an interactive local timeline is wanted without the website, a one-shot renderer (even a QML/Quickshell dialog reusing the banner's runtime) beats a served Go dashboard; the ledger's stable JSONL contract (`from`/`to`/`durationSec`/`reasons`/`probeFailures`) is already the interface any such tool needs.

## 7. Verify block

```sh
# 1. Library version facts
git -C /home/lars/projects/go-health-dashboard describe --tags   # v0.13.3-77-gb608db0
git -C /home/lars/projects/go-health-dashboard log -1 --format='%h %ad' --date=short  # b608db0 2026-11-15
find /home/lars/projects/go-health-dashboard -name go.mod -not -path '*/.git/*' | wc -l  # 1

# 2. Zero usage in the consumer (reports excluded)
rg -n "go-health-dashboard" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  # no output, exit 1
find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*' | wc -l  # 0

# 3. The ledger + website that make the flip a SHOULD-NOT
grep -n 'durationSec\|historyWrite' /home/lars/projects/offline-banner/module.nix | head -3  # ledger writer
grep -n '"astro"' /home/lars/projects/offline-banner/website/package.json  # the better-fit renderer
```

All three blocks were executed on 2026-11-18 and reproduce the stated results.
