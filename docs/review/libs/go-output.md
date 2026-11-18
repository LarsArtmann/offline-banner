# go-output × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-output` (github.com/LarsArtmann/go-output) |
| **Reviewed version** | `bdd/v0.38.7-10-g90fb2a6` — latest local tag (HEAD `90fb2a6`, 2026-11-17; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group D (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — offline-banner's output surfaces (QML banner, JSON state file, journal lines, waybar text, JSONL ledger) are all hand-shaped render targets with no CLI table/format layer for a Go rendering library to serve |
| **Score** | 0/0 (n/a — no applicable surface; structural) |
| **Flip trigger** | A Go CLI in the fleet that renders tabular reports from offline-banner data (e.g. an outage-ledger report generator) — the ledger's JSONL is exactly the input `serialization`'s JSONL/Table renderers consume |

## 1. What the library is

`go-output` turns structured data into **16 output formats** (tables, trees, diagrams) through a CQRS pattern — mutable builders, immutable snapshots, pure renderers — with type-safe `Format` enums, branded IDs, zero-config color (`NO_COLOR`/`CI`/`FORCE_COLOR` aware), and NOM-style real-time progress visualization inspired by nix-output-monitor. The root module is dependency-light (`golang.org/x/term` only); heavier renderers live in isolated sub-modules imported on demand.

**19 go.mod files**, grouped into five families:

| Module path | Family | Purpose/role |
|---|---|---|
| `github.com/larsartmann/go-output` (root) | Core | Data model (`Table`/`TreeNode`/`GraphNode`+`GraphEdge`), 16-constant `Format` enum, shape system (table/tree/graph), capability matrix, unified `RenderTable` dispatch, color/env detection, streaming, projections, registry, branded IDs |
| `…/serialization` | Serialization | Shape-agnostic JSON / YAML / TOML / JSONL renderers for all three shapes |
| `…/delimited` | Serialization | Streaming CSV/TSV writers with auto-quoting and type-switch marshaling |
| `…/escape` | Serialization | Cell-content escaping shared by text formats |
| `…/markdown` | Serialization | Markdown tables: auto column widths, alignment, bold headers/footers |
| `…/markup` | Serialization | XML, styled HTML (tables + collapsible trees), AsciiDoc renderers with XSS escaping |
| `…/table` | Presentation | Lipgloss terminal tables: rounded borders, alternating row colors |
| `…/tree` | Presentation | ASCII box-drawing trees (`├──`/`└──`) with color cycling |
| `…/graph` | Diagrams | DOT/Graphviz and Mermaid renderers (8 node shapes) over the shared `GraphBuilder` |
| `…/d2` | Diagrams | D2: 20 node shapes, 11 arrow types, SQL tables, grid layouts, style classes |
| `…/daghtml` | Diagrams | HTML rendering of DAGs |
| `…/plantuml` | Diagrams | PlantUML component diagrams; Table→graph and Tree→graph conversion |
| `…/nom` | Real-time | NOM-style progress: dependency trees, activity counts, timing estimates, O(1) summary bars at 10k activities, DOT/Mermaid export of live state |
| `…/tui` | Real-time | Bubble Tea terminal UI |
| `…/bdd` | Tooling | BDD-style test scaffolding for output behavior |
| `…/testhelpers` | Tooling | Golden-file and renderer test helpers |
| `…/testhelpers/graphtest` | Tooling | Graph-renderer conformance test suite |
| `…/integration` | Tooling | Cross-module integration suite |
| `…/examples` | Tooling | Runnable examples (own module to keep root deps clean) |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Table rendering (11 tabular formats: JSON, YAML, TOML, CSV, TSV, JSONL, XML, HTML, AsciiDoc, Markdown, terminal) | Build `Table` once, render anywhere | Not Applicable | No Go program exists to embed it; offline-banner renders no tables — its "display" is a Wayland surface, not a terminal grid |
| Tree/diagram rendering (ASCII tree, D2, Mermaid, DOT, PlantUML, daghtml) | Same snapshot → diagram in five syntaxes | Not Applicable | Architecture diagrams are not part of the banner's runtime; the repo documents its own architecture in Markdown prose (module.nix header), which Nix-rendering does natively |
| JSON serialization (`serialization` root/JSON renderers) | Shape-agnostic JSON output from builders | Fully Leveraged (as doctrine) | The state file (`$XDG_RUNTIME_DIR/offline-banner/state`) and the outage ledger are JSON/JSONL produced by hand-shaped `JSON.stringify` + atomic `printf`+`mv` — the *format discipline* (one JSON object per line, stable keys: `from`/`to`/`durationSec`/`reasons`/`probeFailures`) matches go-output's JSONL contract without needing the library |
| Streaming writers (`CSVWriter`/`JSONLWriter`, `StreamingHTMLRenderer`) | Incremental writes, minimal memory | Fully Leveraged (as doctrine) | The ledger append (`printf '%s\n' >> historyPath`) and the state rewrite (`tmp` + `mv -f` rename, CI-proven to avoid empty-file read windows) implement the same write-side streaming/atomicity discipline in `sh` |
| Type-safe enums & branded IDs (`Format`, `D2NodeID`, …) | Parse-time validation, compile-time ID separation | Not Applicable | The banner's "types" are QML string literals (`phase`, `reason`) enforced by flake checks (`module-contract`, `probe-transitions`, `leg-contract`) instead of a compiler — same goal, different host |
| Zero-config color / TTY detection (`ColorModeAuto`) | `NO_COLOR`/`CI`/`FORCE_COLOR` respected | Not Applicable | The banner's color semantics (yellow alarm, info-blue degraded strip) are hardcoded QML `Rectangle` colors on a compositor surface; there is no terminal palette to auto-detect |
| NOM real-time progress | Dependency trees, activity bars, timing estimates for long workflows | Not Applicable | The banner's long-running "workflow" is a probe loop; its progress channel is the 1 Hz `updatedAt` heartbeat, not a TUI |
| TUI (`tui`, Bubble Tea) | Interactive terminal interface | Not Applicable | Interaction is Wayland (click-to-dismiss) plus env-var configuration; no terminal app exists |
| Runtime format selection (`ParseFormat`, `FormatsForShape`) | CLI-flag-driven dispatch with capability matrix | Not Applicable | Consumers pick their surface at integration time (waybar reads the state file; humans read the journal); there is no `--format` flag surface to validate |
| Test helpers / BDD / golden files (`testhelpers`, `bdd`, `graphtest`) | Renderer conformance suites | Fully Leveraged (as doctrine) | The same "pin the exact output" discipline exists as flake checks: `waybar-consumer` fixtures assert the consumer's exact JSON lines; `probe-transitions` asserts state-file shapes; `module-contract` greps unit text |

## 3. Usage evidence in offline-banner

The EXACT commands run (all exclude the reports directory):

- `rg -n "go-output" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **0 matches** (exit 1)
- `find /home/lars/projects/offline-banner -name 'go.mod' -not -path '*/.git/*'` → **0 files**
- `find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*'` → **0 files**

Supporting context (same greps, no library-name match): the repo's only renderers are QML (`module.nix:246` inlines `shell.qml` via `pkgs.writeTextDir`), `printf`+`jq` in POSIX sh (`contrib/offline-banner-waybar`), `JSON.stringify` writes inside the QML (`module.nix:597-617` state object, `module.nix:663-669` ledger entry), and the Astro website (`website/package.json`: astro ^7.4.12, typescript ^6.0.3). Conclusion: zero references; no Go runtime exists in the consumer.

## 4. Should offline-banner adopt it?

**SHOULD-NOT.** go-output solves the problem "render one dataset in many formats from one Go program." offline-banner inverts it: each output surface is *hand-shaped for its consumer* and lives in a different language — the QML strip is rendered by Quickshell's compositor integration, the state file is a jq-friendly fixed-shape JSON whose every key is pinned by flake checks, the journal carries grep-able `banner state=` tokens, the ledger is append-only JSONL, and the waybar consumer emits waybar's exact custom-module JSON. There is no place where a `Table`/`Tree`/`Graph` snapshot and a `Format` enum would collapse this; the formats are not a parameter, they are *the products themselves*.

A forced adoption would also drag a Go toolchain into a Nix/QML flake for zero runtime benefit: the library's value proposition (write once, render anywhere in-process) requires being in the same process as the data — the banner's data never passes through Go. The 19-module workspace would be pure bug-fix surface, which the owner's fleet constraint explicitly calls net-negative.

The one *real* conceptual neighbor: the outage ledger. go-output's JSONL + table renderers are built to turn exactly such an append-only log into human-readable reports — but that consumer doesn't exist yet, and when it does, the honest comparison in this repo is an Astro page (the website stack already present) reading the JSONL over a Go report CLI. That hypothetical is the flip trigger, not an adoption case.

## 5. Fleet perspective

go-output is a strong fit elsewhere in the owner's fleet (any Go CLI with tabular output), so this NOT-APPLICABLE costs nothing. The transferable assets go the *other* direction, and offline-banner already holds them: the "freeze then render" discipline maps to its immutable, check-pinned state-file shape; the streaming-writer discipline maps to its atomic tmp+mv writes; the golden-file test discipline maps to `waybar-consumer` fixtures. If a fleet-wide "render the outage ledger" tool ever gets built, go-output is the right hammer — and it should live in a Go-side project, reading offline-banner's documented JSONL contract, not inside offline-banner.

## 6. If the flip trigger fires

1. **Outage-ledger report CLI in a Go-side fleet repo** (most plausible): a small `cmd/` tool that reads `~/.local/state/offline-banner/*.jsonl`, builds `output.NewTable()` from `{from, to, durationSec, reasons, probeFailures}` rows, and renders Markdown (for docs) and terminal tables (for interactive use) via the root + `markdown` + `table` modules. Lives outside offline-banner; consumes its documented ledger contract.
2. **Website statistics page**: render the ledger into a pre-built JSON/Markdown table at site build time with the same tool, feeding the Astro page — keeps offline-banner itself Go-free.
3. **Probe-transition fixtures**: if the fleet ever unifies "exact output" testing style, `testhelpers` golden-file patterns could inspire a shared fixture harness — though `waybar-consumer`'s existing fixture check already covers the local need.

## 7. Verify block

```sh
# 1. Library version facts
git -C /home/lars/projects/go-output describe --tags   # bdd/v0.38.7-10-g90fb2a6
git -C /home/lars/projects/go-output log -1 --format='%h %ad' --date=short  # 90fb2a6 2026-11-17
find /home/lars/projects/go-output -name go.mod -not -path '*/.git/*' | wc -l  # 19

# 2. Zero usage in the consumer (reports excluded)
rg -n "go-output" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'  # no output, exit 1
find /home/lars/projects/offline-banner -name '*.go' -not -path '*/.git/*' | wc -l  # 0

# 3. The hand-shaped output surfaces that make the library moot
grep -n 'JSON.stringify' /home/lars/projects/offline-banner/module.nix | head -2   # state + ledger writers
grep -rn 'printf' /home/lars/projects/offline-banner/contrib/offline-banner-waybar | head -2  # consumer text
```

All three blocks were executed on 2026-11-18 and reproduce the stated results.
