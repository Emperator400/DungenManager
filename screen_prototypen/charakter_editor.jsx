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

const KLASSEN = ["Barbar","Barde","Kleriker","Druide","Kämpfer","Mönch","Paladin","Waldläufer","Schurke","Zauberer","Hexenmeister","Magier"];
const RASSEN = ["Mensch","Elf","Zwerg","Halbling","Halbelf","Halbork","Tiefling","Drachenblut","Gnome","Aarakocra"];
const GROESSEN = ["Winzig","Klein","Mittel","Groß","Riesig","Gigantisch"];
const AUSRICHTUNGEN = ["Rechtschaffen Gut","Neutral Gut","Chaotisch Gut","Rechtschaffen Neutral","Neutral","Chaotisch Neutral","Rechtschaffen Böse","Neutral Böse","Chaotisch Böse"];
const FERTIGKEITEN = [
  { name: "Akrobatik", attr: "GES" }, { name: "Arkana", attr: "INT" },
  { name: "Athletik", attr: "STÄ" }, { name: "Auftreten", attr: "CHA" },
  { name: "Einschüchterung", attr: "CHA" }, { name: "Geschichte", attr: "INT" },
  { name: "Heimlichkeit", attr: "GES" }, { name: "Heilkunde", attr: "WEI" },
  { name: "Insight", attr: "WEI" }, { name: "Natur", attr: "INT" },
  { name: "Overzeugung", attr: "CHA" }, { name: "Religion", attr: "INT" },
  { name: "Täuschung", attr: "CHA" }, { name: "Tierumgang", attr: "WEI" },
  { name: "Wahrnehmung", attr: "WEI" }, { name: "Überlebenskunst", attr: "WEI" },
];
const RETTUNGSWUERFE = ["Stärke","Geschicklichkeit","Konstitution","Intelligenz","Weisheit","Charisma"];
const AUSRUESTUNG_SLOTS = ["Helm","Rüstung","Schild","Hauptwaffe","Nebenwaffe","Handschuhe","Stiefel","Ring","Ring","Amulett","Umhang"];
const INVENTAR_KATEGORIEN = ["Alle","Waffe","Rüstung","Schild","Verbrauchbar","Werkzeug","Material","Magisches Item","Trank","Schatz"];

const KLASSE_FARBE = {
  Barbar: "#c93a3a", Barde: "#7c3aed", Kleriker: "#d4890a",
  Druide: "#1a7f4b", Kämpfer: "#6b6b66", Mönch: "#0891b2",
  Paladin: "#2f6feb", Waldläufer: "#065f46", Schurke: "#4a4a4a",
  Zauberer: "#be185d", Hexenmeister: "#4A235A", Magier: "#1B4F72",
};

const ATTR_FARBE = {
  STÄ: "#c93a3a", GES: "#1a7f4b", KON: "#d4890a",
  INT: "#2f6feb", WEI: "#7c3aed", CHA: "#be185d",
};

// ── ICONS ─────────────────────────────────────────────────────────────────────
const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    back: "M10 3L5 8l5 5",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
    user: "M8 7a3 3 0 100-6 3 3 0 000 6zm-5 9a5 5 0 0110 0",
    sword: "M3 13l8-8m0 0l2-2 2 2-2 2M5 11l-2 2",
    dnd: "M8 2l2 4h4l-3 3 1 4-4-2-4 2 1-4-3-3h4z",
    bag: "M5 6V4a3 3 0 016 0v2h2a1 1 0 011 1v8a1 1 0 01-1 1H3a1 1 0 01-1-1V7a1 1 0 011-1h2z",
    chevronDown: "M4 6l4 4 4-4",
    plus: "M8 3v10M3 8h10",
    check: "M4 8l3 3 5-5",
    shield: "M8 2l5 2v5c0 3-5 5-5 5S3 12 3 9V4l5-2z",
    heart: "M8 13s-5-3.5-5-7a3 3 0 016 0 3 3 0 016 0c0 3.5-5 7-5 7z",
    zap: "M9 2L4 9h5l-2 5 7-8H9z",
    brain: "M6 3a3 3 0 00-3 3c0 1 .5 2 1 2.5-.5.5-1 1.5-1 2.5a3 3 0 003 3h4a3 3 0 003-3c0-1-.5-2-1-2.5.5-.5 1-1.5 1-2.5a3 3 0 00-3-3",
    eye: "M1 8s3-5 7-5 7 5 7 5-3 5-7 5-7-5-7-5zm7-2a2 2 0 100 4 2 2 0 000-4z",
    star: "M8 2l1.8 3.6L14 6.3l-3 2.9.7 4.1L8 11.2l-3.7 2.1.7-4.1-3-2.9 4.2-.7z",
    coin: "M8 3a5 5 0 100 10A5 5 0 008 3zm0 2v6M6 7h4",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} />
    </svg>
  );
};

