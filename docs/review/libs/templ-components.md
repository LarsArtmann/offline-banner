# templ-components × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/templ-components` (github.com/LarsArtmann/templ-components) |
| **Reviewed version** | `charts/echarts/v1.27.0-104-gd5702fc1` — latest local tag (HEAD `d5702fc1`, 2026-11-17; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group E (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — the offline-banner website is a static Astro/Starlight docs site (TypeScript); templ-components targets interactive Go-served (templ+HTMX) UIs, a category the repo does not have |
| **Score** | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural) |
| **Flip trigger** | offline-banner ships a Go-served interactive page (e.g. a live banner-state web UI served by a Go process) |

## 1. What the library is

From its README: "Server-rendered Go components that ship real HTML — no JavaScript framework required. Built on templ, HTMX, and Tailwind CSS v4." templ-components is the UI layer of the owner's GOTH stack: ~240 prebuilt templ components (dark-mode-aware, CSP-nonce-threading, no DaisyUI/Node.js) that a Go binary renders directly, with generated `*_templ.go` files shipped in-module so a plain `go get` builds without the templ CLI.

Module families (9 go.mod files in the repo):

| Family (module path) | Purpose/role |
|---|---|
| root (`go.mod`) | Core component packages: `display` (53 — cards, tables, tabs, modals, grids, stat cards, native SVG charts, dual-transport kanban, scrollbacks), `feedback` (15 — alerts, toasts, spinners, skeletons), `forms` (26), `navigation` (12), `layout` (11) + `internal` |
| `icons` | 102 SVG icons |
| `htmx` | 9 HTMX integration components (attributes, SSE wiring) |
| `datastar` | 6 Datastar integration components |
| `charts/echarts` | 2 opt-in ECharts adapter components |
| `errorpage` | 4 error-page components |
| `utils` | `wire` — one action struct that drives both HTMX and Datastar transports |
| `visualtest` | Visual regression test harness |
| `website` | The demo/docs site (itself a Go-served templ app) |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| Server-rendered component catalog (display/feedback/forms/navigation/layout) | ~117 core templ components for Go-served pages | Not Applicable | The website is Astro + Starlight (TypeScript components, `astro build`, per website/package.json); no templ templates or Go renderer exist anywhere in the repo |
| HTMX integration | `htmx` package + `utils/wire` dual-transport actions for partial swaps | Not Applicable | No HTMX runtime or server-rendered partials; the only "interactive" surfaces are the QML banner and static site JS |
| Datastar integration | 6 components for the Datastar reactive backend | Not Applicable | No Datastar consumer in the repo |
| Charts (native SVG + ECharts adapter) | LineChart/AreaChart/Pie + opt-in ECharts | Not Applicable | The site's content is docs/marketing (install guide, changelog); no data-driven charts, and the live banner visualization is Quickshell QML, not HTML |
| `icons` (102 SVG icons) | Static SVG icon set usable outside templ | Not Applicable (near-miss) | Starlight ships its own icon system; adopting foreign SVGs into a Starlight theme buys inconsistency, not capability |
| `errorpage` (4 components) | Go-rendered error pages | Not Applicable | Static hosting on Firebase Serving; error pages would come from the host/CDN, not a Go process |
| Dark-mode awareness + CSP nonce threading | `layout.Base`/`ThemeScript` with nonce compliance | Not Applicable | Astro/Starlight handles theming; the site's CSP is patched by its own build step (`node scripts/fix-csp.mjs` in website/package.json) |
| Tailwind CSS v4 styling | Components styled with Tailwind v4 utilities | Partially Used (shared only by coincidence) | The website *does* use Tailwind v4 — but via Astro's own Tailwind integration, not via templ-components; the library contributes nothing to it |
| Thread-safe one-binary rendering | All UI ships inside the Go binary, no Node runtime | Not Applicable | The site intentionally ships as static files; there is no server process to embed UI into |

## 3. Usage evidence in offline-banner

Exact commands run (all include the reports-exclusion glob):

- `rg -n "templ-components" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'` → **2 matches**, both prose mentions of the library's *name* in owner planning docs about the fleet's MIT LICENSE convention (TODO_LIST.md:60 and docs/status/archived/2026-10-17_01-59_full-execution-and-live-smoke-status.md:16). Zero references in code, website config, package.json, or imports.
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod'` → **0 files**.
- `rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go'` → **0 files** (zero Go source, so no templ templates can even compile — templ code is Go).
- `rg -n "templ" /home/lars/projects/offline-banner/website --glob '!node_modules'` → **0 matches** (the Astro site never touches templ).

Conclusion: zero usage. The consumer's web surface is a static Astro + Starlight + Tailwind v4 site (`website/package.json`: `astro`, `starlight` deps, `build: astro build && node scripts/fix-csp.mjs`) deployed to Firebase Hosting; there is no Go-served page for templ-components to render.

## 4. Should offline-banner adopt it?

SHOULD-NOT — and the honest argument must resist the category trap the brief flags.

**The overlap with the website is a category mismatch, not adoption potential.** The nearest overlap is that both the library and the website produce "a docs-ish web surface styled with Tailwind v4." But the mechanisms are disjoint: Starlight *owns* the docs surface — MDX content, sidebar, search, theming are all Starlight's job, and the site already has a working CSP/tailwind/build pipeline. templ-components is a *component library for a Go HTTP handler*; its units (templ components, HTMX partial swaps, CSP-nonce threading through `BaseProps`) only exist inside a Go request/response loop. There is no such loop in offline-banner, and minting one solely to render docs that Starlight already renders would be regression plus a new runtime to supervise.

**What about a live banner-state web page — the one genuinely interesting hypothetical?** The QML engine already writes an atomic JSON state file and a JSONL ledger, and consumers poll it (`contrib/offline-banner-waybar`, evo-x2's DMS plugin). A "banner dashboard in the browser" is conceivable — but it would need a server process to read state and render templ components on each request. That is a brand-new systemd unit with a Go runtime, memory budget, and sandbox posture, replacing what a 30-line static page + `fetch()` of the JSON state file (or the existing waybar pattern) could do. Nothing in the project's shape asks for it.

**Fleet constraint.** Adopting templ-components into offline-banner means adding Go + templ + Tailwind toolchains to a Nix flake whose website is deliberately static and whose UI is deliberately QML — every library upgrade becomes pure bug-fix surface with zero payoff. The verdict is NOT-APPLICABLE without hesitation.

## 5. Fleet perspective

templ-components is a first-rate fit for the GOTH siblings (cqrs-htmx, go-appkit) and a zero fit here, and saying so plainly is what serves the owner: it keeps the component library's roadmap driven by apps that actually render it instead of polite fiction. The transferable doctrine is real but small — templ-components' discipline of *components that ship compliant HTML by construction* (CSP nonce threaded once, dark mode at the layout root) mirrors offline-banner's own discipline of contract-asserted artifacts (the rendered QML and shell scripts are validated by checks before they ship). Where a future offline-banner surface does become Go-served, templ-components is the correct palette — which is exactly what the flip trigger records, and no more.

## 6. If the flip trigger fires

1. **Live banner-state web UI on a tiny Go service.** Where: a new flake package (`packages.banner-web`) serving one templ page; render `layout.Base` + `display.Scrollback` (the terminal-style log component is a near-perfect fit for the JSONL outage ledger) + `feedback.Alert` for the current phase. Why first: the state file contract already exists, so the service is read-only.
2. **Use `utils/wire` + `htmx` for the refresh path.** HTMX polling of the state endpoint gives live phase/degraded-legs updates with zero client JS framework — consistent with the project's no-framework stance.
3. **Adopt `icons` only via the existing Tailwind pipeline.** If the static site ever needs icons, borrow the SVGs as files rather than importing the module — capability without a Go runtime.
4. **Keep Starlight for docs.** Even post-flip, the docs/marketing site stays Astro/Starlight; templ-components serves only the interactive dashboard surface.

## 7. Verify block

A fresh reviewer re-derives the verdict with:

```sh
# 1. Library identity (expect: charts/echarts/v1.27.0-104-gd5702fc1)
git -C /home/lars/projects/templ-components describe --tags

# 2. Module-family count (expect: 9)
find /home/lars/projects/templ-components -name go.mod -not -path '*/.git/*' | wc -l

# 3. Consumer references (expect: exactly 2, both prose LICENSE-convention mentions
#    in TODO_LIST.md and docs/status/archived/…; no code/config hits)
rg -n "templ-components" /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**'

# 4. No Go runtime in the consumer (expect: 0 and 0)
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob 'go.mod' | wc -l
rg --files /home/lars/projects/offline-banner --glob '!.git' --glob '!docs/review/**' --iglob '*.go' | wc -l
```

All four commands were executed by the reviewer on 2026-11-18 and produced exactly the stated results.
