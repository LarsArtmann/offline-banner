# go-idempotency × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-idempotency` (github.com/LarsArtmann/go-idempotency) |
| **Reviewed version** | `idemtest/v0.1.1-3-g80c3129` — latest local tag (HEAD `80c3129`, 2026-11-18; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group A (library-deep-dive runbook), written directly by the orchestrator |
| **Verdict** | NOT-APPLICABLE — no Go runtime in offline-banner, and no at-least-once delivery channel exists whose duplicates would need suppressing |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | offline-banner gains a component that consumes at-least-once deliveries (a queue, a D-Bus command stream, a CQRS stack consumer) with side effects that must not double-fire |

## 1. What the library is

A focused Go SDK that turns at-least-once delivery into at-most-once processing: clients attach stable idempotency keys to logical commands, and an atomic `CheckAndRecord(key)` step rejects retries whose key was already recorded, so a retried operation never executes twice. Built for CQRS command handling, deliberately an SDK — you implement the 3-method `Store` interface against your backend (Redis `SET NX EX`, SQL conditional upsert); the library ships no production backends, only the contract, a deprecated dev-only `MemoryStore`, and the `idemtest` contract-test suite. Sole runtime dependency: go-error-family.

Submodules (from local go.mod files):

| Module | Purpose |
|---|---|
| `go-idempotency` (root) | `Store` interface (`CheckAndRecord`/`Seen`/`Record`), `ErrDuplicate`, atomicity contracts |
| `idemtest/` | Contract test suite for `Store` implementations |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| `CheckAndRecord` atomic dedup | Single-lock check+record; concurrent same-key callers serialize, exactly one wins | Not Applicable | No Go runtime; also no concurrent duplicate-prone delivery channel exists |
| `Store` interface SDK | 3-method contract with named atomic primitive per backend | Not Applicable | No Go code to implement it in |
| `ErrDuplicate` semantics (error-family classified) | Typed duplicate rejection | Not Applicable | No Go error values in the consumer |
| TTL-scoped keys | Keys expire, bounded store growth | Not Applicable | No key store exists |
| `idemtest` contract suite | Verify a custom backend's semantics | Not Applicable | No backend to verify |
| Duplicate-suppression doctrine (`CheckAndRecord` over `Seen`+`Record`) | Anti-TOCTOU guidance | Fully Leveraged (as doctrine, re-derived locally) | The QML state machine debounces on raw counters (`rawDownLegs()` is the only truth; signal-only re-arms are suppressed by comparing `lastDownLegsKey`) — the same "decide on recorded state, not on a racy observation" principle, CI-proven in this repo |

## 3. Usage evidence in offline-banner

```
rg -n "go-idempotency" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules'  → 0 matches
find /home/lars/projects/offline-banner -name "*.go"   (excl .git, node_modules)                → 0 files
find /home/lars/projects/offline-banner -name "go.mod"                                          → 0 files
```

Conclusion: zero references; structurally impossible to reference — the consumer has no Go module or toolchain. Verified 2026-11-18.

## 4. Should offline-banner adopt it?

**SHOULD NOT — structurally, and there is no duplication to eliminate.** Idempotency keys solve a specific problem: the same logical operation arriving twice through a lossy, retrying channel. offline-banner has no such channel. Its side effects are idempotent by construction:

- The state file is a **snapshot, not an event log** — every probe cycle overwrites it wholesale via tmp+mv. Writing the same state twice is invisible, not harmful.
- The outage ledger appends **one entry per completed outage** (open outages never write), so at-most-once matters only at the outage boundary, and that boundary is decided by the QML state machine from raw counters — not from a delivery channel that can replay.
- Sound cues fire once per outage by the same state-machine discipline (no re-sound on mid-outage reason switches is an asserted CI invariant).

The genuinely shared principle — "decide on committed state, never on a racy observation" — is already enforced here with CI teeth. The repo's 2026-11-10 doctrine (a var-binding's CHANGED-SIGNAL is not contract-truth; the degraded re-arm compares the raw leg set and suppresses same-content firings) is `CheckAndRecord`-thinking in QML: deduplicate *events* by comparing against recorded state. That was found independently and is pinned by tests, so there is no gap for the library to fill.

## 5. Fleet perspective

Correct verdict for the fleet constraint: offline-banner should not carry a Go SDK it cannot execute so the owner can claim coverage. The library's improvements (new atomicity guidance, contract-test refinements) benefit the actual CQRS consumers (go-cqrs-lite's `metaengine.DedupStore` capability, cqrs-htmx command handling); offline-banner's benefit from that lineage is indirect and already harvested — its dedup-by-raw-state doctrine and its atomic tmp+mv write both encode the same durability mindset the fleet's libraries formalize.

## 6. If the flip trigger fires

1. **A command/side-effect channel appears** (e.g. a D-Bus or HTTP endpoint that toggles banner behavior and must not double-apply). Implement `Store` with a tiny file-based backend under `XDG_RUNTIME_DIR/offline-banner` (a directory-per-key + atomic rename is the natural `CheckAndRecord` primitive on a local filesystem) and pin it with `idemtest` from day one.
2. **If the repo ever joins a CQRS stack** (consuming go-cqrs-lite): do not hand-roll a backend — use `metaengine.DedupStore`, which supersedes the library's own retired kvstore/sqlstore modules (ADR-0158 there).
3. Never adopt for the state file or ledger: snapshot-overwrite and state-machine-gated append already give at-most-once where it matters.

## 7. Verify block

```bash
git -C /home/lars/projects/go-idempotency describe --tags    # idemtest/v0.1.1-3-g80c3129 (or newer)
rg -n "go-idempotency" /home/lars/projects/offline-banner --glob '!.git'   # 0 matches
find /home/lars/projects/offline-banner -name "go.mod" -not -path "*/.git/*" # 0 files
```
