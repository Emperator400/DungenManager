import { useState } from "react";

const THEMES = {
  light: {
    bg: "#f7f7f5", bgPanel: "#ffffff", bgHover: "#f0f0ed", bgActive: "#eeecea",
    border: "#e4e4e0", borderStrong: "#d0d0ca",
    text: "#1a1a18", textMid: "#6b6b66", textSoft: "#9f9f98",
    accent: "#2f6feb", accentSoft: "#eef3fd",
    green: "#1a7f4b", greenSoft: "#eaf4ee",
    amber: "#d4890a", amberSoft: "#2a1f08",
  },
  dark: {
    bg: "#111110", bgPanel: "#1a1a18", bgHover: "#232320", bgActive: "#2a2a27",
    border: "#2e2e2b", borderStrong: "#3d3d39",
    text: "#edede8", textMid: "#8a8a82", textSoft: "#5a5a54",
    accent: "#4f8ef7", accentSoft: "#1a2540",
    green: "#34c471", greenSoft: "#0f2a1c",
    amber: "#d4890a", amberSoft: "#2a1f08",
  },
};

const Icon = ({ name, size = 20, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    scroll: "M4 2h8a1 1 0 011 1v12l-4.5-2L4 15V3a1 1 0 011-1z",
    paw: "M5 4a1 1 0 100 2 1 1 0 000-2zm6 0a1 1 0 100 2 1 1 0 000-2zM3 8a1 1 0 100 2 1 1 0 000-2zm10 0a1 1 0 100 2 1 1 0 000-2zM8 6c-2 0-4 2-4 4s2 3 4 3 4-1 4-3-2-4-4-4z",
    bag: "M5 6V4a3 3 0 016 0v2h2a1 1 0 011 1v8a1 1 0 01-1 1H3a1 1 0 01-1-1V7a1 1 0 011-1h2z",
    book: "M3 3h8l2 2v10H3V3zm4 5h4M7 11h4",
    music: "M9 3v8.5a2.5 2.5 0 11-1-2V6L5 7V4l4-1z",
    user: "M8 7a3 3 0 100-6 3 3 0 000 6zm-5 9a5 5 0 0110 0",
    settings: "M8 5a3 3 0 100 6 3 3 0 000-6zM2 8a6 6 0 1012 0A6 6 0 002 8z",
    play: "M4 3l10 5-10 5V3z",
    arrow: "M4 8h8M9 5l3 3-3 3",
    clock: "M8 3a5 5 0 100 10A5 5 0 008 3zm0 3v2.5l2 1",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} fill={name === "play" ? color : "none"} />
    </svg>
  );
};

const BEREICHE = [
  { id: "kampagnen", label: "Kampagnen", icon: "scroll", beschreibung: "Verwalte deine Abenteuer", farbe: "#2f6feb", count: 3, countLabel: "aktiv" },
  { id: "bestiarium", label: "Bestiarium", icon: "paw", beschreibung: "Monster & Kreaturen", farbe: "#1a7f4b", count: 47, countLabel: "Einträge" },
  { id: "ausruestung", label: "Ausrüstung", icon: "bag", beschreibung: "Items & Gegenstände", farbe: "#b45309", count: 12, countLabel: "Items" },
  { id: "lore", label: "Lore Keeper", icon: "book", beschreibung: "Wiki & Weltenwissen", farbe: "#7c3aed", count: 27, countLabel: "Einträge" },
  { id: "sounds", label: "Sounds", icon: "music", beschreibung: "Atmosphäre & Musik", farbe: "#0891b2", count: 8, countLabel: "Sets" },
  { id: "profil", label: "DM-Profil", icon: "user", beschreibung: "Dein Profil & Daten", farbe: "#6b6b66", count: null, countLabel: null },
  { id: "einstellungen", label: "Einstellungen", icon: "settings", beschreibung: "App konfigurieren", farbe: "#6b6b66", count: null, countLabel: null },
];

