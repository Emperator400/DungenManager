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
  },
  dark: {
    bg: "#111110", bgPanel: "#1a1a18", bgHover: "#232320", bgActive: "#2a2a27",
    border: "#2e2e2b", borderStrong: "#3d3d39",
    text: "#edede8", textMid: "#8a8a82", textSoft: "#5a5a54",
    accent: "#4f8ef7", accentSoft: "#1a2540",
    green: "#34c471", greenSoft: "#0f2a1c",
    amber: "#d4890a", amberSoft: "#2a1f08",
    red: "#e05555", redSoft: "#2a1212",
  },
};

const TYPEN_CFG = {
  Waffe:          { color: "#c93a3a", bg_l: "#fdf0f0", bg_d: "#2a1212", dot: "#c93a3a" },
  Rüstung:        { color: "#1B4F72", bg_l: "#eef3fd", bg_d: "#0a1828", dot: "#2f6feb" },
  Schild:         { color: "#1a7f4b", bg_l: "#eaf4ee", bg_d: "#0f2a1c", dot: "#1a7f4b" },
  Verbrauchsgut:  { color: "#b45309", bg_l: "#fdf6ec", bg_d: "#2a1f08", dot: "#b45309" },
  Werkzeug:       { color: "#6b6b66", bg_l: "#f0f0ed", bg_d: "#232320", dot: "#6b6b66" },
  Material:       { color: "#065f46", bg_l: "#ecfdf5", bg_d: "#071a14", dot: "#065f46" },
  Komponente:     { color: "#7c3aed", bg_l: "#f3effe", bg_d: "#1e1330", dot: "#7c3aed" },
  "Magisches Item": { color: "#be185d", bg_l: "#fdf0f7", bg_d: "#2a0f1c", dot: "#be185d" },
  Schriftrolle:   { color: "#0891b2", bg_l: "#ecfbff", bg_d: "#0a1f28", dot: "#0891b2" },
  Trank:          { color: "#7c3aed", bg_l: "#f3effe", bg_d: "#1e1330", dot: "#7c3aed" },
  Schatz:         { color: "#d4890a", bg_l: "#fdf6ec", bg_d: "#2a1f08", dot: "#d4890a" },
  Währung:        { color: "#d4890a", bg_l: "#fdf6ec", bg_d: "#2a1f08", dot: "#d4890a" },
  Ausrüstung:     { color: "#2f6feb", bg_l: "#eef3fd", bg_d: "#1a2540", dot: "#2f6feb" },
  "Spruch als Waffe": { color: "#be185d", bg_l: "#fdf0f7", bg_d: "#2a0f1c", dot: "#be185d" },
};

const TYPEN = Object.keys(TYPEN_CFG);

const SCHADENSTYPEN = ["Hieb","Stich","Wucht","Feuer","Kälte","Blitz","Säure","Gift","Nekrotisch","Strahlend","Psychisch","Donnerschlag","Kraft","Nekrotisch"];

const initItems = [
  { id: 1, name: "Langschwert", typ: "Waffe", beschreibung: "Ein klassisches einhändiges Schwert mit ausgewogener Klinge.", wert: 15, gewicht: 3, schadenswurf: "1d8", schadenstyp: "Hieb", attunement: false, haltbarkeit: false, eigenschaften: "Vielseitig (1d10)" },
  { id: 2, name: "Kettenhemd", typ: "Rüstung", beschreibung: "Mittelschwere Rüstung aus miteinander verwobenen Metallringen.", wert: 75, gewicht: 55, schadenswurf: "", schadenstyp: "", attunement: false, haltbarkeit: false, eigenschaften: "AC 16, Nachteil auf Heimlichkeit" },
  { id: 3, name: "Heiltrank", typ: "Trank", beschreibung: "Stellt 2d4+2 Trefferpunkte wieder her.", wert: 50, gewicht: 0.5, schadenswurf: "2d4+2", schadenstyp: "", attunement: false, haltbarkeit: false, eigenschaften: "" },
  { id: 4, name: "Flammenzunge", typ: "Magisches Item", beschreibung: "Eine magische Klinge die Feuer entfacht wenn das Kommandowort gesprochen wird.", wert: 0, gewicht: 2, schadenswurf: "1d6", schadenstyp: "Feuer", attunement: true, haltbarkeit: false, eigenschaften: "+2d6 Feuerschaden" },
  { id: 5, name: "Enterhaken", typ: "Werkzeug", beschreibung: "Nützlich zum Klettern und für Diebstahlsaktionen.", wert: 2, gewicht: 4, schadenswurf: "", schadenstyp: "", attunement: false, haltbarkeit: false, eigenschaften: "" },
];

