# go-codec × offline-banner — Library Utilization Review

| Field | Value |
|---|---|
| **Library repo** | `/home/lars/projects/go-codec` (github.com/LarsArtmann/go-codec) |
| **Reviewed version** | `v0.3.3-7-g98bb1bc` — latest local tag (HEAD `98bb1bc`, 2026-11-15; remotes NOT fetched) |
| **Review date** | 2026-11-18 |
| **Reviewed by** | Fleet-run Group B (library-deep-dive runbook) |
| **Verdict** | NOT-APPLICABLE — offline-banner serializes JSON exclusively from QML (`JSON.stringify`) and asserts it with `jq`; no Go code exists to host a Go codec, and adding one would put a third language between the writer and its asserts |
| **Score** | 0/0 applicable capabilities leveraged (n/a — no applicable surface; structural) |
| **Flip trigger** | A Go component joins the stack and must read or write the state file / outage ledger (e.g. a Go exporter or agent consuming the JSON handoff) — then `JSONCodec` replaces hand-rolled parsing at that boundary |

## 1. What the library is

`go-codec` is the serialization contract for an event-sourcing/CQRS stack, per its README: "Encoding/decoding for event-sourced payloads. Provides the `Codec` interface used by stores, snapshots, and event construction." It offers four codec implementations — `CBORCodec` (canonical RFC 7049, deterministic, signing-safe, recommended), `JSONCodec` (standard `encoding/json`), `CBORCompactCodec` (stricter RFC 8949 Core Deterministic + unknown-field rejection as schema-drift detection), and `RawCodec` (passthrough) — behind one interface (`Encoding()/Encode/Decode`), plus `DeterministicCodec` as a compile-time guarantee for signing/content-addressing, `ObservableCodec` for metrics/hooks, `AutoDetect`/`AutoDetectDebug` for mixed-format streams, `TranscodeToJSON` as a cross-format bridge, `WrapEncode`/`UnwrapDecode` self-describing envelopes, `Size`/`SizeResult` diagnostics, streaming, and a COSE (RFC 9052) structure codec. Sibling modules (`storage/pebble`, `event`, `signing`, `encryption`, `kv`) consume the contract.

Single module, single package — no sub-packages. All 19 non-test source files live in the package root (`codec.go`, `cbor.go`, `cbor_compact.go`, `json.go`, `json_compat_v1.go`, `json_compat_v2.go`, `raw.go`, `envelope.go`, `transcode.go`, `streaming.go`, `cose.go`, `autodetect.go`, `observability.go`, `size.go`, `pool.go`, `normalize.go`, `errors.go`, `base64_json.go`, `doc.go`); verified `find -mindepth 2 -name '*.go'` → 0.

| Path | Purpose / role |
|---|---|
| `/` (module `github.com/larsartmann/go-codec`, package `codec`) | The entire library: `Codec` interface + 4 implementations, envelope/transcode/streaming/COSE/observability/size — one flat package |
| `testdata/`, `docs/`, `reports/`, `result/` | Golden/fuzz fixtures and documentation; no Go packages (verified: zero nested `.go` files outside the root package) |

## 2. Capability inventory

| Capability | What the library offers | Status in offline-banner | Reason |
|---|---|---|---|
| `Codec` interface + `CBORCodec` | Canonical CBOR (RFC 7049): deterministic bytes, sorted map keys, signing-safe | Not Applicable | No Go process serializes anything; the state file's bytes come from QML `JSON.stringify` (`module.nix:597`) |
| `JSONCodec` | Standard `encoding/json` interop, human-readable | Not Applicable | The consumer's JSON writer *is* QML's built-in `JSON.stringify`; a Go JSON codec would sit beside it, not replace it — there is no Go reader either |
| `CBORCompactCodec` | RFC 8949 Core Deterministic + unknown-field rejection (schema-drift guard) | Not Applicable | Schema drift is already guarded at CI time by `jq` shape asserts in the `probe-transitions` check (`flake.nix:944`) — the doctrine without the codec |
| `DeterministicCodec` signing guarantee | Compile-time rejection of non-deterministic codecs for signed/content-addressed payloads | Not Applicable | Nothing in offline-banner is signed or content-addressed; its determinism-adjacent discipline is the atomic `tmp` + `mv` rename so readers see complete files only (`module.nix:588-593`) |
| `BufferEncoder` zero-allocation path | `EncodeToBuffer` hot path with pooling (`pool.go`) | Not Applicable | No serialization hot path exists — writes happen on probe transitions, human-perceptible cadence |
| `ObservableCodec` | Metrics, hooks, monitoring wrapped around any codec | Not Applicable | Observability is the journal lines and ledger file themselves; there is no codec invocation to observe |
| `AutoDetect` / `AutoDetectDebug` | Best-effort encoding inference for mixed-format streams | Not Applicable | Every artifact has exactly one known writer (QML); no mixed formats circulate |
| `TranscodeToJSON` | Convert CBOR-stamped payloads to JSON bytes for REST/browser consumers | Not Applicable | The state file is already JSON end-to-end — no CBOR legacy to bridge |
| `WrapEncode`/`UnwrapDecode` envelopes | Self-describing payloads carrying their encoding stamp | Not Applicable | The state/ledger shapes are fixed contracts asserted by `jq`; an envelope layer would change the shape and break waybar consumers for no gain |
| `Size`/`SizeResult` diagnostics | Payload-size measurement | Not Applicable | State payloads are a few hundred bytes; size is not a managed concern |
| Streaming (`streaming.go`, JSON v2 dual-build) | Streaming encode/decode for large payloads | Not Applicable | All writes are single small documents via spawned `sh` (`printf … > tmp && mv`) |
| COSE (RFC 9052) structure codec | CBOR-based cryptographic message structures | Not Applicable | No signing/encryption exists in the consumer |
| Errors classification + contract/golden/fuzz tests | Behavioral families (go-error-family), golden snapshots, property tests | Not Applicable | The consumer's contract tests are `jq`-based shell asserts — no Go test surface to host these utilities |

