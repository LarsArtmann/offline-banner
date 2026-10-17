# Status: DNS-live verification + CI repair (domain go-live day)

**Generated:** 2026-10-17 ~10:00 CEST · **Session:** owner reported DNS applied, asked "did you link the website on/in the GitHub project meta data?" + continue-until-done · **HEAD at writing:** `8a14308` · **Skills loaded:** none new (carry-over website-launch go-live context; no SKILL.md matched this repair work)

## a) Fully done

1. **GitHub metadata confirmed linked** — `gh repo view` shows `homepageUrl: https://offline-banner.lars.software`, description, 5 topics (was set 2026-10-17; the link now points at a live site).
2. **Custom domain verified live end-to-end** — DNS resolves (CNAME → `offline-banner.web.app`, A 199.36.158.100), Firebase cert ACTIVE, `https://offline-banner.lars.software/` serves the full landing page, and HEAD checks on `/demo.mp4` (200, `video/mp4`, 981847 bytes), `/demo-poster-og.png` (200) and `/` (200) pass with immutable caching.
3. **21-commit push gap closed** — the auto-commit daemon commits but never pushes; everything from the launch session (website.yml, README, docs) was local-only. Pushed `78aa7fc..f3b5888`.
4. **Website CI repaired and PROVEN green** — first real run failed at 0 s: GitHub rejects the `secrets` context in `if` conditionals (the retrospective's step-level gate was never valid). Fixed with a job-level env flag (`HAS_DEPLOY_KEY`), actionlint-clean; run 39014246798 green in 52 s with the deploy job correctly skipping (no secret yet).
5. **`.hyperframes/` leak fixed** — gitignored + `git rm -r --cached` (5 files), commits 6a0e032/a6ed733.
6. **Three probe-transitions CI flakes deflaked (all harness races, product behavior correct)** — (1) exact counter asserts → `assert_journal_re` transition asserts (counter past a floor); (2) heartbeat compare on second-granularity `updatedAt` → state-file mtime at ns resolution (`date -r +%s%N`); (3) link-switch exact `3/2` → regex `≥3`. Final run 39015463434 **green (1m22s) on the emulated aarch64 runner**; `nix flake check --all-systems` green locally at every step.
7. **Docs truth** — CHANGELOG `[Unreleased]` (domain live, CI fixed, deflakes), TODO_LIST (DNS row done, CI row verified, new Dependabot row), 08-37 retrospective annotated inline (d1/b3 resolved, f6/f7 done, canonical-domain question resolved), AGENTS.md (DNS live row, new Git section: daemon-never-pushes + mid-edit commit races, CI-timing doctrine on the probe-transitions check description).

## b) Partially done

1. **CI deploy armament** — workflow green but the deploy job still needs `FIREBASE_SERVICE_ACCOUNT` to actually deploy; console-only (owner).
2. **Dependabot alerts** — 19 on master (13 high / 5 moderate / 1 low, mostly transitive/dev in website/pnpm-lock.yaml); Dependabot version PRs are flowing but unreviewed; CI `pnpm audit` is continue-on-error so nothing gates.

## c) Not started

1. Social preview upload (no API — repo Settings → Social preview).
2. Launch-post posting (owner-gated; drafts ready).
3. Mobile / docs-dark visual QA; a11y-guard + lighthouse CI jobs (unchanged from the 08-37 retro).

## d) Fucked up (own mistakes this session, both repaired in-session)

1. **Commit/squash mishap** — my first "deflake heartbeat" commit (b2dbb14) captured the daemon's docs changes while the flake edit itself was still unstaged, so the pushed commit's message described a change its diff did not contain. Repaired with a follow-up commit (39d51bf) whose message says exactly that; no force-push. Lesson is now in AGENTS.md's Git section: check `git log` immediately before committing while the daemon is active.
2. **Wrong-first-theory on flake #1's scope** — I initially judged exact counter asserts "deterministic at early positions"; CI proved flake #3 (`3/2` link) exactly there. The final doctrine (only counter positions anchored at a zeroed counter are exact) is now codified in the check comments and AGENTS.md.

## e) Improvements

1. The probe-transitions check now documents its own determinism rules (anchor-at-zero ⇒ exact; after a control switch ⇒ regex transition), making the next flake self-explanatory.
2. `website.yml` env-flag gating is the reusable pattern for "optional secret" jobs across the fleet (gogenfilter et al. likely carry the same `secrets`-in-`if` bug — unverified).

## f) Next items

1. Owner: add `FIREBASE_SERVICE_ACCOUNT` repo secret (arms CI deploys).
2. Owner: upload `assets/branding/social-preview.png` (Settings → Social preview).
3. Triage/merge Dependabot PRs for the 19 alerts (or `pnpm update` in `website/`).
4. Owner: post the Discourse + r/NixOS drafts (or green-light posting).
5. Check whether gogenfilter's website workflow carries the same `secrets`-in-`if` pattern; fix fleet-wide if so.
6. Re-run `astro check` + visual QA on docs pages in dark mode / mobile viewport.
7. Port a11y-guard + lighthouse jobs into website.yml.
8. After the SystemNix v3 switch: real-monitor render proof (rides that switch).
9. Consider `nix flake check --all-systems` as a required CI context check for the *Checks* workflow name (branch protection already requires it — verified by the "Bypassed rule" push notices).
10. Optional: 9:16 / voiceover video variants (demand-gated, per open question 3 of the 08-37 retro).

## g) Unanswerable questions for the owner

1. The 3 open questions from the 08-37 retro (posting timing, tier-2/3 video assets) remain unanswered — carry them forward? The canonical-domain question (1 of 3) is now moot: the domain is live.
2. Should CI deploys to Firebase be the source of truth going forward (arms with the secret), or do you prefer manual `firebase deploy` and the CI job as verification-only?
3. Dependabot: weekly cadence is configured for the action pins — do you want dependency-merge-on-green (auto) or review-each-PR?
