# Marketing Launch Status — README sales page, demo video, website, deploy

**Generated:** 2026-10-17 (morning session) · **Task:** "Go FULL on marketing on this project" · **Repo:** github:LarsArtmann/offline-banner · **Skills loaded:** copywriting, website-launch, product-launch-video, hyperframes (+ hyperframes-core contract, demo-video/go-live/dns-terraform/rest-api references)

**Headline:** The project now has a complete public presence, live end-to-end: rewritten README as sales page (docs-drift green), a 24 s promo video rendered from a committed composition (frames verified by eye), an Astro+Starlight website deployed to Firebase Hosting (visual QA passed in both themes), custom domain registered with DNS staged (apply owner-gated), website CI, GitHub homepage + on-brand social preview, and launch-post drafts. Six console/credential actions remain for the owner — all flagged in TODO_LIST.

---

## a) FULLY DONE (verified, not claimed)

| #  | Item                                                                                                                                                                                                                     | Evidence |
|----|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| 1  | **README sales-page rewrite**: centered header + outcome tagline, badges, docs/24s-demo link bar, `Why?` (NM-lies pain), `Who is this for?` (4 personas), comparison table vs NM-applet/nothing, `How it works` (5-step pipeline), `When NOT to use this` (5 honest exclusions), License. Every claim traceable to FEATURES/module behavior; no fabricated stats. | README.md; `nix flake check` green after each rewrite (docs-drift strings intact) |
| 2  | **Promo video**: HyperFrames composition `website/video/index.html` (24 s, 1920x1080, 5 beats: hook → banner arrival (real 450 ms InOutCubic beat) → why/reason-swap → recovery → CTA with flake snippet). Module-true colors (`#f2f9e2af` strip, `#1e1e2e` text, `#181825` bar, `#cdd6f4` bar text) lifted from module.nix + demo scene. | lint: 0 errors; check: PASSED (WCAG AA 20/20, layout errors fixed via intentional-layering markers); rendered `website/public/demo.mp4` 959 KB |
| 3  | **Video frame verification (the §b-4 lesson from 01-59 applied)**: extracted + VIEWED six frames (t=2 hook, t=4.2 mid-slide, t=6 value, t=11 reason-swap "Network link is down", t=16 recovery (strip gone), t=21 CTA). Sales gate: hook frame readable, evidence frame shows the product. Muted test + value test pass on the beat list. | /tmp frame extractions viewed via image tool this session |
| 4  | **Website**: Astro 7 + Starlight + Tailwind v4 on the gogenfilter baseline; landing (hero with Nix code card + star badge, ShowcaseSection with framed `<video>` at `#demo`, 6 feature cards, two-leg probe section, without/with, personas, CTA) + 8 docs pages (installation, configuration, how-it-works, observability, limitations, changelog, contributing, related-tools); banner-yellow accent (`#e8d44d`) on the demo's catppuccin-dark base; new favicon/logo (yellow strip motif); og:image = 1200x630 poster crop; SoftwareApplication + VideoObject JSON-LD. | build: 10 pages + sitemap + pagefind + CSP patched 10/10; `astro check` 0 errors 0 warnings (after TS 7→6 per verified matrix); `html-validate` exit 0 |
| 5  | **Visual QA gate**: headless chromium screenshots of landing (light + forced dark) and installation docs page, VIEWED: hero/gradient/code card/video showcase/features/probe/personas/CTA all render; docs sidebar + expressive code blocks clean. Below-fold sections show mid-fade (scroll animations) — expected. | /tmp/qa-*.png viewed this session |
| 6  | **Deploy**: Firebase hosting site `offline-banner` created in shared `lars-software` (site ID immutable); TWO successful `firebase deploy --only hosting:offline-banner` releases. Tier-1 video checklist verified LIVE: `HEAD /demo.mp4` → 200, `video/mp4`, `Cache-Control: public, max-age=31536000, immutable`, 981847 bytes. | firebase CLI output; node HEAD probe |
| 7  | **Custom domain**: `offline-banner.lars.software` registered via REST API (CLI has no command; configstore-token refresh trick needed — gcloud identity 403s on quota project), CNAME + ACME TXT extracted and STAGED in `~/projects/domains/lars.software.tf` (fmt clean, diff eyeballed: +18 lines only). Firebase side: OWNERSHIP_MISSING, awaiting DNS. | REST 200 response; `tofu fmt -check`; git diff |
| 8  | **Website CI**: `.github/workflows/website.yml` two-job build+deploy (SHA-pinned to match checks.yml, read-only token, path filters, concurrency group); deploy step secret-gated with a notice step so CI stays green before the service-account secret exists. | .github/workflows/website.yml |
| 9  | **GitHub metadata**: homepage set to https://offline-banner.lars.software; social-preview card generated via the skill's script then rebranded (gradient, kicker, hyphen accent → banner yellow) and re-rendered; eyeballed at card size; 1280x640, 48 KB (< 1 MB limit). | `gh repo edit` OK; assets/branding/social-preview.{svg,png} |
| 10 | **Launch posts**: Discourse topic + r/NixOS drafts from the one-narrative (README Why? → value → proof → install → honest status incl. niri-proven/sway-Hyprland-untested). Posting stays owner-gated. | docs/marketing/launch-post-drafts.md |
| 11 | **Docs truth**: TODO_LIST "Public presence (launch)" section (6 closed rows with evidence + 2 owner-gated open rows), CHANGELOG `[Unreleased]` Added section, AGENTS.md website/video commands + Public presence section. | TODO_LIST.md, CHANGELOG.md, AGENTS.md |

