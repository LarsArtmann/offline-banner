# Status: README demo capture (real QML, headless) — 2026-10-17 01:29 CEST

Task: "The readme needs a PNG or even a gif/animated webp of how this looks like."
Tracked as TODO_LIST.md:37 ("Demo GIF for README"). Session: single task, this report closes it.

## Approach (decided this session, rationale kept)

Capture the **real module QML** rendering in a headless sway compositor instead of
recreating the banner in HTML/CSS (HyperFrames) — authenticity: every pixel of the
banner comes from the ground-truth store file, so the asset can never drift from
module.nix. A `/tmp` HyperFrames project was explicitly rejected as both heavier and
less honest.

Novel trick that makes the demo honest: the banner quickshell runs inside a
`unshare -rm` mount namespace with a tmpfs over `/sys/class/net` whose `eth0/carrier`
file is scripted `1 → 0 → 1`. The **real probe script** in the QML reads that fake
carrier, so the demo shows the module's own behavior: link drops → "Network link is
down" banner pushes the bar down (InOutCubic 450 ms) → live "last online Xs ago"
caption ticks → link returns → banner slides back up. Nothing about the banner is
mocked; only the carrier bit is.

## a) Fully done

1. **Prerequisite verification** — `9.9.9.9` reachable (real ok-leg), `203.0.113.1`
   unroutable (fallback force-show), `unshare -rm` + sysfs submount over
   `/sys/class/net` works on this host (carrier read back `1`).
2. **Ground-truth QML extraction pipeline** — `nix eval` of the evaluated module's
   `serviceConfig.ExecStart` → realize the `writeTextDir` store path (never hand-copy
   the Nix indented string; `\"` escaping + `${cfg.layerNamespace}` interpolation make
   hand-copies wrong). Verified: 191-line de-indented QML with interpolation applied.
   Live in scripts/capture-demo.sh:38-69.
3. **Headless render risk retired** — quickshell (0.3.2) + `QT_QUICK_BACKEND=software`
   + `WLR_BACKENDS=headless WLR_RENDERER=pixman sway` renders; bar + foot + sockets +
   `wf-recorder` + `grim` + ffmpeg all mechanically work end to end.
4. **Demo scene files** — scripts/demo/bar/shell.qml (desktop bar with exclusive zone,
   the thing the banner pushes down; clock replaced by static "12:47" after a
   `formatDateTime` API warning), scripts/demo/sway.conf (1920x1080, `#1e1e2e` bg,
   `hide_cursor 800`).
5. **scripts/capture-demo.sh** — full reusable recipe: QML extraction, socket
   discovery via `$XDG_RUNTIME_DIR` diff, scene launch, recorder, in-namespace banner
   run with scripted carrier timeline, poster grab, webp encode; trap cleanup.
   Run-1 root cause (banner never launched — see d1) is fixed and log-verified:
   run-2 banner.log shows `Launching config: /tmp/offline-banner-demo/shell.qml` +
   `Configuration Loaded`.
6. **Run-1 wrongness diagnosed honestly** — viewed the captured poster, saw NO banner,
   traced it to d1 below instead of shipping.

## b) Partially done

1. **The capture itself** — pipeline runs, banner QML confirmed loading in the
   namespace, but run 2 HUNG before producing any artifact: docs/assets/ files all
   still carry run-1 mtimes (00:10:03 webp / 00:11:13 png / 00:11:18 raw.mp4), i.e.
   run 2 wrote nothing. Background shell `00F` still reports running at 01:29.
2. **Final assets** — docs/assets/offline-banner-demo.{webp,png} exist but are
   **run-1 garbage (bannerless desktop)** and must be replaced or deleted; they must
   not be committed as-is.
3. **Verification loop** — only the run-1 poster was ever viewed; no frame-by-frame
   check of any video ever happened (that gap is exactly how run 1's bannerless
   capture almost sailed through).

## c) Not started

1. README embed (hero image, placement/alt text).
2. TODO_LIST.md:37 check-off + evidence.
3. CHANGELOG entry.
4. `nix fmt` + `nix flake check` after the new files (repo checks may ignore .sh/.qml
   — unverified).
