# cqrs-htmx × offline-banner — Library Utilization Review

| Field                | Value                                                                                                                                                                                         |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Library repo**     | `/home/lars/projects/cqrs-htmx` (github.com/LarsArtmann/cqrs-htmx)                                                                                                                            |
| **Reviewed version** | `loginpage/v4.18.0-266-g361f3136` — latest local tag (HEAD `361f3136`, 2026-11-18; remotes NOT fetched)                                                                                       |
| **Review date**      | 2026-11-18                                                                                                                                                                                    |
| **Reviewed by**      | Fleet-run Group E (library-deep-dive runbook)                                                                                                                                                 |
| **Verdict**          | NOT-APPLICABLE — no web server, no users/auth, no HTMX anywhere in the consumer (website is static Astro, banner UI is QML); the env-var contract deliberately replaces the admin-UI use case |
| **Score**            | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural)                                                                                                               |
| **Flip trigger**     | A Go-served interactive surface with users/auth appears (the far-fetched version: an admin UI for banner config)                                                                              |

## 1. What the library is

From its README: "CQRS + event sourcing for server-rendered Go apps — wired to HTTP and HTMX in one declarative line per endpoint." cqrs-htmx is the HTTP/HTMX binding for go-cqrs-lite: `app.Command()`/`app.Query()` return `http.HandlerFunc` composed from declarative `HandlerOption` values (`DecodeJSON`, `Authorize` via Casbin, `ValidateCommand`, `WithSuccessStatus`, `PushURL`) covering decode → authz → validation → dispatch → response, with HTMX-aware headers (`HX-Trigger`, `HX-Redirect`, `HX-Push-Url`), partial-vs-full rendering, error-to-status mapping, and SSE fan-out. It is explicit that "if you are not using go-cqrs-lite, this library is not for you."

Module families (39 go.mod files in the repo):