// ── ICONS ─────────────────────────────────────────────────────────────────────
const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    back: "M10 3L5 8l5 5",
    search: "M7 3a4 4 0 100 8 4 4 0 000-8zM13 13l-3-3",
    plus: "M8 3v10M3 8h10",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
    trash: "M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9",
    edit: "M11 3l2 2-8 8H3v-2l8-8z",
    chevronDown: "M4 6l4 4 4-4",
    check: "M4 8l3 3 5-5",
    sword: "M3 13l8-8m0 0l2-2 2 2-2 2M5 11l-2 2",
    bag: "M5 6V4a3 3 0 016 0v2h2a1 1 0 011 1v8a1 1 0 01-1 1H3a1 1 0 01-1-1V7a1 1 0 011-1h2z",
    coin: "M8 3a5 5 0 100 10A5 5 0 008 3z",
    weight: "M8 3a2 2 0 100 4 2 2 0 000-4zM4 7l-2 8h12l-2-8H4z",
    star: "M8 2l1.8 3.6L14 6.3l-3 2.9.7 4.1L8 11.2l-3.7 2.1.7-4.1-3-2.9 4.2-.7z",
    zap: "M9 2L4 9h5l-2 5 7-8H9z",
    shield: "M8 2l5 2v5c0 3-5 5-5 5S3 12 3 9V4l5-2z",
    close: "M4 4l8 8M12 4l-8 8",
    filter: "M2 4h12M5 8h6M8 12h0",
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
  const cfg = TYPEN_CFG[typ] || TYPEN_CFG["Ausrüstung"];
  return (
    <span style={{
      fontSize: small ? 10 : 11, fontWeight: 500,
      color: cfg.color, background: isDark ? cfg.bg_d : cfg.bg_l,
      padding: small ? "1px 6px" : "2px 8px", borderRadius: 4,
      display: "inline-flex", alignItems: "center", gap: 4,
    }}>
      <span style={{ width: 5, height: 5, borderRadius: "50%", background: cfg.dot, flexShrink: 0 }} />
      {typ}
    </span>
  );
};

