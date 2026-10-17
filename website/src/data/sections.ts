import type { Persona, ProbeLeg } from "./types";

export const probeLegs: ProbeLeg[] = [
  {
    leg: "L1",
    legColor: "accent",
    title: "Link leg — kernel carrier",
    patterns: ["/sys/class/net/*/carrier"],
    hint: "Virtual ifaces excluded: lo, veth, tailscale, docker…",
    hintColor: "accent",
    hintIcon: "check",
  },
  {
    leg: "L2",
    legColor: "blue",
    title: "Internet leg — one ICMP echo",
    patterns: ["ping 9.9.9.9"],
    hint: "An IP, never a name — the banner must not depend on DNS",
    hintColor: "blue",
    hintIcon: "warning",
  },
];

export const personas: Persona[] = [
  {
    title: "NixOS flake users",
    desc: "One input, one option — not a network applet framework.",
    icon: "monitor",
    accent: "accent",
  },
  {
    title: "Multi-monitor desktops",
    desc: "A single bar widget leaves every other screen guessing.",
    icon: "layers",
    accent: "blue",
  },
  {
    title: "Static-IP / hybrid hosts",
    desc: "NM-unmanaged uplinks make NetworkManager indicators read the wrong answer.",
    icon: "server",
    accent: "accent",
  },
  {
    title: "Journal people",
    desc: "journalctl and a state file you can trust more than a tray icon that silently died.",
    icon: "terminal",
    accent: "success",
  },
];
