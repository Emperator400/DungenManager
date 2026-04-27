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

const KREATUR_TYPEN = ["Beast","Dragon","Humanoid","Undead","Fiend","Celestial","Construct","Elemental","Fey","Giant","Monstrosity","Ooze","Plant","Aberration"];
const GROESSEN = ["Winzig","Klein","Mittel","Groß","Riesig","Gigantisch"];
const AUSRICHTUNGEN = ["Rechtschaffen Gut","Neutral Gut","Chaotisch Gut","Rechtschaffen Neutral","Neutral","Chaotisch Neutral","Rechtschaffen Böse","Neutral Böse","Chaotisch Böse","Unaligned"];
const SCHADENSTYPEN = ["Hieb","Stich","Wucht","Feuer","Kälte","Blitz","Säure","Gift","Nekrotisch","Strahlend","Psychisch","Kraft"];

const TYP_FARBE = {
  Beast: "#1a7f4b", Dragon: "#c93a3a", Humanoid: "#2f6feb",
  Undead: "#4A235A", Fiend: "#7c3aed", Celestial: "#d4890a",
  Construct: "#6b6b66", Elemental: "#0891b2", Fey: "#be185d",
  Giant: "#065f46", Monstrosity: "#b45309", Ooze: "#065f46",
  Plant: "#1a7f4b", Aberration: "#4A235A",
};

const ATTR_LISTE = [
  { key: "STÄ", label: "Stärke" },
  { key: "GES", label: "Geschicklichkeit" },
  { key: "KON", label: "Konstitution" },
  { key: "INT", label: "Intelligenz" },
  { key: "WEI", label: "Weisheit" },
  { key: "CHA", label: "Charisma" },
];

const initKreaturen = [
  {
    id: 1, name: "Goblin", typ: "Beast", subtyp: "", groesse: "Klein",
    ausrichtung: "Neutral Böse", hp: 7, ac: 15, cr: "1/4",
    attribute: { STÄ: 8, GES: 14, KON: 10, INT: 10, WEI: 8, CHA: 8 },
    faehigkeiten: "Heimlichkeit +6\nSinne: Dunkelsicht 18 Meter, passive Wahrnehmung 9",
    angriffe: "Krummsäbel: +4 zu treffen, 1d6+2 Hiebschaden\nBogen: +4 zu treffen, 1d6+2 Stichschaden",
    eigenschaften: "Agil: Bonus-Aktion für Ausweichen oder Verstecken",
    quellen: "Eigene", favorit: false,
  },
  {
    id: 2, name: "Mantikor", typ: "Monstrosity", subtyp: "", groesse: "Groß",
    ausrichtung: "Chaotisch Böse", hp: 68, ac: 14, cr: "3",
    attribute: { STÄ: 17, GES: 16, KON: 17, INT: 7, WEI: 11, CHA: 8 },
    faehigkeiten: "Sinne: Dunkelsicht 18 Meter, passive Wahrnehmung 10",
    angriffe: "Mehrfachangriff: 3 Angriffe pro Runde\nBiss: +5, 1d8+3 Stich\nKlaue: +5, 2d6+3 Hieb\nSchwanzstachel: 5x10 Fuß Kegel, DC13 GES",
    eigenschaften: "Mehrfachangriff: Der Mantikor macht 3 Angriffe.",
    quellen: "Offiziell", favorit: false,
  },
  {
    id: 3, name: "Skelett", typ: "Undead", subtyp: "", groesse: "Mittel",
    ausrichtung: "Rechtschaffen Böse", hp: 13, ac: 13, cr: "1/4",
    attribute: { STÄ: 10, GES: 14, KON: 15, INT: 6, WEI: 8, CHA: 5 },
    faehigkeiten: "Sinne: Dunkelsicht 18 Meter\nImmunität: Gift, Erschöpfung",
    angriffe: "Kurzbögen: +4 zu treffen, 1d6+2 Stich",
    eigenschaften: "Untotes Wesen ohne Atem",
    quellen: "Offiziell", favorit: true,
  },
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
    star: "M8 2l1.8 3.6L14 6.3l-3 2.9.7 4.1L8 11.2l-3.7 2.1.7-4.1-3-2.9 4.2-.7z",
    shield: "M8 2l5 2v5c0 3-5 5-5 5S3 12 3 9V4l5-2z",
    heart: "M8 13s-5-3.5-5-7a3 3 0 016 0 3 3 0 016 0c0 3.5-5 7-5 7z",
    sword: "M3 13l8-8m0 0l2-2 2 2-2 2M5 11l-2 2",
    zap: "M9 2L4 9h5l-2 5 7-8H9z",
    eye: "M1 8s3-5 7-5 7 5 7 5-3 5-7 5-7-5-7-5zm7-2a2 2 0 100 4 2 2 0 000-4z",
    paw: "M5 4a1 1 0 100 2 1 1 0 000-2zm6 0a1 1 0 100 2 1 1 0 000-2zM3 8a1 1 0 100 2 1 1 0 000-2zm10 0a1 1 0 100 2 1 1 0 000-2zM8 6c-2 0-4 2-4 4s2 3 4 3 4-1 4-3-2-4-4-4z",
    check: "M4 8l3 3 5-5",
    download: "M8 3v8M5 8l3 3 3-3M3 13h10",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} />
    </svg>
  );
};

