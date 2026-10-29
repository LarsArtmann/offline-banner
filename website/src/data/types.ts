export const featureIconKeys = [
  "monitor",
  "layers",
  "clock",
  "shield",
  "eye",
  "sliders",
  "volume",
  "archive",
] as const;
export type FeatureIcon = (typeof featureIconKeys)[number];

export type AccentColor = "accent" | "blue" | "success";

export interface Feature {
  icon: FeatureIcon;
  title: string;
  desc: string;
  accent: AccentColor;
}

export interface ProbeLeg {
  leg: string;
  legColor: "accent" | "blue";
  title: string;
  patterns: string[];
  hint: string;
  hintColor: "accent" | "blue";
  hintIcon: "check" | "warning";
}

export const personaIconKeys = ["monitor", "layers", "server", "terminal"] as const;
export type PersonaIcon = (typeof personaIconKeys)[number];

export interface Persona {
  title: string;
  desc: string;
  icon: PersonaIcon;
  accent: AccentColor;
}

export const uiIconKeys = [
  "arrow-external",
  "arrow-right",
  "github",
  "menu",
  "close",
  "sun",
  "moon",
  "monitor",
  "star",
  "play",
  "warning",
  "check",
] as const;
export type UIIcon = (typeof uiIconKeys)[number];

export type IconName = FeatureIcon | PersonaIcon | UIIcon;