// ── HELPER KOMPONENTEN ────────────────────────────────────────────────────────
const Label = ({ children, C }) => (
  <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>
    {children}
  </div>
);

const Card = ({ children, C, style = {} }) => (
  <div style={{ background: C.bgPanel, border: `1px solid ${C.border}`, borderRadius: 10, padding: "14px 16px", ...style }}>
    {children}
  </div>
);

const SectionTitle = ({ children, C }) => (
  <div style={{ fontSize: 12, fontWeight: 600, color: C.textMid, letterSpacing: 0.3, marginBottom: 12, textTransform: "uppercase" }}>
    {children}
  </div>
);

const AppInput = ({ value, onChange, placeholder, C, type = "text", center }) => (
  <input type={type} value={value} onChange={onChange} placeholder={placeholder} style={{
    width: "100%", padding: "8px 10px",
    background: C.bgHover, border: `1px solid ${C.border}`,
    borderRadius: 7, fontSize: 13, color: C.text,
    fontFamily: "inherit", outline: "none", boxSizing: "border-box",
    textAlign: center ? "center" : "left",
  }}
    onFocus={e => e.target.style.borderColor = C.accent}
    onBlur={e => e.target.style.borderColor = C.border}
  />
);

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

const StatBox = ({ label, value, onChange, C, color }) => (
  <div style={{ textAlign: "center" }}>
    <div style={{ fontSize: 10, fontWeight: 500, color: color || C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 4 }}>{label}</div>
    <input type="number" value={value} onChange={onChange} style={{
      width: "100%", padding: "8px 4px",
      background: C.bgHover, border: `1px solid ${color ? color + "44" : C.border}`,
      borderRadius: 8, fontSize: 16, fontWeight: 700, color: color || C.text,
      fontFamily: "inherit", outline: "none", textAlign: "center", boxSizing: "border-box",
    }}
      onFocus={e => e.target.style.borderColor = color || C.accent}
      onBlur={e => e.target.style.borderColor = color ? color + "44" : C.border}
    />
    <div style={{ fontSize: 11, color: C.textSoft, marginTop: 3 }}>
      Mod: <span style={{ color: C.green, fontWeight: 600 }}>
        {Math.floor((value - 10) / 2) >= 0 ? "+" : ""}{Math.floor((value - 10) / 2)}
      </span>
    </div>
  </div>
);

const Toggle = ({ on, onChange, C }) => (
  <button onClick={() => onChange(!on)} style={{
    width: 36, height: 20, borderRadius: 10, border: "none",
    background: on ? C.accent : C.border,
    cursor: "pointer", position: "relative", transition: "background 0.2s", flexShrink: 0,
  }}>
    <div style={{
      position: "absolute", top: 3, left: on ? 19 : 3,
      width: 14, height: 14, borderRadius: "50%",
      background: "#fff", transition: "left 0.2s",
      boxShadow: "0 1px 2px rgba(0,0,0,0.2)",
    }} />
  </button>
);