## 3. Usage evidence in offline-banner

Exact commands and results (run 2026-11-18):

- `rg -ci "go-codec" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules'` → **0 matches** (rg exit 1)
- `rg -in "codec|cbor" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules'` → only `@jridgewell/sourcemap-codec` entries in `website/pnpm-lock.yaml` — an unrelated JS sourcemap transitive dependency, not this library
- `rg -n "JSON.stringify|JSON.parse" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules'` → **`module.nix:597`** (state file), **`module.nix:664`** (outage ledger JSONL), plus two Astro `ld+json` SEO snippets in `website/src/layouts/LandingLayout.astro` — i.e., all serialization is QML/JS-side
- `rg -ln "jq " /home/lars/projects/offline-banner` → `flake.nix`, `contrib/offline-banner-waybar`, docs — the consumer side of the JSON contracts
- `fd -e go . /home/lars/projects/offline-banner` → **0 files**; `find /home/lars/projects/offline-banner -name go.mod -not -path '*/.git/*'` → **0 files**

**Zero references, and no Go runtime exists to instantiate any codec.** The repo's serialization story is complete without Go: QML writes, waybar/`jq` read, `probe-transitions` asserts shapes in CI.

## 4. Should offline-banner adopt it?

SHOULD-NOT — and this is the subtlest of the four cases, because the *concept* go-codec sells (deterministic, schema-guarded serialization of small state payloads) is exactly what offline-banner already does well, in different materials:

- **State file**: written by QML `JSON.stringify` with a fixed key set (`active/demo/reason/failures/legs/phase/since/updatedAt`, `module.nix:597`), atomically renamed (`tmp` + `mv`), read by `contrib/offline-banner-waybar` and asserted by `probe-transitions` (`flake.nix:944`). A Go codec cannot participate: it would be neither the writer nor the assert engine.
- **Outage ledger**: JSONL appended by spawned `sh` from QML (`module.nix:664`), consumed as journal/history. Same story.
- **The fleet-applicable ideas are already implemented natively**: unknown-field rejection ≈ the `jq` shape asserts; determinism for readers ≈ the rename-atomicity discipline; one-codec-per-store documentation ≈ the "everything observable stays ADDITIVE" rule in `module.nix`.

Adopting go-codec would require adding a Go toolchain *and* rewiring either the writer (losing QML's direct access to engine state) or adding a Go reader (a third language between QML writes and `jq` asserts) — pure added surface: build inputs, go.sum, CVE tracking, zero new capability. Under the owner's fleet constraint, that is precisely the adoption to avoid. NOT-APPLICABLE.

## 5. Fleet perspective

This review demonstrates the fleet rule at its sharpest: go-codec is the *right* library for every Go store/snapshot/event module in the owner's stack, and the *wrong* dependency for a project whose serialization lives in QML + `jq` — and only an explicit report prevents a well-meaning "dogfood it somewhere" pass from blurring that line. The durable transfer is doctrine, and it already crossed: the consumer's additive-state + atomic-rename + CI shape-assert pattern is go-codec's determinism/schema-guard story implemented in Nix/QML/sh, evidence that the owner's libraries and projects are converging on the same principles without forced couplings.

## 6. If the flip trigger fires

1. **A Go agent/exporter consuming the state file or ledger** (e.g. exporting outages to a monitoring backend): adopt `JSONCodec` at that boundary first — typed decode with `encoding/json` semantics beats hand-rolled map walking, and unknown-field behavior documents itself.
2. **A Go writer joining the pair** (two processes writing state): adopt `CBORCodec` only if the format can change for *all* consumers (waybar must be migrated too — additive migration, hence last); otherwise keep JSON and use `WrapEncode` envelopes to stamp provenance if mixed writers ever matter.
3. **Schema-drift hardening**: if the `jq` asserts grow brittle, port the *pattern* (not the library): assert key shapes and reject unknown keys in CI, mirroring `CBORCompactCodec`'s drift guard.
4. **Signing/content-addressing of ledgers**: only if outage history ever needs cryptographic integrity, `DeterministicCodec`-backed CBOR becomes relevant — a distant hypothetical.

## 7. Verify block

```sh
git -C /home/lars/projects/go-codec describe --tags
# → v0.3.3-7-g98bb1bc
git -C /home/lars/projects/go-codec log -1 --format='%h %ad' --date=short
# → 98bb1bc 2026-11-15
find /home/lars/projects/go-codec -name go.mod -not -path '*/.git/*' | wc -l
# → 1
rg -ci "go-codec" /home/lars/projects/offline-banner --glob '!.git' --glob '!node_modules' || echo "0 matches"
# → 0 matches
rg -n "JSON.stringify" /home/lars/projects/offline-banner/module.nix
# → 597: … JSON.stringify({   /   664: … JSON.stringify({   (QML-side serialization, no Go)
```
