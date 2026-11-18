# httputil/endpoints × offline-banner — Library Utilization Review

| Field                | Value                                                                                                                                                                                        |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Library repo**     | `/home/lars/projects/httputil` — submodule `endpoints/` (module `github.com/larsartmann/httputil/endpoints`, package `endpoints`)                                                            |
| **Reviewed version** | `v1.9.0-21-g8a0cdc2` — latest local tag (HEAD `8a0cdc2`, 2026-11-17; remotes NOT fetched)                                                                                                    |
| **Review date**      | 2026-11-18                                                                                                                                                                                   |
| **Reviewed by**      | Fleet-run Group B (library-deep-dive runbook)                                                                                                                                                |
| **Verdict**          | NOT-APPLICABLE — offline-banner has no HTTP routing surface at all: no mux, no handlers, no server; the listing's premise (`*http.ServeMux` can't enumerate itself) has nothing to attach to |
| **Score**            | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural)                                                                                                              |
| **Flip trigger**     | A Go HTTP server with ≥2 routes appears in the repo (e.g. a status API replacing the state-file handoff) — then `Registry` + `Register` becomes its route bookkeeping from the first route   |

## 1. What the submodule is

`httputil/endpoints` (package `endpoints`) provides self-describing HTTP route registration for Go's `http.ServeMux`, per its README: "register your routes through a `Registry` and get a `GET /endpoints` listing of them all — JSON for API clients, an HTML table for humans, picked by content negotiation on the `Accept` header." Because `*http.ServeMux` cannot enumerate the patterns registered on it, the registry is the single source of truth: every route registered through it is _mounted on the mux AND recorded in one declaration_, so the listing can never drift from what is actually served. **Zero dependencies** — its `go.mod` contains only the `module` and `go 1.27` directives (verified). The root `httputil` README lists it as a re-exported feature ("Endpoints Listing").

**Sub-packages: none.** This is a single flat package — verified: zero `.go` files exist below the submodule root (`find /home/lars/projects/httputil/endpoints -mindepth 2 -name '*.go'` → 0). Its surface is four source files plus tests:

| Path                                                                                       | Purpose / role                                                                                                                                                                         |
| ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `endpoints/endpoints.go`                                                                   | `Registry` (`NewRegistry`, `HandleFunc`/`Handle` — mount + record in one call, wiring errors as values, never panics) and `Register(mux, routes)` which mounts `GET /endpoints` itself |
| `endpoints/negotiate.go`                                                                   | RFC 9110 proactive content negotiation on `Accept` (JSON vs HTML); `Vary: Accept`, `Cache-Control: no-store`, never 406                                                                |
| `endpoints/qvalue.go`                                                                      | q-value parsing model (multi-line `Accept` headers joined per RFC 9110 § 5.3; unparseable entries skipped)                                                                             |
| `endpoints/render.go`                                                                      | JSON and HTML representations; HTML table with no inline styles/scripts (strict-CSP safe), all fields HTML-escaped (fuzz-tested)                                                       |
| `doc.go`, `example_test.go`, `*_test.go`, `*_bench_test.go`, `*_fuzz_test.go`, `testdata/` | Docs, behavioral tests (concurrency snapshots, UTF-8 validation), benchmarks, fuzz corpus                                                                                              |

## 2. Capability inventory