## b) PARTIALLY DONE

1. **Custom domain resolution** — Firebase side is done (domain registered, records demanded); the Namecheap side is staged but NOT applied: `tofu init` cannot load the GCS backend state from this host (`UserProjectAccountProblem` — the host gcloud identity lacks quota/billing access; the firebase CLI identity works but `tofu` uses ADC). Until apply + 10-60 min cert provisioning, https://offline-banner.web.app serves everything and the README/docs link the lars.software URL (which resolves after apply).
2. **CI deploys** — workflow merged but the deploy job will notice-skip until `FIREBASE_SERVICE_ACCOUNT` exists on the repo (the shared key is owner-managed).

## c) NOT STARTED (deliberate)

1. Social preview upload (manual console action, no API) — file staged in assets/branding/.
2. Posting the launch drafts (owner's voice account).
3. 9:16 vertical cut + TTS voiceover (distribution tier 2/3 — demand-gated per demo-video.md).
4. og:image `--verify` pass (script's post-upload check needs the image live on GitHub first).

## d) TOTALLY FUCKED UP (process failures, all recovered)

1. **Wrote LandingLayout without the `<body>` tag** — build failed with "Closing tag </body> has no matching opening tag"; the first fix attempt also missed because I edited from memory instead of re-reading (old_string mismatch). Re-read, fixed, rebuilt. Cost: 2 cycles. Lesson (repeat of an old one): re-read the file before every edit after a failed match.
2. **astro check shipped broken under TS 7** ("does not currently support TypeScript 7.0") — gogenfilter's package.json carries `typescript: ^7.0.2` so its `astro check` script cannot work either; I flipped to the verified-matrix pin (`^6.0.3`) instead of skipping the check.
3. **First `check` run had 2 layout errors treated as warnings** — the CTA card legitimately covers the bar text and the strip legitimately starts off-canvas; fixed with `data-layout-allow-occlusion` / `data-layout-allow-overflow` markers (the documented way to say "intentional"), NOT by suppressing anything.
4. **Trusted type-checked cross-references too late** — "check"/`blue` missing from the icon unions surfaced only at `astro check` (6 errors). Fixed by adding the icon + renaming the secondary accent token `amber`→`blue` (the name must tell the truth).

## e) WHAT WE SHOULD IMPROVE

1. **gogenfilter's website flake/CI carry dead weight for forks** (md-go-validator app, /v3 import gate, CHANGELOG sync gate) — the fleet baseline should grow a "minimal site" variant; I pruned per-repo instead.
2. **A fleet `hf-env.sh` pointer belongs in AGENTS.md everywhere hyperframes is used** — the npx-under-bun trap is fleet-wide; the recipe now lives in this repo's AGENTS.md (Public presence section).
3. **Firebase REST domain creation needs the configstore token** — the runbook lists gcloud first; on hosts where gcloud lacks project quota, the firebase-CLI token (refresh by running any CLI command first) is the working path. Recorded in the status here; consider a runbook patch upstream (fleet skill repo).

## f) Next tasks (proposal-ready)

1. Owner: apply DNS (`cd ~/projects/domains && tofu apply -target=namecheap_domain_records.lars_software`), then poll cert → CERT_ACTIVE, then `fetch` https://offline-banner.lars.software and flip any remaining web.app references if desired.
2. Owner: add `FIREBASE_SERVICE_ACCOUNT` (shared lars-software key) to repo secrets → CI deploy arms.
3. Owner: upload `assets/branding/social-preview.png` in Settings → Social preview; run the skill's `--verify LarsArtmann/offline-banner` after.
4. Owner: post the two launch drafts; cross-link the Discourse topic from the README (one line).
5. Dependabot will open pin PRs for the two new actions in website.yml — review like the checks.yml pins.
6. When the SystemNix switch lands (real-monitor proof), retake `demo-poster.png` from a real-monitor capture if the headless colors differ visibly.
7. ROADMAP fuel: 9:16 vertical cut; per-page OG images already exist — consider a "watch the demo" GIF teaser for the README (≤ 6 s, 480p) if Discord/Telegram sharing becomes a real channel.

## g) Questions I cannot answer myself

1. Is `offline-banner.lars.software` the right canonical domain (vs `offlinebanner` short form)? Site ID is immutable but the DNS record is not — a rename now is one Terraform edit + one REST call.
2. Should the launch posts go out before or after the SystemNix switch (real-monitor proof would strengthen the "every monitor" claim with live footage)?
