#!/usr/bin/env bash
#
# Click-dismiss machine proof (TODO row 34 leg c): boots the smoke demo
# transient on the REAL output, proves the yellow strip is on screen via
# grim hue detection, clicks it through niri's virtual-pointer protocol,
# and asserts dismissal through the isolated state file — the module's
# own MouseArea -> dismissed path, machine-verified end to end.
#
# Live-session tool: needs a running niri session (NIRI_SOCKET +
# WAYLAND_DISPLAY) with a visible output; NOT a flake check. Safe beside
# the live unit — the smoke transient is fully isolated (distinct
# runtime/state dirs, silent by default), and the script never clicks
# unless the strip hue is confirmed at the click coordinates first.
#
# Usage: scripts/click-dismiss-proof.sh
# Needs in PATH: nix, grim, jq, busctl (wlrctl and python3 are fetched
#   via `nix shell` when missing).
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
uid="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$uid}"
: "${WAYLAND_DISPLAY:?export WAYLAND_DISPLAY (e.g. wayland-1) — see: ls "$XDG_RUNTIME_DIR" | grep wayland}"
: "${NIRI_SOCKET:?export NIRI_SOCKET (e.g. "$XDG_RUNTIME_DIR"/niri.wayland-1.<pid>.sock)}"

# Output geometry: DP-1 defaults (4K, 1.25 scale). Override for other
# outputs; the strip band is scanned in PHYSICAL rows 40-120 and the
# click lands at the LOGICAL centre of the strip.
strip_rows_lo=40
strip_rows_hi=120
logical_w="${LOGICAL_W:-3072}"
logical_y="${LOGICAL_Y:-64}"
click_x=$((logical_w / 2))

live_state="$XDG_RUNTIME_DIR/offline-banner/state"
smoke_state="$XDG_RUNTIME_DIR/offline-banner-smoke/state"

log() { printf '[click-dismiss-proof] %s\n' "$*" >&2; }
die() {
	log "FAIL: $*"
	exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || die "missing tool: $1 (nix shell nixpkgs#$1)"; }
for tool in nix grim jq busctl; do
	need "$tool"
done

if command -v wlrctl >/dev/null 2>&1; then
	wlrctl() { command wlrctl "$@"; }
else
	log "wlrctl not in PATH — fetching via nix shell"
	wlrctl() { nix shell nixpkgs#wlrctl -c wlrctl "$@"; }
fi
if command -v python3 >/dev/null 2>&1; then
	band_count() { command python3 "$repo/scripts/demo/band-count.py" "$@"; }
else
	log "python3 not in PATH — fetching via nix shell"
	band_count() { nix shell nixpkgs#python3 -c python3 "$repo/scripts/demo/band-count.py" "$@"; }
fi

# Hue-aware strip detector (render-smoke calibration doctrine: the raw
# #f2f9e2 never survives the compositor transform; require r>=200,
# g>=170, r-b>=40 over the strip band). Prints the qualifying pixel
# count; FAIL-CLOSED — any capture or parse failure aborts the proof
# BEFORE the click (the 2026-11-18 first run clicked on empty evidence
# because grim's STDOUT mode silently produced zero bytes; an explicit
# output path is required).
band_pixels() {
	tmp="$(mktemp "${TMPDIR:-/tmp}/ob-click-proof.XXXXXX.ppm")"
	grim -t ppm "$tmp" || {
		rm -f "$tmp"
		die "grim failed — cannot verify the strip; refusing to click blind"
	}
	out="$(band_count "$tmp" "$strip_rows_lo" "$strip_rows_hi")" || {
		rm -f "$tmp"
		die "band-count failed — refusing to continue without pixel evidence"
	}
	rm -f "$tmp"
	case "$out" in
	'' | *[!0-9]*) die "band-count produced non-numeric output: '$out'" ;;
	esac
	printf '%s\n' "$out"
}

transient_started=0
stop_transient() {
	if [ "$transient_started" -eq 1 ]; then
		busctl --user call org.freedesktop.systemd1 /org/freedesktop/systemd1 \
			org.freedesktop.systemd1.Manager StopUnit ss \
			"offline-banner-smoke.service" "replace" >/dev/null 2>&1 ||
			log "warning: transient stop via busctl failed (stop it manually)"
	fi
}
trap stop_transient EXIT

poll() { # poll TRIES DELAY CMD... — succeeds on first CMD success
	tries=$1
	delay=$2
	shift 2
	for _ in $(seq 1 "$tries"); do
		if "$@" >/dev/null 2>&1; then return 0; fi
		sleep "$delay"
	done
	return 1
}

# --- preconditions ----------------------------------------------------------

systemd_unit_path="$(busctl --user call org.freedesktop.systemd1 /org/freedesktop/systemd1 \
	org.freedesktop.systemd1.Manager GetUnit s "offline-banner-smoke.service" 2>/dev/null || true)"
if [ -n "$systemd_unit_path" ]; then
	die "offline-banner-smoke transient already exists — stop it first (busctl StopUnit), then rerun"
fi

baseline="$(band_pixels)" || die "baseline capture failed"
if [ "$baseline" -gt 38400 ]; then
	die "strip band already present BEFORE the demo (pixels=$baseline) — baseline not clean, aborting without clicking"
fi
log "baseline clean (band pixels=$baseline)"

live_active_before="absent"
if [ -f "$live_state" ]; then
	live_active_before="$(jq -c '.active' "$live_state")"
fi
log "live unit state before: active=$live_active_before (asserted unchanged after)"

# --- demo transient ---------------------------------------------------------

log "starting smoke demo transient (silent by default)"
(cd "$repo" && OFFLINE_BANNER_SMOKE_DEMO=1 nix run .#smoke >/dev/null)
transient_started=1

poll 80 250 jq -e '.active == true' "$smoke_state" ||
	die "smoke state never reached active:true at $smoke_state — transient did not show; nothing clicked"
log "demo shown (state active:true)"

shown="$(band_pixels)" || die "show capture failed"
if [ "$shown" -lt 38400 ]; then
	die "yellow strip not detected after show (pixels=$shown) — nothing clicked; check output geometry"
fi
log "strip verified on screen (band pixels=$shown) — clicking at logical ($click_x, $logical_y)"

# --- the click ---------------------------------------------------------------

wlrctl pointer move -99999 -99999
sleep 0.3
wlrctl pointer move "$click_x" "$logical_y"
sleep 0.3
wlrctl pointer click left

poll 50 100 jq -e '.active == false' "$smoke_state" ||
	die "click did not dismiss: state still active:true after 5 s"
log "DISMISSED: state active flipped false within the poll window"

# The strip slides up animatedly — the state flips before the pixels do.
# Poll the band down (transition poll, not sleep-then-single-shot).
after=""
band_gone() {
	[ "$(band_pixels)" -lt 38400 ]
}
poll 20 250 band_gone || after="$(band_pixels)"
if [ -n "$after" ]; then
	die "strip still on screen after dismissal (pixels=$after) — state flipped but pixels never settled"
fi
after="$(band_pixels)"
log "strip gone from screen (band pixels=$after)"

live_active_after="absent"
if [ -f "$live_state" ]; then
	live_active_after="$(jq -c '.active' "$live_state")"
fi
if [ "$live_active_before" != "$live_active_after" ]; then
	die "live unit state changed by the proof ($live_active_before -> $live_active_after) — isolation broken"
fi

log "PASS: click-dismiss machine proof complete"
log "evidence: $smoke_state active true->false; band $baseline -> $shown -> $after; live unit untouched (active=$live_active_after)"
log "journal: journalctl --user -u offline-banner-smoke.service -e --no-pager"
