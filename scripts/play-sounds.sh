#!/usr/bin/env sh
# Audition the synthesized banner sounds: plays the full 3-theme x 4-event
# matrix (chime/droplet/retro x offline-net/offline-link/recover/dismiss)
# exactly the way the unit plays a cue — pw-play --volume <linear> <wav>
# against the session PipeWire. Only 2 of the 12 cues have ever been heard
# by a human; this is the tuning loop's player side. Edit genSoundsScript
# in module.nix, rebuild, re-run — re-synthesis is one rebuild (AGENTS.md).
#
# Sounds dir resolution, first match wins:
#   1. $1 (or OFFLINE_BANNER_SOUNDS_DIR)
#   2. the RUNNING unit's OFFLINE_BANNER_SOUNDS env (the live truth)
#   3. a fresh `nix build .#sounds`
#
# Volume mirrors OFFLINE_BANNER_SOUND_VOLUME (percent, default 60),
# rendered as pw-play's linear 0..1 factor like the QML does.
set -eu

dir=""
if [ "$#" -ge 1 ]; then
	dir="$1"
elif [ -n "${OFFLINE_BANNER_SOUNDS_DIR:-}" ]; then
	dir="$OFFLINE_BANNER_SOUNDS_DIR"
fi

if [ -z "$dir" ] && command -v systemctl >/dev/null 2>&1; then
	if systemctl --user is-active --quiet offline-banner 2>/dev/null; then
		unit_env=$(systemctl --user show offline-banner -p Environment --value)
		dir=$(printf '%s\n' "$unit_env" |
			tr ' ' '\n' |
			grep '^OFFLINE_BANNER_SOUNDS=' |
			head -1 |
			cut -d= -f2- |
			tr -d '"')
	fi
fi

if [ -z "$dir" ]; then
	echo "play-sounds: no sounds dir given; building .#sounds ..." >&2
	dir=$(nix build --no-link --print-out-paths .#sounds | tail -1)
fi

if ! command -v pw-play >/dev/null 2>&1; then
	echo "play-sounds: pw-play not found (pipewire CLI) — is PipeWire installed?" >&2
	exit 1
fi
[ -d "$dir" ] || {
	echo "play-sounds: sounds dir '$dir' not found" >&2
	exit 1
}

volume="${OFFLINE_BANNER_SOUND_VOLUME:-60}"
case $volume in
'' | *[!0-9]*) volume=60 ;;
esac
[ "$volume" -le 100 ] || volume=100
volume_arg=$(awk -v v="$volume" 'BEGIN { printf "%.2f", v / 100 }')

echo "play-sounds: theme dir $dir, volume $volume% (linear $volume_arg)"
found=0
for theme in chime droplet retro; do
	for event in offline-net offline-link recover dismiss; do
		wav="$dir/$theme-$event.wav"
		[ -f "$wav" ] || {
			echo "play-sounds: MISSING $theme-$event.wav" >&2
			continue
		}
		found=$((found + 1))
		echo "--- $theme / $event"
		pw-play --volume "$volume_arg" "$wav"
	done
done
[ "$found" -eq 12 ] || {
	echo "play-sounds: expected 12 cues, found $found (rebuild .#sounds?)" >&2
	exit 1
}
echo "play-sounds: all 12 cues played"