// ── HELPERS ───────────────────────────────────────────────────────────────────
const TypBadge = ({ typ, isDark, C }) => {
  const farbe = TYP_FARBE[typ] || C.textSoft;
  return (
    <span style={{
      fontSize: 10, fontWeight: 500, color: farbe,
      background: farbe + (isDark ? "22" : "18"),
      padding: "1px 7px", borderRadius: 4,
      display: "inline-flex", alignItems: "center", gap: 4,
    }}>
      <span style={{ width: 5, height: 5, borderRadius: "50%", background: farbe }} />
      {typ}
    </span>
  );
};

const Card = ({ children, title, C, style = {} }) => (
  <div style={{ background: C.bgPanel, border: `1px solid ${C.border}`, borderRadius: 10, padding: "14px 16px", ...style }}>
    {title && <div style={{ fontSize: 11, fontWeight: 600, color: C.textSoft, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 12 }}>{title}</div>}
    {children}
  </div>
);

const Label = ({ children, C }) => (
  <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>{children}</div>
);

const AppInput = ({ value, onChange, placeholder, C, type = "text", center, rows }) => {
  const shared = {
    width: "100%", padding: "8px 10px",
    background: C.bgHover, border: `1px solid ${C.border}`,
    borderRadius: 7, fontSize: 13, color: C.text,
    fontFamily: "inherit", outline: "none", boxSizing: "border-box",
    textAlign: center ? "center" : "left",
  };
  return rows
    ? <textarea value={value} onChange={onChange} placeholder={placeholder} rows={rows}
        style={{ ...shared, resize: "vertical", lineHeight: 1.5 }}
        onFocus={e => e.target.style.borderColor = C.accent}
        onBlur={e => e.target.style.borderColor = C.border} />
    : <input type={type} value={value} onChange={onChange} placeholder={placeholder}
        style={shared}
        onFocus={e => e.target.style.borderColor = C.accent}
        onBlur={e => e.target.style.borderColor = C.border} />;
};