5. AGENTS.md update (a demo recipe now exists; the "rendering needs a live compositor"
   doctrine deserves a pointer to the headless recipe).
6. GIF-vs-WebP format decision and any size/quality tuning.
7. Anything click-to-dismiss-shaped in the demo.

## d) Totally fucked up

1. **Forgot to launch the banner inside the namespace (run 1).** The `unshare -rm`
   script animated only the carrier file — `quickshell -p` was never exec'd — and the
   pipeline "succeeded": 10 s of desktop with no banner, encoded to a 13 K webp and a
   bannerless poster, dropped into docs/assets/. The bug was caught only because I
   viewed the poster after the encode; a frame-check inside the pipeline would have
   caught it before ffmpeg ever ran.
2. **No machine assertion that the banner appeared.** The script has zero failure
   signal for "recorded 10 s of nothing" — banner.log silence (run 1: the file was
   empty because no quickshell ever started) was the only tell, and nothing read it.
3. **Hung run 2 with live strays (current state).** Run 2's banner ran and was killed
   on schedule, but the script never produced artifacts and left: sway (4024977),
   swaybg, bar quickshell (4040652), foot (4040653), wf-recorder (4041977). Leading
   hypothesis (unverified): the scene is damage-static, wf-recorder never receives a
   frame / ignores the stop signal, and the script blocks in `wait` — run 1 got frames
   only because the terminal content differed. Needs post-mortem before any re-run.
4. **Unverified API guess in shipped scene code** — `SystemClock` + `Qt.formatDateTime`
   threw `Invalid argument passed to formatDateTime()` (bar.log); replaced with static
   text instead of looking the API up. Lazy, but contained to scene dressing.
5. **User foot config leaked into the demo** — foot read `~/.config/foot/foot.ini`
   (incompatible `[colors]` section) and printed the error line into the captured
   terminal; fixed with `-c /dev/null` in run 2 but it polluted run 1's poster.

## e) What to improve (distilled)

1. **Verify inside the pipeline, not after it**: extract 2-3 frames + check
   banner.log for `Configuration Loaded` BEFORE ffmpeg; fail loudly otherwise.
2. **Assert the visual, not the log**: e.g. pixel-compare the top strip pre/post
   appearance, or require `swaymsg -t get_layers` (namespace `offline-banner`) to
   list the surface during the hold window.
3. **Stage artifacts in `$work`, move into docs/assets/ only after verification** —
   wrong bytes never touch the repo.
