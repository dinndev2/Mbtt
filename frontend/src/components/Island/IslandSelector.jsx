import { useState } from "react";
import IslandMap from "./IslandMap.jsx";
import { ChevronRight } from "lucide-react";
import { tokens } from "../../assets/tokens.js";

const ISLANDS = [
  { key: "masbate", name: "Masbate", blurb: "Buses, vans and jeeps from the city terminal.", chips: ["8 places", "No crossing"] },
  { key: "ticao", name: "Ticao", blurb: "Ferry from Masbate City Port, then habal-habal.", chips: ["10 places", "Ferry · 40m"] },
  { key: "burias", name: "Burias", blurb: "RoRo from Mobo Port. A full day out.", chips: ["4 places", "RoRo · 9h"] },
];

export default function IslandSelector({ onConfirm }) {
  const [selected, setSelected] = useState("masbate");
  console.log(selected)
  const c = tokens.color;

  return (
    <div style={{ background: c.bg, minHeight: "100vh", padding: "20px 22px" }}>
      <h1 style={{ font: `400 29px/1.02 ${tokens.font.display}`, color: c.ink, margin: 0 }}>
        Which island are you on?
      </h1>
      <p style={{ margin: "8px 0 0", font: `300 13px/1.45 ${tokens.font.body}`, color: c.inkMuted, maxWidth: 280 }}>
        Fares and crossings differ by island. You can switch any time.
      </p>

      <div style={{ display: "flex", justifyContent: "center", padding: "10px 0 0" }}>
        <IslandMap selected={selected} onSelect={setSelected} width={212} />
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 9, paddingTop: 10 }}>
        {ISLANDS.map(({ key, name, blurb, chips }) => {
          const on = selected === key;
          return (
            <button
              key={key}
              onClick={() => { setSelected(key); onConfirm?.(key); }}
              style={{
                cursor: "pointer", textAlign: "left", display: "flex", alignItems: "center", gap: 14,
                background: c.surface, borderRadius: 24, padding: "14px 17px", transition: ".15s",
                border: `1.5px solid ${on ? c.primary : "transparent"}`,
                boxShadow: on ? tokens.shadow.raised : tokens.shadow.row,
              }}
            >
              <span style={{ flex: 1, minWidth: 0 }}>
                <span style={{ display: "flex", alignItems: "center", gap: 9 }}>
                  <span style={{ width: 9, height: 9, borderRadius: "50%", background: on ? c.primary : c.islandIdle }} />
                  <span style={{ font: `400 23px/1 ${tokens.font.display}`, color: c.ink }}>{name}</span>
                </span>
                <span style={{ display: "block", marginTop: 5, font: `300 12px/1.4 ${tokens.font.body}`, color: c.inkMuted }}>
                  {blurb}
                </span>
                <span style={{ display: "flex", gap: 6, marginTop: 8, flexWrap: "wrap" }}>
                  {chips.map((t) => (
                    <span key={t} style={{ background: c.inset, borderRadius: 999, padding: "5px 10px", font: `400 11px ${tokens.font.body}`, color: c.inkMuted }}>
                      {t}
                    </span>
                  ))}
                </span>
              </span>
              <ChevronRight size={20} strokeWidth={2.4} color={c.primary} style={{ flex: "none" }} />
            </button>
          );
        })}
      </div>
    </div>
  );
}
