import { useState } from "react";

// ── THEMES ────────────────────────────────────────────────────────────────────
const THEMES = {
  light: {
    bg: "#f7f7f5", bgPanel: "#ffffff", bgHover: "#f0f0ed", bgActive: "#eeecea",
    border: "#e4e4e0", borderStrong: "#d0d0ca",
    text: "#1a1a18", textMid: "#6b6b66", textSoft: "#9f9f98",
    accent: "#2f6feb", accentSoft: "#eef3fd",
    green: "#1a7f4b", greenSoft: "#eaf4ee",
    amber: "#b45309", amberSoft: "#fdf6ec",
    red: "#c93a3a", redSoft: "#fdf0f0",
    overlay: "rgba(0,0,0,0.2)",
  },
  dark: {
    bg: "#111110", bgPanel: "#1a1a18", bgHover: "#232320", bgActive: "#2a2a27",
    border: "#2e2e2b", borderStrong: "#3d3d39",
    text: "#edede8", textMid: "#8a8a82", textSoft: "#5a5a54",
    accent: "#4f8ef7", accentSoft: "#1a2540",
    green: "#34c471", greenSoft: "#0f2a1c",
    amber: "#d4890a", amberSoft: "#2a1f08",
    red: "#e05555", redSoft: "#2a1212",
    overlay: "rgba(0,0,0,0.5)",
  },
};

const TYP_CFG = {
  NPC:        { color: "#2f6feb", bg_l: "#eef3fd", bg_d: "#1a2540", dot: "#2f6feb" },
  Ort:        { color: "#1a7f4b", bg_l: "#eaf4ee", bg_d: "#0f2a1c", dot: "#1a7f4b" },
  Lore:       { color: "#7c3aed", bg_l: "#f3effe", bg_d: "#1e1330", dot: "#7c3aed" },
  Fraktion:   { color: "#b45309", bg_l: "#fdf6ec", bg_d: "#2a1f08", dot: "#b45309" },
  Magie:      { color: "#be185d", bg_l: "#fdf0f7", bg_d: "#2a0f1c", dot: "#be185d" },
  Geschichte: { color: "#0891b2", bg_l: "#ecfbff", bg_d: "#0a1f28", dot: "#0891b2" },
  Gegenstand: { color: "#065f46", bg_l: "#ecfdf5", bg_d: "#071a14", dot: "#065f46" },
  Quest:      { color: "#c93a3a", bg_l: "#fdf0f0", bg_d: "#2a1212", dot: "#c93a3a" },
  Kreatur:    { color: "#6b6b66", bg_l: "#f0f0ed", bg_d: "#232320", dot: "#6b6b66" },
};

const TYPEN = Object.keys(TYP_CFG);

const initEintraege = [
  { id: 1, titel: "Geschichten aus Phandalin", typ: "Lore", scope: "Global", tags: ["Lore", "Geschichte"], inhalt: "W6 Geschichte\n1\n2", datum: "25.3.2026", standort: null },
  { id: 2, titel: "Rathaus", typ: "Ort", scope: "Global", tags: ["Ort", "Stadt", "Phandalin"], inhalt: "Das Rathaus von Phandalin ist das Zentrum der Stadtregierung. Hier trifft der Stadtrat zusammen.", datum: "20.3.2026", standort: "Phandalin" },
  { id: 3, titel: "Elmar Barthen", typ: "NPC", scope: "Global", tags: ["NPC", "Händler"], inhalt: "Elmar Barthen ist ein freundlicher Händler in Phandalin. Er betreibt Barthens Proviant.", datum: "18.3.2026", standort: "Phandalin" },
  { id: 4, titel: "Schwarzspinnen-Bande", typ: "Fraktion", scope: "Global", tags: ["Fraktion", "Antagonisten"], inhalt: "Eine gefährliche Verbrecherorganisation die die Region terrorisiert.", datum: "15.3.2026", standort: null },
  { id: 5, titel: "Gasthaus Steinhügel", typ: "Ort", scope: "Global", tags: ["Ort", "Taverne", "Phandalin"], inhalt: "Das gemütlichste Gasthaus in Phandalin. Hier kann man sich ausruhen und Informationen sammeln.", datum: "14.3.2026", standort: "Phandalin" },
  { id: 6, titel: "Schwertküste", typ: "Ort", scope: "Global", tags: ["Ort", "Region"], inhalt: "Eine ausgedehnte Küstenregion im Westen Faeruns.", datum: "10.3.2026", standort: null },
];