const AppSelect = ({ value, onChange, options, C }) => (
  <div style={{ position: "relative" }}>
    <select value={value} onChange={onChange} style={{
      width: "100%", padding: "8px 28px 8px 10px",
      background: C.bgHover, border: `1px solid ${C.border}`,
      borderRadius: 7, fontSize: 13, color: C.text,
      fontFamily: "inherit", outline: "none", appearance: "none",
      boxSizing: "border-box", cursor: "pointer",
    }}>
      {options.map(o => <option key={o} value={o}>{o}</option>)}
    </select>
    <div style={{ position: "absolute", right: 8, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
      <Icon name="chevronDown" size={12} color={C.textSoft} />
    </div>
  </div>
);

// ── KREATUR EDITOR ────────────────────────────────────────────────────────────
const KreaturEditor = ({ kreatur, C, isDark, onBack, onSave, onDelete }) => {
  const isNeu = !kreatur?.id;
  const [form, setForm] = useState({
    name: kreatur?.name || "",
    typ: kreatur?.typ || "Beast",
    subtyp: kreatur?.subtyp || "",
    groesse: kreatur?.groesse || "Mittel",
    ausrichtung: kreatur?.ausrichtung || "Neutral",
    hp: kreatur?.hp ?? 10,
    ac: kreatur?.ac ?? 10,
    cr: kreatur?.cr || "1",
    attribute: kreatur?.attribute || { STÄ: 10, GES: 10, KON: 10, INT: 10, WEI: 10, CHA: 10 },
    faehigkeiten: kreatur?.faehigkeiten || "",
    angriffe: kreatur?.angriffe || "",
    eigenschaften: kreatur?.eigenschaften || "",
    quellen: kreatur?.quellen || "Eigene",
  });
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));
  const setAttr = (k, v) => setForm(f => ({ ...f, attribute: { ...f.attribute, [k]: v } }));
  const farbe = TYP_FARBE[form.typ] || C.accent;

  return (
    <div style={{
      fontFamily: "-apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif",
      background: C.bg, height: "100vh", overflow: "hidden",
      color: C.text, fontSize: 13, display: "flex", flexDirection: "column",
    }}>
      {/* Topbar */}
      <div style={{
        height: 48, background: C.bgPanel, borderBottom: `1px solid ${C.border}`,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 20px", flexShrink: 0,
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
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{
              width: 28, height: 28, borderRadius: 7,
              background: farbe + "20", border: `1.5px solid ${farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ fontSize: 13, fontWeight: 700, color: farbe }}>{form.name?.[0] || "?"}</span>
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{form.name || "Neue Kreatur"}</div>
              <div style={{ fontSize: 10, color: C.textSoft }}>{form.groesse} {form.typ} · CR {form.cr}</div>
            </div>
          </div>
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          {!isNeu && (
            <button onClick={() => { onDelete(kreatur.id); onBack(); }} style={{
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
      <div style={{ flex: 1, overflow: "auto", padding: "16px 20px" }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>

          {/* LINKS */}
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>

            <Card title="Grundinformationen" C={C}>
              <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                <div>
                  <Label C={C}>Name *</Label>
                  <AppInput value={form.name} onChange={e => set("name", e.target.value)} placeholder="Kreaturname" C={C} />
                </div>
                <div>
                  <Label C={C}>Kreaturentyp</Label>
                  <AppSelect value={form.typ} onChange={e => set("typ", e.target.value)} options={KREATUR_TYPEN} C={C} />
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
                  <div>
                    <Label C={C}>Subtyp</Label>
                    <AppInput value={form.subtyp} onChange={e => set("subtyp", e.target.value)} placeholder="Optional" C={C} />
                  </div>
                  <div>
                    <Label C={C}>Größe</Label>
                    <AppSelect value={form.groesse} onChange={e => set("groesse", e.target.value)} options={GROESSEN} C={C} />
                  </div>
                </div>
                <div>
                  <Label C={C}>Ausrichtung</Label>
                  <AppSelect value={form.ausrichtung} onChange={e => set("ausrichtung", e.target.value)} options={AUSRICHTUNGEN} C={C} />
                </div>
                <div>
                  <Label C={C}>Quelle</Label>
                  <div style={{ display: "flex", gap: 5 }}>
                    {["Eigene", "Offiziell"].map(q => (
                      <button key={q} onClick={() => set("quellen", q)} style={{
                        padding: "5px 12px", borderRadius: 6,
                        background: form.quellen === q ? C.accent : "transparent",
                        border: `1px solid ${form.quellen === q ? C.accent : C.border}`,
                        color: form.quellen === q ? "#fff" : C.textMid,
                        fontSize: 12, cursor: "pointer", fontFamily: "inherit",
                      }}>{q}</button>
                    ))}
                  </div>
                </div>
              </div>
            </Card>

            <Card title="Kampfwerte" C={C}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                {[
                  { key: "hp", label: "Max HP", color: C.red },
                  { key: "ac", label: "RK (AC)", color: C.accent },
                  { key: "cr", label: "Challenge Rating", color: C.amber, type: "text" },
                ].map(f => (
                  <div key={f.key} style={{ textAlign: "center" }}>
                    <div style={{ fontSize: 10, fontWeight: 500, color: f.color, marginBottom: 4, textTransform: "uppercase", letterSpacing: 0.3 }}>{f.label}</div>
                    <input type={f.type || "number"} value={form[f.key]}
                      onChange={e => set(f.key, f.type === "text" ? e.target.value : parseInt(e.target.value) || 0)}
                      style={{
                        width: "100%", padding: "8px 4px",
                        background: C.bgHover, border: `1px solid ${f.color}33`,
                        borderRadius: 8, fontSize: 16, fontWeight: 700, color: f.color,
                        fontFamily: "inherit", outline: "none", textAlign: "center", boxSizing: "border-box",
                      }} />
                  </div>
                ))}
              </div>
            </Card>

            <Card title="Attribute" C={C}>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10 }}>
                {ATTR_LISTE.map(a => {
                  const val = form.attribute[a.key] || 10;
                  const mod = Math.floor((val - 10) / 2);
                  return (
                    <div key={a.key} style={{ textAlign: "center" }}>
                      <div style={{ fontSize: 10, color: C.textSoft, marginBottom: 4, textTransform: "uppercase" }}>{a.label}</div>
                      <input type="number" value={val}
                        onChange={e => setAttr(a.key, parseInt(e.target.value) || 10)}
                        style={{
                          width: "100%", padding: "6px 4px",
                          background: C.bgHover, border: `1px solid ${C.border}`,
                          borderRadius: 7, fontSize: 15, fontWeight: 700, color: C.text,
                          fontFamily: "inherit", outline: "none", textAlign: "center", boxSizing: "border-box",
                        }} />
                      <div style={{ fontSize: 11, color: C.textSoft, marginTop: 2 }}>
                        <span style={{ color: mod >= 0 ? C.green : C.red, fontWeight: 600 }}>
                          {mod >= 0 ? "+" : ""}{mod}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>
          </div>

          {/* RECHTS */}
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>

            <Card title="Fähigkeiten & Sinne" C={C}>
              <AppInput value={form.faehigkeiten} onChange={e => set("faehigkeiten", e.target.value)}
                placeholder="Fertigkeiten, Sinne, Immunitäten..." C={C} rows={5} />
            </Card>

            <Card title="Angriffe" C={C}>
              <AppInput value={form.angriffe} onChange={e => set("angriffe", e.target.value)}
                placeholder="Angriffsaktionen und Schadenswürfel..." C={C} rows={5} />
            </Card>

            <Card title="Besondere Eigenschaften" C={C}>
              <AppInput value={form.eigenschaften} onChange={e => set("eigenschaften", e.target.value)}
                placeholder="Passive Fähigkeiten, Aktionen, Legendäre Aktionen..." C={C} rows={5} />
            </Card>

            {/* Stat Übersicht */}
            <Card title="Modifier Übersicht" C={C}>
              <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
                {ATTR_LISTE.map(a => {
                  const val = form.attribute[a.key] || 10;
                  const mod = Math.floor((val - 10) / 2);
                  return (
                    <div key={a.key} style={{
                      display: "flex", alignItems: "center", gap: 8,
                      padding: "5px 8px", borderRadius: 6,
                      background: C.bgHover,
                    }}>
                      <span style={{ flex: 1, fontSize: 12, color: C.textMid }}>{a.label}</span>
                      <span style={{ fontSize: 12, fontWeight: 600, color: C.text, minWidth: 24, textAlign: "center" }}>{val}</span>
                      <span style={{ fontSize: 12, fontWeight: 700, color: mod >= 0 ? C.green : C.red, minWidth: 28, textAlign: "right" }}>
                        {mod >= 0 ? "+" : ""}{mod}
                      </span>
                    </div>
                  );
                })}
              </div>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── KREATUR DETAIL ────────────────────────────────────────────────────────────
const KreaturDetail = ({ kreatur, C, isDark, onEdit }) => {
  const farbe = TYP_FARBE[kreatur.typ] || C.accent;
  return (
    <div style={{ padding: "20px", height: "100%", overflow: "auto" }}>
      {/* Header */}
      <div style={{
        padding: "14px 16px", borderRadius: 10, marginBottom: 14,
        background: farbe + (isDark ? "18" : "10"),
        border: `1px solid ${farbe}30`,
      }}>
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 9,
              background: farbe + "20", border: `1.5px solid ${farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ fontSize: 17, fontWeight: 700, color: farbe }}>{kreatur.name[0]}</span>
            </div>
            <div>
              <div style={{ fontSize: 16, fontWeight: 600, color: C.text }}>{kreatur.name}</div>
              <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 3 }}>
                <TypBadge typ={kreatur.typ} isDark={isDark} C={C} />
                <span style={{ fontSize: 10, color: C.textSoft }}>{kreatur.groesse}</span>
                <span style={{ fontSize: 10, color: C.textSoft }}>·</span>
                <span style={{ fontSize: 10, color: C.textSoft }}>{kreatur.ausrichtung}</span>
              </div>
            </div>
          </div>
          <button onClick={() => onEdit(kreatur)} style={{
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

      {/* Kampfwerte */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 8, marginBottom: 14 }}>
        {[
          { label: "HP", value: kreatur.hp, color: C.red, icon: "heart" },
          { label: "RK (AC)", value: kreatur.ac, color: C.accent, icon: "shield" },
          { label: "CR", value: kreatur.cr, color: C.amber, icon: "star" },
        ].map(s => (
          <div key={s.label} style={{
            padding: "10px 12px", borderRadius: 8, textAlign: "center",
            background: C.bgPanel, border: `1px solid ${C.border}`,
          }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 4, marginBottom: 2 }}>
              <Icon name={s.icon} size={11} color={s.color} />
              <span style={{ fontSize: 10, color: C.textSoft }}>{s.label}</span>
            </div>
            <div style={{ fontSize: 18, fontWeight: 700, color: s.color }}>{s.value}</div>
          </div>
        ))}
      </div>

      {/* Attribute */}
      <div style={{ marginBottom: 14 }}>
        <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 8 }}>Attribute</div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 6 }}>
          {ATTR_LISTE.map(a => {
            const val = kreatur.attribute?.[a.key] || 10;
            const mod = Math.floor((val - 10) / 2);
            return (
              <div key={a.key} style={{
                padding: "8px", borderRadius: 7, textAlign: "center",
                background: C.bgPanel, border: `1px solid ${C.border}`,
              }}>
                <div style={{ fontSize: 9, color: C.textSoft, textTransform: "uppercase", marginBottom: 2 }}>{a.key}</div>
                <div style={{ fontSize: 15, fontWeight: 700, color: C.text }}>{val}</div>
                <div style={{ fontSize: 11, color: mod >= 0 ? C.green : C.red, fontWeight: 600 }}>
                  {mod >= 0 ? "+" : ""}{mod}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Fähigkeiten */}
      {kreatur.faehigkeiten && (
        <div style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 6 }}>Fähigkeiten & Sinne</div>
          <div style={{ padding: "10px 12px", borderRadius: 8, background: C.bgPanel, border: `1px solid ${C.border}`, fontSize: 12, color: C.textMid, lineHeight: 1.6, whiteSpace: "pre-wrap" }}>
            {kreatur.faehigkeiten}
          </div>
        </div>
      )}

      {/* Angriffe */}
      {kreatur.angriffe && (
        <div style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 6 }}>Angriffe</div>
          <div style={{ padding: "10px 12px", borderRadius: 8, background: C.bgPanel, border: `1px solid ${C.border}`, fontSize: 12, color: C.textMid, lineHeight: 1.6, whiteSpace: "pre-wrap" }}>
            {kreatur.angriffe}
          </div>
        </div>
      )}

      {/* Eigenschaften */}
      {kreatur.eigenschaften && (
        <div style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 6 }}>Besondere Eigenschaften</div>
          <div style={{ padding: "10px 12px", borderRadius: 8, background: C.bgPanel, border: `1px solid ${C.border}`, fontSize: 12, color: C.textMid, lineHeight: 1.6 }}>
            {kreatur.eigenschaften}
          </div>
        </div>
      )}
    </div>
  );
};

