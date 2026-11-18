# go-credentials-store × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-credentials-store` (github.com/LarsArtmann/go-credentials-store) |
| **Reviewed version** | `v0.4.3-1-gd62a698` — latest local tag (HEAD `d62a698`, 2026-11-15; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group D (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — offline-banner holds zero secrets under a fully public env-var contract and a sandbox that deliberately minimizes writable state; there is no credential to store, resolve, or audit |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | offline-banner acquiring any secret at all (e.g. tokens for remote outage notifications) — a design the public-contract doctrine makes deliberately unlikely |

## 1. What the library is

`go-credentials-store` is an event-sourced, encrypted-at-rest credentials store for personal infrastructure — **API keys**, **Playwright session blobs** (storageState), and **passwords** — with lifecycle audit (created/rotated/probed/used/revealed) and a single-operator loopback admin UI. Secret material is sealed with XChaCha20-Poly1305 (KeyID rotation) *before* it becomes an event; views and HTML carry verdicts only, never secrets. It is library-first (`credentials.Build(ctx, opts)` + `Resolve(ctx, platform, kind)`), built on go-cqrs-lite's `system` composition root + `metaengine` read models, feature-complete for single-operator use and adopted by CV in production; the admin UI (list filtering, SSE live updates, audited one-time reveal, `/status` page, Prometheus `/metrics`; non-loopback binds require an API key) is an opt-in `adminui.Mount` shim, and `cmd/credentials-server` is the reference Nix-packaged host.

Single module: `github.com/larsartmann/go-credentials-store` (go 1.27.2). Notable fleet-internal dependencies: `go-daemon v0.4.0` (server lifecycle), the `go-cqrs-lite` family (command/decider/encryption/event/id/metaengine/query/system/systemscenario), `go-sse`, `httputil`, `templ-components`, `cmdguard`.

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Credential resolution (`credentials.Build` + `Resolve(platform, kind)`) | Typed lookup of API keys / session blobs / passwords at runtime | Not Applicable | The banner's entire configuration surface is public env vars (`OFFLINE_BANNER_PROBE_HOST`, `OFFLINE_BANNER_SOUNDS`, `OFFLINE_BANNER_HISTORY`, sound theme/volume, …) — nothing it reads is secret, so there is nothing to resolve |
| Encryption at rest (XChaCha20-Poly1305, KeyID rotation, sealed-before-event) | Secret material never exists unencrypted in the event log | Not Applicable | The only data offline-banner persists is non-sensitive outage metadata (times, leg names, failure counts) written to a user-owned JSONL ledger; encrypting it would add key management to protect nothing |
| Event sourcing (go-cqrs-lite system + metaengine read models) | Full command/event history, replayable views | Fully Leveraged (as doctrine) | The outage ledger is a minimal event log by the same philosophy: append-only JSONL entries `{from, to, durationSec, reasons, probeFailures}` written only on completed transitions (recovery), never mutated — an event-sourced outage history without the engine |
| Lifecycle audit (created/rotated/probed/used/revealed) | Every credential touch is an auditable event | Fully Leveraged (as doctrine) | The same "every state change is observable" doctrine: phase transitions emit grep-able journal tokens (`banner state=`) and terminal outages append ledger entries — audit for *availability*, which is this repo's only state |
| Admin UI (`adminui.Mount`: SSE updates, one-time reveal, `/status`, `/metrics`) | Loopback operator console with auth on non-loopback binds | Not Applicable | No operator console exists and none is wanted — the "operator surface" is the always-visible banner strip itself plus the waybar widget; a UI requiring an API key would contradict the repo's zero-credential posture |
| Server runtime (`cmd/credentials-server`, go-daemon-backed) | Reference Nix-packaged host with sandbox/key config | Not Applicable | offline-banner's only daemon is the Quickshell unit; adding a second persistent service to hold credentials it does not have is the double-service anti-pattern |
| CV compatibility (`cvcompat`, `cmd/credentials-import-cv`) | Migration path from CV's prior storage | Not Applicable | No prior credential store exists to migrate from |
| Freshness/probe tracking (internal `freshness`) | Tracks credential probe staleness | Not Applicable | The only freshness contract in offline-banner is the `updatedAt` heartbeat consumed via `OFFLINE_BANNER_MAX_AGE` — it guards a public state file, not secret validity |

## 3. Usage evidence in offline-banner

The EXACT commands run (all exclude the reports directory):

- `rg -n "go-credentials-store" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (exit 1)
- `find /home/lars/projects/offline-banner -name 'go.mod' -not -path '*/.git/*'` → **0 files**
- `find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*'` → **0 files**

Secret-adjacent audit (same greps, no matches for credential shapes): `rg -n -i "token|secret|password|apikey|api_key|credential" … --glob '!.git' --glob '!docs/review/**'` surfaces only (a) the CI workflow's `FIREBASE_SERVICE_ACCOUNT` — a **GitHub Actions repository secret consumed by `website.yml` for Firebase Hosting deploys**, i.e. repository configuration, never a user-facing store or part of the banner runtime; (b) `flake.nix:205`'s `password = "smoke"` — the throwaway autologin credential of the VM smoke-test user, a test fixture with no relationship to any host; and (c) prose in docs/CHANGELOG/TODO. The module's own header confirms the posture: the sandbox (`ProtectSystem=strict`, `ProtectHome=read-only`) leaves exactly **one** writable path — the StateDirectory-provisioned ledger dir — and that path holds outage history, not credentials. Conclusion: zero references, zero secrets; no Go runtime exists in the consumer.

## 4. Should offline-banner adopt it?

**SHOULD-NOT, unconditionally.** The library presupposes a problem offline-banner architecturally refuses to have: credentials. The banner reads public configuration from env vars, probes the network with unauthenticated primitives (ICMP, TCP connect, NSS resolution), writes only non-sensitive outage facts, and its systemd sandbox intentionally shrinks writable state to a single ledger directory — the 2026-11-05 226/NAMESPACE incident was *about* keeping that write surface provisioned and minimal. Introducing a credentials store would invert the repo's core security story: a component designed to have no secret material would gain a master key, an encrypted event database, and an admin surface to guard.

The fleet's one credential-adjacent fact — CI's `FIREBASE_SERVICE_ACCOUNT` — also argues against adoption rather than for it: it lives in GitHub's secret store, is consumed solely by the website deploy workflow, and is exactly where a build-time deploy credential belongs. Moving it "into" offline-banner (or resolving it via go-credentials-store at runtime) would put a deploy credential into a desktop banner's blast radius for zero benefit.

Under the owner's fleet constraint this is the cleanest NOT-APPLICABLE of the set: the library is excellent *for the projects that hold secrets* (CV in production proves it), and its correct relationship to offline-banner is none at all. The only shared doctrine — append-only event logs and observable state changes — offline-banner already implements natively in the ledger and journal.

## 5. Fleet perspective

This verdict is pure upside for the collective: go-credentials-store's value concentrates in fleet projects that genuinely hold secrets, where its encrypted-at-rest + audited-lifecycle design (and its go-daemon/go-cqrs-lite stack, already wired through the fleet's first-party modules) pays off — offline-banner simply has no seat for it. The doctrine transfer runs the friendly direction: the ledger's append-only, transition-only, never-mutated entry shape is a small-scale instance of the same event-sourcing discipline the store implements at full strength, and either repo's docs can cite the other as the minimal/maximal version of "state changes are facts, facts are events." No action needed; nothing to improve via a non-Go channel beyond what the ledger already does.

## 6. If the flip trigger fires

1. **Remote outage notifications gain auth** (hypothetical first mover): if the banner ever pushes outage events to a webhook/NTFY-style sink requiring a token, the token should still be injected via systemd `Environment=`/credentials (`LoadCredential=`) rather than an embedded store — and only if that proves unmanageable would `credentials.Resolve` belong in a small *helper*, never in the banner unit itself.
2. **A fleet-wide secrets tier**: if the owner's infrastructure consolidates secrets in go-credentials-store, fleet projects consume it *at deploy/configuration time*, keeping runtime units secret-free — offline-banner's flip trigger would still not fire because the unit itself would keep reading env vars.
3. **Stay honest**: neither scenario is on any roadmap (ROADMAP.md's items are retuning/IPC and docs work); the trigger exists in the review contract, not in any plan.

## 7. Verify block

```sh
# 1. Library version facts
git -C /home/lars/projects/go-credentials-store describe --tags   # v0.4.3-1-gd62a698
git -C /home/lars/projects/go-credentials-store log -1 --format='%h %ad' --date=short  # d62a698 2026-11-15
find /home/lars/projects/go-credentials-store -name go.mod -not -path '*/.git/*' | wc -l  # 1

# 2. Zero usage in the consumer (reports excluded)
rg -n "go-credentials-store" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  # no output, exit 1
find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*' | wc -l  # 0

# 3. The zero-secret posture that makes the library moot
rg -n -i "token|secret|password|api_?key|credential" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' -g '!*.lock'  # only CI FIREBASE_SERVICE_ACCOUNT, the VM smoke-test fixture, and prose
grep -n 'ProtectSystem\|ProtectHome' /home/lars/projects/offline-banner/module.nix  # sandbox: read-only world, one writable ledger dir
```

All three blocks were executed on 2026-11-18 and reproduce the stated results.