| Family (module path)                                        | Purpose/role                                                                                                                                                                                                                                                                                                                                                        |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root (`go.mod`)                                             | Command/query dispatch + typed handlers, HTMX response builder (every `HX-*` header, notifications, OOB swaps, `RenderPartialOrFull`), SSE (thread-safe `Broadcaster`, durable `JournalSSEStore`, heartbeats, ACK protocol), middleware stack, OpenAPI collection, HTTP QUERY method (RFC 10008) with method override, embedded htmx v2/v4 assets with ETag caching |
| `usermgmt` (4 go.mods: root + `webauthn`, `oauth2`, `totp`) | Event-sourced user management: register/login/logout/me, sessions, roles, tenants, bots, lockout, audit log, SQL stores (SQLite/Postgres/MySQL); passwordless WebAuthn/passkeys, OAuth2/OIDC, TOTP MFA as independent sub-modules                                                                                                                                   |
| `adminui`                                                   | Ready-made admin panel (templ): dashboards, audit views, confirm modals                                                                                                                                                                                                                                                                                             |
| `dashboardui`                                               | Live event-store observability dashboard                                                                                                                                                                                                                                                                                                                            |
| `loginpage`                                                 | Prebuilt login page (the repo's own version tag train)                                                                                                                                                                                                                                                                                                              |
| `identity-model`                                            | Shared identity types                                                                                                                                                                                                                                                                                                                                               |
| `auditlog`                                                  | Queryable audit log                                                                                                                                                                                                                                                                                                                                                 |
| `setup`                                                     | One-call full-stack wiring (router + usermgmt + adminui + CQRS)                                                                                                                                                                                                                                                                                                     |
| `datastar`                                                  | Datastar transport alongside HTMX                                                                                                                                                                                                                                                                                                                                   |
| `huma`                                                      | Huma framework adapter                                                                                                                                                                                                                                                                                                                                              |
| `health`                                                    | Health/readiness integration                                                                                                                                                                                                                                                                                                                                        |
| `systemadapter`                                             | go-cqrs-lite `system` engine adapter                                                                                                                                                                                                                                                                                                                                |
| `gfl-usermgmt`                                              | Fleet-consumed usermgmt variant                                                                                                                                                                                                                                                                                                                                     |
| `examples` (13 go.mods)                                     | Runnable, tested demos                                                                                                                                                                                                                                                                                                                                              |
| `scripts` (8 go.mods)                                       | Build/release tooling modules                                                                                                                                                                                                                                                                                                                                       |

## 2. Capability inventory

| Capability                                                    | What the library offers                                                                      | Status in offline-banner   | Reason                                                                                                                                                                                                        |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Command/query HTTP dispatch                                   | `app.Command()`/`app.Query()` HandlerOptions: decode, authorize, validate, dispatch, respond | Not Applicable             | There is no HTTP endpoint and no CQRS core to dispatch against; the domain logic lives in QML                                                                                                                 |
| HTMX-aware responses                                          | Fluent `HX-*` header builder, notifications, OOB swaps, `RenderPartialOrFull`                | Not Applicable             | No HTMX runtime exists; the banner UI is QML, the website is static Astro                                                                                                                                     |
| SSE (hub-first: Broadcaster, JournalSSEStore, heartbeat, ACK) | Durable server-push fan-out of domain events                                                 | Not Applicable (near-miss) | The consumer-channel question was explicitly settled in favor of a polled atomic state file (`contrib/offline-banner-waybar` + evo-x2's DMS plugin poll state; no server process exists to host SSE) — see §4 |
| WebAuthn/passkey auth                                         | Passwordless registration/login ceremonies                                                   | Not Applicable             | There are no users: the banner is a single-host system service; its "authentication" is the systemd user-session boundary                                                                                     |
| OAuth2/OIDC + TOTP MFA                                        | Federated login and second factors                                                           | Not Applicable             | Same — no account model exists to protect                                                                                                                                                                     |
| Authorization (Casbin + `DispatchGate` + `authztest`)         | Provable per-route/per-command posture                                                       | Not Applicable             | Access is governed by the NixOS unit sandbox (which users can run the service), not by HTTP policies                                                                                                          |
| Admin UI / dashboard UI / login page                          | Ready-made templ panels                                                                      | Not Applicable             | Configuration deliberately flows through NixOS module options and env vars (see §4); no admin surface is wanted                                                                                               |
| Audit trail (actor chains, auth-audit events)                 | Who-did-what outliving sessions                                                              | Not Applicable (near-miss) | The outage ledger (`history.jsonl`) is the audit log, and it already answers the domain's audit question (which legs down, when, why) without actors, since the only actor is the banner itself               |
| HTTP QUERY method + OpenAPI                                   | RFC 10008 reads + collected OpenAPI docs                                                     | Not Applicable             | No API surface; docs-drift is handled by the `docs-drift` flake check                                                                                                                                         |
| Embedded htmx assets with ETag caching                        | Zero-CDN htmx/idiomorph/SSE extensions                                                       | Not Applicable             | The static website ships no htmx; Astro bundles what it needs                                                                                                                                                 |

## 3. Usage evidence in offline-banner

Exact commands run (all include the reports-exclusion glob):

- `rg -n "cqrs-htmx" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (the repo never references the library, prose included).
- `rg -n "htmx" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (no HTMX anywhere, independently confirmed).
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod'` → **0 files**.
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go'` → **0 files**.

Conclusion: zero references; no Go runtime exists in the consumer. The three web-ish surfaces are: a static Astro/Starlight website (no server-side rendering, no auth), a QML banner UI inside Quickshell, and a POSIX sh + jq state-file consumer (`contrib/offline-banner-waybar`). None overlaps cqrs-htmx's binding surface.

## 4. Should offline-banner adopt it?

SHOULD-NOT, with one design decision worth honoring explicitly.

**No surface matches.** cqrs-htmx sits between an HTTP router and go-cqrs-lite's dispatcher — offline-banner has neither. The website is static files on Firebase Hosting; the banner UI is QML; the only integration channel consumers use is polling the atomically-written state file. There is no handler to compose `HandlerOption` values into, no command to authorize, no session to carry actor metadata.

**The nearest overlap — SSE — was already decided, and correctly.** cqrs-htmx's SSE hub (broadcaster, journal store, heartbeats) is the fleet's best push channel, and a live-updating banner state feed is exactly the shape it serves. But offline-banner faced this exact consumer-channel question and settled it in favor of the polled state file: the writer is one QML process doing atomic tmp+mv writes, consumers are a jq script and a DMS plugin, and polling a JSON file survives banner restarts, needs no server, and has no reconnect logic to get wrong. Introducing SSE would require standing up a Go process whose only job is to re-broadcast a file that two lightweight consumers already read — net-negative under the fleet constraint.

**The far-fetched version — an admin UI for banner config — is precisely what the env-var contract replaced.** All banner configuration flows NixOS module options → systemd unit env vars (`OFFLINE_BANNER_*`, each contract-asserted by checks). That design means configuration is declarative, reproducible, version-controlled in the host's configuration, and testable in `nix flake check` — an HTTP admin form would fight every one of those properties: state would drift from the Nix config, mutations would escape the eval/check pipeline, and auth would be needed exactly where there are no users. The absence of a config UI is not a gap; it is the architecture. cqrs-htmx's admin/usermgmt stack is excellent machinery for the problem offline-banner deliberately does not have.

## 5. Fleet perspective

This verdict protects both sides of the fleet: it keeps cqrs-htmx's roadmap driven by real GOTH-stack apps rather than a NixOS flake that can never render it, and it records — with receipts — that offline-banner's env-var contract and polled state file are deliberate substitutions for the library's admin surface and push channel, not oversights a future session should "fix." The doctrine transfer is small but real: cqrs-htmx's `authztest` idea (prove the declared posture of every route in CI) has a family resemblance to offline-banner's `module-contract`/`unit-verify` checks, which prove the declared posture of every unit property — the same "declared posture, machine-proven" principle applied to systemd instead of HTTP. When any fleet project does grow a Go-served, user-facing surface, cqrs-htmx plus go-cqrs-lite is the prepared stack; offline-banner is simply not that project.

## 6. If the flip trigger fires

1. **Banner-state web UI on cqrs-htmx queries.** Where: a small Go daemon unit (`packages.banner-web`) using `app.Query()` + `RenderPartialOrFull` to serve current phase/legs from the state file, with SSE (`transport.ServeDomainEvents` over the JSONL ledger) for live updates. Why first: it reuses the existing state/ledger contracts read-only, and the SSE hub finally has a consumer the polling pattern can't serve (browser push).
2. **Add `usermgmt` only when the UI serves multiple humans.** Passkey login via the WebAuthn sub-module, with `authztest` proving every route's posture — the "who can see my outage history" question becomes real only with multi-user hosting.
3. **Use `adminui`'s dashboard patterns, not its panels.** The observability-dashboard templates (event-store views) would guide a banner-history page; importing `adminui` wholesale would drag in auth assumptions the single-user case lacks.
4. **Never add a config-mutating admin page.** Even post-flip, configuration stays NixOS-options → env vars; the web surface stays read-only. This preserves the declarative contract that makes the module testable.

## 7. Verify block

A fresh reviewer re-derives the verdict with:

```sh
# 1. Library identity (expect: loginpage/v4.18.0-266-g361f3136)
git -C /home/lars/projects/cqrs-htmx describe --tags

# 2. Module-family count (expect: 39)
find /home/lars/projects/cqrs-htmx -name go.mod -not -path '*/.git/*' | wc -l

# 3. Consumer references (expect: 0 matches for both — no prose mention either)
rg -n "cqrs-htmx" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'
rg -n "htmx" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'

# 4. No Go runtime in the consumer (expect: 0 and 0)
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod' | wc -l
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go' | wc -l
```

All commands were executed by the reviewer on 2026-11-18 and produced exactly the stated results.
