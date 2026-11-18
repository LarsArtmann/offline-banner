# go-datastar × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-datastar` (github.com/LarsArtmann/go-datastar) |
| **Reviewed version** | `static/v0.8.0` — latest local tag (HEAD `f909928`, 2026-11-17; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group C (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — DataStar pushes DOM patches from a Go server to a browser; offline-banner has no server, no browser surface, and its reactive channel is native QML bindings |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | a browser-rendered surface for banner state (web dashboard / remote viewer) backed by a Go endpoint |

## 1. What the library is

The Go server-side vocabulary for the DataStar hypermedia protocol: every patch (elements, signals, script) is a first-class value implementing `Patch interface { Event() sse.Event }`, so patches can be constructed without a live connection, then stored, filtered, replayed, and broadcast through go-sse's transport. Positioned honestly against the official `starfederation/datastar-go` SDK — same wire format, different architecture ("patches are values, not method calls"), at the cost of a Go 1.27.1+ floor.

Submodules (from local go.mod files):

| Module | Purpose/role |
|---|---|
| `github.com/larsartmann/go-datastar` (root) | Pure protocol vocabulary: patch constructors + `With*` options, fluent `Response` for single-connection handlers, `ScriptHandler` (ETag + Cache-Control) for the JS client, error-family-classified errors, version constants (deps: go-sse, go-error-family, golang.org/x/mod) |
| `github.com/larsartmann/go-datastar/broadcast` | Connection lifecycle: fan-out, reconnection replay (`WithReplayCapacity`), hub sharing, plus `storecontract` assertion helpers for custom replay stores |
| `github.com/larsartmann/go-datastar/datastartest` | E2E test helpers: real HTTP server, typed event decoding, `RequireElements`, `UnmarshalSignals` |
| `github.com/larsartmann/go-datastar/static` | Embedded zero-dependency DataStar JS client bundle (upstream v1.0.4), served via `ScriptHandler` |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Patch-as-value protocol model | Construct DataStar patches anywhere; `.Event()` yields an `sse.Event` | Not Applicable | No DataStar client exists on the consuming side; the banner renders via QML, not DOM patches |
| Server-pushed DOM/signals updates | `PatchElements`, `PatchSignals`, fluent `Response` over SSE | Not Applicable | There is no browser DOM; Quickshell's QML property bindings are the reactive channel, same-process and push-native |
| Broadcast/replay connection layer | `broadcast.NewBroadcaster*`, hub sharing, Last-Event-ID replay | Not Applicable | The consumer set is waybar/DMS widgets polling a file; no connected-client topology to broadcast to |
| JS client serving (`static` + `ScriptHandler`) | Embedded client with ETag caching | Not Applicable | No HTTP server and no web page ship with the NixOS module (the Astro website is static marketing/docs, not runtime) |
| E2E test helpers (`datastartest`) | Typed decode + assertions of DataStar events | Not Applicable | Nothing emits DataStar events to assert on; CI asserts on the JSON state file instead (`assert_state_jq`) |
| Error classification | Stable codes/families/retryability via go-error-family | Not Applicable | The runtime is QML + POSIX sh; its failure vocabulary is per-leg probe state and journal lines |
| Named version constants (`VersionIsValid`) | Machine-checkable client/server version pairing (HEAD commit f909928) | Not Applicable | No DataStar client/server pair to keep in version lockstep |

## 3. Usage evidence in offline-banner

```
rg -in "datastar|datastartest" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  → 0 matches
rg -n "larsartmann/go-datastar" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' → 0 matches
find /home/lars/projects/offline-banner \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) -not -path '*/.git/*' → 0 files
```

(The `!docs/review/**` exclusion skips this audit's own reports, which necessarily name the libraries.)

Conclusion: zero references; no Go runtime exists in the consumer (verified 2026-11-18). The nearest architectural analogue to a DataStar "patch" in offline-banner is the whole-state JSON document written to `$XDG_RUNTIME_DIR/offline-banner/state` (module.nix `emitState()`, keys `active/since/reason/phase/legs/degradedVisible/updatedAt`) — a value produced independently of any reader, exactly the decoupling go-datastar prizes, but delivered by atomic file replacement + polling rather than SSE + DOM patching.

## 4. Should offline-banner adopt it?

**SHOULD NOT.** The conceptual neighbor is *the reactive channel itself*. DataStar's entire reason to exist is: your UI is a browser DOM, your server is Go, and you want server state to flow into the DOM. offline-banner's UI is a native Quickshell QML strip whose bindings update in the same process as the probe engine — the "server→UI patch" hop DataStar industrializes simply does not exist; QML solved it at the language level. The banner's out-of-process consumers (waybar, DMS) are deliberately dumb: they poll the state file on their own cadence and validate liveness via the `updatedAt` heartbeat, which a pushed patch model would actually *weaken* (a consumer that missed a patch cannot tell silence from death, and DataStar's replay answers "what did I miss" only for clients that stayed connected). Adopting go-datastar would require manufacturing both missing halves — a Go HTTP server and a browser client — adding a Go toolchain plus a JS runtime dependency to a NixOS module for zero benefit to the yellow strip. Under the owner's fleet constraint this is the definition of net-negative: real bug-fix surface, no payoff.

## 5. Fleet perspective

The verdict keeps offline-banner lean while go-datastar matures for genuine browser-dashboard consumers elsewhere in the fleet. One transferable principle is already embodied in the consumer: go-datastar's core insight — state changes should be values that can be produced, stored, and routed independently of any connection — is the same insight behind the state file being written atomically by a spawned child while the UI and readers consume it on their own schedules. If a fleet project ever does adopt go-datastar, offline-banner's heartbeat doctrine (stamp every emitted value with `updatedAt`; fail closed on staleness) is the piece worth carrying over to its broadcast/replay layer, because replay covers reconnection but not a silently-dead publisher.

## 6. If the flip trigger fires

1. **Web status dashboard** — a Go endpoint exposing banner state to a browser. Build it on go-datastar + go-sse: `PatchSignals` (or `PatchElements`) per state write through `broadcast.NewBroadcaster`, served by `ScriptHandler` for the client bundle. The state file stays the source of truth; the endpoint mirrors it.
2. **Test-first** — use `datastartest.Collect` + `RequireElements` in the flake checks from the first commit, mirroring the existing `assert_state_jq` polling style, so the web channel is CI-pinned the way the file channel is.
3. **Version pinning** — use the exported version constants (HEAD f909928) to assert server/client compatibility in CI rather than eyeballing the embedded bundle version, since `static` pins upstream client v1.0.4 independently of the Go tags.

## 7. Verify block

```bash
git -C /home/lars/projects/go-datastar describe --tags                              # static/v0.8.0 (or newer)
rg -in "datastar" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'                 # 0 matches
find /home/lars/projects/offline-banner \( -name '*.go' -o -name 'go.mod' \) -not -path '*/.git/*'  # 0 files
rg -n "emitState|degradedVisible|updatedAt" /home/lars/projects/offline-banner/module.nix | head -5  # the value-object channel exists (state JSON)
rg -n "assert_state_jq" /home/lars/projects/offline-banner/flake.nix | head -3      # CI pins the channel, not a browser
```
