/**
 * Design tokens lifted from the mockups.
 * Import in JS, or copy the :root block below into your global stylesheet.
 */

export const tokens = {
  color: {
    bg: "#F7F4EE",          // app ground
    surface: "#FFFFFF",     // cards, rows, inputs
    canvas: "#E6E2D9",      // image wells, behind-frame workspace
    inset: "#F4F1EA",        // chips, insets inside cards
    divider: "#E0DBD0",

    ink: "#2E3A43",
    inkMuted: "rgba(46,58,67,.74)",

    primary: "#16587B",     // Venice Blue
    primaryTintBg: "#EEF3F6",
    primaryLight: "#5F92B5",
    islandIdle: "#CFDDE5",

    onPrimary: "#F7F4EE",
    highlight: "#DBE8EF",   // search-match background
  },

  font: {
    display: "'Rozha One', serif",   // headlines, fares, island names
    body: "Jost, system-ui, sans-serif", // everything else — 300 / 400 / 500 / 600
  },

  radius: {
    chip: 999,
    input: 20,
    row: 22,
    card: 26,
    panel: 30,
    well: 18,
  },

  shadow: {
    row: "0 2px 10px rgba(46,58,67,.05)",
    card: "0 3px 12px rgba(46,58,67,.06)",
    raised: "0 6px 20px rgba(22,88,123,.10)",
    panel: "0 12px 34px rgba(46,58,67,.14)",
  },
};

/*
:root {
  --bg: #F7F4EE;
  --surface: #FFFFFF;
  --canvas: #E6E2D9;
  --inset: #F4F1EA;
  --divider: #E0DBD0;
  --ink: #2E3A43;
  --ink-muted: rgba(46, 58, 67, .74);
  --primary: #16587B;
  --primary-tint-bg: #EEF3F6;
  --primary-light: #5F92B5;
  --island-idle: #CFDDE5;
  --on-primary: #F7F4EE;
  --highlight: #DBE8EF;

  --font-display: "Rozha One", serif;
  --font-body: "Jost", system-ui, sans-serif;

  --radius-input: 20px;
  --radius-row: 22px;
  --radius-card: 26px;
  --radius-panel: 30px;

  --shadow-row: 0 2px 10px rgba(46, 58, 67, .05);
  --shadow-card: 0 3px 12px rgba(46, 58, 67, .06);
  --shadow-raised: 0 6px 20px rgba(22, 88, 123, .10);
}
*/

// Fonts — add to index.html <head>:
// <link href="https://fonts.googleapis.com/css2?family=Rozha+One&family=Jost:wght@300;400;500;600&display=swap" rel="stylesheet">