| Capability                         | What the submodule offers                                                                                                                                                                                            | Status in offline-banner | Reason                                                                                                                                                                                 |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Registry` route bookkeeping       | `NewRegistry()` + `HandleFunc(mux, "GET /users/{id}", h, "summary")` mounts the route and records it in one declaration; wiring errors returned as values (nil mux, empty/duplicate/malformed pattern), never panics | Not Applicable           | No `http.ServeMux` exists anywhere in the consumer; the only "registration" surfaces are Nix flake outputs (`nixosModule`, checks) and Astro content collections                       |
| `GET /endpoints` listing           | Self-describing JSON/HTML listing that includes itself and can never drift from served routes                                                                                                                        | Not Applicable           | There are no served routes to list; the repo's surface map lives in `FEATURES.md` and the flake — static docs, by design                                                               |
| `Register(mux, routes)` self-mount | One call adds the listing endpoint                                                                                                                                                                                   | Not Applicable           | Same absence of a mux                                                                                                                                                                  |
| Content negotiation                | RFC 9110 q-value negotiation, multi-line `Accept` joining, `Vary`/`Cache-Control` headers, never-406 posture                                                                                                         | Not Applicable           | The only `Accept` decisions in the consumer are made by Firebase Hosting and the waybar consumer script (`contrib/offline-banner-waybar`), none of which this repo's code answers      |
| Concurrency-safe registry          | Reads off immutable atomic snapshots; routes can be added while listings serve                                                                                                                                       | Not Applicable           | No concurrent Go readers exist; the analogous atomicity need (readers never see a partial state file) is already solved by the QML engine's `tmp` + `mv` rename (`module.nix:588-593`) |
| Security posture                   | HTML escaping fuzz-tested, UTF-8 validated at registration, CSP-safe table, deliberate-mount guidance (listing documents your attack surface)                                                                        | Not Applicable           | No attack surface is exposed by repo-run code — the unit is a user-session QML renderer, and the website is Firebase-served static assets                                              |
| Zero-dependency embeddability      | Stdlib-only submodule, importable without root `httputil` (first fleet consumer: LarsArtmann/CV since v0.1.0, 2026-11-17)                                                                                            | Not Applicable           | There is no Go module in offline-banner for it to be imported into                                                                                                                     |

## 3. Usage evidence in offline-banner

Exact commands and results (run 2026-11-18):

- `rg -n "ServeMux|Registry" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'` → **0 matches** (rg exit 1; the glob excludes this review's own reports)
- `rg -ci "httputil" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'` → **0 matches**
- `fd -e go . /home/lars/projects/offline-banner` → **0 files**; `find /home/lars/projects/offline-banner -name go.mod -not -path '*/.git/*'` → **0 files**

The repo's executable surfaces are: the systemd user unit running Quickshell with the QML banner engine (inlined in `module.nix`), the shell helper `lib/net-probe.sh`, the waybar consumer in `contrib/`, and the static Astro website under `website/` served by Firebase Hosting. **Zero references, and structurally no HTTP server for a route listing to describe.**

## 4. Should offline-banner adopt it?

SHOULD-NOT. The library solves one precise problem — a route listing that cannot drift from a `ServeMux` it shares — and offline-banner has no `ServeMux`. Its nearest neighbors are all non-HTTP:

- The _state handoff_ to consumers (waybar polls the JSON state file; `probe-transitions` asserts its key shapes via `jq`, `flake.nix:944`) is a filesystem contract, not a route table. Its drift-protection analog is the assert suite itself, which already guards key shapes at CI time — the same job `endpoints` does for routes, done without HTTP.
- The _website_ routes through Astro's file-based router and is served by Firebase Hosting; repo code never enumerates routes at runtime.
- The _flake_ is self-describing by construction: `nix flake show` enumerates outputs the way `GET /endpoints` enumerates routes.

Adopting the submodule would require building a Go HTTP server whose only purpose is to host a listing of itself — adding a toolchain, a unit, and a sandbox profile to expose one URL of documentation. Under the owner's fleet constraint that is the definition of net-negative: bug-fix surface with no payoff. NOT-APPLICABLE.

## 5. Fleet perspective

The verdict documents where `endpoints` _does_ belong in the fleet — CV (its first consumer) routes its whole surface through one mux and derives the listing from the registration site, and any future Go service in the fleet should start with the same discipline from route one. Recording that offline-banner is structurally outside that pattern (filesystem contracts + static hosting, no mux) prevents wasted dogfooding effort here while pointing the next HTTP-owning project at a proven, zero-dependency default.

## 6. If the flip trigger fires

1. **A Go status API serving banner/ledger state** (replacing or augmenting the state file): adopt `endpoints.Register` immediately — a service whose whole point is one JSON surface benefits most from a listing that proves what it exposes, and the listing should be API-key-guarded like CV's.
2. **Multiple route families** (state, ledger, health): switch all registration through one `Registry` from the start so drift is impossible rather than policed.
3. **Public exposure**: follow the README's security note — mount the listing behind auth, since it enumerates the attack surface of an availability-sensitive service.
4. **Non-Go alternative meanwhile**: if the goal is only "document what the service exposes", extend the existing `jq` assert suite or `FEATURES.md` instead — no adoption needed.

## 7. Verify block

```sh
git -C /home/lars/projects/httputil describe --tags
# → v1.9.0-21-g8a0cdc2
cat /home/lars/projects/httputil/endpoints/go.mod
# → module github.com/larsartmann/httputil/endpoints ; go 1.27  (no require block = zero dependencies)
find /home/lars/projects/httputil/endpoints -mindepth 2 -name '*.go' -not -path '*/.git/*' | wc -l
# → 0  (single flat package; no sub-packages)
rg -ci "ServeMux" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**' || echo "0 matches"
# → 0 matches   (glob excludes these review reports — the only files mentioning ServeMux)
fd -e go . /home/lars/projects/offline-banner | wc -l
# → 0
```
