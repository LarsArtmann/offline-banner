# httputil × offline-banner — Library Utilization Review

| Field                | Value                                                                                                                                                                                                                   |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Library repo**     | `/home/lars/projects/httputil` (github.com/LarsArtmann/httputil)                                                                                                                                                        |
| **Reviewed version** | `v1.9.0-21-g8a0cdc2` — latest local tag (HEAD `8a0cdc2`, 2026-11-17; remotes NOT fetched)                                                                                                                               |
| **Review date**      | 2026-11-18                                                                                                                                                                                                              |
| **Reviewed by**      | Fleet-run Group B (library-deep-dive runbook)                                                                                                                                                                           |
| **Verdict**          | NOT-APPLICABLE — offline-banner contains zero Go code; its only HTTP traffic is outbound probes spawned from QML and a Firebase-served static site, so there is no Go handler stack for HTTP middleware to compose into |
| **Score**            | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural)                                                                                                                                         |
| **Flip trigger**     | Any first-party Go HTTP server enters the repo (e.g. a Go status/demo endpoint or Go-based test harness) — then root `httputil` `Chain` becomes the default middleware stack for it                                     |

## 1. What the library is

`httputil` is a composable HTTP middleware and utility library for Go's `net/http`, per its README: "Composable HTTP middleware, utility primitives, and server lifecycle helpers for Go — CORS, client IP extraction, response recording, middleware chaining, security headers, CSP nonce support, request ID, panic recovery, timeout enforcement, structured logging, response compression, request body decompression with bomb protection, ETag conditional requests, W3C Server-Timing, CSRF protection, keyed rate limiting, content-language negotiation, configurable HTTP server, standard health checks, and — from the separate `endpoints` module — a self-describing `/endpoints` route listing." Every middleware follows the standard `func(http.Handler) http.Handler` shape, all config types implement `Validate() error` for startup checks, and the root module keeps a deliberately small dependency set (justinas/nosurf, go-error-family, go-etag/server, golang.org/x/time — verified in `go.mod`; the `httputil/server_timing` require is the same-repo submodule re-exported at root).

Two capabilities are additionally split out as zero-dependency Go submodules (own `go.mod` each, stdlib-only): `server_timing/` and `endpoints/`. A fourth go.mod exists at `testdata/otelinterop/` — a compile-proof fixture module for the OpenTelemetry integration docs, deliberately outside the root module and not shipped to consumers. Submodule deep-dives live in sibling reports: [httputil-server_timing.md](httputil-server_timing.md), [httputil-endpoints.md](httputil-endpoints.md).

### Module / package table

| Path                                                                      | Purpose / role                                                                                                 |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `/` (module `github.com/larsartmann/httputil`, package `httputil`)        | Root module: all middleware, server wrapper, health handlers, error classification, test spec suite            |
| `endpoints/` (module `github.com/larsartmann/httputil/endpoints`)         | Zero-dep submodule: self-describing route registration + `GET /endpoints` listing (single package `endpoints`) |
| `server_timing/` (module `github.com/larsartmann/httputil/server_timing`) | Zero-dep submodule: W3C `Server-Timing` header instrumentation (package `servertiming`)                        |
| `testdata/otelinterop/`                                                   | Fixture go.mod: proves the documented OpenTelemetry lanes compile; not a consumer-facing package               |
| `httpspec/`                                                               | Behavioral spec suite sources used by the library's own HTTP middleware tests                                  |

## 2. Capability inventory

| Capability                                                     | What the library offers                                                                        | Status in offline-banner | Reason                                                                                                                                                                            |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Middleware chaining                                            | `Chain` / `Compose` — standard `func(http.Handler) http.Handler`, first arg outermost          | Not Applicable           | No Go handler chain exists; the only "chain" in the consumer is the QML probe ladder (`net/tcp/dns/link`) executed via spawned processes                                          |
| Configurable HTTP server                                       | `httputil.Server` wrapper with graceful shutdown                                               | Not Applicable           | No Go process runs; process lifecycle is owned by the systemd user unit in `module.nix` (restart policy, sandboxing)                                                              |
| Health checks                                                  | `/health`, `/health/live`, `/health/ready` handlers                                            | Not Applicable           | Liveness is systemd's job here (`Restart=` policy); there is no HTTP endpoint to answer health probes                                                                             |
| CORS                                                           | Configurable CORS incl. preflight 204, wildcard origins, Local Network Access, `Validate()`    | Not Applicable           | No HTTP API exists; the Astro website's assets are served by Firebase Hosting (no repo-owned server code)                                                                         |
| Security headers + CSP nonce                                   | `SecurityHeaders`, nonce generation/propagation                                                | Not Applicable           | The website sets its own `<script>`/meta CSP via Astro templates, not via Go middleware                                                                                           |
| CSRF protection                                                | Double-submit cookie via nosurf, HTMX-aware helpers                                            | Not Applicable           | No form-posting server surface; the site is static                                                                                                                                |
| Request ID / Logging / Recovery / Timeout                      | Per-request observability and resilience middleware                                            | Not Applicable           | The consumer's observability is journal lines from the QML engine (`module.nix:423` `probe ok recovered_after=`, `module.nix:460` `probe failed reason=…`), not HTTP request logs |
| Client IP extraction                                           | `ClientIP` with `X-Forwarded-For` → `X-Real-IP` → `RemoteAddr` precedence + context middleware | Not Applicable           | No inbound requests arrive at anything this repo runs; Firebase Hosting terminates client connections                                                                             |
| Response recording + compression/decompression                 | `ResponseRecorder`, content negotiation, bomb-protected body decompression, pools              | Not Applicable           | No response bodies are produced by repo code; `demo.mp4` is served from the static site                                                                                           |
| ETag conditional requests                                      | Composed via same-author `go-etag/server`                                                      | Not Applicable           | Conditional-request semantics would live in the Firebase/CDN layer, not in this repo                                                                                              |
| Rate limiting / Content-Language                               | Keyed token-bucket limiter, language negotiation                                               | Not Applicable           | No server-side request volume exists to limit or negotiate                                                                                                                        |
| Error classification                                           | go-error-family behavioral families (Transient/Infrastructure) for retry decisions             | Not Applicable           | Retry policy lives in the QML debounce/dwell state machine, not in Go error values                                                                                                |
| Server-Timing + endpoints listing (root re-exports)            | Root module re-exports the two submodules                                                      | Not Applicable           | Covered structurally by the submodule reports; same absence of any HTTP surface                                                                                                   |
| Test utilities (`httpspec`, fuzz corpora, otelinterop fixture) | Behavioral spec suite for HTTP middleware under test                                           | Not Applicable           | flake checks (`probe-transitions`, `render-smoke`, `waybar-consumer`) are shell/QML integration tests; there are no Go tests to spec                                              |

