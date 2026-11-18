# go-retry × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-retry` (github.com/LarsArtmann/go-retry) |
| **Reviewed version** | `v0.9.0-7-g356fbd4` — latest local tag (HEAD `356fbd4`, 2026-11-14; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group A (library-deep-dive runbook), written directly by the orchestrator |
| **Verdict** | NOT-APPLICABLE — no Go runtime in offline-banner; the retry problem it solves is already solved in QML by the probe ladder, deliberately shaped differently |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | a Go artifact in offline-banner must retry an operation (companion CLI fetching/checking something flaky) |

## 1. What the library is

A dependency-light Go retry loop: `retry.Do`/`DoWithValue` with exponential backoff, additive jitter, configurable `MaxAttempts`/`InitialDelay`, and a pluggable retryable predicate built on go-error-family's `IsRetryable`. Deliberately minimal — no CQRS message types, no OTel SDK (the CQRS-wrapped variant lives in `go-cqrs-lite/middleware/v4`) — so CLIs and batch jobs can retry without importing a platform.

Submodules (from local go.mod files):

| Module | Purpose |
|---|---|
| `go-retry` (root) | `Do`, `DoWithValue`, `DefaultConfig`, backoff + jitter, retryable predicate |
| `tools/` | Repo tooling |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Retry loop with attempt counter | `Do(ctx, cfg, fn)` — attempts until success/exhaustion | Not Applicable | No Go runtime; retries are the QML probe engine's job |
| Value-returning retry | `DoWithValue` removes closure-variable plumbing | Not Applicable | No Go call sites |
| Exponential backoff + additive jitter | Configurable timing policy | Not Applicable (by deliberate design difference, not by omission) | The banner needs *periodic steady-state probing* (`OFFLINE_BANNER_INTERVAL`), not escalating retry toward a deadline; a fixed cadence is the correct policy for an ambient status monitor |
| Retryable predicate (error-family `IsRetryable`) | Classify-then-decide per attempt | Not Applicable | The QML ladder classifies by leg (net/tcp/dns/link) and counts failures across `OFFLINE_BANNER_FAILURES` — classification exists, but in a domain-specific form |
| MaxAttempts exhaustion | Bounded retry | Not Applicable | The banner never exhausts: it probes forever and *degrades* presentation instead (degraded dwell ladder) — an ambient monitor's correct alternative to giving up |
| CQRS/OTel variant pointer | Delegated to go-cqrs-lite/middleware | Not Applicable | No message bus, no traces |

## 3. Usage evidence in offline-banner

```
rg -n "go-retry" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules'  → 0 matches
find /home/lars/projects/offline-banner -name "*.go"   (excl .git, node_modules)          → 0 files
find /home/lars/projects/offline-banner -name "go.mod"                                    → 0 files
```

Conclusion: zero references; structurally impossible — no Go toolchain in the consumer. Verified 2026-11-18.

## 4. Should offline-banner adopt it?

**SHOULD NOT — and this is the most instructive non-adoption in the fleet run.** offline-banner has an extensive retry-shaped subsystem, and it is *deliberately* not a retry loop:

- **Probe cadence is a timer, not a backoff.** `OFFLINE_BANNER_INTERVAL`/`PROBE_TIMEOUT` define a fixed periodic probe. Escalating backoff would make an outage *less* observable (the exact failure the banner exists to surface) and jitter would only add nondeterminism to CI transition asserts.
- **Failure handling is a threshold, not an exhaustion.** `OFFLINE_BANNER_FAILURES` (debounce) and `OFFLINE_BANNER_DEGRADED_DWELL` (faded-but-visible rung) implement "keep watching, present worse news more quietly" — the opposite terminal state from `retry.Do` returning `err`. A retry library's vocabulary (attempts, exhaustion) simply does not describe an always-on monitor's vocabulary (legs, dwell, re-arm).
- **Retryability is per-leg classification.** A dns-leg failure and a tcp-leg failure carry different reasons into the journal, state file, and ledger — richer than a binary `IsRetryable`, and load-bearing for consumers (waybar/DMS render reason-specific text).

Adopting go-retry would add a Go toolchain and then *fight* the library's shape (you would end up calling `Do` once per interval with `MaxAttempts: 1` — an anti-pattern both sides would regret). The honest framing: offline-banner is a consumer of retry *doctrine* (classify before retrying, bound your work, make failure states explicit), and it satisfies that doctrine natively.

## 5. Fleet perspective

go-retry keeps improving for Go consumers with zero maintenance cost flowing back to offline-banner. The one durable cross-pollination worth noting: if go-retry ever documents a class of failure that should *not* be retried (Corruption-family per error-family), that distinction could inform a future QML leg (e.g. a permanently-misconfigured `OFFLINE_BANNER_PROBE_HOST` is not "network down" and arguably deserves its own presentation) — a free idea, no dependency attached.

## 6. If the flip trigger fires

1. **A Go companion tool that performs flaky I/O** (e.g. uploading the ledger somewhere, or a state-file exporter). Use `retry.Do` with `DefaultConfig`, wrap failures in error-family `Transient` so the predicate does the deciding, cap `MaxAttempts: 3`. Do not tune backoff per-site; keep it default.
2. **Never** re-express the QML probe ladder on top of go-retry concepts (attempts/backoff) — the periodic-monitor semantics are not a retry problem, and mapping them would corrupt both vocabularies.
3. If a second Go tool appears, share one `retry` config in a tiny internal package rather than per-tool constants.

## 7. Verify block

```bash
git -C /home/lars/projects/go-retry describe --tags         # v0.9.0-7-g356fbd4 (or newer)
rg -n "go-retry" /home/lars/projects/offline-banner --glob '!.git'         # 0 matches
find /home/lars/projects/offline-banner -name "go.mod" -not -path "*/.git/*" # 0 files
rg -n "OFFLINE_BANNER_INTERVAL|OFFLINE_BANNER_FAILURES" /home/lars/projects/offline-banner/module.nix | head -5   # the QML-native retry policy exists
```
