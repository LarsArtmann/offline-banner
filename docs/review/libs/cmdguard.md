# cmdguard × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/cmdguard` (github.com/LarsArtmann/cmdguard) |
| **Reviewed version** | `v5.1.0-30-g5290526` — latest local tag (HEAD `5290526`, 2026-11-17; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group E (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — offline-banner has no Go CLI (its only CLI-adjacent surface is a bash-generated `systemd-run` wrapper); there is no Cobra command tree for cmdguard to guard |
| **Score** | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural) |
| **Flip trigger** | A real Go CLI with a subcommand surface appears in the repo (e.g. the smoke transient or a config tool migrates from shell to Go) |

## 1. What the library is

From its README: cmdguard is "the Go CLI framework that catches missing handlers, duplicate commands, and invalid flags at construction — not at 2am in production." It wraps Cobra so consumers keep full compatibility while adding a validated construction path: struct-tag flags (no string lookups), dependency injection with lifecycle management, graceful shutdown in reverse order on SIGINT, a zero-panic error contract (no `Run`, no `Must*`; the error is printed exactly once with correct exit codes), health/doctor commands, and a machine-readable `describe` command that emits the full command/flag tree as versioned JSON for AI agents and tooling.

Module families (8 go.mod files in the repo):

| Family (module path) | Purpose/role |
|---|---|
| root (`pkg/cmdguard/v5`, `go.mod`) | Core framework: Cobra wrapper, struct-tag flags, DI scope, lifecycle, doctor/healthchecker, `describe` JSON contract, exit-code handling |
| `flightrecorder` | Go 1.25+ `runtime/trace.FlightRecorder` middleware — buffers execution traces, auto-captures `.trace` snapshots when commands are slow or error; stdlib-only |
| `glamour` | Markdown help rendering for cmdguard CLIs (styled `--help` via charmbracelet/glamour) |
| `lint` | Static-analysis rules (analyzer-based) detecting anti-patterns in cmdguard consumer codebases, derived from real consumer audits and the documented execution contract |
| `prompts` | AI-agent prompt assets for building cmdguard CLIs |
| `schema` | Emits JSON Schema draft 2020-12 describing a config struct or whole CLI from the same struct tags that drive flags/env/config |
| `spinner` | Optional visual spinner for long-running commands |
| `telemetry` | Optional OpenTelemetry middleware (`v5.WithMiddleware(telemetry.Middleware[Config](tracer))`) |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Type-safe struct-tag flags | Flags declared as struct fields, validated when commands are added | Not Applicable | No Go CLI exists; the only argv surface is a POSIX/bash script built by `pkgs.writeText`-style shell generation in flake.nix |
| Construction-time command-tree validation | Missing handlers, duplicate commands, invalid names caught at `AddCommand` time | Fully Leveraged (as doctrine) | The repo's flake checks validate the *rendered* artifacts at build time (unit-verify, module-contract, docs-drift, shell-content, shell-scripts) — the same "fail before it ships" posture, implemented in Nix/bash because there is no Go construction step |
| Dependency injection + service lifecycle | `Provide`/`Injector`, lazy services, reverse-order shutdown on SIGINT | Not Applicable | Nothing to inject into: the runtime process is Quickshell (QML) supervised by systemd, not a Go binary |
| Zero-panic error contract | Every function returns errors; error printed exactly once; `ExecuteAndExit` exit codes | Not Applicable | No Go code in the consumer; the shell scripts fail with plain `exit` codes under `set -eu` |
| Graceful shutdown on SIGINT | Cancels the run and shuts down DI services in reverse order | Not Applicable | Shutdown semantics are owned by systemd (`Restart = "always"`, `RestartSec = "5s"`, module.nix ~:1162) on the QML process |
| Health checks (`DoctorCommand`, `Healthchecker`) | Built-in self-diagnosis commands | Not Applicable | Health is asserted by the `vm-smoke` and `unit-verify` checks against the systemd unit, not by a CLI subcommand |
| Machine-readable `describe` JSON | Hidden `describe` command prints command/flag tree as versioned JSON | Not Applicable | The analog contract exists in another shape: the smoke app's `--print` emits `%q`-quoted, re-runnable shell output derived from the rendered serviceConfig — but it is shell, not cmdguard's JSON |
| `schema` module — JSON Schema from struct tags | Draft 2020-12 schema for config structs | Not Applicable | Configuration is NixOS module options + env vars; no Go config struct exists |
| `flightrecorder` / `telemetry` / `spinner` / `glamour` / `lint` / `prompts` | Trace capture, OTel middleware, progress UI, markdown help, consumer lint rules, agent prompts | Not Applicable | All are Go-runtime conveniences for a Go CLI; offline-banner has no Go runtime to host them |

## 3. Usage evidence in offline-banner

Exact commands run (all include the reports-exclusion glob):

- `rg -n "cmdguard" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **2 matches**, both prose mentions in owner planning docs about the fleet's LICENSE convention (TODO_LIST.md:60 and docs/status/archived/2026-10-17_01-59_full-execution-and-live-smoke-status.md:16). Zero references in code, config, flake inputs, or scripts.
- `rg -n "cobra" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (no Cobra anywhere).
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod'` → **0 files**.
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go'` → **0 files** (zero Go source in the whole repo, website included).

Conclusion: zero usage. The only CLI-adjacent surface in offline-banner is `nix run .#smoke` — a bash-generated transient (`exec systemd-run --user --unit="$name" "''${args[@]}" -- "$qs_bin" -p "$qml_dir"`, flake.nix ~:158) — plus copy-paste POSIX sh scripts under `contrib/` and `scripts/`. There is no Go process to link cmdguard against.

## 4. Should offline-banner adopt it?

SHOULD-NOT, on three independent grounds.

**No linker target.** cmdguard is a Go library; offline-banner contains zero Go code. Adoption would mean introducing an entire Go toolchain into a Nix flake whose runtime process is Quickshell executing QML — pure dependency surface, zero runtime benefit. The `lint`, `schema`, `telemetry`, and `flightrecorder` modules all presuppose a Go CLI that does not exist.

**The smoke app is too small for a framework — and the bug class was structurally outside cmdguard's reach.** The brief asks the honest question: 0.2.1 shipped three argv-integrity bugs in `nix run .#smoke` (CHANGELOG 0.2.1: unquoted array expansion word-split multi-value directives; each props line baked the `-p` prefix into a single argv token getopt mis-parsed; the transient ran bare `quickshell` through whatever PATH it found) — all "structural-grep-invisible," fixed in 41b3f49 by an execution gate in the `smoke-script` check. Would cmdguard have prevented this? No, and the reason is precise: cmdguard validates a *Go command tree at construction* — missing handlers, duplicate commands, invalid flags. The smoke bugs were *shell argv construction* failures: word-splitting, quoting, and PATH resolution in a generated bash script. There is no Go construction step whose validation could have covered them. cmdguard's framework weight (DI, lifecycle, doctor commands, describe JSON) would also be absurd overhead for a ~30-line wrapper whose entire job is one `systemd-run` invocation.

**What the episode actually proves is cmdguard's *doctrine*, not its code.** The fix — an EXECUTION gate that runs the real app under a systemd-run shim, captures argv, asserts multi-value directives arrive as single tokens, checks the command after `--` is the resolved binary, and re-parses `--print` output to the identical argv with the shipped word-split bug as the negative fixture — is cmdguard's core principle ("validated at construction, not at 2am in production") carried to its logical endpoint for shell: when there is no typed construction surface, the gate must be an execution. That doctrine row in §2 is the honest transfer; the library itself stays out.

Under the owner's fleet constraint — many projects, limited time, no net-negative adoptions — importing a CLI framework into a Go-free Nix flake is the textbook net-negative.

## 5. Fleet perspective

This verdict is the cheap kind of good news: cmdguard needs nothing from offline-banner, and offline-banner needs nothing from cmdguard — the audit cost is a few greps. The one-way knowledge transfer already happened through doctrine, and it is concretely documented: cmdguard's "catch it at construction, not in production" principle is what the fleet's check-gate pattern implements, and the 0.2.1 smoke incident (three structural-grep-invisible argv bugs fixed only by an execution gate) is the fleet's best evidence for why check suites need execution-level gates, not just structural greps — a lesson that flows back to every Go project that might over-trust construction-time validation alone. If a future offline-banner tool grows a real subcommand surface in Go, this report's flip trigger fires and cmdguard becomes the obvious first choice.

## 6. If the flip trigger fires

1. **Port `nix run .#smoke` to a Go CLI on cmdguard v5.** Where: a new `cmd/` package wired into flake.nix's `packages.smoke`. Why first: it is the only existing CLI-adjacent surface, and cmdguard would convert its implicit argv contract (single-token directives, resolved binary, `%q`-re-parsable `--print`) into struct-tag flags plus the `describe` JSON contract — deleting the hand-rolled quoting logic that produced the three 0.2.1 bugs.
2. **Adopt `cmdguard/schema` for the smoke app's config surface.** Emit JSON Schema for the derived serviceConfig whitelist so the `smoke-script` check can validate against a versioned schema instead of bespoke greps.
3. **Use `cmdguard/lint` in CI for the new CLI.** The static-analysis rules encode the execution-contract anti-patterns; they would have flagged the argv-handling class at review time.
4. **Leave the QML/shell surfaces untouched.** Even in the flipped world, the banner engine, waybar consumer, and scripts stay shell/QML — cmdguard only claims the Go process.

## 7. Verify block

A fresh reviewer re-derives the verdict with:

```sh
# 1. Library identity (expect: v5.1.0-30-g5290526)
git -C /home/lars/projects/cmdguard describe --tags

# 2. Module-family count (expect: 8)
find /home/lars/projects/cmdguard -name go.mod -not -path '*/.git/*' | wc -l

# 3. Consumer references (expect: exactly 2, both prose LICENSE-convention mentions
#    in TODO_LIST.md and docs/status/archived/…; no code/config hits)
rg -n "cmdguard" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'

# 4. No Go runtime in the consumer (expect: 0 and 0)
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod' | wc -l
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go' | wc -l
```

All four commands were executed by the reviewer on 2026-11-18 and produced exactly the stated results.