// ── ICONS ─────────────────────────────────────────────────────────────────────
const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    back: "M10 3L5 8l5 5",
    search: "M7 3a4 4 0 100 8 4 4 0 000-8zM13 13l-3-3",
    plus: "M8 3v10M3 8h10",
    close: "M4 4l8 8M12 4l-8 8",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
    chevronDown: "M4 6l4 4 4-4",
    chevronUp: "M4 10l4-4 4 4",
    edit: "M11 3l2 2-8 8H3v-2l8-8z",
    trash: "M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9",
    tag: "M2 8l6-6h5a1 1 0 011 1v5L8 14a1 1 0 01-1.4 0L2 8.6A1 1 0 012 8zm9-3a1 1 0 100 2 1 1 0 000-2z",
    location: "M8 2a4 4 0 014 4c0 3-4 8-4 8S4 9 4 6a4 4 0 014-4zm0 3a1 1 0 100 2 1 1 0 000-2z",
    calendar: "M3 5h10a1 1 0 011 1v8a1 1 0 01-1 1H3a1 1 0 01-1-1V6a1 1 0 011-1zm0 0V3m10 2V3",
    book: "M3 3h8l2 2v10H3V3zm4 5h4M7 11h4",
    globe: "M8 2a6 6 0 100 12A6 6 0 008 2zM2 8h12M8 2c-2 2-3 4-3 6s1 4 3 6M8 2c2 2 3 4 3 6s-1 4-3 6",
    dots: "M4 8a1 1 0 100-2 1 1 0 000 2zm4 0a1 1 0 100-2 1 1 0 000 2zm4 0a1 1 0 100-2 1 1 0 000 2z",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} />
    </svg>
  );
};

// ── TYP BADGE ─────────────────────────────────────────────────────────────────
const TypBadge = ({ typ, isDark, small }) => {
  const cfg = TYP_CFG[typ] || TYP_CFG["Lore"];
  return (
    <span style={{
      fontSize: small ? 10 : 11, fontWeight: 500,
      color: cfg.color, background: isDark ? cfg.bg_d : cfg.bg_l,
      padding: small ? "1px 6px" : "2px 8px", borderRadius: 4,
      display: "inline-flex", alignItems: "center", gap: 4,
    }}>
      <span style={{ width: 5, height: 5, borderRadius: "50%", background: cfg.dot, display: "inline-block", flexShrink: 0 }} />
      {typ}
    </span>
  );
};

