// Masbate province — real coastlines (Natural Earth 50m, Mercator-projected, simplified).
// One shared projection, so relative position and scale between the three islands are true.
// viewBox is fixed at "0 0 400 470" — all three paths live in that coordinate space.

export const ISLAND_VIEWBOX = "0 0 400 470";

export const ISLAND_PATHS = {
  masbate:
    "M267.75,282.51L328.11,321.28L370.24,386.42L374.80,436.36L371.38,456L352.02,434.12L308.75,403.82L279.14,397.08L270.03,391.47L273.45,374.63L254.09,359.47L251.81,353.29L234.73,346.55L208.54,312.29L190.32,305.55L173.23,312.85L133.38,363.96L91.24,399.89L90.10,385.86L107.19,341.50L118.57,269.58L125.41,247.66L116.3,215.60L115.16,186.91L147.04,200.41L186.90,213.35L217.65,231.91L222.20,244.28Z",
  ticao:
    "M285.97,228.54L287.11,257.21L275.72,246.53L237.01,190.85L226.76,170.59L237.01,157.09L265.47,177.91Z",
  burias:
    "M129.96,99.09L157.29,148.64L127.68,114.86L93.52,91.77L58.22,54.02L32.03,40.49L25.19,32.60L27.47,16.81L46.83,14L54.80,15.12L106.05,82.19Z",
};

export type IslandKey = keyof typeof ISLAND_PATHS;

// Label anchors inside the same coordinate space.
export const ISLAND_LABELS = {
  burias: { x: 172, y: 70 },
  ticao: { x: 330, y: 196 },
  masbate: { x: 196, y: 290 },
} as const satisfies Record<IslandKey, { x: number; y: number }>

// Draw order matters: smallest island first so Masbate's rounded stroke never clips it.
export const ISLAND_ORDER = ["burias", "ticao", "masbate"] as const satisfies readonly IslandKey[];

export const ISLAND_NAMES = {
  masbate: "Masbate",
  ticao: "Ticao",
  burias: "Burias",
} as const satisfies Record <string, string>;

export function toIslandKey(island: string | null | undefined): IslandKey | null {
  return ISLAND_ORDER.includes(island as IslandKey) ? (island as IslandKey) : null
}
