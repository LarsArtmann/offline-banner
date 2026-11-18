# go-sse × offline-banner — Library Utilization Review

| Field                | Value                                                                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Library repo**     | `/home/lars/projects/go-sse` (github.com/LarsArtmann/go-sse)                                                                              |
| **Reviewed version** | `v0.7.0-5-ga1b4674` — latest local tag (HEAD `a1b4674`, 2026-11-17; remotes NOT fetched)                                                  |
| **Review date**      | 2026-11-18                                                                                                                                |
| **Reviewed by**      | Fleet-run Group C (library-deep-dive runbook)                                                                                             |
| **Verdict**          | NOT-APPLICABLE — offline-banner has no SSE server surface of any kind; its state channel is a polled JSON file, not a pushed event stream |
| **Score**            | 0/0 (n/a — no applicable surface; structural)                                                                                             |
| **Flip trigger**     | offline-banner gains any HTTP/SSE endpoint (e.g. a state-file HTTP exporter, web dashboard, or browser-facing consumer)                   |

## 1. What the library is

Server-Sent Events transport for Go: the wire format (`Event`, `EventID`, `WriteEvent`), connection lifecycle (`Stream` with headers, heartbeat, context, Last-Event-ID), generic subscriber fan-out (`Broadcaster[T]`, `SubscribeFilter`), and reconnection replay (`EventStore`/`Replay`/`FilteredEventStore`). Deliberately narrow — two small dependencies, no framework, no opinion about payload format, and an explicit refusal to ship a `ServeSSE` convenience handler (the canonical pattern lives in `example/`).

Submodules (from local go.mod files):

| Module                                   | Purpose/role                                                                                                                                                |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `github.com/larsartmann/go-sse` (root)   | Core SSE transport: wire types, serializer, `Stream`, `Broadcaster[T]`, filters, replay (deps: `templ`, `go-branded-id`, `go-error-family`; Go 1.27)        |
| `github.com/larsartmann/go-sse/sseparse` | Zero-dependency WHATWG HTML § 9.2.6 parser + exported WPT conformance corpus + assertion helpers — usable as a spec oracle by non-HTTP consumers            |
| `github.com/larsartmann/go-sse/ssetest`  | E2E test helpers: spins up a real HTTP server, drives handlers, parses the wire format into typed assertable events (`Collect`, `Require*`, `StreamReader`) |

## 2. Capability inventory

| Capability                                | What the library offers                                                                            | Status in offline-banner | Reason                                                                                                                                              |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| SSE wire-format types + serializer        | `Event`/`EventID`, allocation-minimized `WriteEvent` (multi-line data, CRLF)                       | Not Applicable           | Nothing in offline-banner serializes SSE frames; the only wire format it emits is a JSON state file and waybar's one-line JSON                      |
| Connection lifecycle (`Stream`)           | Headers, send, context, Last-Event-ID, fire-and-forget `Heartbeat(ctx, 15s)` that survives proxies | Not Applicable           | No HTTP connections exist to keep alive; the runtime surface is a systemd user unit + Quickshell QML, not a server                                  |
| Generic fan-out (`Broadcaster[T]`)        | Subscribe/broadcast/close with hooks, multiple concurrent subscribers                              | Not Applicable           | There is exactly one consumer per surface (the bar strip reads its own bindings; waybar polls the file); no fan-out topology                        |
| Predicate subscriptions + filtered replay | `SubscribeFilter`, `ReplayFiltered`, `FilteredEventStore` push-down                                | Not Applicable           | No subscriber set to filter; waybar filters by jq on a polled snapshot instead                                                                      |
| Reconnection replay (`EventStore`)        | Missed events resent on reconnect via `Last-Event-ID`                                              | Not Applicable           | Pollers re-read the whole (tiny) state file every interval — replay is meaningless when the current snapshot is one `jq` away                       |
| Event ID validation                       | `ParseEventID` rejects newline-corrupting input                                                    | Not Applicable           | No event IDs exist in a poll-a-file channel                                                                                                         |
| Test modules (`sseparse`, `ssetest`)      | WPT conformance corpus as a spec oracle; HTTP collection + typed assertions                        | Not Applicable           | No SSE parser exists in the consumer to test; the analogous testing doctrine (poll-until-equal `assert_state_jq` in flake.nix) is already CI-proven |

