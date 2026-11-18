# httputil/server_timing × offline-banner — Library Utilization Review

| Field                | Value                                                                                                                                                             |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Library repo**     | `/home/lars/projects/httputil` — submodule `server_timing/` (module `github.com/larsartmann/httputil/server_timing`, package `servertiming`)                      |
| **Reviewed version** | `v1.9.0-21-g8a0cdc2` — latest local tag (HEAD `8a0cdc2`, 2026-11-17; remotes NOT fetched)                                                                         |
| **Review date**      | 2026-11-18                                                                                                                                                        |
| **Reviewed by**      | Fleet-run Group B (library-deep-dive runbook)                                                                                                                     |
| **Verdict**          | NOT-APPLICABLE — the Server-Timing header is emitted into HTTP responses, and offline-banner owns no HTTP response writer: nothing it runs ever answers a request |
| **Score**            | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural)                                                                                   |
| **Flip trigger**     | A Go HTTP server appears in the repo whose per-request phase timings (DB/cache/render analogs) should be visible in browser DevTools or RUM tooling               |

## 1. What the submodule is

`httputil/server_timing` (package `servertiming`) implements W3C [Server-Timing](https://w3c.github.io/server-timing/) header instrumentation for Go HTTP handlers, per its README: "Record named timing metrics (database, cache, external calls, ...) from anywhere in the handler call chain and have them serialized into the `Server-Timing` response header — where browser DevTools, RUM agents, and load-testing tools can read them without any vendor-specific agent." It is **zero-dependency** (its `go.mod` contains only the `module` and `go 1.27` directives — verified) so it can be embedded without the root `httputil` module; the root module in fact depends on it (`httputil/server_timing v1.0.3` in the root `go.mod`) and re-exports it.

It is a single flat package — no sub-packages — of three source files plus tests:

| Path                                                                | Purpose / role                                                                                                                                                             |
| ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `server_timing/server_timing.go`                                    | The `*ServerTiming` collector, context helpers (`MeasureServerTiming`, `RecordServerTiming`, `ServerTimingFromContext`, `WithServerTiming`), header serialization          |
| `server_timing/middleware.go`                                       | `ServerTimingMiddleware()`, conditional variant `ServerTimingMiddlewareWhen(pred)`, `WrapServerTiming(w, r)` manual writer wrapping, finalize-`total`-on-first-write logic |
| `server_timing/doc.go`                                              | Package documentation                                                                                                                                                      |
| `example_test.go`, `*_test.go`, `*_bench_test.go`, `*_fuzz_test.go` | Examples, unit/behavioral tests, benchmarks, fuzz corpus for header-value injection safety                                                                                 |

## 2. Capability inventory

| Capability                             | What the submodule offers                                                                                                                             | Status in offline-banner | Reason                                                                                                                                                                         |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `ServerTimingMiddleware()`             | Wraps the `ResponseWriter`, stores a concurrency-safe collector in the request context, stamps the header exactly once at first `Write`/`WriteHeader` | Not Applicable           | No Go handler ever runs; there is no `http.ResponseWriter` in any repo-owned process to wrap                                                                                   |
| Timed-region recording                 | `MeasureServerTiming(ctx, name)` returns a `stop()` — records durations for named metrics (`total` auto-recorded as time-to-first-byte)               | Not Applicable           | The consumer's timing facts (probe durations, outage `durationSec` in the JSONL ledger, `module.nix:654`) are journaled as text/JSONL files, not request-scoped header metrics |
| Pre-measured recording + direct access | `RecordServerTiming` (already-measured durations), `ServerTimingFromContext` (collector access); all helpers nil-safe no-ops without the middleware   | Not Applicable           | Same absence of an HTTP response path — nil-safety cannot help a codebase with no Go at all                                                                                    |
| Conditional instrumentation            | `ServerTimingMiddlewareWhen(pred)` — collect only for matching requests (the README notes Server-Timing can leak internals; gate it in production)    | Not Applicable           | There is no request stream to gate; the consumer's privacy posture is handled by systemd sandboxing + `StateDirectory` visibility                                              |
| Manual control                         | `WrapServerTiming(w, r)` and `NewServerTiming()` + `WithServerTiming(ctx, st)` for frameworks that own the middleware chain                           | Not Applicable           | No framework, no writer/request pair exists                                                                                                                                    |
| Injection-safe header serialization    | Metric names sanitized to RFC 7230 tokens, quoted-string-escaped descriptions, CR/LF neutralized (fuzz-tested); fractional ms preserved               | Not Applicable           | The analogous hygiene need here is shell quoting in spawned commands (e.g. `module.nix:591` `printf '%s' "$2" > "$1.tmp"`), which QML/sh handle — not HTTP header tokens       |
| Transparent writer delegation          | `Flush`/`Hijack`/`Push`/`Unwrap` pass through so SSE, WebSockets, HTTP/2, `http.ResponseController` keep working                                      | Not Applicable           | No streaming endpoints exist; the "stream" in this repo is `appendFile` of ledger lines via spawned `sh`                                                                       |
| Zero-dependency embeddability          | Stdlib-only submodule, importable without root `httputil`                                                                                             | Not Applicable           | There is no Go module anywhere in the consumer for it to be embedded into                                                                                                      |

The honest structural note: offline-banner _does_ measure exactly the kind of phases Server-Timing exists to expose — the probe ladder journals per-leg `probe ok/failed` transitions and the ledger stores outage durations — but those timings terminate in a journal/state file read by `jq` asserts and humans, never in an HTTP response a browser's DevTools could open.

## 3. Usage evidence in offline-banner

Exact commands and results (run 2026-11-18):

- `rg -ci "server-timing|servertiming" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'` → **0 matches** (rg exit 1; the glob excludes this review's own reports)
- `rg -ci "httputil" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'` → **0 matches** (parent library equally absent)
- `fd -e go . /home/lars/projects/offline-banner` → **0 files**; `find /home/lars/projects/offline-banner -name go.mod -not -path '*/.git/*'` → **0 files**

The only HTTP in the consumer is outbound probe traffic spawned as child processes (ICMP exec, `/dev/tcp` dial in `lib/net-probe.sh`, `getent ahostsv4` DNS) and the static website served by Firebase Hosting. **Zero references; no Go runtime exists to import this submodule.**

## 4. Should offline-banner adopt it?

SHOULD-NOT. The closest conceptual neighbor is real and worth naming: the QML probe engine journals `probe ok recovered_after=` / `probe failed reason=… failures=n/m` (`module.nix:423`, `:460`) and the outage ledger records `durationSec` (`module.nix:654`). That is Server-Timing's _data shape_ (named, per-phase durations) — but its _channel_ is the opposite: written to a state file and journal for `jq`/human consumers, whereas Server-Timing rides on an HTTP response into browser DevTools. Converting would require inventing an HTTP server just to have something to time — a tail wagging the dog.

Adoption also cannot be partial: emitting one header requires a complete `net/http` handler chain (middleware → writer → response). There is none, and the systemd unit + QML engine already deliver the observability the project needs. Under the owner's fleet constraint, pulling in a Go toolchain to host a header no browser will ever see is pure bug-fix surface with zero payoff. NOT-APPLICABLE is the correct verdict.

## 5. Fleet perspective

A clean NOT-APPLICABLE here keeps the fleet honest about _what a library is for_, not just whether it exists: `server_timing` is exceptional at moving timing data to browsers, and this project's consumers are `jq`, waybar, and terminal journals — different channel, different contract. If a fleet project ever needs user-visible server phase timings (e.g. the Astro website gains a real API), this submodule is the zero-dependency first choice; the report records that decision point so it can be made in seconds rather than re-researched.

## 6. If the flip trigger fires

1. **A Go status endpoint for the banner state** (serving the `state` JSON that currently moves via `RuntimeDirectory`): adopt `server_timing` alongside the endpoint from day one — `MeasureServerTiming(ctx, "read-state")` around the state-file read surfaces real latency to whoever debugs the endpoint in DevTools.
2. **A Go ledger exporter** (outage JSONL → Prometheus/RUM): use `RecordServerTiming` for already-measured `durationSec` values rather than re-timing them.
3. **Gated exposure**: prefer `ServerTimingMiddlewareWhen` with an admin/debug predicate — the README's leak warning applies doubly to an offline/availability service whose timings reveal infrastructure details.
4. Nothing to adopt before an HTTP server exists — all four items are downstream of that one structural change.

## 7. Verify block

```sh
git -C /home/lars/projects/httputil describe --tags
# → v1.9.0-21-g8a0cdc2
cat /home/lars/projects/httputil/server_timing/go.mod
# → module github.com/larsartmann/httputil/server_timing ; go 1.27  (no require block = zero dependencies)
ls /home/lars/projects/httputil/server_timing/
# → doc.go example_test.go middleware.go server_timing.go …(tests, testdata)
rg -ci "server-timing|servertiming" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**' || echo "0 matches"
# → 0 matches   (glob excludes these review reports — the only files mentioning server-timing)
fd -e go . /home/lars/projects/offline-banner | wc -l
# → 0
```
