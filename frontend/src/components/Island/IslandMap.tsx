import type { CSSProperties, SVGProps } from "react";
import { cn } from "../../ui";
import {
  ISLAND_VIEWBOX,
  ISLAND_PATHS,
  ISLAND_LABELS,
  ISLAND_ORDER,
  ISLAND_NAMES,
  type IslandKey,
} from "./island-paths.tsx";

type IslandMapProps = {
  selected?: IslandKey | null;
  onSelect?: (island: IslandKey) => void;
  /** Optional hard cap in px. Leave unset and size it with `className` instead. */
  width?: number;
  className?: string;
  showLabels?: boolean;
  fill?: string;
  highlight?: string;
  ink?: string;
  inkOnFill?: string;
};

const round = {
  strokeWidth: 11,
  strokeLinejoin: "round",
  strokeLinecap: "round",
} satisfies SVGProps<SVGPathElement>;

/**
 * Ticao and Burias are slivers - at phone width their painted stroke is only a
 * few px across, well under a fingertip. An invisible fatter copy of each path
 * carries the tap.
 */
const hit = {
  fill: "none",
  stroke: "transparent",
  strokeWidth: 26,
  strokeLinejoin: "round",
  strokeLinecap: "round",
} satisfies SVGProps<SVGPathElement>;

export default function IslandMap({
  selected = "masbate",
  onSelect,
  width,
  className,
  showLabels = false,
  fill = "#cfdde5",
  highlight = "#16587b",
  ink = "#2e3a43",
  inkOnFill = "#ffffff",
}: IslandMapProps) {
  const interactive = onSelect !== undefined;
  const labelStyle: CSSProperties = {
    font: "600 11.5px Jost, sans-serif",
    letterSpacing: ".09em",
    pointerEvents: "none",
  };

  return (
    <svg
      // The viewBox carries the 400x470 ratio, so height follows width on its
      // own - no fixed pixel size, and the map shrinks with the column.
      className={cn("h-auto w-full", className)}
      style={width ? { maxWidth: width } : undefined}
      viewBox={ISLAND_VIEWBOX}
      preserveAspectRatio="xMidYMid meet"
      role="img"
      aria-label="Masbate province: Masbate, Ticao and Burias islands"
    >
      {ISLAND_ORDER.map((key) => {
        const on = selected === key;
        const color = on ? highlight : fill;
        const select = onSelect ? () => onSelect(key) : undefined;
        return (
          <g key={key} aria-label={ISLAND_NAMES[key]}>
            <path
              d={ISLAND_PATHS[key]}
              fill={color}
              stroke={color}
              {...round}
              onClick={select}
              style={{
                cursor: interactive ? "pointer" : undefined,
                transition: "fill .15s, stroke .15s",
              }}
            />
            {interactive && (
              <path d={ISLAND_PATHS[key]} {...hit} onClick={select} style={{ cursor: "pointer" }} />
            )}
          </g>
        );
      })}

      {showLabels &&
        ISLAND_ORDER.map((key) => (
          <text
            key={key}
            x={ISLAND_LABELS[key].x}
            y={ISLAND_LABELS[key].y}
            textAnchor="middle"
            fill={selected === key ? inkOnFill : ink}
            style={labelStyle}
          >
            {ISLAND_NAMES[key].toUpperCase()}
          </text>
        ))}
    </svg>
  );
}
