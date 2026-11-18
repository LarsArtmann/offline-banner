# go-etag × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-etag` (github.com/LarsArtmann/go-etag) |
| **Reviewed version** | `v0.7.1-3-g56cc961` — latest local tag (HEAD `56cc961`, 2026-11-18; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group A (library-deep-dive runbook), written directly by the orchestrator |
| **Verdict** | NOT-APPLICABLE — offline-banner owns no HTTP server or HTTP client code; the one HTTP surface (static website) is served by Firebase Hosting and has no cache validator to manage |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | offline-banner ships any HTTP endpoint of its own (a local status HTTP endpoint for the banner state would be the realistic one) |

## 1. What the library is

A two-sided RFC 7232 ETag library for Go. Server middleware generates entity-tags from response bodies and answers `If-None-Match` with `304 Not Modified` (weak comparison, handler-set validator passthrough, graceful streaming, error-family classification); client transport wraps any `http.Client` to replay validators as conditional GETs, rebuild 304s as 200s with freshened metadata (RFC 9111 §4.3.4), surface `Age`, invalidate after unsafe methods, honor `no-store`, and bound memory with FIFO eviction. Zero configuration required on either side.

Submodules (from local go.mod files):

| Module | Purpose |
|---|---|
| `go-etag/server` | ETag middleware for `net/http` |
| `go-etag/client` | Conditional-GET caching `http.RoundTripper` |
| `go-etag/entitytag` | Shared RFC 7232 §2.3 entity-tag domain type (parse, strength, comparisons) |
| `go-etag/metrics` | Atomic counters for server observability hooks |
| `go-etag` (root) | Deprecated alias shim for server (removed in v1.0.0) |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Server ETag middleware | Auto ETag + 304 handling for every GET/HEAD | Not Applicable | No HTTP server exists in the repo; the website is static, served by Firebase Hosting (which manages its own validators) |
| Client conditional-GET cache | `RoundTripper` turning re-fetches into free 304s | Not Applicable | The only HTTP client is QML's probe `fetch` usage and package installs — none consume cacheable re-reads in a hot path |
| Entity-tag domain type | RFC 7232 parse/strength/compare | Not Applicable | No Go code; no validator negotiation |
| 304 freshening + `Age` surfacing | RFC 9111 correctness layer | Not Applicable | No client cache to freshen |
| Mutation invalidation, `no-store` handling | RFC 9111 §4.4/§3 semantics | Not Applicable | No cache semantics owned by this repo |
| Bounded memory (FIFO, body cap) | Eviction policy | Not Applicable | Nothing caches HTTP bodies |
| Metrics hooks | Atomic counters per hit/miss/store | Not Applicable | No HTTP metrics surface (the repo's observability is the journal + state file) |

## 3. Usage evidence in offline-banner

```
rg -n "go-etag" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'  → 0 matches
find /home/lars/projects/offline-banner -name "*.go"   (excl .git, node_modules)         → 0 files
find /home/lars/projects/offline-banner -name "go.mod"                                   → 0 files
```

Conclusion: zero references; structurally impossible — the consumer owns no HTTP server/client code in any language. Verified 2026-11-18.

## 4. Should offline-banner adopt it?

**SHOULD NOT.** The repo's HTTP story is entirely delegated:

- The **website** is static content served by Firebase Hosting/CDN — caching validators are the host's concern; adding a Go server to serve what a CDN serves cheaper would be architecture regression, not improvement.
- The **banner probe** deliberately uses raw connectivity checks (ICMP via ping's `cap_net_raw`, TCP connects, DNS `getent` lookups) precisely so that failure *reasons* are leg-classified. An HTTP fetch with conditional caching would collapse that classification (a 304 and a timeout both mean "HTTP layer spoke or didn't" — the net/tcp/dns leg distinction would be lost).
- The **state file** is the freshness mechanism, and it is a better fit than HTTP caching for the consumer problem: the waybar/DMS consumers poll a heartbeat with a max-age check (`OFFLINE_BANNER_MAX_AGE`, default 15 s) — file mtimes at ns resolution replace validators, with zero protocol overhead.

Nothing in go-etag's capability map has an empty slot to fill here. The one conceptual echo — "don't re-send what hasn't changed" — is already answered more cheaply by the journal/heartbeat design.

## 5. Fleet perspective

Clean no. go-etag's improvements (RFC 9111 freshening refinements, metrics) accrue to Go API consumers; offline-banner's cost is zero and its exposure to those bugs is zero. If the owner's constraint is "collective improvement over per-project reintegration," this library is the clearest case of the two being independent: no amount of go-etag excellence would make offline-banner better, and no amount of offline-banner work would improve go-etag.

## 6. If the flip trigger fires

1. **A local HTTP status endpoint** (say, exposing banner state to non-file-reading consumers on localhost). Use `go-etag/server` middleware immediately — the state payload is small and re-readable, the textbook ETag case; add `go-etag/metrics` hooks only if the endpoint earns observability.
2. **A Go tool polling remote resources** (e.g. checking the website's health). Use `go-etag/client` as the `http.Client` transport so repeat checks are free 304s, with `MaxEntries` sized to the resource count.
3. Never wire ETag semantics into the probe path — leg classification must stay protocol-raw.

## 7. Verify block

```bash
git -C /home/lars/projects/go-etag describe --tags          # v0.7.1-3-g56cc961 (or newer)
rg -n "go-etag" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'          # 0 matches (the glob excludes this report itself, which contains the search term)
find /home/lars/projects/offline-banner -name "go.mod" -not -path "*/.git/*" # 0 files
rg -n "http" /home/lars/projects/offline-banner/module.nix                  # only env/probe context, no server
```
