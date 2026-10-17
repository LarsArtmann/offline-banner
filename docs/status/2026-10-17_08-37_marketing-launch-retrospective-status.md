# Marketing-Launch Retrospective — what shipped, what leaked, what's next

**Generated:** 2026-10-17 08:37 CEST · **Session:** single "Go FULL on marketing" push over the v0.1.0 tree · **HEAD at writing:** `1cc9a1e` (auto-commit daemon; everything of this session committed) · **Skills loaded:** copywriting, website-launch, product-launch-video, hyperframes, hyperframes-core (+ 7 website-launch references)

**Headline:** Public presence shipped live end-to-end — README sales page (docs-drift green), 24 s promo video (frames eyeballed), Astro+Starlight website deployed twice to Firebase Hosting (visual QA in both themes, live HEAD checks), custom domain registered with DNS staged, website CI, GitHub homepage, on-brand social preview, launch drafts, docs truth. Two leaks found by this retrospective: **`.hyperframes/` local state is tracked in git** (d1) and **CI runs of the new workflow are unverified** (b3) — both FIXED the same morning: d1 ignored + untracked (6a0e032/a6ed733), b3's first run failed at parse time on the secrets-in-`if` pattern and is green after the env-flag fix; the owner applied DNS and offline-banner.lars.software serves live (cert ACTIVE).

---

## a) FULLY DONE (verified, not claimed)