## 3. Usage evidence in offline-banner

Exact commands and results (run 2026-11-18):

- `rg -ci "httputil" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'` → **0 matches** (rg exit 1; the `!docs/review/**` glob excludes this review's own reports, which are otherwise the only mentions)
- `rg -ci "go-codec" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'` → **0 matches** (sanity: neither library is referenced at all)
- `fd -e go . /home/lars/projects/offline-banner` → **0 files**
- `find /home/lars/projects/offline-banner -name 'go.mod' -not -path '*/.git/*'` → **0 files**
- `find /home/lars/projects/offline-banner -name 'go.sum' -not -path '*/.git/*'` → **0 files**

Languages present (verified by tree walk): Nix (`flake.nix`, `module.nix`), QML/JS (`scripts/demo/bar/shell.qml` plus QML inlined in `module.nix`), POSIX sh (`contrib/offline-banner-waybar`, `scripts/*.sh`, `lib/net-probe.sh`), Markdown, and one Astro/TypeScript website under `website/`. The conclusion is plain: **zero references to httputil anywhere, and no Go runtime exists in the consumer to host it.**

## 4. Should offline-banner adopt it?

SHOULD-NOT. The consumer's runtime surfaces map onto httputil's capabilities only by analogy, never by mechanism:

- **Process lifecycle**: the systemd user unit in `module.nix` provisions `RuntimeDirectory`/`StateDirectory`, sandboxing, and restart policy — the role `httputil.Server` plays for a Go process. There is no Go process.
- **Observability**: journal lines and the JSONL outage ledger (`module.nix:423`, `:460`, `:649-667`) are written by QML `console.log` + spawned `sh`, consumed by humans and `jq` asserts (`probe-transitions` check, `flake.nix:944`). `Logging`/metrics middleware would have nothing to intercept.
- **HTTP**: the only network traffic is _outbound_ probes — ICMP via exec, TCP dials in `lib/net-probe.sh` (`exec 3<>"/dev/tcp/..."`), DNS via `getent ahostsv4` — plus a static site on Firebase Hosting. Middleware shapes inbound `http.Handler` chains; a probe ladder is not one.

Forced adoption would mean adding a Go toolchain to the flake (build inputs, CI, go.sum maintenance) to instantiate a `net/http` stack that serves nothing. Under the owner's fleet constraint — many projects, limited time — every library line added without a consumer capability is pure bug-fix surface: strictly net-negative. The honest verdict is NOT-APPLICABLE.

## 5. Fleet perspective

This verdict protects the fleet's shared budget: recording that offline-banner structurally cannot use httputil prevents a future "why don't we dogfood it here?" cycle from burning owner time re-deriving the same conclusion. The transferable value flows the other way and needs no Go: offline-banner's doctrines — additive observability (journal lines + additive state-file keys), atomic `tmp` + `mv` writes so readers never see partial state, and eval-time validation via NixOS module option types — are concrete patterns the httputil docs already mirror (`Validate()` at startup, header-finalize-once, errors-as-values). Cross-pollination belongs in docs/doctrine, not in a forced dependency.

## 6. If the flip trigger fires

1. **A Go demo/status endpoint** (e.g. a tiny Go server that renders the offline state as JSON/HTML next to the QML banner): adopt root `httputil` first — `Chain(Recovery, Logging, RequestID, SecurityHeaders)` is the correct 10-line stack, and `endpoints.Register` gives a free self-describing route listing.
2. **A Go integration-test harness** replacing shell `jq` asserts with typed checks: adopt `httpspec` + root module test utilities to spec its handlers the same way the library specs its own.
3. **A Go collector that tails the outage ledger** and serves it over HTTP for the website demo: root module again, adding `CORS` with `AllowPrivateNetwork` since the site would fetch LAN-local data.
4. Only after all of the above exists would the zero-dep submodules become individually relevant (see the submodule reports).

## 7. Verify block

A fresh reviewer re-derives the verdict with:

```sh
git -C /home/lars/projects/httputil describe --tags
# → v1.9.0-21-g8a0cdc2
git -C /home/lars/projects/httputil log -1 --format='%h %ad' --date=short
# → 8a0cdc2 2026-11-17
find /home/lars/projects/httputil -name go.mod -not -path '*/.git/*' | wc -l
# → 4  (root, endpoints/, server_timing/, testdata/otelinterop/)
rg -ci "httputil" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**' || echo "0 matches"
# → 0 matches   (glob excludes these review reports — the only files mentioning httputil)
fd -e go . /home/lars/projects/offline-banner | wc -l
# → 0
```
