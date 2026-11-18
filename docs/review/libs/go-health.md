# go-health × offline-banner — Library Utilization Review

| Field                | Value                                                                                                                                                                                                                   |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Library repo**     | `/home/lars/projects/go-health` (github.com/LarsArtmann/go-health)                                                                                                                                                      |
| **Reviewed version** | `v0.10.0-4-g2c9c743` — latest local tag (HEAD `2c9c743`, 2026-11-15; remotes NOT fetched)                                                                                                                               |
| **Review date**      | 2026-11-18                                                                                                                                                                                                              |
| **Reviewed by**      | Fleet-run Group D (library-deep-dive runbook)                                                                                                                                                                           |
| **Verdict**          | NOT-APPLICABLE — offline-banner IS a health-check system, but it is one, implemented natively in QML+systemd; the conceptual overlap is deep yet every capability has a structural reason to stay unhosted              |
| **Score**            | 0/0 (n/a — no applicable surface; structural)                                                                                                                                                                           |
| **Flip trigger**     | Any fleet Go service adopting probe-style health endpoints — go-health is the right SDK there; for offline-banner itself only a Go port of the probe engine (implausible — QML is the process host) would open the door |

## 1. What the library is

`go-health` is a Kubernetes health-probe SDK for [samber/do](https://github.com/samber/do) v2 containers: it turns the three-probe pattern (liveness, readiness, startup) into a single `Probe` type with sensible defaults, critical/non-critical service classification, 1-second background caching, and shutdown awareness — so a dependency blip degrades instead of triggering a kubelet restart cascade.

**3 go.mod files:**

| Module path                               | Purpose/role                                                                                                                                                                                                                            |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `github.com/larsartmann/go-health` (root) | The SDK: `Probe` lifecycle (`Start`/`Shutdown`/`AwaitReady`), `/healthz` `/readyz` `/startupz` `/version` routes, classification, cache, `aggregate/` and `federation/` packages, `checks/` common-check batteries, recorder/audit seam |
| `…/testdata/httputil-interop`             | Fixture module (deliberately outside root): proves the documented `httputil` composition recipes compile against the published release; ships nothing to consumers                                                                      |
| `…/tools/doanalyzerv2`                    | Static-analysis tool (depends on go-design-smells) for samber/do usage in the repo                                                                                                                                                      |

## 2. Capability inventory

The concept-by-concept comparison against offline-banner's native implementation (probe ladder with legs, debounce, phase ladder, staleness heartbeat — all in `module.nix`'s inlined QML plus the POSIX `contrib/offline-banner-waybar` consumer):