## 3. Usage evidence in offline-banner

```
rg -n "larsartmann/go-sse|go-sse" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  → 0 matches
rg -in "sseparse|ssetest"        /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  → 0 matches
find /home/lars/projects/offline-banner \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) -not -path '*/.git/*' → 0 files
```

(The `!docs/review/**` exclusion skips this audit's own reports, which necessarily name the libraries.)

Conclusion: zero references; no Go runtime exists in the consumer (verified 2026-11-18 — the repo is Nix + QML/JS + POSIX sh + one Astro/TS website). The real-time/UI update channel is QML property bindings plus the JSON state file at `$XDG_RUNTIME_DIR/offline-banner/state` (module.nix `emitState()`), polled by `contrib/offline-banner-waybar` at `interval: 5` — a pull channel, the architectural opposite of go-sse's push transport.

## 4. Should offline-banner adopt it?

**SHOULD NOT.** The conceptual neighbor here is _push vs pull_: go-sse is infrastructure for pushing events to connected clients; offline-banner's consumers are stateless per-interval POSIX sh processes (waybar custom modules) that own no persistent connection to hold a `Stream` on. The banner's contract is intentionally "the file is always the truth; read it when you wake up" with a `updatedAt` heartbeat (max-age 15 s) so staleness itself is detectable. Pushing events would _remove_ that property: a missed push is indistinguishable from silence, which is exactly the failure mode the fail-closed heartbeat exists to eliminate. There is also no server anywhere in the unit — adding one purely so go-sse has something to attach to would be a Go toolchain plus an HTTP surface purchased for zero runtime benefit. One genuine curiosity worth recording: go-sse's canonical heartbeat (`stream.Heartbeat(ctx, 15*time.Second)`) and offline-banner's `OFFLINE_BANNER_MAX_AGE` default are both 15 s — the same liveness doctrine arrived at independently from the push and pull sides.

## 5. Fleet perspective

go-sse keeps improving for Go consumers at zero maintenance cost to offline-banner, which is the correct outcome under the owner's fleet constraint. The durable non-Go takeaway already banked: a channel design should make silence _distinguishable from health_ — offline-banner does that with the heartbeat-stamped state file, and any future Go service in the fleet that adopts go-sse should pair its 15 s `Heartbeat` with the same fail-closed consumer-side staleness check rather than trusting an open TCP connection as proof of life.

## 6. If the flip trigger fires

1. **State-file HTTP exporter first** — a tiny Go sidecar (or a flake check-local tool) serving `GET /state` and `GET /events` (SSE). Use `sse.NewStream` + `Broadcaster[sse.Event]`, broadcast on every state write, and set `Retry` so browsers reconnect cleanly. Keep the state file as the source of truth; the SSE stream mirrors it.
2. **Add `ssetest` from day one** — `Collect`/`RequireData` against the handler, plus `sseparse.Corpus()` if any custom framing creeps in. The CI harness culture of offline-banner (poll-until-equal asserts) maps directly onto these helpers.
3. **Replay only if a real reconnecting consumer appears** — start with `EventStore` unimplemented; add a ring-buffer store (`WithReplayCapacity`-style) only when a browser client that flaps across network changes actually consumes the stream.

## 7. Verify block

```bash
git -C /home/lars/projects/go-sse describe --tags                                   # v0.7.0-5-ga1b4674 (or newer)
rg -n "larsartmann/go-sse|go-sse" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' # 0 matches
find /home/lars/projects/offline-banner \( -name '*.go' -o -name 'go.mod' \) -not -path '*/.git/*'  # 0 files
rg -n "emitState|updatedAt" /home/lars/projects/offline-banner/module.nix | head -5 # the pull channel exists (state file + heartbeat)
rg -n "OFFLINE_BANNER_MAX_AGE|interval" /home/lars/projects/offline-banner/contrib/offline-banner-waybar | head -3 # the poller and its staleness threshold
```
