import { addons } from "storybook/manager-api";
import { create } from "storybook/theming";
import { SITE_NAME } from "./site";

// Storybook's own theme, light or dark as the system prefers (what it picks
// with no theme set), with the design system's name as its brand title.
const dark = globalThis.matchMedia?.("(prefers-color-scheme: dark)").matches ?? false;

addons.setConfig({
  theme: create({ base: dark ? "dark" : "light", brandTitle: SITE_NAME }),
});
