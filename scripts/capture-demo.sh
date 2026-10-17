#!/usr/bin/env bash
#
# Captures the README demo (docs/assets/offline-banner-demo.{webp,png}) from
# the REAL module QML in a headless sway compositor.
#
# Scene: bar + terminal desktop -> link drops -> banner pushes the bar down
# (InOutCubic) -> "last online" caption ticks -> link returns -> banner
# slides back up. The rendered QML is the ground-truth store file extracted
# from the built module (never a hand-copied Nix string); only the link
# carrier is simulated, via a private /sys/class/net inside a user+mount
# namespace — so probe, caption, animation and recovery are the module's
# own behavior against a real compositor.
#
# Usage: scripts/capture-demo.sh [output-dir]
# Needs in PATH: nix, sway, quickshell, foot, wf-recorder, grim, ffmpeg.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
outdir="${1:-$repo/docs/assets}"
work="${TMPDIR:-/tmp}/offline-banner-demo"
mkdir -p "$work" "$outdir"

for tool in nix sway quickshell foot wf-recorder grim ffmpeg; do
	command -v "$tool" >/dev/null 2>&1 || {
		echo "missing tool: $tool" >&2
		exit 1
	}
done

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DEMO_REPO="$repo"

# --- ground-truth QML: realize the module's writeTextDir store file -------
if [ ! -f "$work/shell.qml" ]; then
	out="$(nix build --impure --no-link --print-out-paths --expr "$(
		cat <<'EXPR'
let
  repo = toString (builtins.getEnv "DEMO_REPO");
  flake = builtins.getFlake repo;
  nixpkgs = flake.inputs.nixpkgs;
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  m = import (repo + "/module.nix");
  execStart =
    (nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        m
        { services.offline-banner.enable = true; }
      ];
    }).config.systemd.user.services.offline-banner.serviceConfig.ExecStart;
in
pkgs.runCommandLocal "shell-qml-ground-truth" { } ''
  qmldir=$(echo "${execStart}" | awk '{print $3}')
  cp "$qmldir/shell.qml" "$out"
''
EXPR
	)")"
	cp "$out" "$work/shell.qml"
fi

# --- headless compositor ---------------------------------------------------
sway_pid="" bar_pid="" foot_pid="" rec_pid="" banner_pid=""
cleanup() {
	for p in "$rec_pid" "$banner_pid" "$foot_pid" "$bar_pid" "$sway_pid"; do
		[ -n "$p" ] && kill "$p" 2>/dev/null || true
	done
	wait 2>/dev/null || true
}
trap cleanup EXIT

snapshot() { find "$XDG_RUNTIME_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort; }
before="$(snapshot)"

WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
	sway --unsupported-gpu -c "$repo/scripts/demo/sway.conf" >"$work/sway.log" 2>&1 &
sway_pid=$!

wayland_sock="" sway_sock=""
for _ in $(seq 1 100); do
	new="$(comm -13 <(echo "$before") <(snapshot) || true)"
	wayland_sock="$(echo "$new" | grep -E '^wayland-[0-9]+$' | head -1 || true)"
	sway_sock="$(echo "$new" | grep -E '^sway-ipc\.[0-9]+\.sock$' | head -1 || true)"
	[ -n "$wayland_sock" ] && [ -n "$sway_sock" ] && break
	sleep 0.1
done
[ -n "$wayland_sock" ] || {
	echo "sway did not start:" >&2
	cat "$work/sway.log" >&2
	exit 1
}
export WAYLAND_DISPLAY="$wayland_sock"
export SWAYSOCK="$XDG_RUNTIME_DIR/$sway_sock"
sleep 0.5

# --- desktop dressing: bar + terminal --------------------------------------
QT_QUICK_BACKEND=software quickshell -p "$repo/scripts/demo/bar" >"$work/bar.log" 2>&1 &
bar_pid=$!
QT_QUICK_BACKEND=software foot -c /dev/null -e sh -c \
	"printf 'lars@nixos ~ » systemctl --user status offline-banner\n● offline-banner.service - Yellow offline banner on all monitors\n   Active: active (running)\n\nlars@nixos ~ » '; sleep infinity" \
	>/dev/null 2>&1 &
foot_pid=$!
sleep 1.5

# --- record -----------------------------------------------------------------
wf-recorder -o HEADLESS-1 -f "$work/raw.mp4" >"$work/recorder.log" 2>&1 &
rec_pid=$!
sleep 0.7

# Banner run, inside a private mount ns: carrier 1 -> 0 at t=2.5 (banner
# appears within one probe interval) -> back to 1 at t=6.0 (recovery).
# "$work" rides in as $1 (sh -c 'script' name arg1) so the inner script
# stays single-quoted without quote gymnastics.
env \
	OFFLINE_BANNER_INTERVAL=1000 \
	OFFLINE_BANNER_FAILURES=1 \
	OFFLINE_BANNER_PROBE_TIMEOUT=2 \
	OFFLINE_BANNER_PROBE_HOST=9.9.9.9 \
	QT_QUICK_BACKEND=software \
	# shellcheck disable=SC2016 — "$1"/"$qs" are for the INNER shell (shellcheck
# cannot follow sh -c through unshare, so it misreads them as outer-expansion
# intent; args after the script string pass "$work" in as $1).
unshare -rm sh -c '
    mount -t tmpfs tmpfs /sys/class/net || exit 3
    mkdir -p /sys/class/net/eth0
    echo 1 > /sys/class/net/eth0/carrier
    quickshell -p "$1" &
    qs=$!
    sleep 2.5
    echo 0 > /sys/class/net/eth0/carrier
    sleep 3.5
    echo 1 > /sys/class/net/eth0/carrier
    sleep 8
    kill "$qs"
  ' offline-banner-demo "$work" >"$work/banner.log" 2>&1 &
banner_pid=$!

sleep 5.0
grim -o HEADLESS-1 "$outdir/offline-banner-demo.png"
sleep 4.5
kill -INT "$rec_pid" 2>/dev/null || true
wait "$rec_pid" 2>/dev/null || true
rec_pid=""

# --- encode -----------------------------------------------------------------
ffmpeg -y -loglevel error -i "$work/raw.mp4" \
	-vf "fps=25,scale=1600:-2:flags=lanczos" -loop 0 -an \
	-compression_level 6 -q:v 70 \
	"$outdir/offline-banner-demo.webp"

echo "wrote:"
ls -lh "$outdir"/offline-banner-demo.webp "$outdir"/offline-banner-demo.png
echo "raw capture kept at: $work/raw.mp4"
