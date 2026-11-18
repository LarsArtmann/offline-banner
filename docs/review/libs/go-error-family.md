# go-error-family × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-error-family` (github.com/LarsArtmann/go-error-family) |
| **Reviewed version** | `v0.12.0-12-g898004e` — latest local tag (HEAD `898004e`, 2026-11-15; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group A (library-deep-dive runbook), written directly by the orchestrator |
| **Verdict** | NOT-APPLICABLE — offline-banner contains no Go code; a Go error-classification protocol has no runtime to execute in |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | offline-banner grows any Go artifact (companion CLI, Go check harness, Go state-file analyzer). Any such tool must adopt error-family from its first commit. |

## 1. What the library is

A structured error protocol for Go: behavioral classification of errors into six Families (Rejection, Conflict, Transient, Corruption, Infrastructure, Orchestration), each mapping deterministically to retry decisions, BSD sysexits.h exit codes, HTTP status codes, and user-facing tone ("Share the protocol, not the implementation"). Root module is zero-dependency and stable; experimental submodules carry integrations.

Submodules (from local go.mod files):

| Module | Purpose |
|---|---|
| `go-error-family` (root) | Classification core: `Family`, `Classify`, `ExitCode`, `IsRetryable`, `Code`, `HTTPStatus`, six small interfaces (`Coded`, `Classified`, `Contextual`, `Retryable`, `ExitCoder`, `HTTPStatuser`) |
| `agent/` | Experimental agent integration |
| `bridge/` | samber/oops enrichment bridge (classifies here, enriches there) |
| `diagnose/`, `diagnose/git/`, `diagnose/postgres/` | Diagnostic rule packs per backend |
| `examples/` | Runnable CLI/HTTP/custom-rule/oops demos |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Family classification | 6-Family behavioral taxonomy driving downstream decisions | Not Applicable | No Go runtime; the repo is Nix + QML + POSIX sh |
| Six-interface contract | `Coded`/`Classified`/`Contextual`/`Retryable`/`ExitCoder`/`HTTPStatuser` — implement what you need | Not Applicable | No Go types exist anywhere in the repo |
| `Classify(err)` universal classification | Works on any error (multi-error → interface → sentinels → default) | Not Applicable | No error values exist in a Go sense |
| Exit-code discipline | `ExitCode(err)` → BSD sysexits (75 EX_TEMPFAIL etc.) | Not Applicable | Exit codes here come from systemd semantics and POSIX sh conventions, not Go |
| Retry decision | `IsRetryable(err)` binary decision per Family | Not Applicable | Retry policy is hand-rolled in QML (probe ladder + `OFFLINE_BANNER_FAILURES` debounce) |
| HTTP mapping | `HTTPStatus()`, `HTTPHandler` middleware | Not Applicable | The only HTTP in the consumer is a QML `fetch` probe and Firebase-served static files — no server code |
| What/Why/Fix/WayOut messaging | Structured audience-aware user errors via `HandleError` | Not Applicable | User-facing text is QML banner strings and Markdown docs |
| Multi-error worst-family | `errors.Join` + deterministic worst-Family pick | Not Applicable | No Go error aggregation surface |
| Experimental submodules (agent, bridge, diagnose/git, diagnose/postgres) | Enrichment and backend-specific diagnostics | Not Applicable | Go-only integrations (oops, git, postgres) with no consumer counterpart |

## 3. Usage evidence in offline-banner

```
rg -n "go-error-family" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' --glob '!docs/review/**'  → 0 matches
find /home/lars/projects/offline-banner -name "*.go"   (excl .git, node_modules)               → 0 files
find /home/lars/projects/offline-banner -name "go.mod"                                         → 0 files
```

Conclusion: zero references, and structurally zero possibility of references — the consumer has no Go module, no Go file, no Go toolchain. Verified 2026-11-18.

## 4. Should offline-banner adopt it?

**SHOULD NOT — structurally.** There is nothing to adopt into: no Go compilation unit exists for the library to link against, and adding a Go toolchain to a Nix + QML + sh repo purely to host an error taxonomy would be net-negative (a second build system, CI surface, and dependency set guarding code that nothing executes).

The honest observation is that offline-banner already arrived at error-family's *conclusions* in its own materials:

- **Classification before string-matching.** The QML journals machine-parseable structured lines (`probe failed reason=net failures=1/2`, `banner state=shown reason=...`) and the flake checks assert on `reason=` values via regex — never on prose. That is error-family's "share the protocol, not the implementation" doctrine applied to a journal instead of an error value. The AGENTS.md doctrine "exact counts only at deterministic positions; assert the TRANSITION" is the same idea: consumers depend on stable *classes* (reason, state), not on wording.
- **Audience-aware presentation.** The banner renders differently per failure class (net/tcp/dns/link legs, degraded ladder, demo marker) — presentation follows classification exactly as `Classify(err).Audience()` prescribes for messages.
- **Exit-code behavior.** The systemd unit's restart policy (`Restart = "always"`, `RestartSec = "5s"` — module.nix:1162-1163) absorbs any exit code and re-runs the service, which is why exit-code *derivation* never became load-bearing here; where it does matter (a Go companion tool), `ExitCode(err)` is the pattern to copy, with the sandbox's known constraints (NoNewPrivileges withheld to keep ping's `cap_net_raw`) documented as deliberate behavior, not accidents.

These are independent rediscoveries of the same design principles, not incomplete adoptions. Nothing is missing; the medium is just not Go.

## 5. Fleet perspective

This is the verdict that serves the owner's constraint best: go-error-family keeps improving for every Go consumer (exit codes, HTTP mapping, diagnose packs) and offline-banner gets those improvements for free *as doctrine* — the classification-before-strings principle it already follows — without carrying a dead dependency. If the library ever renames a concept or ships a better diagnostic contract, nothing in offline-banner breaks, because nothing in offline-banner binds to it.

## 6. If the flip trigger fires

1. **A Go companion CLI** (most plausible: an outage-ledger report generator reading `~/.local/state/offline-banner/ledger` into human/CSV output). Adopt error-family at the CLI boundary from day one: `Family` for probe/sandbox/file errors, `ExitCode(err)` for the process exit, What/Why/Fix/WayOut for `--help`-adjacent error output. Cost: one import; benefit: exit codes a supervisor script can branch on.
2. **A Go check harness** replacing any shell assertion layer. Use `IsRetryable` for CI-flake-prone probes only if the harness owns retry logic (today the QML owns it — do not duplicate).
3. Never adopt `bridge/` or `diagnose/*` here: oops enrichment and git/postgres diagnostics have no target.

## 7. Verify block

```bash
git -C /home/lars/projects/go-error-family describe --tags   # v0.12.0-12-g898004e (or newer on re-review)
rg -n "go-error-family" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'   # 0 matches (the glob excludes this report itself, which contains the search term)
find /home/lars/projects/offline-banner -name "go.mod" -not -path "*/.git/*" # 0 files
find /home/lars/projects/offline-banner -name "*.go" -not -path "*/.git/*"   # 0 files
```
