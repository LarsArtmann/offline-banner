# TODO List — offline-banner

Dispatch queue. Lifecycle tags: `[ready]` `[blocked:user]` `[blocked:push]` `[blocked:deploy]` `[watch]` `[decision]`. Sources use sibling-relative paths into SystemNix (`../SystemNix/docs/status/...`) — the extraction origin.

## Quality

- [ ] [ready] **state-transition observability** — journal line on show/hide (probe-script stderr or `console.log`) + fail-closed presence metric (`offline_banner_active` + unit-alive gauge); a dead banner is currently silent. **Source:** ../SystemNix/docs/status/2026-10-16_02-26_offline-banner-live-session-status.md §f.1
- [ ] [ready] **VM/negative test** — env-overridable carrier sysroot (`OFFLINE_BANNER_SYSROOT`, default `/sys`) + probe injection; assert link/net/ok/debounce transitions. **Source:** same report §f.2
- [ ] [ready] **IPv4-only probe blind spot** — probeHost is an IPv4 literal: v6-up/v4-down shows "offline" while browsing works over v6. Document the tradeoff in the option description or add a v6 leg. **Source:** same report §f.7
- [ ] [ready] **demo mode (`OFFLINE_BANNER_DEMO=1`)** — force-show without probes; retires the unroutable-IP drop-in hack for demos + post-deploy checks. **Source:** ../SystemNix/docs/status/2026-10-16_04-43_offline-banner-v3-iteration-status.md §f.3
- [ ] [ready] **claim cleanup** — (1) the module-header claim "DMS plugins cannot render layer-shell surfaces" was reasoned, never tested: verify or soften (now in README too); (2) the iface-exclude list (lo/docker/br-/veth/virbr/tailscale/zt/wg/tun/tap) also exists in SystemNix's dual-wan QML — keep a cross-reference comment pointing at the sibling copy. **Source:** ../SystemNix/docs/status/2026-10-16_02-26_offline-banner-live-session-status.md §f.5/§f.6

## Verification debts (carried from the origin host)

- [ ] [watch] **hardened-unit live verification** — the systemd sandbox added 2026-10-16 (`ProtectSystem=strict`, `RestrictAddressFamilies`, kernel/clock/hostname protections; `NoNewPrivileges` deliberately absent, see module.nix) is eval-checked only (`module-contract` asserts the unit text). Quickshell must still render + ping under it in a live session before the SystemNix cutover; expected-benign: Qt cache-write warnings under the read-only filesystem. **Source:** nix-review pass 2026-10-16

- [ ] [watch] **live-verification debts** — reboot/re-login auto-start via graphical-session.target (origin host's first start was manual); multi-monitor proof (only DP-1 proven on origin); click-to-dismiss never machine-verified (virtual-pointer harness or first live outage). **Source:** ../SystemNix/docs/status/2026-10-16_02-26_offline-banner-live-session-status.md §f.4/§f.8/§f.9

## Project plumbing

- [ ] [blocked:user] **LICENSE decision** — no license file yet; origin sibling niri-session-manager is GPLv3. Owner must choose.
- [ ] [blocked:push] **create remote + push** — `github:LarsArtmann/offline-banner` does not exist yet; nothing (CI included) is live until pushed. The SystemNix cutover (add flake input, relock, thin-wrapper conversion, parity verify, delete in-tree module) is queued in SystemNix's TODO_LIST and waits on this.
- [ ] [watch] **origin-host tunables** — live-tunable interval/threshold without rebuild (dms ipc or drop-in doc): a change currently requires rebuild or manual drop-in. **Source:** ../SystemNix/docs/status/2026-10-16_02-26_offline-banner-live-session-status.md §f.18