// ── TAB: STAMMDATEN ───────────────────────────────────────────────────────────
const TabStammdaten = ({ char, setChar, C }) => {
  const farbe = KLASSE_FARBE[char.klasse] || C.accent;
  const profBonus = Math.ceil(char.stufe / 4) + 1;

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>

      {/* LINKS */}
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>

        {/* Charakter Info */}
        <Card C={C}>
          <SectionTitle C={C}>Charakter</SectionTitle>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            <div>
              <Label C={C}>Name</Label>
              <AppInput value={char.name} onChange={e => setChar(c => ({ ...c, name: e.target.value }))} placeholder="Heldenname" C={C} />
            </div>
            <div>
              <Label C={C}>Spieler</Label>
              <AppInput value={char.spieler} onChange={e => setChar(c => ({ ...c, spieler: e.target.value }))} placeholder="Name des Spielers" C={C} />
            </div>
          </div>
        </Card>

        {/* Klasse & Rasse */}
        <Card C={C}>
          <SectionTitle C={C}>Klasse & Rasse</SectionTitle>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            <div>
              <Label C={C}>Klasse</Label>
              <AppSelect value={char.klasse} onChange={e => setChar(c => ({ ...c, klasse: e.target.value }))} options={KLASSEN} C={C} />
            </div>
            <div>
              <Label C={C}>Rasse</Label>
              <AppSelect value={char.rasse} onChange={e => setChar(c => ({ ...c, rasse: e.target.value }))} options={RASSEN} C={C} />
            </div>
          </div>
        </Card>

        {/* Fertigkeiten */}
        <Card C={C}>
          <SectionTitle C={C}>Fertigkeiten</SectionTitle>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            {FERTIGKEITEN.map(f => {
              const aktiv = char.fertigkeiten?.includes(f.name);
              const attrVal = char.attribute?.[f.attr] || 10;
              const mod = Math.floor((attrVal - 10) / 2);
              const bonus = aktiv ? mod + profBonus : mod;
              return (
                <div key={f.name} onClick={() => setChar(c => ({
                  ...c, fertigkeiten: aktiv
                    ? (c.fertigkeiten || []).filter(x => x !== f.name)
                    : [...(c.fertigkeiten || []), f.name]
                }))} style={{
                  display: "flex", alignItems: "center", gap: 8,
                  padding: "5px 6px", borderRadius: 5, cursor: "pointer",
                  transition: "background 0.1s",
                }}
                  onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
                  onMouseLeave={e => e.currentTarget.style.background = "transparent"}
                >
                  <div style={{
                    width: 14, height: 14, borderRadius: 3, flexShrink: 0,
                    background: aktiv ? C.accent : "transparent",
                    border: `1.5px solid ${aktiv ? C.accent : C.borderStrong}`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>
                    {aktiv && <Icon name="check" size={10} color="#fff" />}
                  </div>
                  <span style={{ flex: 1, fontSize: 12, color: C.text }}>{f.name}</span>
                  <span style={{ fontSize: 10, color: C.textSoft, minWidth: 28 }}>{f.attr}</span>
                  <span style={{ fontSize: 11, fontWeight: 600, color: bonus >= 0 ? C.green : C.red, minWidth: 24, textAlign: "right" }}>
                    {bonus >= 0 ? "+" : ""}{bonus}
                  </span>
                </div>
              );
            })}
          </div>
        </Card>
      </div>

      {/* RECHTS */}
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>

        {/* Kampfwerte */}
        <Card C={C}>
          <SectionTitle C={C}>Kampfwerte</SectionTitle>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8, marginBottom: 12 }}>
            <div>
              <Label C={C}>Stufe</Label>
              <AppInput type="number" value={char.stufe} onChange={e => setChar(c => ({ ...c, stufe: parseInt(e.target.value) || 1 }))} C={C} center />
            </div>
            <div>
              <Label C={C}>Max HP</Label>
              <AppInput type="number" value={char.maxHp} onChange={e => setChar(c => ({ ...c, maxHp: parseInt(e.target.value) || 0 }))} C={C} center />
            </div>
            <div>
              <Label C={C}>Basis AC</Label>
              <AppInput type="number" value={char.ac} onChange={e => setChar(c => ({ ...c, ac: parseInt(e.target.value) || 10 }))} C={C} center />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
            <div style={{
              padding: "10px 12px", borderRadius: 7, background: C.bgHover,
              border: `1px solid ${C.border}`,
            }}>
              <div style={{ fontSize: 10, color: C.textSoft, marginBottom: 2 }}>ÜBUNGSBONUS</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: C.accent }}>+{profBonus}</div>
              <div style={{ fontSize: 10, color: C.textSoft, marginTop: 1 }}>auto. berechnet</div>
            </div>
            <div>
              <Label C={C}>Initiative</Label>
              <AppInput type="number" value={char.initiative} onChange={e => setChar(c => ({ ...c, initiative: parseInt(e.target.value) || 0 }))} C={C} center />
            </div>
          </div>
        </Card>

        {/* Rettungswürfe */}
        <Card C={C}>
          <SectionTitle C={C}>Rettungswürfe</SectionTitle>
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            {RETTUNGSWUERFE.map(r => {
              const aktiv = char.rettungswuerfe?.includes(r);
              return (
                <div key={r} onClick={() => setChar(c => ({
                  ...c, rettungswuerfe: aktiv
                    ? (c.rettungswuerfe || []).filter(x => x !== r)
                    : [...(c.rettungswuerfe || []), r]
                }))} style={{
                  display: "flex", alignItems: "center", gap: 8,
                  padding: "6px 6px", borderRadius: 5, cursor: "pointer",
                }}
                  onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
                  onMouseLeave={e => e.currentTarget.style.background = "transparent"}
                >
                  <div style={{
                    width: 14, height: 14, borderRadius: 3, flexShrink: 0,
                    background: aktiv ? C.green : "transparent",
                    border: `1.5px solid ${aktiv ? C.green : C.borderStrong}`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>
                    {aktiv && <Icon name="check" size={10} color="#fff" />}
                  </div>
                  <span style={{ fontSize: 12, color: C.text }}>{r}</span>
                </div>
              );
            })}
          </div>
        </Card>

        {/* Währung */}
        <Card C={C}>
          <SectionTitle C={C}>Währung</SectionTitle>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
            {[
              { key: "gold", label: "Gold", color: "#d4890a" },
              { key: "silber", label: "Silber", color: C.textMid },
              { key: "kupfer", label: "Kupfer", color: "#b45309" },
            ].map(w => (
              <div key={w.key}>
                <div style={{ fontSize: 10, color: w.color, fontWeight: 500, marginBottom: 4 }}>{w.label}</div>
                <input type="number" value={char[w.key] || 0}
                  onChange={e => setChar(c => ({ ...c, [w.key]: parseInt(e.target.value) || 0 }))}
                  style={{
                    width: "100%", padding: "8px 6px",
                    background: C.bgHover, border: `1px solid ${w.color}33`,
                    borderRadius: 7, fontSize: 14, fontWeight: 600, color: w.color,
                    fontFamily: "inherit", outline: "none", textAlign: "center", boxSizing: "border-box",
                  }} />
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
};

// ── TAB: ATTRIBUTE ────────────────────────────────────────────────────────────
const TabAttribute = ({ char, setChar, C }) => {
  const attrs = [
    { key: "STÄ", label: "Stärke" },
    { key: "GES", label: "Geschicklichkeit" },
    { key: "KON", label: "Konstitution" },
    { key: "INT", label: "Intelligenz" },
    { key: "WEI", label: "Weisheit" },
    { key: "CHA", label: "Charisma" },
  ];

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
      {/* Links: Attribute Grid */}
      <Card C={C}>
        <SectionTitle C={C}>Attributspunkte</SectionTitle>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 14 }}>
          {attrs.map(a => (
            <StatBox key={a.key} label={a.label}
              value={char.attribute?.[a.key] || 10}
              onChange={e => setChar(c => ({ ...c, attribute: { ...c.attribute, [a.key]: parseInt(e.target.value) || 10 } }))}
              C={C} color={ATTR_FARBE[a.key]} />
          ))}
        </div>
        <div style={{ marginTop: 14, padding: "10px 12px", borderRadius: 7, background: C.bgHover, border: `1px solid ${C.border}` }}>
          <div style={{ fontSize: 11, color: C.textSoft }}>
            Punktekauf: {attrs.reduce((sum, a) => {
              const v = char.attribute?.[a.key] || 10;
              return sum + Math.max(0, v - 8);
            }, 0)} / 27 Punkte verwendet
          </div>
        </div>
      </Card>

      {/* Rechts: Modifier Übersicht */}
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        <Card C={C}>
          <SectionTitle C={C}>Modifier Übersicht</SectionTitle>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {attrs.map(a => {
              const val = char.attribute?.[a.key] || 10;
              const mod = Math.floor((val - 10) / 2);
              const color = ATTR_FARBE[a.key];
              return (
                <div key={a.key} style={{
                  display: "flex", alignItems: "center", gap: 10,
                  padding: "6px 10px", borderRadius: 7, background: color + "10",
                  border: `1px solid ${color}22`,
                }}>
                  <div style={{ width: 6, height: 6, borderRadius: "50%", background: color, flexShrink: 0 }} />
                  <span style={{ flex: 1, fontSize: 12, color: C.textMid }}>{a.label}</span>
                  <span style={{ fontSize: 13, fontWeight: 600, color: C.text }}>{val}</span>
                  <span style={{ fontSize: 13, fontWeight: 700, color: mod >= 0 ? C.green : C.red, minWidth: 32, textAlign: "right" }}>
                    {mod >= 0 ? "+" : ""}{mod}
                  </span>
                </div>
              );
            })}
          </div>
        </Card>

        {/* Trefferwürfel */}
        <Card C={C}>
          <SectionTitle C={C}>Trefferwürfel</SectionTitle>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{
              width: 48, height: 48, borderRadius: 10,
              background: C.accent + "20", border: `2px solid ${C.accent}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 18, fontWeight: 700, color: C.accent,
            }}>d8</div>
            <div>
              <div style={{ fontSize: 13, color: C.text }}>Stufe {char.stufe} × d8</div>
              <div style={{ fontSize: 11, color: C.textSoft, marginTop: 2 }}>Für Kurzrast verwenden</div>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
};

// ── TAB: D&D DETAILS ──────────────────────────────────────────────────────────
const TabDnD = ({ char, setChar, C }) => (
  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <Card C={C}>
        <SectionTitle C={C}>Grunddaten</SectionTitle>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <div>
            <Label C={C}>Größe</Label>
            <AppSelect value={char.groesse} onChange={e => setChar(c => ({ ...c, groesse: e.target.value }))} options={GROESSEN} C={C} />
          </div>
          <div>
            <Label C={C}>Ausrichtung</Label>
            <AppSelect value={char.ausrichtung} onChange={e => setChar(c => ({ ...c, ausrichtung: e.target.value }))} options={AUSRICHTUNGEN} C={C} />
          </div>
        </div>
      </Card>

      <Card C={C}>
        <SectionTitle C={C}>Beschreibung</SectionTitle>
        <textarea value={char.beschreibung} onChange={e => setChar(c => ({ ...c, beschreibung: e.target.value }))}
          placeholder="Charakterbeschreibung, Hintergrundgeschichte..." rows={5}
          style={{
            width: "100%", padding: "8px 10px",
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 7, fontSize: 13, color: C.text,
            fontFamily: "inherit", outline: "none", resize: "vertical",
            lineHeight: 1.5, boxSizing: "border-box",
          }}
          onFocus={e => e.target.style.borderColor = C.accent}
          onBlur={e => e.target.style.borderColor = C.border} />
      </Card>
    </div>

    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <Card C={C}>
        <SectionTitle C={C}>Spezielle Fähigkeiten</SectionTitle>
        <textarea value={char.faehigkeiten} onChange={e => setChar(c => ({ ...c, faehigkeiten: e.target.value }))}
          placeholder="Klassenfähigkeiten, Rassenmerkmale..." rows={4}
          style={{
            width: "100%", padding: "8px 10px",
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 7, fontSize: 13, color: C.text,
            fontFamily: "inherit", outline: "none", resize: "vertical",
            lineHeight: 1.5, boxSizing: "border-box",
          }}
          onFocus={e => e.target.style.borderColor = C.accent}
          onBlur={e => e.target.style.borderColor = C.border} />
      </Card>

      <Card C={C}>
        <SectionTitle C={C}>Angriffe</SectionTitle>
        <textarea value={char.angriffe} onChange={e => setChar(c => ({ ...c, angriffe: e.target.value }))}
          placeholder="Angriffe und Schadenswürfel..." rows={4}
          style={{
            width: "100%", padding: "8px 10px",
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 7, fontSize: 13, color: C.text,
            fontFamily: "inherit", outline: "none", resize: "vertical",
            lineHeight: 1.5, boxSizing: "border-box",
          }}
          onFocus={e => e.target.style.borderColor = C.accent}
          onBlur={e => e.target.style.borderColor = C.border} />
      </Card>

      <Card C={C}>
        <SectionTitle C={C}>Optionen</SectionTitle>
        {[
          { key: "customContent", label: "Benutzerdefinierte Inhalte", desc: "Eigene Inhalte erstellen" },
          { key: "oeffentlich", label: "Öffentlich", desc: "Für andere Spieler sichtbar" },
        ].map(opt => (
          <div key={opt.key} style={{
            display: "flex", alignItems: "center", justifyContent: "space-between",
            padding: "8px 0", borderBottom: `1px solid ${C.border}`,
          }}>
            <div>
              <div style={{ fontSize: 13, color: C.text }}>{opt.label}</div>
              <div style={{ fontSize: 11, color: C.textSoft }}>{opt.desc}</div>
            </div>
            <Toggle on={char[opt.key]} onChange={v => setChar(c => ({ ...c, [opt.key]: v }))} C={C} />
          </div>
        ))}
      </Card>
    </div>
  </div>
);

// ── TAB: INVENTAR ─────────────────────────────────────────────────────────────
const TabInventar = ({ char, setChar, C }) => {
  const [kategorie, setKategorie] = useState("Alle");

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>

      {/* Links: Ausrüstungs-Slots */}
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        <Card C={C}>
          <SectionTitle C={C}>Ausrüstung ({(char.ausruestung || []).filter(Boolean).length}/{AUSRUESTUNG_SLOTS.length})</SectionTitle>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 6 }}>
            {AUSRUESTUNG_SLOTS.map((slot, i) => (
              <div key={i} style={{
                padding: "10px 6px", borderRadius: 7, textAlign: "center",
                background: C.bgHover, border: `1px solid ${C.border}`,
                cursor: "pointer", transition: "border-color 0.15s",
              }}
                onMouseEnter={e => e.currentTarget.style.borderColor = C.borderStrong}
                onMouseLeave={e => e.currentTarget.style.borderColor = C.border}
              >
                <div style={{ fontSize: 18, marginBottom: 4 }}>
                  <Icon name="bag" size={16} color={C.textSoft} />
                </div>
                <div style={{ fontSize: 10, color: C.textSoft }}>{slot}</div>
              </div>
            ))}
          </div>
        </Card>

        {/* Währung */}
        <Card C={C}>
          <SectionTitle C={C}>Währung</SectionTitle>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
            {[
              { key: "gold", label: "Gold", color: "#d4890a" },
              { key: "silber", label: "Silber", color: C.textMid },
              { key: "kupfer", label: "Kupfer", color: "#b45309" },
            ].map(w => (
              <div key={w.key} style={{ textAlign: "center" }}>
                <div style={{ fontSize: 10, color: w.color, fontWeight: 500, marginBottom: 4 }}>{w.label}</div>
                <input type="number" value={char[w.key] || 0}
                  onChange={e => setChar(c => ({ ...c, [w.key]: parseInt(e.target.value) || 0 }))}
                  style={{
                    width: "100%", padding: "8px 4px",
                    background: C.bgHover, border: `1px solid ${w.color}33`,
                    borderRadius: 7, fontSize: 16, fontWeight: 700, color: w.color,
                    fontFamily: "inherit", outline: "none", textAlign: "center", boxSizing: "border-box",
                  }} />
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Rechts: Inventar Liste */}
      <Card C={C} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <SectionTitle C={C}>Inventar</SectionTitle>
          <button style={{
            display: "flex", alignItems: "center", gap: 4,
            padding: "5px 10px", borderRadius: 6,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 11, fontWeight: 500,
            cursor: "pointer", fontFamily: "inherit",
          }}>
            <Icon name="plus" size={11} color="#fff" />
            Hinzufügen
          </button>
        </div>

        {/* Kategorien */}
        <div style={{ display: "flex", flexWrap: "wrap", gap: 4 }}>
          {INVENTAR_KATEGORIEN.slice(0, 6).map(k => (
            <button key={k} onClick={() => setKategorie(k)} style={{
              padding: "3px 9px", borderRadius: 5,
              background: kategorie === k ? C.accent : C.bgHover,
              border: `1px solid ${kategorie === k ? C.accent : C.border}`,
              color: kategorie === k ? "#fff" : C.textMid,
              fontSize: 11, cursor: "pointer", fontFamily: "inherit",
              transition: "all 0.15s",
            }}>{k}</button>
          ))}
        </div>

        {/* Leer-Zustand */}
        <div style={{
          flex: 1, display: "flex", flexDirection: "column",
          alignItems: "center", justifyContent: "center",
          padding: "30px 20px", color: C.textSoft,
          border: `1.5px dashed ${C.border}`, borderRadius: 8, marginTop: 4,
        }}>
          <Icon name="bag" size={28} color={C.border} />
          <div style={{ fontSize: 13, marginTop: 10, color: C.textSoft }}>Inventar ist leer</div>
          <div style={{ fontSize: 11, marginTop: 4, color: C.textSoft }}>Füge Gegenstände aus der Bibliothek hinzu</div>
        </div>
      </Card>
    </div>
  );
};

// ── HAUPT ─────────────────────────────────────────────────────────────────────
export default function CharakterEditor() {
  const [isDark, setIsDark] = useState(false);
  const [aktTab, setAktTab] = useState("stamm");
  const [char, setChar] = useState({
    name: "Ayleen", spieler: "Ayleen",
    klasse: "Barbar", rasse: "Zwerg",
    stufe: 1, maxHp: 10, ac: 10, initiative: 0,
    attribute: { STÄ: 10, GES: 10, KON: 10, INT: 10, WEI: 10, CHA: 10 },
    fertigkeiten: [], rettungswuerfe: [],
    groesse: "Mittel", ausrichtung: "Neutral",
    beschreibung: "", faehigkeiten: "", angriffe: "",
    gold: 0, silber: 0, kupfer: 0,
    customContent: true, oeffentlich: false,
  });

  const C = THEMES[isDark ? "dark" : "light"];
  const farbe = KLASSE_FARBE[char.klasse] || C.accent;

  const tabs = [
    { id: "stamm", label: "Stammdaten", icon: "user" },
    { id: "attribute", label: "Attribute", icon: "star" },
    { id: "dnd", label: "D&D Details", icon: "dnd" },
    { id: "inventar", label: "Inventar", icon: "bag" },
  ];

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
        padding: "0 16px", flexShrink: 0,
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

          {/* Charakter Avatar */}
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{
              width: 28, height: 28, borderRadius: 7,
              background: farbe + "20", border: `1.5px solid ${farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ fontSize: 13, fontWeight: 700, color: farbe }}>{char.name?.[0] || "?"}</span>
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600, color: C.text, lineHeight: 1 }}>{char.name || "Held"}</div>
              <div style={{ fontSize: 10, color: C.textSoft }}>Lvl {char.stufe} {char.klasse} · {char.rasse}</div>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div style={{ display: "flex", gap: 2 }}>
          {tabs.map(t => (
            <button key={t.id} onClick={() => setAktTab(t.id)} style={{
              display: "flex", alignItems: "center", gap: 5,
              padding: "6px 12px", borderRadius: 7, border: "none",
              background: aktTab === t.id ? C.bgActive : "transparent",
              color: aktTab === t.id ? C.text : C.textMid,
              fontSize: 12, fontWeight: aktTab === t.id ? 500 : 400,
              cursor: "pointer", fontFamily: "inherit", transition: "all 0.15s",
            }}>
              <Icon name={t.icon} size={13} color={aktTab === t.id ? C.accent : C.textSoft} />
              {t.label}
            </button>
          ))}
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <button onClick={() => setIsDark(d => !d)} style={{
            width: 32, height: 32, borderRadius: 7,
            background: C.bgHover, border: `1px solid ${C.border}`,
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
          </button>
          <button style={{
            display: "flex", alignItems: "center", gap: 6,
            padding: "7px 14px", borderRadius: 7,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 12, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
          }}>
            <Icon name="save" size={13} color="#fff" />
            Speichern
          </button>
        </div>
      </div>

      {/* INHALT */}
      <div style={{ flex: 1, overflow: "auto", padding: "16px" }}>
        {aktTab === "stamm" && <TabStammdaten char={char} setChar={setChar} C={C} />}
        {aktTab === "attribute" && <TabAttribute char={char} setChar={setChar} C={C} />}
        {aktTab === "dnd" && <TabDnD char={char} setChar={setChar} C={C} />}
        {aktTab === "inventar" && <TabInventar char={char} setChar={setChar} C={C} />}
      </div>

      <style>{`
        * { box-sizing: border-box; }
        input::placeholder, textarea::placeholder { color: ${C.textSoft}; }
        select option { background: ${C.bgPanel}; color: ${C.text}; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
        textarea { font-family: inherit; }
      `}</style>
    </div>
  );
}