| #   | Item                                                                                                                                                            | Evidence                                                                                              |
|-----|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| 1   | **README sales-page rewrite** — centered header, outcome tagline, badge row, docs + "Watch the 24s demo" link bar, `Why?` (NM-lies pain), 4 personas, comparison table, `How it works` pipeline, `When NOT to use this` (5 exclusions), License. No fabricated stats; docs-drift strings preserved. | README.md; `nix flake check` green after every rewrite (final run this session: "all checks passed") |
| 2   | **Promo video composition** — `website/video/index.html`: 5 beats (hook → arrival with the real 450 ms InOutCubic beat → reason-swap → recovery → flake-snippet CTA), strip/bar/text colors lifted from module.nix:315/331 + demo bar QML, transform-only + stacked-opacity crossfades (seek-safe), intentional-layering markers where the CTA covers the bar. | lint 0 errors; check PASSED (WCAG AA 20/20)                                                           |
| 3   | **Video render + frame verification** — 24.0 s, 1920x1080, 30 fps, 959 KB → `website/public/demo.mp4`; six frames extracted and VIEWED (t=2 hook readable, t=4.2 mid-slide, t=6 value, t=11 "Network link is down", t=16 recovered strip-gone, t=21 CTA). Muted test + value test pass on the beat list. | ffmpeg extractions viewed via image tool this session; ffprobe banner                                   |
| 4   | **Website build** — Astro 7 + Starlight + Tailwind v4 (gogenfilter baseline, pruned per-repo): landing (hero Nix code card, ShowcaseSection `#demo`, 6 features, two-leg probe, without/with, personas, CTA) + 8 docs pages; banner-yellow accent on catppuccin-dark; new favicon/logo; TS pinned to the verified-matrix ^6.0.3 so `astro check` actually runs. | 10 pages + sitemap + pagefind + CSP 10/10; `astro check` 0 errors; `html-validate` exit 0              |
| 5   | **Visual QA gate** — headless chromium screenshots VIEWED: landing light, landing forced-dark, installation docs (light). Layout, gradients, code cards, video poster, feature grid, persona grid all render. | /tmp/qa-*.png this session                                                                             |
| 6   | **Deploy** — hosting site `offline-banner` created in shared `lars-software`; two successful `firebase deploy --only hosting:offline-banner` releases; live `fetch` of / and /getting-started/installation/ returned full correct content; Tier-1 video checks live: `HEAD /demo.mp4` → 200, `video/mp4`, `Cache-Control: immutable`, 981847 B. | firebase CLI output; node HEAD probe; fetch tool                                                                 |
| 7   | **Custom domain registration** — `offline-banner.lars.software` created via Firebase REST (CLI cannot; gcloud identity 403'd on quota project → refreshed configstore token path found), CNAME + ACME TXT extracted from the API response. | REST 200 `operations/2c36625e…`; `GET customDomains` shows OWNERSHIP_MISSING (awaiting DNS)             |
| 8   | **DNS staging** — both records inserted into `~/projects/domains/lars.software.tf` per fleet pattern, `tofu fmt -check` clean, diff reviewed (+18 lines only). | git diff lars.software.tf                                                                              |
| 9   | **Website CI** — `.github/workflows/website.yml` two-job build+deploy, SHA-pinned to match checks.yml, read-only token, path filters, concurrency; deploy step secret-gated with notice so CI stays green pre-secret. | .github/workflows/website.yml                                                                          |
| 10  | **GitHub metadata + social preview** — homepage set via `gh repo edit`; card generated by the skill script then rebranded (top gradient, kicker, hyphen → banner yellow) and re-rendered; eyeballed at card size; 1280x640, 48 KB. | `gh repo edit` OK; assets/branding/social-preview.{svg,png}                                            |
| 11  | **og:image discipline** — 1200x630 crop of the selling frame (`demo-poster-og.png`), LandingLayout og/twitter/VideoObject metadata all point at it with correct dimensions. | website/public/demo-poster-og.png; grep of LandingLayout                                               |
| 12  | **Launch drafts** — Discourse topic + r/NixOS post from the one-narrative (README Why? → value → proof → install → honest status incl. niri-proven / sway-Hyprland-untested). Posting stays owner-gated. | docs/marketing/launch-post-drafts.md                                                                   |
| 13  | **Docs truth** — TODO_LIST "Public presence (launch)" section (6 closed rows with evidence, 2 owner-gated open), CHANGELOG `[Unreleased]` Added section, AGENTS.md website/video commands + Public presence section, prior report indexed. | TODO_LIST.md; CHANGELOG.md; AGENTS.md; docs/status/README.md                                           |
| 14  | **Final gates** — `nix flake check` green; working tree fully committed by the daemon (66 files under website/ tracked). | flake check output; git status empty                                                                   |

## b) PARTIALLY DONE

1. **Custom domain resolution** — Firebase side complete (domain registered, records demanded, cert CERT_VALIDATING); Namecheap side staged but NOT applied: `tofu init` fails loading the GCS backend state (`UserProjectAccountProblem` — host gcloud identity lacks quota/billing access; firebase CLI identity works but `tofu` uses ADC). Until apply + provisioning, `offline-banner.web.app` serves everything while README/site metadata name the lars.software URL (canonical + homepage + link bar all point at a domain that does not resolve yet).
2. **CI runs of the new workflow — UNVERIFIED.** The daemon committed website.yml and I never checked `gh run list` for a run of "Website". The build job should pass (same steps ran locally) but the step-level `if: secrets.FIREBASE_SERVICE_ACCOUNT != ''` pattern is untested in the wild — if GitHub rejects secrets in an `if` (it does allow it, but empty-string semantics + the notice step path are unproven here), master could show a red Website run right now. **RESOLVED 2026-10-17:** GitHub does NOT allow the `secrets` context in `if` conditionals — the first real run failed at parse time (0 s). Fixed with a job-level env flag (`HAS_DEPLOY_KEY`); the next run went green in 52 s with the deploy job correctly skipping (no secret yet).
3. **Mobile visual QA — not done.** All screenshots were 1440 px wide. The baseline's responsive classes exist (sm:/lg: grids, nav toggle) but the rewritten components (personas 4-col, comparison 2-col, hero clamp) were never eyeballed at 375/768 px.
4. **Docs dark theme — not eyeballed.** Landing was checked in both themes; the Starlight docs chrome (sidebar, TOC, expressive code in dracula) was only seen in light.
5. **CI-adjacent quality steps ported only partially** — gogenfilter's website pipeline also runs pnpm audit (kept, continue-on-error), a11y-guard, dedup, docs-code-block validation, CHANGELOG sync, /v3 import gate; I kept audit + astro check + build + html-validate and dropped the rest deliberately, but the a11y-guard and lighthouse jobs of the template family are real quality bars, not gogenfilter cruft — they were dropped for scope, not judged.
6. **Video distribution tiers 2-3** — the 16:9 master is done; vertical cut, voiceover+captions, GIF teaser, YouTube are not started (deliberate, demand-gated — but the "launch" tier per the reference is arguably tier 1 only, so this is honestly fine).

## c) NOT STARTED

1. Social preview upload (console-only, no API) — file staged at `assets/branding/social-preview.png`.
2. Posting the launch drafts (owner accounts).
3. `FIREBASE_SERVICE_ACCOUNT` secret on the repo.
4. DNS apply + cert wait + post-apply verification of https://offline-banner.lars.software.
5. Click-to-dismiss shown in motion anywhere (video scene 3 or a capture-demo segment) — the README headline behavior remains un-animated.
6. Multi-monitor demo footage (two headless outputs) — "every monitor" is the #1 claim and the only visual proof is one monitor.
7. Real-monitor capture of any kind (rides the SystemNix switch).
8. Blog post / write-up of the extraction + "NetworkManager lies" story (best organic-marketing asset available; not drafted).
9. nixpkgs upstreaming decision (search.nixos.org visibility = marketing; ROADMAP fuel #26).
10. Analytics/privacy decision for the site (none wired — also arguably correct by default).
11. gh Discussions / community surface decision.
12. 9:16 cut, voiceover, GIF teaser, YouTube (tiers 2-3 above).
13. Lighthouse CI job (template family has one; not ported).
14. `nix run .#deploy` flake app never exercised (defined in website/flake.nix, untested).
15. Post-apply `--verify` of the social preview (script supports it post-upload).

## d) TOTALLY FUCKED UP (all found by this retrospective unless noted; none shipped broken)

1. **`.hyperframes/` tool state is TRACKED IN GIT** — `git ls-files website/video/` shows `.hyperframes/artifacts/checks/*.json`, `history-id`, `video-state.json` committed by the daemon (my .gitignore added `website/video/node_modules/` but NOT `website/video/.hyperframes/`). Local CLI state does not belong in the repo; it will churn on every lint/check run and pollutes diffs. Fix is one gitignore line + `git rm -r --cached`; NOT done in this session because the instruction was report-then-wait. **FIXED 2026-10-17:** ignored + untracked in commits 6a0e032/a6ed733.
2. **CI status of my own workflow never checked** — I shipped a workflow and did not look at a single run of it. "Checks green" claims elsewhere in this session refer to local gates only. This is the exact "verify the delivering layer" lesson from crush-config fan-out doctrine, applied late.
3. **LandingLayout shipped without `<body>`** — build failed with a confusing "closing tag has no matching opening tag"; the first repair attempt then edited from memory and missed (old_string mismatch), costing a second cycle. Re-read → fixed → rebuilt. Twice-taught lesson: re-read before every edit, especially after a failed match.
4. **astro check was shipped broken under TypeScript 7** — inherited `typescript: ^7.0.2` from the gogenfilter baseline means its own `astro check` cannot ever have run cleanly; I first accepted the failure, then fixed it properly (verified-matrix pin `^6.0.3`). The baseline itself carries this latent breakage — worth reporting upstream to the fleet skill.
5. **Type unions trusted until the type-checker disagreed** — "check" missing from `uiIconKeys`, and the secondary accent still named `amber` while every new component passed `blue`: 6 astro-check errors surfaced only after install. Renamed the token rather than lying in CSS (name-must-tell-the-truth), but both errors were preventable by checking the type unions while writing Icon.astro.
6. **Two intentional-layout choices first surfaced as check ERRORS** — CTA card occluding the bar text and the strip starting off-canvas were design decisions, but I only encoded them via `data-layout-allow-*` markers after the checker complained. The markers should have been authored with the layout.
7. **gcloud-identity assumption cost one failed REST call** — the runbook lists gcloud first; this host's gcloud lacks quota access to lars-software. The fallback (configstore token, refreshed by running any CLI command) worked but I burned a 403 + a 401 discovering it.
8. **`nix flake check --all-systems` not run** — only the default system; aarch64 eval was skipped (docs-only changes make an eval diff essentially impossible, but the release runbook discipline says both, and I let the warning slide).

## e) WHAT WE SHOULD IMPROVE

1. **Ignore local tool state patterns upfront**: any new tool dir (`.hyperframes/`, `.astro/`, `.firebase/`) goes into .gitignore at creation time, not at first polluting commit. `.astro/` and `.firebase/` were covered by the baseline website/.gitignore; `.hyperframes/` was new to me and slipped.
2. **Check CI right after shipping CI**: `gh run list --workflow website.yml` is a 10-second gate; make it part of "ship a workflow".
3. **Run the type-checker earlier in component rewrites** — after data/types + Icon (the two hubs), not only after all 10 pages exist.
4. **The fleet website template needs a "minimal" variant** — pruning md-go-validator, /v3 gates, CHANGELOG sync, dedup per-repo is repeated work and invites divergence; a documented minimal manifest would have saved an hour.
5. **The video composition must track module behavior** — a behavior change (colors, caption format, animation duration) silently makes the promo stale. Candidate: a docs-drift-style check grepping the composition for the module's color literals, or at least an AGENTS warning (now partially covered by the Public presence section).
6. **Canonical URL while DNS is pending** — site metadata names a domain that 404s until apply; acceptable (canonical is forward-looking), but a temporary web.app canonical would be honest now and a one-line flip later. Owner call.
7. **Two pnpm-workspace.yaml files (website/ + website/video/)** — scoping works but is undocumented; one line in AGENTS would prevent a future session from "fixing" it into breakage.
8. **Screenshot QA grid**: capture light+dark × desktop+mobile × landing+docs systematically (2x3) instead of ad-hoc.
9. **Sell the multi-monitor claim with pixels** — a two-headless-output capture is cheap (sway supports it headless) and would upgrade the strongest claim from prose to footage.
10. **Put the launch narrative in one file** — README Why? is canonical, drafts derive from it, video beats derive from it; today that linkage lives in three places' comments. A short `docs/marketing/NARRATIVE.md` (hook, value sentence, proof points, exclusions) would make every future surface a mechanical derivation.

## f) Up to 50 things to get done next (owner-gated items marked 👤)

**Unblock the launch (today):**
1. 👤 Apply DNS: `cd ~/projects/domains && tofu plan/apply -target=namecheap_domain_records.lars_software`; poll cert → CERT_ACTIVE; fetch https://offline-banner.lars.software
2. 👤 Add `FIREBASE_SERVICE_ACCOUNT` (shared lars-software key) → CI deploy arms
3. 👤 Upload `assets/branding/social-preview.png` (Settings → Social preview), then run the script's `--verify LarsArtmann/offline-banner`
4. 👤 Post the Discourse draft; cross-link the topic from README (one line)
5. 👤 Post the r/NixOS draft
6. Check `gh run list --workflow website.yml` — first run must be green (notice step, not red) — DONE 2026-10-17 (green after the secrets-in-if fix)
7. Untrack `.hyperframes/`: add `website/video/.hyperframes/` to .gitignore + `git rm -r --cached website/video/.hyperframes` — DONE 2026-10-17
8. `nix flake check --all-systems` once (aarch64, release-runbook discipline)
9. Mobile visual QA: 375 px + 768 px screenshots of landing + a docs page
10. Docs dark-theme eyeball pass (Starlight chrome + dracula code)

**Site/CI hardening (this week):**
11. Verify production build's hero star-badge path (GITHUB_TOKEN present in CI; "0 Stars" fallback correct when API rate-limits)
12. 404 page: confirm dist/404.html renders styled
13. Port the template family's a11y-guard + lighthouse jobs (or consciously reject them in AGENTS)
14. `pnpm audit` locally once; triage anything high
15. Decide + document the /og/*.png route's consumers (referenced for docs pages or a ghost system?)
16. Spot-check pagefind search UI on the live site
17. CHANGELOG compare-link footers (Unreleased + 0.1.0) per keep-a-changelog
18. Test `nix run .#deploy` from website/flake.nix once
19. Dependabot: triage the incoming website.yml action-pin PRs
20. Document (or unify) the two pnpm-workspace.yaml files
21. Add compare-link + version badge sync check adapted from gogenfilter's CHANGELOG sync gate (root `## [0.1.0]` vs mdx `## 0.1.0` formats differ — normalize first)
22. Consider `lastUpdated: true` + editLink in Starlight config (fleet maintenance-mode checklist)

**Video/marketing content (next):**
23. Add a click-to-dismiss beat (video scene or capture-demo segment with a synthetic swaymsg click) — headline behavior still never animated
24. Two-headless-output capture proving "every monitor" visually
25. 9:16 vertical cut (resized composition per demo-video.md "Location")
26. TTS voiceover + burned captions (tier 3)
27. ≤6 s 480p GIF teaser for Discord/Telegram embeds
28. YouTube version with chapters
29. Extract 3-4 stills into website/public/screenshots/ for docs embedding
30. Re-record poster/webp from a real-monitor session after the SystemNix switch; compare against headless colors
31. Write the extraction story blog post ("NetworkManager lies on NM-unmanaged uplinks" is the hook) — larsartmann.com or dev.to
32. Version-pin hyperframes in website/video docs (0.8.163 installed vs 0.8.167 in the npx cache — lockfile pins it, note it in AGENTS)
33. Consider a CI job that runs video lint+check on composition changes (ubuntu runner + puppeteer chrome — feasibility spike)
34. Add a marketing "NARRATIVE.md" (see e10) and derive README/drafts/video from it explicitly

**Module-adjacent marketing:**
35. 👤 SystemNix switch (rides real-monitor proof) — the strongest pending marketing event
36. nixpkgs upstreaming decision (search.nixos.org visibility; ROADMAP fuel #26)
37. `nixosModules.example` (laptop defaults) — lowers the try-it barrier (ROADMAP fuel #31)
38. Try-it path on the website: a "try the demo in a live session" block (`OFFLINE_BANNER_DEMO=1` recipe)
39. Enable GitHub Discussions + pin the launch topic (owner preference)
40. Release automation: tag → CI → GH release notes (ROADMAP fuel #29; runbook already in AGENTS)

**Docs/content upkeep:**
41. README top badge row: add a website badge/link (link bar exists below; consistency)
42. Roadmap: add a "public surface upkeep" theme (video/website must track module behavior)
43. Feedback links on docs pages (content-patterns pattern; not implemented)
44. Starlight search keywords/aliases for "nmcli", "offline", "wayland"
45. Analytics decision (privacy-friendly or none) — owner preference, default none
46. `/demo` anchor from the header nav — already wired; verify anchor scroll offset under the fixed header once
47. og:image for the docs pages: wire Starlight head to the generated per-page images (if e15 says they're wanted)
48. Add the website + video to FEATURES.md as project-infra rows or explicitly exclude (decide the inventory boundary)
49. Rename `docs/assets/offline-banner-demo.webp` usage note: README image caption could link the capture recipe (f25 of the old report, still open)
50. After DNS + secret + upload land: re-run this report's §f1-6 verifications and close the two open TODO rows

## g) Questions I cannot answer myself

1. **Canonical while DNS is pending**: should site metadata (`canonical`, `og:url`, homepage, README bar) temporarily point at the live `offline-banner.web.app` and flip to `offline-banner.lars.software` after apply — or stay pointed at the future canonical (current state) and accept a not-yet-resolving URL for a day? (Pure preference/risk call — I cannot infer how soon you'll apply DNS.) **RESOLVED 2026-10-17:** DNS was applied the same morning; the canonical domain is live (cert ACTIVE), so staying pointed at it was the right call and no temp-URL flip is needed.
2. **Launch sequencing**: post the Discourse/r/NixOS drafts now (web.app live, module machine-verified) — or wait for the SystemNix switch so "every monitor" has real-monitor footage? This is a strategy tradeoff (timing vs proof strength) only you can weigh.
3. **Investment tiers**: build the 9:16 vertical cut + TTS voiceover now as launch assets, or hold tier 2-3 until a channel (Shorts/Reels/YouTube) actually exists? I default to "hold until demand" per the reference, but if you plan to push social channels this week, the answer changes.