// ── ITEM EDITOR SEITE ─────────────────────────────────────────────────────────
const ItemEditor = ({ item, C, isDark, onBack, onSave, onDelete }) => {
  const isNeu = !item?.id;
  const [form, setForm] = useState({
    name: item?.name || "",
    typ: item?.typ || "Waffe",
    beschreibung: item?.beschreibung || "",
    wert: item?.wert ?? 0,
    gewicht: item?.gewicht ?? 0,
    schadenswurf: item?.schadenswurf || "",
    schadenstyp: item?.schadenstyp || "",
    attunement: item?.attunement || false,
    haltbarkeit: item?.haltbarkeit || false,
    eigenschaften: item?.eigenschaften || "",
  });
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const cfg = TYPEN_CFG[form.typ] || TYPEN_CFG["Ausrüstung"];

  const inputStyle = {
    width: "100%", padding: "9px 12px",
    background: C.bgHover, border: `1px solid ${C.border}`,
    borderRadius: 7, fontSize: 13, color: C.text,
    fontFamily: "inherit", outline: "none", boxSizing: "border-box",
  };

  const Label = ({ children }) => (
    <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>
      {children}
    </div>
  );

  const Card = ({ children, title, style = {} }) => (
    <div style={{ background: C.bgPanel, border: `1px solid ${C.border}`, borderRadius: 10, padding: "14px 16px", marginBottom: 12, ...style }}>
      {title && <div style={{ fontSize: 12, fontWeight: 600, color: C.textMid, letterSpacing: 0.3, textTransform: "uppercase", marginBottom: 12 }}>{title}</div>}
      {children}
    </div>
  );

  return (
    <div style={{
      fontFamily: "-apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif",
      background: C.bg, minHeight: "100vh",
      color: C.text, fontSize: 13,
    }}>
      {/* Topbar */}
      <div style={{
        height: 48, background: C.bgPanel, borderBottom: `1px solid ${C.border}`,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 20px", position: "sticky", top: 0, zIndex: 10,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <button onClick={onBack} style={{
            width: 30, height: 30, borderRadius: 7, background: "transparent",
            border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          ><Icon name="back" size={16} color={C.textMid} /></button>
          <div style={{ width: 1, height: 18, background: C.border }} />
          <div>
            <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{isNeu ? "Neues Item" : "Item bearbeiten"}</div>
            {!isNeu && <div style={{ fontSize: 10, color: C.textSoft }}>{item.name}</div>}
          </div>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          {!isNeu && (
            <button onClick={() => { if (confirm("Item wirklich löschen?")) { onDelete(item.id); onBack(); } }} style={{
              padding: "7px 12px", borderRadius: 7,
              background: C.redSoft, border: `1px solid ${C.red}33`,
              color: C.red, fontSize: 12, fontWeight: 500,
              cursor: "pointer", fontFamily: "inherit",
              display: "flex", alignItems: "center", gap: 5,
            }}>
              <Icon name="trash" size={12} color={C.red} />
              Löschen
            </button>
          )}
          <button onClick={() => { onSave(form); onBack(); }} style={{
            padding: "7px 16px", borderRadius: 7,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 12, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
            display: "flex", alignItems: "center", gap: 5,
          }}>
            <Icon name="save" size={12} color="#fff" />
            Speichern
          </button>
        </div>
      </div>

      {/* Inhalt */}
      <div style={{ maxWidth: 800, margin: "0 auto", padding: "20px 24px 60px" }}>

        {/* Typ Vorschau Header */}
        <div style={{
          display: "flex", alignItems: "center", gap: 14,
          padding: "14px 16px", borderRadius: 10, marginBottom: 16,
          background: isDark ? cfg.bg_d : cfg.bg_l,
          border: `1px solid ${cfg.dot}33`,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 10,
            background: cfg.dot + "20", border: `1.5px solid ${cfg.dot}44`,
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <span style={{ fontSize: 18, fontWeight: 700, color: cfg.dot }}>{form.name?.[0] || "?"}</span>
          </div>
          <div>
            <div style={{ fontSize: 16, fontWeight: 600, color: C.text }}>{form.name || "Item Name"}</div>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 3 }}>
              <TypBadge typ={form.typ} isDark={isDark} small />
              {form.wert > 0 && <span style={{ fontSize: 11, color: C.textSoft }}>{form.wert} GP</span>}
              {form.gewicht > 0 && <span style={{ fontSize: 11, color: C.textSoft }}>{form.gewicht} lbs</span>}
            </div>
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          {/* LINKS */}
          <div>
            <Card title="Grundinformationen">
              <div style={{ marginBottom: 10 }}>
                <Label>Name *</Label>
                <input value={form.name} onChange={e => set("name", e.target.value)}
                  placeholder="Item Name" style={inputStyle}
                  onFocus={e => e.target.style.borderColor = C.accent}
                  onBlur={e => e.target.style.borderColor = C.border} />
              </div>
              <div style={{ marginBottom: 10 }}>
                <Label>Beschreibung</Label>
                <textarea value={form.beschreibung} onChange={e => set("beschreibung", e.target.value)}
                  placeholder="Beschreibung des Items..." rows={4}
                  style={{ ...inputStyle, resize: "vertical", lineHeight: 1.5 }}
                  onFocus={e => e.target.style.borderColor = C.accent}
                  onBlur={e => e.target.style.borderColor = C.border} />
              </div>
              <div>
                <Label>Item Typ</Label>
                <div style={{ position: "relative" }}>
                  <select value={form.typ} onChange={e => set("typ", e.target.value)} style={{
                    ...inputStyle, appearance: "none", paddingRight: 28, cursor: "pointer",
                  }}>
                    {TYPEN.map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                  <div style={{ position: "absolute", right: 10, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
                    <Icon name="chevronDown" size={13} color={C.textSoft} />
                  </div>
                </div>
              </div>
            </Card>

            <Card title="Details">
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                <div>
                  <Label>Wert (GP)</Label>
                  <input type="number" value={form.wert} onChange={e => set("wert", parseFloat(e.target.value) || 0)}
                    style={{ ...inputStyle, textAlign: "center" }}
                    onFocus={e => e.target.style.borderColor = C.accent}
                    onBlur={e => e.target.style.borderColor = C.border} />
                </div>
                <div>
                  <Label>Gewicht (lbs)</Label>
                  <input type="number" value={form.gewicht} onChange={e => set("gewicht", parseFloat(e.target.value) || 0)}
                    style={{ ...inputStyle, textAlign: "center" }}
                    onFocus={e => e.target.style.borderColor = C.accent}
                    onBlur={e => e.target.style.borderColor = C.border} />
                </div>
              </div>
            </Card>
          </div>

          {/* RECHTS */}
          <div>
            {/* Waffen-spezifisch */}
            {(form.typ === "Waffe" || form.typ === "Magisches Item" || form.typ === "Spruch als Waffe") && (
              <Card title="Kampf">
                <div style={{ marginBottom: 10 }}>
                  <Label>Schadenswurf</Label>
                  <input value={form.schadenswurf} onChange={e => set("schadenswurf", e.target.value)}
                    placeholder="z.B. 1d8+3" style={inputStyle}
                    onFocus={e => e.target.style.borderColor = C.accent}
                    onBlur={e => e.target.style.borderColor = C.border} />
                </div>
                <div>
                  <Label>Schadenstyp</Label>
                  <div style={{ position: "relative" }}>
                    <select value={form.schadenstyp} onChange={e => set("schadenstyp", e.target.value)} style={{
                      ...inputStyle, appearance: "none", paddingRight: 28, cursor: "pointer",
                    }}>
                      <option value="">Schadenstyp wählen...</option>
                      {SCHADENSTYPEN.map(s => <option key={s} value={s}>{s}</option>)}
                    </select>
                    <div style={{ position: "absolute", right: 10, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
                      <Icon name="chevronDown" size={13} color={C.textSoft} />
                    </div>
                  </div>
                </div>
              </Card>
            )}

            <Card title="Erweiterte Optionen">
              {[
                { key: "attunement", label: "Attunement erforderlich", desc: "Das Item erfordert eine Ruhephase zur Bindung" },
                { key: "haltbarkeit", label: "Haltbarkeit aktivieren", desc: "Das Item hat eine begrenzte Haltbarkeit" },
              ].map(opt => (
                <div key={opt.key} style={{
                  display: "flex", alignItems: "center", justifyContent: "space-between",
                  padding: "9px 0", borderBottom: `1px solid ${C.border}`,
                }}>
                  <div>
                    <div style={{ fontSize: 13, color: C.text }}>{opt.label}</div>
                    <div style={{ fontSize: 11, color: C.textSoft, marginTop: 1 }}>{opt.desc}</div>
                  </div>
                  <button onClick={() => set(opt.key, !form[opt.key])} style={{
                    width: 36, height: 20, borderRadius: 10, border: "none",
                    background: form[opt.key] ? C.accent : C.border,
                    cursor: "pointer", position: "relative", transition: "background 0.2s", flexShrink: 0,
                  }}>
                    <div style={{
                      position: "absolute", top: 3, left: form[opt.key] ? 19 : 3,
                      width: 14, height: 14, borderRadius: "50%",
                      background: "#fff", transition: "left 0.2s",
                    }} />
                  </button>
                </div>
              ))}
            </Card>

            <Card title="Eigenschaften">
              <textarea value={form.eigenschaften} onChange={e => set("eigenschaften", e.target.value)}
                placeholder="Spezielle Eigenschaften, Boni, Effekte..." rows={4}
                style={{ ...inputStyle, resize: "vertical", lineHeight: 1.5 }}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── ITEM DETAIL ───────────────────────────────────────────────────────────────
const ItemDetail = ({ item, C, isDark, onEdit }) => {
  const cfg = TYPEN_CFG[item.typ] || TYPEN_CFG["Ausrüstung"];
  return (
    <div style={{ padding: "20px", height: "100%", overflow: "auto" }}>
      {/* Header */}
      <div style={{
        padding: "14px 16px", borderRadius: 10, marginBottom: 16,
        background: isDark ? cfg.bg_d : cfg.bg_l,
        border: `1px solid ${cfg.dot}33`,
      }}>
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 9,
              background: cfg.dot + "20", border: `1.5px solid ${cfg.dot}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ fontSize: 17, fontWeight: 700, color: cfg.dot }}>{item.name[0]}</span>
            </div>
            <div>
              <div style={{ fontSize: 16, fontWeight: 600, color: C.text }}>{item.name}</div>
              <TypBadge typ={item.typ} isDark={isDark} small />
            </div>
          </div>
          <button onClick={() => onEdit(item)} style={{
            display: "flex", alignItems: "center", gap: 5,
            padding: "6px 12px", borderRadius: 7,
            background: C.bgPanel, border: `1px solid ${C.border}`,
            color: C.textMid, fontSize: 11, fontWeight: 500,
            cursor: "pointer", fontFamily: "inherit",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = C.bgPanel}
          >
            <Icon name="edit" size={11} color={C.textMid} />
            Bearbeiten
          </button>
        </div>
      </div>

      {/* Beschreibung */}
      {item.beschreibung && (
        <div style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 6 }}>Beschreibung</div>
          <div style={{ fontSize: 13, color: C.textMid, lineHeight: 1.6 }}>{item.beschreibung}</div>
        </div>
      )}

      {/* Stats Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 14 }}>
        {[
          { label: "Wert", value: `${item.wert} GP`, icon: "coin" },
          { label: "Gewicht", value: `${item.gewicht} lbs`, icon: "weight" },
          item.schadenswurf && { label: "Schaden", value: item.schadenswurf, icon: "sword" },
          item.schadenstyp && { label: "Schadenstyp", value: item.schadenstyp, icon: "zap" },
        ].filter(Boolean).map((s, i) => (
          <div key={i} style={{
            padding: "10px 12px", borderRadius: 8,
            background: C.bgPanel, border: `1px solid ${C.border}`,
          }}>
            <div style={{ fontSize: 10, color: C.textSoft, marginBottom: 3 }}>{s.label}</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{s.value}</div>
          </div>
        ))}
      </div>

      {/* Eigenschaften */}
      {item.eigenschaften && (
        <div style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 6 }}>Eigenschaften</div>
          <div style={{
            padding: "10px 12px", borderRadius: 8,
            background: C.bgPanel, border: `1px solid ${C.border}`,
            fontSize: 13, color: C.textMid, lineHeight: 1.5,
          }}>{item.eigenschaften}</div>
        </div>
      )}

      {/* Badges */}
      <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
        {item.attunement && (
          <span style={{
            fontSize: 11, color: "#be185d",
            background: isDark ? "#2a0f1c" : "#fdf0f7",
            padding: "3px 9px", borderRadius: 5, fontWeight: 500,
          }}>✦ Attunement</span>
        )}
        {item.haltbarkeit && (
          <span style={{
            fontSize: 11, color: C.amber,
            background: C.amberSoft,
            padding: "3px 9px", borderRadius: 5, fontWeight: 500,
          }}>⏱ Haltbarkeit</span>
        )}
      </div>
    </div>
  );
};

// ── HAUPT ─────────────────────────────────────────────────────────────────────
export default function Ausruestungskammer() {
  const [isDark, setIsDark] = useState(false);
  const [items, setItems] = useState(initItems);
  const [suche, setSuche] = useState("");
  const [aktivTyp, setAktivTyp] = useState("Alle");
  const [selectedId, setSelectedId] = useState(initItems[0]?.id || null);
  const [editorItem, setEditorItem] = useState(null); // null = liste, item = bearbeiten, "neu" = neu

  const C = THEMES[isDark ? "dark" : "light"];

  const typCounts = TYPEN.reduce((acc, t) => {
    acc[t] = items.filter(i => i.typ === t).length;
    return acc;
  }, {});

  const gefiltert = items.filter(item => {
    const matchSuche = item.name.toLowerCase().includes(suche.toLowerCase());
    const matchTyp = aktivTyp === "Alle" || item.typ === aktivTyp;
    return matchSuche && matchTyp;
  });

  const selectedItem = items.find(i => i.id === selectedId);

  const handleSave = (form) => {
    if (editorItem === "neu") {
      const neu = { ...form, id: Date.now() };
      setItems(prev => [...prev, neu]);
      setSelectedId(neu.id);
    } else {
      setItems(prev => prev.map(i => i.id === editorItem.id ? { ...i, ...form } : i));
    }
    setEditorItem(null);
  };

  const handleDelete = (id) => {
    setItems(prev => prev.filter(i => i.id !== id));
    setSelectedId(items.find(i => i.id !== id)?.id || null);
  };

  // Editor Seite anzeigen
  if (editorItem !== null) {
    return (
      <ItemEditor
        item={editorItem === "neu" ? null : editorItem}
        C={C} isDark={isDark}
        onBack={() => setEditorItem(null)}
        onSave={handleSave}
        onDelete={handleDelete}
      />
    );
  }

  return (
    <div style={{
      fontFamily: "-apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif",
      background: C.bg, height: "100vh", overflow: "hidden",
      color: C.text, fontSize: 13, display: "flex", flexDirection: "column",
      transition: "background 0.25s, color 0.25s",
    }}>

      {/* TOPBAR */}
      <div style={{
        height: 48, background: C.bgPanel, borderBottom: `1px solid ${C.border}`,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 20px", flexShrink: 0,
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
            <Icon name="bag" size={16} color={C.accent} />
            <span style={{ fontSize: 14, fontWeight: 600 }}>Ausrüstungskammer</span>
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{ fontSize: 12, color: C.textSoft }}>{gefiltert.length} Items</span>
          <button onClick={() => setIsDark(d => !d)} style={{
            width: 32, height: 32, borderRadius: 7,
            background: C.bgHover, border: `1px solid ${C.border}`,
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
          </button>
          <button onClick={() => setEditorItem("neu")} style={{
            display: "flex", alignItems: "center", gap: 6,
            padding: "7px 14px", borderRadius: 7,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 12, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
          }}>
            <Icon name="plus" size={13} color="#fff" />
            Neues Item
          </button>
        </div>
      </div>

      {/* HAUPTBEREICH */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>

        {/* ══ LINKE SEITE — Liste ══ */}
        <div style={{
          width: "40%", display: "flex", flexDirection: "column",
          background: C.bgPanel, borderRight: `1px solid ${C.border}`,
          overflow: "hidden",
        }}>

          {/* Suche */}
          <div style={{ padding: "12px 12px 8px", flexShrink: 0 }}>
            <div style={{ position: "relative" }}>
              <div style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)" }}>
                <Icon name="search" size={13} color={C.textSoft} />
              </div>
              <input value={suche} onChange={e => setSuche(e.target.value)}
                placeholder="Ausrüstung suchen..."
                style={{
                  width: "100%", padding: "8px 10px 8px 30px",
                  background: C.bgHover, border: `1px solid ${C.border}`,
                  borderRadius: 7, fontSize: 12, color: C.text,
                  outline: "none", fontFamily: "inherit", boxSizing: "border-box",
                }}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
            </div>
          </div>

          {/* Typ Filter — scrollbar horizontal */}
          <div style={{
            padding: "0 12px 10px", flexShrink: 0,
            display: "flex", gap: 5, overflowX: "auto",
            scrollbarWidth: "none",
          }}>
            <button onClick={() => setAktivTyp("Alle")} style={{
              padding: "3px 10px", borderRadius: 5, flexShrink: 0,
              background: aktivTyp === "Alle" ? C.accent : "transparent",
              border: `1px solid ${aktivTyp === "Alle" ? C.accent : C.border}`,
              color: aktivTyp === "Alle" ? "#fff" : C.textMid,
              fontSize: 11, cursor: "pointer", fontFamily: "inherit",
            }}>Alle</button>
            {TYPEN.filter(t => typCounts[t] > 0).map(t => {
              const cfg = TYPEN_CFG[t];
              const aktiv = aktivTyp === t;
              return (
                <button key={t} onClick={() => setAktivTyp(t)} style={{
                  padding: "3px 9px", borderRadius: 5, flexShrink: 0,
                  background: aktiv ? (isDark ? cfg.bg_d : cfg.bg_l) : "transparent",
                  border: `1px solid ${aktiv ? cfg.dot : C.border}`,
                  color: aktiv ? cfg.color : C.textMid,
                  fontSize: 11, cursor: "pointer", fontFamily: "inherit",
                  display: "flex", alignItems: "center", gap: 4,
                }}>
                  <span style={{ width: 5, height: 5, borderRadius: "50%", background: cfg.dot }} />
                  {t}
                </button>
              );
            })}
          </div>

          {/* Item Liste */}
          <div style={{ flex: 1, overflow: "auto" }}>
            {gefiltert.length === 0 ? (
              <div style={{ padding: "40px 20px", textAlign: "center", color: C.textSoft }}>
                <Icon name="bag" size={28} color={C.border} />
                <div style={{ marginTop: 10, fontSize: 13 }}>Keine Items gefunden</div>
              </div>
            ) : (
              gefiltert.map(item => {
                const isSelected = selectedId === item.id;
                const cfg = TYPEN_CFG[item.typ] || TYPEN_CFG["Ausrüstung"];
                return (
                  <div key={item.id} onClick={() => setSelectedId(item.id)} style={{
                    display: "flex", alignItems: "center", gap: 10,
                    padding: "10px 14px",
                    background: isSelected ? C.bgActive : "transparent",
                    borderBottom: `1px solid ${C.border}`,
                    cursor: "pointer", transition: "background 0.15s",
                    borderLeft: `3px solid ${isSelected ? cfg.dot : "transparent"}`,
                  }}
                    onMouseEnter={e => { if (!isSelected) e.currentTarget.style.background = C.bgHover; }}
                    onMouseLeave={e => { if (!isSelected) e.currentTarget.style.background = "transparent"; }}
                  >
                    <div style={{
                      width: 32, height: 32, borderRadius: 7, flexShrink: 0,
                      background: cfg.dot + "18", border: `1px solid ${cfg.dot}30`,
                      display: "flex", alignItems: "center", justifyContent: "center",
                    }}>
                      <span style={{ fontSize: 13, fontWeight: 700, color: cfg.dot }}>{item.name[0]}</span>
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: isSelected ? 500 : 400, color: C.text, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                        {item.name}
                      </div>
                      <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 2 }}>
                        <TypBadge typ={item.typ} isDark={isDark} small />
                        {item.wert > 0 && <span style={{ fontSize: 10, color: C.textSoft }}>{item.wert} GP</span>}
                      </div>
                    </div>
                    {item.attunement && <span style={{ fontSize: 10, color: "#be185d" }}>✦</span>}
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* ══ RECHTE SEITE — Detail ══ */}
        <div style={{ flex: 1, overflow: "hidden", background: C.bg }}>
          {selectedItem ? (
            <ItemDetail item={selectedItem} C={C} isDark={isDark} onEdit={item => setEditorItem(item)} />
          ) : (
            <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", color: C.textSoft, flexDirection: "column", gap: 10 }}>
              <Icon name="bag" size={32} color={C.border} />
              <div style={{ fontSize: 14 }}>Item auswählen</div>
            </div>
          )}
        </div>
      </div>

      <style>{`
        * { box-sizing: border-box; }
        input::placeholder, textarea::placeholder { color: ${C.textSoft}; }
        select option { background: ${C.bgPanel}; color: ${C.text}; }
        textarea { font-family: inherit; }
        ::-webkit-scrollbar { width: 4px; height: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
        ::-webkit-scrollbar-track { background: transparent; }
      `}</style>
    </div>
  );
}