// ── WIKI KARTE ────────────────────────────────────────────────────────────────
const WikiKarte = ({ eintrag, isDark, C, onEdit, expanded, onToggle }) => {
  const cfg = TYP_CFG[eintrag.typ] || TYP_CFG["Lore"];
  const [hovered, setHovered] = useState(false);

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: C.bgPanel,
        border: `1px solid ${expanded ? C.borderStrong : hovered ? C.borderStrong : C.border}`,
        borderRadius: 10, overflow: "hidden",
        transition: "all 0.2s ease",
        boxShadow: expanded
          ? (isDark ? "0 8px 24px rgba(0,0,0,0.4)" : "0 8px 24px rgba(0,0,0,0.08)")
          : "none",
        gridColumn: expanded ? "span 2" : "span 1",
      }}
    >
      {/* Farbstreifen */}
      <div style={{ height: 3, background: cfg.dot }} />

      {/* Haupt-Inhalt */}
      <div style={{ padding: "12px 14px" }}>
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 8 }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 5 }}>
              <TypBadge typ={eintrag.typ} isDark={isDark} small />
              <span style={{ fontSize: 10, color: C.textSoft }}>{eintrag.scope}</span>
            </div>
            <div style={{ fontSize: 14, fontWeight: 600, color: C.text, lineHeight: 1.2 }}>
              {eintrag.titel}
            </div>
          </div>
          <div style={{ display: "flex", gap: 3, flexShrink: 0, marginLeft: 8 }}>
            {hovered && (
              <button onClick={e => { e.stopPropagation(); onEdit(eintrag); }} style={{
                width: 26, height: 26, borderRadius: 5, border: "none",
                background: C.bgHover, cursor: "pointer",
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>
                <Icon name="edit" size={12} color={C.textSoft} />
              </button>
            )}
            <button onClick={onToggle} style={{
              width: 26, height: 26, borderRadius: 5, border: "none",
              background: expanded ? C.bgActive : "transparent",
              cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center",
              transition: "background 0.15s",
            }}>
              <Icon name={expanded ? "chevronUp" : "chevronDown"} size={12} color={C.textSoft} />
            </button>
          </div>
        </div>

        {/* Vorschau Text */}
        {!expanded && (
          <p style={{
            margin: "0 0 8px", fontSize: 12, color: C.textMid, lineHeight: 1.5,
            display: "-webkit-box", WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical", overflow: "hidden",
          }}>
            {eintrag.inhalt}
          </p>
        )}

        {/* Tags */}
        <div style={{ display: "flex", gap: 4, flexWrap: "wrap", marginBottom: 8 }}>
          {eintrag.tags.map(t => (
            <span key={t} style={{
              fontSize: 10, color: C.textSoft,
              background: C.bgHover, border: `1px solid ${C.border}`,
              padding: "1px 6px", borderRadius: 4,
            }}>{t}</span>
          ))}
        </div>

        {/* Meta */}
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <Icon name="calendar" size={11} color={C.textSoft} />
            <span style={{ fontSize: 10, color: C.textSoft }}>{eintrag.datum}</span>
          </div>
          {eintrag.standort && (
            <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
              <Icon name="location" size={11} color={C.textSoft} />
              <span style={{ fontSize: 10, color: C.textSoft }}>{eintrag.standort}</span>
            </div>
          )}
        </div>
      </div>

      {/* Aufgeklappter Inhalt */}
      {expanded && (
        <div style={{
          borderTop: `1px solid ${C.border}`,
          padding: "14px 14px",
          background: isDark ? "rgba(0,0,0,0.15)" : "rgba(0,0,0,0.015)",
          display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16,
        }}>
          <div>
            <div style={{ fontSize: 10, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 8 }}>Inhalt</div>
            <p style={{ margin: 0, fontSize: 13, color: C.textMid, lineHeight: 1.6, whiteSpace: "pre-wrap" }}>
              {eintrag.inhalt}
            </p>
          </div>
          <div>
            <div style={{ fontSize: 10, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 8 }}>Details</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 11, color: C.textSoft, minWidth: 60 }}>Typ</span>
                <TypBadge typ={eintrag.typ} isDark={isDark} small />
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 11, color: C.textSoft, minWidth: 60 }}>Scope</span>
                <span style={{ fontSize: 11, color: C.textMid }}>{eintrag.scope}</span>
              </div>
              {eintrag.standort && (
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  <span style={{ fontSize: 11, color: C.textSoft, minWidth: 60 }}>Standort</span>
                  <span style={{ fontSize: 11, color: C.textMid }}>{eintrag.standort}</span>
                </div>
              )}
              <div style={{ display: "flex", gap: 8, alignItems: "flex-start" }}>
                <span style={{ fontSize: 11, color: C.textSoft, minWidth: 60 }}>Tags</span>
                <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                  {eintrag.tags.map(t => (
                    <span key={t} style={{
                      fontSize: 10, color: C.textSoft,
                      background: C.bgHover, border: `1px solid ${C.border}`,
                      padding: "1px 6px", borderRadius: 4,
                    }}>{t}</span>
                  ))}
                </div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 6, marginTop: 16 }}>
              <button onClick={() => onEdit(eintrag)} style={{
                flex: 1, padding: "7px", borderRadius: 6,
                background: C.accent, border: "none",
                color: "#fff", fontSize: 11, fontWeight: 500,
                cursor: "pointer", fontFamily: "inherit",
                display: "flex", alignItems: "center", justifyContent: "center", gap: 4,
              }}>
                <Icon name="edit" size={11} color="#fff" />
                Bearbeiten
              </button>
              <button style={{
                padding: "7px 10px", borderRadius: 6,
                background: "transparent", border: `1px solid ${C.border}`,
                color: C.red, fontSize: 11,
                cursor: "pointer", fontFamily: "inherit",
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>
                <Icon name="trash" size={11} color={C.red} />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// ── EDITOR SEITENLEISTE ────────────────────────────────────────────────────────
const EditorLeiste = ({ eintrag, C, isDark, onClose, onSave }) => {
  const isNeu = !eintrag?.id;
  const [form, setForm] = useState({
    titel: eintrag?.titel || "",
    typ: eintrag?.typ || "Lore",
    scope: eintrag?.scope || "Global",
    inhalt: eintrag?.inhalt || "",
    tags: eintrag?.tags || [],
    standort: eintrag?.standort || "",
    neuerTag: "",
  });
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const handleTagAdd = () => {
    if (form.neuerTag.trim()) {
      set("tags", [...form.tags, form.neuerTag.trim()]);
      set("neuerTag", "");
    }
  };

  const inputStyle = {
    width: "100%", padding: "8px 10px",
    background: C.bgHover, border: `1px solid ${C.border}`,
    borderRadius: 7, fontSize: 13, color: C.text,
    fontFamily: "inherit", outline: "none", boxSizing: "border-box",
  };

  const Label = ({ children }) => (
    <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>
      {children}
    </div>
  );

  return (
    <>
      {/* Backdrop */}
      <div onClick={onClose} style={{
        position: "fixed", inset: 0, zIndex: 20,
        background: C.overlay,
        backdropFilter: "blur(2px)",
        animation: "fadeIn 0.2s ease",
      }} />

      {/* Leiste */}
      <div style={{
        position: "fixed", top: 0, right: 0, bottom: 0,
        width: "min(420px, 90vw)", zIndex: 30,
        background: C.bgPanel, borderLeft: `1px solid ${C.border}`,
        display: "flex", flexDirection: "column",
        boxShadow: isDark ? "-8px 0 32px rgba(0,0,0,0.5)" : "-8px 0 32px rgba(0,0,0,0.1)",
        animation: "slideInRight 0.25s cubic-bezier(0.34,1.2,0.64,1)",
      }}>

        {/* Header */}
        <div style={{
          padding: "14px 16px", borderBottom: `1px solid ${C.border}`,
          display: "flex", alignItems: "center", justifyContent: "space-between",
          flexShrink: 0,
        }}>
          <h2 style={{ margin: 0, fontSize: 15, fontWeight: 600, color: C.text }}>
            {isNeu ? "Neuer Wiki-Eintrag" : "Eintrag bearbeiten"}
          </h2>
          <button onClick={onClose} style={{
            width: 28, height: 28, borderRadius: 6, background: "transparent",
            border: "none", cursor: "pointer",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          ><Icon name="close" size={14} color={C.textMid} /></button>
        </div>

        {/* Body */}
        <div style={{ flex: 1, overflow: "auto", padding: "16px" }}>

          {/* Titel */}
          <div style={{ marginBottom: 14 }}>
            <Label>Titel *</Label>
            <input value={form.titel} onChange={e => set("titel", e.target.value)}
              placeholder="Titel des Eintrags" style={inputStyle}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
          </div>

          {/* Typ */}
          <div style={{ marginBottom: 14 }}>
            <Label>Eintragstyp</Label>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
              {TYPEN.map(t => {
                const cfg = TYP_CFG[t];
                const aktiv = form.typ === t;
                return (
                  <button key={t} onClick={() => set("typ", t)} style={{
                    padding: "4px 10px", borderRadius: 6,
                    background: aktiv ? (isDark ? cfg.bg_d : cfg.bg_l) : "transparent",
                    border: `1px solid ${aktiv ? cfg.dot : C.border}`,
                    color: aktiv ? cfg.color : C.textMid,
                    fontSize: 11, fontWeight: aktiv ? 500 : 400,
                    cursor: "pointer", fontFamily: "inherit",
                    transition: "all 0.15s",
                  }}>{t}</button>
                );
              })}
            </div>
          </div>

          {/* Scope */}
          <div style={{ marginBottom: 14 }}>
            <Label>Scope</Label>
            <div style={{ display: "flex", gap: 5 }}>
              {["Global", "Kampagne"].map(s => (
                <button key={s} onClick={() => set("scope", s)} style={{
                  padding: "5px 12px", borderRadius: 6,
                  background: form.scope === s ? C.accent : "transparent",
                  border: `1px solid ${form.scope === s ? C.accent : C.border}`,
                  color: form.scope === s ? "#fff" : C.textMid,
                  fontSize: 12, cursor: "pointer", fontFamily: "inherit",
                  transition: "all 0.15s",
                }}>{s}</button>
              ))}
            </div>
          </div>

          {/* Inhalt */}
          <div style={{ marginBottom: 14 }}>
            <Label>Inhalt *</Label>
            <textarea value={form.inhalt} onChange={e => set("inhalt", e.target.value)}
              placeholder="Beschreibung des Wiki-Eintrags..." rows={6}
              style={{ ...inputStyle, resize: "vertical", lineHeight: 1.5 }}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
          </div>

          {/* Tags */}
          <div style={{ marginBottom: 14 }}>
            <Label>Tags</Label>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 5, marginBottom: 8 }}>
              {form.tags.map((t, i) => (
                <span key={i} style={{
                  display: "flex", alignItems: "center", gap: 4,
                  fontSize: 11, color: C.textMid,
                  background: C.bgHover, border: `1px solid ${C.border}`,
                  padding: "2px 8px", borderRadius: 5,
                }}>
                  {t}
                  <button onClick={() => set("tags", form.tags.filter((_, j) => j !== i))} style={{
                    background: "none", border: "none", cursor: "pointer",
                    color: C.textSoft, padding: 0, lineHeight: 1,
                    display: "flex", alignItems: "center",
                  }}>×</button>
                </span>
              ))}
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <input value={form.neuerTag} onChange={e => set("neuerTag", e.target.value)}
                placeholder="Neuer Tag" style={{ ...inputStyle, flex: 1 }}
                onKeyDown={e => e.key === "Enter" && handleTagAdd()}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
              <button onClick={handleTagAdd} style={{
                width: 36, height: 36, borderRadius: 7,
                background: C.bgHover, border: `1px solid ${C.border}`,
                cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
              }}>
                <Icon name="plus" size={14} color={C.textMid} />
              </button>
            </div>
          </div>

          {/* Standort */}
          <div style={{ marginBottom: 14 }}>
            <Label>Standort (Optional)</Label>
            <input value={form.standort} onChange={e => set("standort", e.target.value)}
              placeholder="z.B. Phandalin" style={inputStyle}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
            <div style={{ fontSize: 11, color: C.textSoft, marginTop: 4 }}>
              Für zukünftige Kartenintegration
            </div>
          </div>
        </div>

        {/* Footer */}
        <div style={{
          padding: "12px 16px", borderTop: `1px solid ${C.border}`,
          display: "flex", gap: 8, flexShrink: 0,
        }}>
          <button onClick={onClose} style={{
            flex: 1, padding: "9px", borderRadius: 7,
            background: "transparent", border: `1px solid ${C.border}`,
            color: C.textMid, fontSize: 13, fontWeight: 500,
            cursor: "pointer", fontFamily: "inherit",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          >Abbrechen</button>
          <button onClick={() => { onSave(form); onClose(); }} style={{
            flex: 2, padding: "9px", borderRadius: 7,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 13, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
            display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
          }}>
            <Icon name="save" size={13} color="#fff" />
            {isNeu ? "Erstellen" : "Speichern"}
          </button>
        </div>
      </div>
    </>
  );
};

// ── HAUPT ─────────────────────────────────────────────────────────────────────
export default function LoreKeeper() {
  const [isDark, setIsDark] = useState(false);
  const [eintraege, setEintraege] = useState(initEintraege);
  const [suche, setSuche] = useState("");
  const [aktivTyp, setAktivTyp] = useState("Alle");
  const [expandedId, setExpandedId] = useState(null);
  const [editor, setEditor] = useState(null); // null | eintrag | "neu"

  const C = THEMES[isDark ? "dark" : "light"];

  const typCounts = TYPEN.reduce((acc, t) => {
    acc[t] = eintraege.filter(e => e.typ === t).length;
    return acc;
  }, {});

  const gefiltert = eintraege.filter(e => {
    const matchSuche = e.titel.toLowerCase().includes(suche.toLowerCase()) ||
      e.inhalt.toLowerCase().includes(suche.toLowerCase());
    const matchTyp = aktivTyp === "Alle" || e.typ === aktivTyp;
    return matchSuche && matchTyp;
  });

  const handleSave = (form) => {
    if (editor === "neu") {
      setEintraege(prev => [...prev, {
        ...form, id: Date.now(),
        datum: new Date().toLocaleDateString("de-DE"),
      }]);
    } else {
      setEintraege(prev => prev.map(e => e.id === editor.id ? { ...e, ...form } : e));
    }
  };

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
        padding: "0 20px", position: "sticky", top: 0, zIndex: 10,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <button style={{
            width: 30, height: 30, borderRadius: 7, background: "transparent",
            border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          ><Icon name="back" size={16} color={C.textMid} /></button>
          <div style={{ width: 1, height: 18, background: C.border }} />
          <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
            <Icon name="book" size={16} color={C.accent} />
            <span style={{ fontSize: 14, fontWeight: 600 }}>Lore Keeper</span>
          </div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{ fontSize: 12, color: C.textSoft }}>{gefiltert.length} Einträge</span>
          <button onClick={() => setIsDark(d => !d)} style={{
            width: 32, height: 32, borderRadius: 7,
            background: C.bgHover, border: `1px solid ${C.border}`,
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
          </button>
        </div>
      </div>

      {/* INHALT */}
      <div style={{ maxWidth: 1000, margin: "0 auto", padding: "20px 20px 80px" }}>

        {/* Suche */}
        <div style={{ position: "relative", marginBottom: 14 }}>
          <div style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)" }}>
            <Icon name="search" size={14} color={C.textSoft} />
          </div>
          <input value={suche} onChange={e => setSuche(e.target.value)}
            placeholder="Wiki-Einträge durchsuchen..."
            style={{
              width: "100%", padding: "9px 12px 9px 32px",
              background: C.bgPanel, border: `1px solid ${C.border}`,
              borderRadius: 8, fontSize: 13, color: C.text,
              outline: "none", fontFamily: "inherit", boxSizing: "border-box",
            }}
            onFocus={e => e.target.style.borderColor = C.accent}
            onBlur={e => e.target.style.borderColor = C.border} />
        </div>

        {/* Typ Filter */}
        <div style={{ display: "flex", gap: 5, flexWrap: "wrap", marginBottom: 20 }}>
          <button onClick={() => setAktivTyp("Alle")} style={{
            padding: "4px 12px", borderRadius: 6,
            background: aktivTyp === "Alle" ? C.accent : C.bgPanel,
            border: `1px solid ${aktivTyp === "Alle" ? C.accent : C.border}`,
            color: aktivTyp === "Alle" ? "#fff" : C.textMid,
            fontSize: 12, cursor: "pointer", fontFamily: "inherit",
            display: "flex", alignItems: "center", gap: 5,
          }}>
            Alle <span style={{ fontSize: 10, opacity: 0.8 }}>{eintraege.length}</span>
          </button>
          {TYPEN.map(t => {
            const cfg = TYP_CFG[t];
            const aktiv = aktivTyp === t;
            const count = typCounts[t] || 0;
            if (count === 0) return null;
            return (
              <button key={t} onClick={() => setAktivTyp(t)} style={{
                padding: "4px 10px", borderRadius: 6,
                background: aktiv ? (isDark ? cfg.bg_d : cfg.bg_l) : C.bgPanel,
                border: `1px solid ${aktiv ? cfg.dot : C.border}`,
                color: aktiv ? cfg.color : C.textMid,
                fontSize: 12, cursor: "pointer", fontFamily: "inherit",
                display: "flex", alignItems: "center", gap: 5,
                transition: "all 0.15s",
              }}>
                <span style={{ width: 5, height: 5, borderRadius: "50%", background: cfg.dot }} />
                {t}
                <span style={{ fontSize: 10, opacity: 0.7 }}>{count}</span>
              </button>
            );
          })}
        </div>

        {/* Karten Grid */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(2, 1fr)",
          gap: 10,
          alignItems: "start",
        }}>
          {gefiltert.map(e => (
            <WikiKarte
              key={e.id} eintrag={e} isDark={isDark} C={C}
              onEdit={e => setEditor(e)}
              expanded={expandedId === e.id}
              onToggle={() => setExpandedId(expandedId === e.id ? null : e.id)}
            />
          ))}

          {gefiltert.length === 0 && (
            <div style={{
              gridColumn: "span 2", textAlign: "center",
              padding: "50px 20px", color: C.textSoft,
            }}>
              <Icon name="book" size={32} color={C.border} />
              <div style={{ marginTop: 12, fontSize: 14 }}>Keine Einträge gefunden</div>
            </div>
          )}
        </div>
      </div>

      {/* FAB */}
      <button onClick={() => setEditor("neu")} style={{
        position: "fixed", bottom: 24, right: 24,
        display: "flex", alignItems: "center", gap: 8,
        padding: "12px 20px", borderRadius: 10,
        background: C.accent, border: "none",
        color: "#fff", fontSize: 13, fontWeight: 600,
        cursor: "pointer", fontFamily: "inherit",
        boxShadow: `0 4px 16px ${C.accent}55`, zIndex: 10,
        transition: "transform 0.2s",
      }}
        onMouseEnter={e => e.currentTarget.style.transform = "translateY(-1px)"}
        onMouseLeave={e => e.currentTarget.style.transform = "translateY(0)"}
      >
        <Icon name="plus" size={14} color="#fff" />
        Neuer Eintrag
      </button>

      {/* EDITOR SEITENLEISTE */}
      {editor && (
        <EditorLeiste
          eintrag={editor === "neu" ? null : editor}
          C={C} isDark={isDark}
          onClose={() => setEditor(null)}
          onSave={handleSave}
        />
      )}

      <style>{`
        * { box-sizing: border-box; }
        input::placeholder, textarea::placeholder { color: ${C.textSoft}; }
        textarea { font-family: inherit; }
        @keyframes fadeIn { from { opacity:0 } to { opacity:1 } }
        @keyframes slideInRight { from { transform:translateX(100%) } to { transform:translateX(0) } }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
      `}</style>
    </div>
  );
}
