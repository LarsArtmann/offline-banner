# shellcheck shell=sh
# tcp+dns leg probe. Two output lines, exact format: "tcp ok|fail" then
# "dns ok|fail". module.nix embeds this file verbatim into shell.qml and
# runs it under `sh -c` with the unit PATH (bash, coreutils, getent,
# iputils); checks.leg-contract executes it against a stub getent.
# The answer must be PUBLIC: a private/loopback/link-local/unspecified
# address means the resolver synthesized it (a DNS blocker's zero-IP
# block page, a split-horizon zone) — the leg would otherwise read green
# forever with no packet leaving the host (evo-x2 2026-11-18: the probe
# name sat on a blocklist and resolved to the blocker's 192.168.1.200).
if timeout "$OFFLINE_BANNER_PROBE_TIMEOUT" bash -c 'exec 3<>"/dev/tcp/$OFFLINE_BANNER_TCP_HOST/$OFFLINE_BANNER_TCP_PORT"' 2>/dev/null; then
	echo tcp ok
else
	echo tcp fail
fi
addr=$(timeout "$OFFLINE_BANNER_PROBE_TIMEOUT" getent ahostsv4 "$OFFLINE_BANNER_DNS_NAME" 2>/dev/null | head -n1 | cut -d' ' -f1)
case "$addr" in
"" | 0.0.0.0 | 127.* | 10.* | 192.168.* | 172.1[6-9].* | 172.2[0-9].* | 172.3[01].* | 169.254.* | ::1 | fe80:* | fc* | fd*)
	echo dns fail
	;;
*)
	echo dns ok
	;;
esac