const LETZTE_AKTIVITAET = [
  { text: "Goblin bearbeitet", bereich: "Bestiarium", zeit: "vor 2 Min", farbe: "#1a7f4b" },
  { text: "Session 3 in 'Die Verlorene Krone'", bereich: "Kampagnen", zeit: "vor 1 Std", farbe: "#2f6feb" },
  { text: "Flammenzunge hinzugefügt", bereich: "Ausrüstung", zeit: "gestern", farbe: "#b45309" },
  { text: "Rathaus (Ort) erstellt", bereich: "Lore Keeper", zeit: "gestern", farbe: "#7c3aed" },
];

export default function Startseite() {
  const [isDark, setIsDark] = useState(false);
  const [aktiv, setAktiv] = useState(null);
  const C = THEMES[isDark ? "dark" : "light"];

  const aktivBereich = BEREICHE.find(b => b.id === aktiv);

  return (
    <div style={{
      fontFamily: "-apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif",
      background: C.bg, minHeight: "100vh",
      color: C.text, fontSize: 13,
      transition: "background 0.25s, color 0.25s",
    }}>

      {/* TOPBAR */}
      <div style={{
        height: 48, background: C.bgPanel, borderBottom: `1px solid ${C.border}`,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 24px", position: "sticky", top: 0, zIndex: 10,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <div style={{
            width: 24, height: 24, borderRadius: 6, background: C.text,
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <span style={{ color: C.bgPanel, fontSize: 13, fontWeight: 700 }}>D</span>
          </div>
          <span style={{ fontSize: 14, fontWeight: 600 }}>DungenManager</span>
        </div>
        <button onClick={() => setIsDark(d => !d)} style={{
          width: 32, height: 32, borderRadius: 7,
          background: C.bgHover, border: `1px solid ${C.border}`,
          cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
        }}>
          <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
        </button>
      </div>

      <div style={{ maxWidth: 820, margin: "0 auto", padding: "32px 24px 60px" }}>

        {/* Begrüßung */}
        <div style={{ marginBottom: 28 }}>
          <h1 style={{ margin: "0 0 4px", fontSize: 22, fontWeight: 700, letterSpacing: -0.4, color: C.text }}>
            Willkommen zurück, Tim
          </h1>
          <p style={{ margin: 0, fontSize: 13, color: C.textSoft }}>
            Was möchtest du heute vorbereiten?
          </p>
        </div>

        {/* Schnellstart */}
        <div style={{
          padding: "14px 18px", borderRadius: 10, marginBottom: 28,
          background: C.bgPanel, border: `1px solid ${C.border}`,
          display: "flex", alignItems: "center", justifyContent: "space-between",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 8,
              background: "#2f6feb22", border: "1.5px solid #2f6feb44",
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ fontSize: 15, fontWeight: 700, color: "#2f6feb" }}>D</span>
            </div>
            <div>
              <div style={{ fontSize: 13, fontWeight: 600, color: C.text }}>Die Verlorene Krone</div>
              <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 2 }}>
                <div style={{ width: 6, height: 6, borderRadius: "50%", background: C.green }} />
                <span style={{ fontSize: 11, color: C.textSoft }}>Zuletzt gespielt · Session 3</span>
              </div>
            </div>
          </div>
          <button style={{
            display: "flex", alignItems: "center", gap: 6,
            padding: "8px 16px", borderRadius: 7,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 12, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
          }}>
            <Icon name="play" size={12} color="#fff" />
            Session fortsetzen
          </button>
        </div>

        {/* App Grid */}
        <div style={{ marginBottom: aktiv ? 12 : 28 }}>
          <p style={{ margin: "0 0 12px", fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase" }}>
            Bereiche
          </p>
          <div style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(108px, 1fr))",
            gap: 10,
          }}>
            {BEREICHE.map(b => {
              const isAktiv = aktiv === b.id;
              return (
                <button key={b.id} onClick={() => setAktiv(isAktiv ? null : b.id)} style={{
                  background: isAktiv
                    ? isDark ? b.farbe + "22" : b.farbe + "12"
                    : C.bgPanel,
                  border: `1.5px solid ${isAktiv ? b.farbe + "55" : C.border}`,
                  borderRadius: 12, padding: "14px 10px 12px",
                  cursor: "pointer", fontFamily: "inherit",
                  display: "flex", flexDirection: "column", alignItems: "center", gap: 8,
                  transition: "all 0.18s ease",
                  transform: isAktiv ? "scale(1.03)" : "scale(1)",
                  boxShadow: isAktiv ? `0 4px 16px ${b.farbe}22` : "none",
                }}
                  onMouseEnter={e => { if (!isAktiv) { e.currentTarget.style.background = C.bgHover; e.currentTarget.style.borderColor = C.borderStrong; } }}
                  onMouseLeave={e => { if (!isAktiv) { e.currentTarget.style.background = C.bgPanel; e.currentTarget.style.borderColor = C.border; } }}
                >
                  <div style={{
                    width: 44, height: 44, borderRadius: 11,
                    background: b.farbe + (isDark ? "25" : "15"),
                    border: `1.5px solid ${b.farbe}${isDark ? "40" : "30"}`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>
                    <Icon name={b.icon} size={20} color={b.farbe} />
                  </div>
                  <div style={{ textAlign: "center" }}>
                    <div style={{ fontSize: 12, fontWeight: 500, color: C.text, lineHeight: 1.2 }}>
                      {b.label}
                    </div>
                    {b.count !== null && (
                      <div style={{ fontSize: 10, color: C.textSoft, marginTop: 2 }}>
                        {b.count} {b.countLabel}
                      </div>
                    )}
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Detail-Banner wenn Bereich ausgewählt */}
        {aktivBereich && (
          <div style={{
            padding: "12px 16px", borderRadius: 10, marginBottom: 24,
            background: C.bgPanel, border: `1.5px solid ${aktivBereich.farbe}44`,
            display: "flex", alignItems: "center", justifyContent: "space-between",
            animation: "fadeSlideIn 0.2s ease",
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{
                width: 34, height: 34, borderRadius: 9,
                background: aktivBereich.farbe + "20",
                border: `1.5px solid ${aktivBereich.farbe}44`,
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>
                <Icon name={aktivBereich.icon} size={16} color={aktivBereich.farbe} />
              </div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: C.text }}>{aktivBereich.label}</div>
                <div style={{ fontSize: 11, color: C.textSoft, marginTop: 1 }}>{aktivBereich.beschreibung}</div>
              </div>
            </div>
            <button style={{
              display: "flex", alignItems: "center", gap: 6,
              padding: "7px 16px", borderRadius: 7,
              background: aktivBereich.farbe, border: "none",
              color: "#fff", fontSize: 12, fontWeight: 600,
              cursor: "pointer", fontFamily: "inherit",
              transition: "opacity 0.15s",
            }}
              onMouseEnter={e => e.currentTarget.style.opacity = "0.9"}
              onMouseLeave={e => e.currentTarget.style.opacity = "1"}
            >
              Öffnen
              <Icon name="arrow" size={13} color="#fff" />
            </button>
          </div>
        )}

        {/* Letzte Aktivität */}
        <div>
          <p style={{ margin: "0 0 12px", fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase" }}>
            Letzte Aktivität
          </p>
          <div style={{ background: C.bgPanel, border: `1px solid ${C.border}`, borderRadius: 10, overflow: "hidden" }}>
            {LETZTE_AKTIVITAET.map((a, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", gap: 12,
                padding: "10px 16px",
                borderBottom: i < LETZTE_AKTIVITAET.length - 1 ? `1px solid ${C.border}` : "none",
                cursor: "pointer", transition: "background 0.15s",
              }}
                onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
                onMouseLeave={e => e.currentTarget.style.background = "transparent"}
              >
                <div style={{ width: 7, height: 7, borderRadius: "50%", background: a.farbe, flexShrink: 0 }} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <span style={{ fontSize: 13, color: C.text }}>{a.text}</span>
                  <span style={{ fontSize: 11, color: C.textSoft, marginLeft: 6 }}>· {a.bereich}</span>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
                  <Icon name="clock" size={11} color={C.textSoft} />
                  <span style={{ fontSize: 11, color: C.textSoft }}>{a.zeit}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <style>{`
        * { box-sizing: border-box; }
        @keyframes fadeSlideIn { from { opacity:0; transform:translateY(6px) } to { opacity:1; transform:translateY(0) } }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
      `}</style>
    </div>
  );
}