4. **Damage-starvation recorder**: force frame flow (1px cursor wiggle via
   `swaymsg seat seat cursor move`, or `wf-recorder -d`/`--flush`-style options, or
   verify wf-recorder's damage behavior on headless first) and add a hard timeout
   around recorder stop + `wait`.
5. **Replace blind `sleep` choreography with state polling** (layer appears /
   disappears) so the timeline can't silently desync.
6. Component pre-flight: smoke each scene piece (bar QML, foot args) against a
   2-second headless sway before the full run.
7. Kill-by-pidgroup hygiene: run scene under `setsid` so strays die with the script.

## f) Next tasks (full list; top ~10 will be proposed for TODO_LIST if asked)

1. Post-mortem the hung run 2 (shell 00F): find where it blocked (`wait`/recorder),
   fix, and delete the wrong run-1 artifacts from docs/assets/.
2. Identify the three store-path quickshell processes (10924, 11113, 11139) BEFORE
   touching them — they may be the live SystemNix desktop's own offline-banner/DMS
   instances (deployed gen 904), not this session's strays. Kill only confirmed own
   strays: sway 4024977, swaybg, bar 4040652, foot 4040653, wf-recorder 4041977.
3. Add the banner-appeared assertion (log + `swaymsg` layers + frame diff) to
   capture-demo.sh.
4. Stage-then-move artifact flow in capture-demo.sh.
5. Re-run capture; view frames at key timestamps (pre/during/post banner) before
   encoding.
6. Encode: tune fps (25 → maybe 30), quality (`-q:v`), scale (1600 native vs 1280);
   target ≤ 2 MB webp.
7. Verify loop seam (first frame ≈ last frame) and trim head/tail.
8. Poster: re-capture from the verified run (current PNG is bannerless) — pick a hold
   frame with an informative caption ("last online 4s ago").
9. Decide WebP vs GIF for the README embed (WebP primary assumed; GIF fallback only
   if compatibility concern) — commit exactly the embedded file(s).
10. Embed in README (after the intro block, `<p align="center">`, alt text describing
    push-down + recovery), link the capture recipe.
11. Check off TODO_LIST.md:37 with evidence (asset paths + script).
12. CHANGELOG entry for the demo assets + recipe.
13. AGENTS.md: document the headless capture recipe under Commands/Checks; soften
    "rendering needs a live compositor" to point at the recipe (module-contract still
    does not test rendering — that stays true).
14. Run `nix fmt` + `nix flake check`; confirm treefmt ignores .sh/.qml (or extend
    config deliberately if wanted).
15. shellcheck capture-demo.sh (if available; else eyeball).
16. Test script re-run idempotency (cached shell.qml path) and the EXIT trap under
    `set -u` with unset pids.
17. Wrap scene launch in `setsid`/process-group kill for stray-proof cleanup.
18. Poll `swaymsg -t get_layers` for `offline-banner` namespace instead of sleep-sync.
19. Force compositor damage (cursor wiggle) so wf-recorder always receives frames;
    add `timeout` around recorder stop.
20. Consider recording the click-to-dismiss path as a second short segment (needs a
    synthetic click: `swaymsg seat seat cursor ...` press/release) — README headline
    behavior currently not shown in motion.
21. Consider a two-monitor variant (second headless output) to visually back the
    "every monitor" claim.
22. Consider 2x scale (3840x2160 output downscaled) for crisper banner text in the
    final asset.
23. Verify webp colors survive yuv420p (yellow strip vs grim PNG ground truth); if
    shifted, record lossless/rgb intermediate.
24. Sanity-check the caption math on screen ("last online Ns ago" ticking) once
    frames are viewable.
25. README "Runtime tuning & demos" section: link to scripts/capture-demo.sh as the
    supported demo path (alongside the drop-in override trick).
26. Optionally add `nix run .#capture-demo` flake app wrapping the tool deps
    (sway/quickshell/foot/wf-recorder/grim/ffmpeg) hermetically.
27. Decide the bar's static "12:47" (keep / drop right-side text / fix SystemClock
    usage properly by reading quickshell 0.3.2 docs).
28. Check docs/assets naming/alt-text conventions; consider a posters/fallback png
    usage in README for clients without animated webp.
29. Add a short "how this was captured" note near the README image (one line —
    authenticity is a selling point).
30. Confirm no host-identifying data in the final assets (bar text "nixos ·
    offline-banner demo", fake prompt, no IPs — current design is clean; re-verify on
    final frames).
31. After green capture: auto-commit daemon will pick the files up — verify the
    commit contains only intended assets + script + doc changes.
32. Consider upstreaming nothing — the namespace ns trick is demo-local; keep the
    module untouched (hard rule: single-file module stayed untouched this session —
    confirmed, only scripts/ + docs/ changed so far).

## g) Questions I cannot answer myself

1. **Embed format**: animated WebP (smaller, modern) as primary, or GIF for maximum
   compatibility — and is one committed file the right call, or do you want
   webp + poster png both embedded (I plan: webp embedded, png as the fallback link)?
2. **Demo scope**: is appear → caption ticking → recovery enough, or should the loop
   also show click-to-dismiss (longer capture, synthetic click via sway IPC)?
3. **Fidelity ceiling**: is scene dressing acceptable (demo quickshell bar, fake
   prompt, static clock), or do you want the capture against your real desktop shell
   (niri + your actual bar config), which would make the recipe machine-specific?

## Session hygiene notes

- Module untouched; changed/added files this session: scripts/capture-demo.sh (new),
  scripts/demo/bar/shell.qml (new), scripts/demo/sway.conf (new),
  docs/assets/offline-banner-demo.webp + .png (new, **currently wrong**, replace or
  delete), this report.
- Background shell `00F` from the hung run is still alive; kill it as step 1 of the
  next session (with the stray list from f2).
- Observed in passing while listing processes: a second, unrelated Crush session runs
  in ~/projects/CV; its quickshell instances may be among the store-path PIDs in f2 —
  one more reason to identify-before-kill.
