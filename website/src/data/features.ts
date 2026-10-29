import type { Feature } from "./types";

export const features: Feature[] = [
  {
    icon: "monitor",
    title: "Every monitor, one truth",
    desc: "One layer-shell surface per connected output. No screen left quietly lying to you.",
    accent: "accent",
  },
  {
    icon: "layers",
    title: "Pushes down, never covers",
    desc: "An animated exclusive zone (InOutCubic, 450 ms) that your bar slides beneath — nothing hidden, nothing unreachable.",
    accent: "blue",
  },
  {
    icon: "clock",
    title: "Debounced, with a memory",
    desc: "Two failed probes (~10 s) before it appears — one lost ping changes nothing. 'last online 4m 12s ago' while it's up.",
    accent: "accent",
  },
  {
    icon: "shield",
    title: "Sandboxed by contract",
    desc: "A strict systemd sandbox — reads /sys, pings, talks Wayland; nothing else. Asserted line-by-line by a flake check.",
    accent: "success",
  },
  {
    icon: "eye",
    title: "Fail visible, never silent",
    desc: "A probe that cannot run counts as a failure. Journal lines and a JSON state file rewritten on every probe.",
    accent: "blue",
  },
  {
    icon: "sliders",
    title: "Tune live, no rebuild",
    desc: "OFFLINE_BANNER_* env vars mirror every option — retune a running system with a drop-in, or force-show with demo mode.",
    accent: "accent",
  },
  {
    icon: "volume",
    title: "Says it out loud, once",
    desc: "Three synthesized themes, no audio files: a lower droop for link loss than for net loss, a sparkle on recovery. One cue per outage, never per probe.",
    accent: "blue",
  },
  {
    icon: "archive",
    title: "Keeps the receipt",
    desc: "One JSON line per completed outage — start, end, duration, reasons. Blips shorter than the debounce never make the log; demo runs never write.",
    accent: "success",
  },
];