// ── HAUPT ─────────────────────────────────────────────────────────────────────
export default function Bestiarium() {
  const [isDark, setIsDark] = useState(false);
  const [kreaturen, setKreaturen] = useState(initKreaturen);
  const [suche, setSuche] = useState("");
  const [filter, setFilter] = useState("Alle"); // Alle | Eigene | Offiziell | Favoriten
  const [selectedId, setSelectedId] = useState(initKreaturen[0]?.id || null);
  const [editor, setEditor] = useState(null);

  const C = THEMES[isDark ? "dark" : "light"];

  const gefiltert = kreaturen.filter(k => {
    const matchSuche = k.name.toLowerCase().includes(suche.toLowerCase()) ||
      k.typ.toLowerCase().includes(suche.toLowerCase());
    const matchFilter = filter === "Alle" ||
      (filter === "Eigene" && k.quellen === "Eigene") ||
      (filter === "Offiziell" && k.quellen === "Offiziell") ||
      (filter === "Favoriten" && k.favorit);
    return matchSuche && matchFilter;
  });

  const selectedKreatur = kreaturen.find(k => k.id === selectedId);

  const handleSave = (form) => {
    if (editor === "neu") {
      const neu = { ...form, id: Date.now(), favorit: false };
      setKreaturen(prev => [...prev, neu]);
      setSelectedId(neu.id);
    } else {
      setKreaturen(prev => prev.map(k => k.id === editor.id ? { ...k, ...form } : k));
    }
    setEditor(null);
  };

  const handleDelete = (id) => {
    setKreaturen(prev => prev.filter(k => k.id !== id));
    const rest = kreaturen.filter(k => k.id !== id);
    setSelectedId(rest[0]?.id || null);
    setEditor(null);
  };

  const toggleFavorit = (id) => {
    setKreaturen(prev => prev.map(k => k.id === id ? { ...k, favorit: !k.favorit } : k));
  };

  if (editor !== null) {
    return (
      <KreaturEditor
        kreatur={editor === "neu" ? null : editor}
        C={C} isDark={isDark}
        onBack={() => setEditor(null)}
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
            <Icon name="paw" size={16} color={C.accent} />
            <span style={{ fontSize: 14, fontWeight: 600 }}>Bestiarium</span>
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{ fontSize: 12, color: C.textSoft }}>{gefiltert.length} Kreaturen</span>
          <button style={{
            width: 32, height: 32, borderRadius: 7,
            background: C.bgHover, border: `1px solid ${C.border}`,
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name="download" size={14} color={C.textMid} />
          </button>
          <button onClick={() => setIsDark(d => !d)} style={{
            width: 32, height: 32, borderRadius: 7,
            background: C.bgHover, border: `1px solid ${C.border}`,
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
          </button>
          <button onClick={() => setEditor("neu")} style={{
            display: "flex", alignItems: "center", gap: 6,
            padding: "7px 14px", borderRadius: 7,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 12, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
          }}>
            <Icon name="plus" size={13} color="#fff" />
            Neue Kreatur
          </button>
        </div>
      </div>

      {/* HAUPTBEREICH */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>

        {/* ══ LINKE SEITE ══ */}
        <div style={{
          width: "38%", display: "flex", flexDirection: "column",
          background: C.bgPanel, borderRight: `1px solid ${C.border}`,
          overflow: "hidden",
        }}>

          {/* Suche + Filter */}
          <div style={{ padding: "12px 12px 8px", flexShrink: 0 }}>
            <div style={{ position: "relative", marginBottom: 8 }}>
              <div style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)" }}>
                <Icon name="search" size={13} color={C.textSoft} />
              </div>
              <input value={suche} onChange={e => setSuche(e.target.value)}
                placeholder="Kreaturen suchen..."
                style={{
                  width: "100%", padding: "8px 10px 8px 30px",
                  background: C.bgHover, border: `1px solid ${C.border}`,
                  borderRadius: 7, fontSize: 12, color: C.text,
                  outline: "none", fontFamily: "inherit", boxSizing: "border-box",
                }}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
            </div>
            <div style={{ display: "flex", gap: 4 }}>
              {["Alle", "Eigene", "Offiziell", "Favoriten"].map(f => (
                <button key={f} onClick={() => setFilter(f)} style={{
                  flex: 1, padding: "4px 4px", borderRadius: 6,
                  background: filter === f ? C.accent : "transparent",
                  border: `1px solid ${filter === f ? C.accent : C.border}`,
                  color: filter === f ? "#fff" : C.textMid,
                  fontSize: 11, cursor: "pointer", fontFamily: "inherit",
                  transition: "all 0.15s",
                }}>{f}</button>
              ))}
            </div>
          </div>

          {/* Liste */}
          <div style={{ flex: 1, overflow: "auto" }}>
            {gefiltert.length === 0 ? (
              <div style={{ padding: "40px 20px", textAlign: "center", color: C.textSoft }}>
                <Icon name="paw" size={28} color={C.border} />
                <div style={{ marginTop: 10 }}>Keine Kreaturen gefunden</div>
              </div>
            ) : gefiltert.map(k => {
              const isSelected = selectedId === k.id;
              const farbe = TYP_FARBE[k.typ] || C.textSoft;
              return (
                <div key={k.id} onClick={() => setSelectedId(k.id)} style={{
                  display: "flex", alignItems: "center", gap: 10,
                  padding: "10px 14px",
                  background: isSelected ? C.bgActive : "transparent",
                  borderBottom: `1px solid ${C.border}`,
                  cursor: "pointer", transition: "background 0.15s",
                  borderLeft: `3px solid ${isSelected ? farbe : "transparent"}`,
                }}
                  onMouseEnter={e => { if (!isSelected) e.currentTarget.style.background = C.bgHover; }}
                  onMouseLeave={e => { if (!isSelected) e.currentTarget.style.background = "transparent"; }}
                >
                  <div style={{
                    width: 34, height: 34, borderRadius: 8, flexShrink: 0,
                    background: farbe + "18", border: `1px solid ${farbe}30`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>
                    <span style={{ fontSize: 14, fontWeight: 700, color: farbe }}>{k.name[0]}</span>
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: isSelected ? 500 : 400, color: C.text, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                      {k.name}
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 2 }}>
                      <TypBadge typ={k.typ} isDark={isDark} C={C} />
                      <span style={{ fontSize: 10, color: C.textSoft }}>CR {k.cr}</span>
                    </div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}>
                    <div style={{ textAlign: "center" }}>
                      <div style={{ fontSize: 11, fontWeight: 600, color: C.red }}>{k.hp}</div>
                      <div style={{ fontSize: 9, color: C.textSoft }}>HP</div>
                    </div>
                    <div style={{ textAlign: "center" }}>
                      <div style={{ fontSize: 11, fontWeight: 600, color: C.accent }}>{k.ac}</div>
                      <div style={{ fontSize: 9, color: C.textSoft }}>AC</div>
                    </div>
                    <button onClick={e => { e.stopPropagation(); toggleFavorit(k.id); }} style={{
                      width: 24, height: 24, borderRadius: 5, border: "none",
                      background: "transparent", cursor: "pointer",
                      display: "flex", alignItems: "center", justifyContent: "center",
                    }}>
                      <Icon name="star" size={13} color={k.favorit ? C.amber : C.textSoft} />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* ══ RECHTE SEITE ══ */}
        <div style={{ flex: 1, overflow: "hidden", background: C.bg }}>
          {selectedKreatur ? (
            <KreaturDetail kreatur={selectedKreatur} C={C} isDark={isDark} onEdit={k => setEditor(k)} />
          ) : (
            <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", color: C.textSoft, flexDirection: "column", gap: 10 }}>
              <Icon name="paw" size={32} color={C.border} />
              <div style={{ fontSize: 14 }}>Kreatur auswählen</div>
            </div>
          )}
        </div>
      </div>

      <style>{`
        * { box-sizing: border-box; }
        input::placeholder, textarea::placeholder { color: ${C.textSoft}; }
        select option { background: ${C.bgPanel}; color: ${C.text}; }
        textarea { font-family: inherit; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
      `}</style>
    </div>
  );
}