| Capability                                                                     | What the library offers                                                                                | Status in offline-banner      | Reason                                                                                                                                                                                                                                                                        |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Check registry (samber/do named services, `WithCriticalServices`)              | Register every check by name; eager first-batch validates critical names (`ErrUnknownCriticalService`) | Fully Leveraged (as doctrine) | The per-leg ladder (link / icmp / tcp / dns) is the registry: each leg is a named, independently-tracked check with its own counter (`failures`/`tcpFailures`/`dnsFailures`) and per-leg journal tokens; "critical" is expressed by the phase ladder, not a registration list |
| Health states & classification (pass/warn/fail; critical vs non-critical)      | Readiness gates on critical failures only; non-critical → 200 `warn`                                   | Fully Leveraged (as doctrine) | The online/degraded/offline ladder is the same classifier: _offline_ = critical (yellow alarm, sound cue, ledger entry), _degraded_ = a leg down while others are up, no ledger, auto-fading strip (module.nix header, "SMART DISPLAY")                                       |
| Per-check `since` metadata                                                     | Probe-observed transition timestamps per check                                                         | Fully Leveraged (as doctrine) | The state file carries `since` (outage start, epoch sec, the live twin of the ledger's `from`) plus per-leg `failures` counters — same observability shape, JSON file instead of HTTP body                                                                                    |
| Freshness / cache staleness (`CacheAge()`, `CachedResponseFresh(maxAge)`)      | Distinguish "never evaluated" from "fresh pass"; serve-cache-or-mark-stale                             | Fully Leveraged (as doctrine) | The `updatedAt` heartbeat + `OFFLINE_BANNER_MAX_AGE` (default 15 s, ~three probe intervals) in the waybar consumer is the identical fail-closed contract: an old heartbeat means "unit effectively dead", never silence                                                       |
| Probe debounce/coalescing (1 s background cache, `WithLiveThrottle`)           | Coalesce poll floods into one evaluation per window                                                    | Fully Leveraged (as doctrine) | Per-leg consecutive-failure debounce (`failuresToShow`) kills flap-driven flapping — the policed-ICMP lesson (2026-11-09 evo-x2) is the same "one noisy check must not flap the aggregate" principle                                                                          |
| Startup latch (`/startupz`)                                                    | Latch 200 once all critical services pass                                                              | Not Applicable                | The banner has no boot-gated contract to expose; QML starts probing immediately and the unit's `Restart=always` makes a failed start self-healing                                                                                                                             |
| HTTP probe endpoints (`/healthz` `/readyz` `/version` + method-set 405s)       | Kubelet-consumable JSON routes                                                                         | Not Applicable                | The observability surfaces are a polled JSON state file (`$XDG_RUNTIME_DIR/offline-banner/state`) and journald tokens — file+journal, not HTTP; adding a listener would widen the sandbox for no consumer                                                                     |
| Aggregate & federation packages (`aggregate/`, `federation/`)                  | Merge multiple probes; fetch remote probes into one view                                               | Not Applicable                | Single host, single unit, one probe engine — there is nothing to federate                                                                                                                                                                                                     |
| Shutdown awareness (`Shutdown()` flips readiness 503)                          | Signal "going away" to LBs                                                                             | Not Applicable                | systemd owns stop semantics; the staleness heartbeat already reports the post-death state to consumers                                                                                                                                                                        |
| Recorder/audit seam (`HealthRecorder`, `ChainRecorders`, `WithEvaluationHook`) | Observe every classified check batch                                                                   | Fully Leveraged (as doctrine) | The outage ledger (JSONL append on recovery: `{from,to,durationSec,reasons,probeFailures}`) plus structured journal lines are the record sink; every phase transition is journal-greppable (`banner state=`)                                                                  |
| Panic-hardening & fail-closed responses                                        | Recover misbehaving checks into failed status                                                          | Not Applicable                | The probe runs `ping`/`getent`/TCP connects via QML `Process` with exit-code checks; there are no Go panics to recover from, and fail-closed is enforced by the consumer's jq-based max-age check                                                                             |
| Deterministic testing (`WithNowFunc`)                                          | Injected clock, no sleeps                                                                              | Fully Leveraged (as doctrine) | Flake checks (`probe-transitions`, `waybar-consumer` fixtures, `leg-contract`) drive the same determinism by faking state files/argv seams instead of a clock object                                                                                                          |
| `checks/` batteries & `testdata/httputil-interop`                              | Reusable common checks; compile-proof fixtures                                                         | Not Applicable                | The four legs are bespoke (carrier via sysfs, ICMP, TCP connect, NSS-resolver answer validation) — exactly the checks a generic battery does not ship                                                                                                                         |

## 3. Usage evidence in offline-banner

The EXACT commands run (all exclude the reports directory):

- `rg -n "go-health" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (exit 1) — note this pattern would also catch `go-health-dashboard`; both are absent
- `rg -n "go-health-dashboard" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (exit 1)
- `find /home/lars/projects/offline-banner -name 'go.mod' -not -path '*/.git/*'` → **0 files**
- `find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*'` → **0 files**

Conclusion: zero references; no Go runtime exists in the consumer. The health system is natively implemented in ≈675 lines of inlined QML (`module.nix:246-921` — probe ladder, debounce, phase ladder, state/journal/ledger writers) plus the POSIX waybar consumer, supervised by the systemd user unit.

## 4. Should offline-banner adopt it?

**SHOULD-NOT — this is the strongest conceptual neighbor in the set, and still structurally N/A.** Concept-by-concept, offline-banner independently arrived at go-health's architecture: named checks (legs) ≈ service registry; online/degraded/offline ≈ pass/warn/fail with critical classification; per-leg debounce ≈ cache/throttle coalescing; `updatedAt` + `OFFLINE_BANNER_MAX_AGE` ≈ `CachedResponseFresh(maxAge)`; the outage ledger ≈ the recorder seam; the fail-closed stale marker ≈ shutdown-aware fail-closed. The _design language_ is the same; the _runtime host_ could not be more different.

Adoption fails on three structural grounds. (1) **No Go host**: go-health is a library for Go processes registered in a samber/do container; offline-banner's process is a Quickshell QML engine — embedding a Go probe SDK into it is not possible without replacing the entire banner. (2) **Wrong surface**: go-health serves HTTP to a kubelet; offline-banner's consumers are a jq-polling shell script and a human reading the journal — an HTTP listener inside the unit would expand the sandbox (`ProtectSystem=strict`, read-only home) for zero gain. (3) **Probe semantics are domain-specific**: the four legs (sysfs carrier, ICMP to a literal IP so DNS can't gate the banner, TCP to 1.1.1.1:53, NSS-path DNS with block-page answer validation) are precisely the checks a Kubernetes-flavored battery does not ship, tuned by live incidents (the 2026-11-09 policed-ICMP flap, the 2026-11-05 226/NAMESPACE outage).

Under the owner's fleet constraint, forcing it would add a Go toolchain plus samber/do for a system whose every check already exists and is CI-pinned — pure bug-fix surface, zero payoff. The honest outcome is exactly this verdict.

## 5. Fleet perspective

The verdict protects both sides: offline-banner stays a pure Nix/QML flake, while go-health keeps serving the fleet projects that actually run Go HTTP services. The flow that _should_ happen is doctrine export, and it has already happened in effect — offline-banner's legs/debounce/heartbeat design and go-health's three-probe design are convergent solutions to "health is not one boolean." Where a fleet Go service needs probes, go-health is the obvious SDK; where offline-banner needs health semantics, it already implements the same principles natively. A future cross-pollination worth noting: offline-banner's _public-answer validation_ on the DNS leg (a synthesized/private answer counts as down) is a sharper test than a generic TCP dial check, and that idea could strengthen go-health's `checks/` battery for real-resolver scenarios.

## 6. If the flip trigger fires

1. **A fleet Go service (most plausible)**: adopt go-health in any Go HTTP daemon that needs kubelet-compatible probes — root module + `RegisterRoutes(mux, DefaultRoutes())` is the whole integration. Lives in that service's repo, not offline-banner.
2. **A Go port of the probe engine** (hypothetical): if the probe ladder ever outgrew QML (e.g. fleet-wide multi-host aggregation), go-health's aggregate/federation packages would be the natural home — but it would still live beside the banner as a separate unit, with offline-banner's state file as the interface.
3. **Cross-credit the DNS-answer validation**: port offline-banner's "public answer or down" rule into go-health's `checks/` battery as a resolver check — an improvement to the library driven by the banner's live incidents, requiring no adoption in the consumer.

## 7. Verify block

```sh
# 1. Library version facts
git -C /home/lars/projects/go-health describe --tags   # v0.10.0-4-g2c9c743
git -C /home/lars/projects/go-health log -1 --format='%h %ad' --date=short  # 2c9c743 2026-11-15
find /home/lars/projects/go-health -name go.mod -not -path '*/.git/*' | wc -l  # 3

# 2. Zero usage in the consumer (reports excluded)
rg -n "go-health" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  # no output, exit 1
find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*' | wc -l  # 0

# 3. The native health system that makes the library moot
grep -n 'phase: root.phase\|updatedAt: Math.floor' /home/lars/projects/offline-banner/module.nix  # state writer
grep -n 'OFFLINE_BANNER_MAX_AGE' /home/lars/projects/offline-banner/contrib/offline-banner-waybar  # staleness heartbeat
```

All three blocks were executed on 2026-11-18 and reproduce the stated results.
