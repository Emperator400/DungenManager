import { useState } from "react";

const THEMES = {
  light: {
    bg: "#f7f7f5", bgPanel: "#ffffff", bgHover: "#f0f0ed", bgActive: "#eeecea",
    border: "#e4e4e0", borderStrong: "#d0d0ca",
    text: "#1a1a18", textMid: "#6b6b66", textSoft: "#9f9f98",
    accent: "#2f6feb", accentSoft: "#eef3fd",
    green: "#1a7f4b", greenSoft: "#eaf4ee",
    amber: "#b45309", amberSoft: "#fdf6ec",
    red: "#c93a3a", redSoft: "#fdf0f0",
    purple: "#7c3aed", purpleSoft: "#f3effe",
    overlay: "rgba(0,0,0,0.3)",
  },
  dark: {
    bg: "#111110", bgPanel: "#1a1a18", bgHover: "#232320", bgActive: "#2a2a27",
    border: "#2e2e2b", borderStrong: "#3d3d39",
    text: "#edede8", textMid: "#8a8a82", textSoft: "#5a5a54",
    accent: "#4f8ef7", accentSoft: "#1a2540",
    green: "#34c471", greenSoft: "#0f2a1c",
    amber: "#d4890a", amberSoft: "#2a1f08",
    red: "#e05555", redSoft: "#2a1212",
    purple: "#a78bfa", purpleSoft: "#1e1330",
    overlay: "rgba(0,0,0,0.6)",
  },
};

const SZENEN_TYPEN = ["Einführung","Sozial","Erforschung","Kampf","Rätsel","Abschluss","Reise","Händler","Rast"];

const TYP_FARBE = {
  Einführung: "#2f6feb", Sozial: "#7c3aed", Erforschung: "#1a7f4b",
  Kampf: "#c93a3a", Rätsel: "#b45309", Abschluss: "#0891b2",
  Reise: "#065f46", Händler: "#d4890a", Rast: "#6b6b66",
};

const MOCK_CHARAKTERE = ["Benedict ex Sancitas (Lvl 1)", "Lüthien Eireannon (Lvl 1)", "Johann (Lvl 1)", "Ayleen (Lvl 1)", "Jören (Lvl 1)"];
const MOCK_QUESTS = ["Der Haderhügel", "Gnomengrad", "Die Zwergenausgrabung"];
const MOCK_SOUNDS = ["cave-1", "cave-2", "summer-summer-atmosphere", "thunder-1"];
const MOCK_WIKI = ["Phandalin", "Rathaus", "Gasthaus Steinhügel", "Barthens Proviant"];

const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    close: "M4 4l8 8M12 4l-8 8",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
    plus: "M8 3v10M3 8h10",
    chevDown: "M4 6l4 4 4-4",
    user: "M8 7a3 3 0 100-6 3 3 0 000 6zm-5 9a5 5 0 0110 0",
    flag: "M3 14V3l10 4-10 4",
    music: "M9 3v8.5a2.5 2.5 0 11-1-2V6L5 7V4l4-1z",
    book: "M3 3h8l2 2v10H3V3zm4 5h4M7 11h4",
    scroll: "M4 2h8a1 1 0 011 1v12l-4.5-2L4 15V3a1 1 0 011-1z",
    check: "M4 8l3 3 5-5",
    trash: "M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} />
    </svg>
  );
};

// ── AUSWAHL MODAL ──────────────────────────────────────────────────────────────
const AuswahlModal = ({ titel, optionen, ausgewaehlt, onToggle, onClose, C, isDark }) => (
  <div onClick={onClose} style={{
    position: "fixed", inset: 0, zIndex: 100,
    background: C.overlay, backdropFilter: "blur(2px)",
    display: "flex", alignItems: "center", justifyContent: "center",
  }}>
    <div onClick={e => e.stopPropagation()} style={{
      width: "min(360px, 90vw)", background: C.bgPanel,
      border: `1px solid ${C.border}`, borderRadius: 12,
      overflow: "hidden",
      boxShadow: isDark ? "0 20px 60px rgba(0,0,0,0.6)" : "0 20px 60px rgba(0,0,0,0.12)",
    }}>
      <div style={{ padding: "14px 16px", borderBottom: `1px solid ${C.border}`, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{titel}</span>
        <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", width: 28, height: 28, borderRadius: 6 }}
          onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
          onMouseLeave={e => e.currentTarget.style.background = "none"}
        ><Icon name="close" size={13} color={C.textMid} /></button>
      </div>
      <div style={{ maxHeight: 300, overflow: "auto" }}>
        {optionen.map((opt, i) => {
          const aktiv = ausgewaehlt.includes(opt);
          return (
            <div key={i} onClick={() => onToggle(opt)} style={{
              display: "flex", alignItems: "center", gap: 10,
              padding: "10px 16px", cursor: "pointer",
              borderBottom: `1px solid ${C.border}`,
              background: aktiv ? C.bgActive : "transparent",
              transition: "background 0.15s",
            }}
              onMouseEnter={e => { if (!aktiv) e.currentTarget.style.background = C.bgHover; }}
              onMouseLeave={e => { if (!aktiv) e.currentTarget.style.background = "transparent"; }}
            >
              <div style={{
                width: 16, height: 16, borderRadius: 4, flexShrink: 0,
                background: aktiv ? C.accent : "transparent",
                border: `1.5px solid ${aktiv ? C.accent : C.borderStrong}`,
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>
                {aktiv && <Icon name="check" size={10} color="#fff" />}
              </div>
              <span style={{ fontSize: 13, color: C.text }}>{opt}</span>
            </div>
          );
        })}
      </div>
      <div style={{ padding: "10px 16px", borderTop: `1px solid ${C.border}`, display: "flex", justifyContent: "flex-end" }}>
        <button onClick={onClose} style={{
          padding: "7px 16px", borderRadius: 7,
          background: C.accent, border: "none",
          color: "#fff", fontSize: 12, fontWeight: 600,
          cursor: "pointer", fontFamily: "inherit",
        }}>Fertig</button>
      </div>
    </div>
  </div>
);

// ── SZENE EDITOR SEITENLEISTE ─────────────────────────────────────────────────
const SzeneEditor = ({ szene, C, isDark, onClose, onSave }) => {
  const isNeu = !szene?.id;
  const [form, setForm] = useState({
    titel: szene?.titel || "",
    typ: szene?.typ || "Erforschung",
    beschreibung: szene?.beschreibung || "",
    charaktere: szene?.charaktere || [],
    quests: szene?.quests || [],
    sounds: szene?.sounds || [],
    wiki: szene?.wiki || [],
  });
  const [auswahlModal, setAuswahlModal] = useState(null);
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const toggleItem = (key, item) => {
    setForm(f => ({
      ...f,
      [key]: f[key].includes(item) ? f[key].filter(x => x !== item) : [...f[key], item],
    }));
  };

  const removeItem = (key, item) => setForm(f => ({ ...f, [key]: f[key].filter(x => x !== item) }));

  const farbe = TYP_FARBE[form.typ] || C.accent;

  const inputStyle = {
    width: "100%", padding: "9px 10px",
    background: C.bgHover, border: `1px solid ${C.border}`,
    borderRadius: 7, fontSize: 13, color: C.text,
    fontFamily: "inherit", outline: "none", boxSizing: "border-box",
  };

  const SectionHeader = ({ icon, label, count, onAdd, addLabel, color }) => (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <Icon name={icon} size={13} color={color || C.textSoft} />
        <span style={{ fontSize: 12, fontWeight: 600, color: C.text }}>{label}</span>
        <span style={{ fontSize: 10, color: C.textSoft, background: C.bgHover, padding: "1px 6px", borderRadius: 4 }}>{count}</span>
      </div>
      {onAdd && (
        <button onClick={onAdd} style={{
          display: "flex", alignItems: "center", gap: 4,
          padding: "4px 9px", borderRadius: 6,
          background: "transparent", border: `1px solid ${C.border}`,
          color: C.textMid, fontSize: 11, cursor: "pointer", fontFamily: "inherit",
        }}
          onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
          onMouseLeave={e => e.currentTarget.style.background = "transparent"}
        >
          <Icon name="plus" size={11} color={C.textSoft} />
          {addLabel}
        </button>
      )}
    </div>
  );

  const TagList = ({ items, onRemove, color }) => (
    <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
      {items.map((item, i) => (
        <span key={i} style={{
          display: "flex", alignItems: "center", gap: 5,
          fontSize: 11, color: color || C.textMid,
          background: color ? color + "15" : C.bgHover,
          border: `1px solid ${color ? color + "33" : C.border}`,
          padding: "3px 8px", borderRadius: 5,
        }}>
          {item}
          <button onClick={() => onRemove(item)} style={{
            background: "none", border: "none", cursor: "pointer",
            color: C.textSoft, padding: 0, display: "flex", alignItems: "center",
            fontSize: 13, lineHeight: 1,
          }}>×</button>
        </span>
      ))}
      {items.length === 0 && (
        <span style={{ fontSize: 12, color: C.textSoft, fontStyle: "italic" }}>Keine verknüpft</span>
      )}
    </div>
  );

  return (
    <>
      {/* Backdrop */}
      <div onClick={onClose} style={{
        position: "fixed", inset: 0, zIndex: 40,
        background: C.overlay, backdropFilter: "blur(2px)",
        animation: "fadeIn 0.2s ease",
      }} />

      {/* Seitenleiste */}
      <div style={{
        position: "fixed", top: 0, right: 0, bottom: 0,
        width: "min(440px, 92vw)", zIndex: 50,
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
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{
              width: 28, height: 28, borderRadius: 7,
              background: farbe + "20", border: `1.5px solid ${farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <Icon name="scroll" size={13} color={farbe} />
            </div>
            <h2 style={{ margin: 0, fontSize: 15, fontWeight: 600, color: C.text }}>
              {isNeu ? "Neue Szene" : "Szene bearbeiten"}
            </h2>
          </div>
          <button onClick={onClose} style={{
            width: 28, height: 28, borderRadius: 6, background: "transparent",
            border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          ><Icon name="close" size={14} color={C.textMid} /></button>
        </div>

        {/* Body */}
        <div style={{ flex: 1, overflow: "auto", padding: "16px" }}>

          {/* Grundinformationen */}
          <div style={{
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 10, padding: "14px", marginBottom: 12,
          }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: C.textSoft, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 10 }}>
              Grundinformationen
            </div>
            <div style={{ marginBottom: 10 }}>
              <div style={{ fontSize: 11, color: C.textSoft, marginBottom: 4 }}>Name *</div>
              <input value={form.titel} onChange={e => set("titel", e.target.value)}
                placeholder="Szenen-Name" style={inputStyle}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
            </div>
            <div>
              <div style={{ fontSize: 11, color: C.textSoft, marginBottom: 4 }}>Szenen-Typ</div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
                {SZENEN_TYPEN.map(t => {
                  const f = TYP_FARBE[t] || C.textSoft;
                  const aktiv = form.typ === t;
                  return (
                    <button key={t} onClick={() => set("typ", t)} style={{
                      padding: "4px 10px", borderRadius: 6,
                      background: aktiv ? f + "20" : "transparent",
                      border: `1px solid ${aktiv ? f : C.border}`,
                      color: aktiv ? f : C.textMid,
                      fontSize: 11, fontWeight: aktiv ? 500 : 400,
                      cursor: "pointer", fontFamily: "inherit",
                      transition: "all 0.15s",
                    }}>{t}</button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Beschreibung */}
          <div style={{
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 10, padding: "14px", marginBottom: 12,
          }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: C.textSoft, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 10 }}>
              Beschreibung
            </div>
            <textarea value={form.beschreibung} onChange={e => set("beschreibung", e.target.value)}
              placeholder="Szenen-Beschreibung, DM-Notizen, wichtige Details..." rows={5}
              style={{ ...inputStyle, resize: "vertical", lineHeight: 1.6 }}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
          </div>

          {/* Charaktere */}
          <div style={{
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 10, padding: "14px", marginBottom: 12,
          }}>
            <SectionHeader icon="user" label="Charaktere" count={form.charaktere.length}
              onAdd={() => setAuswahlModal("charaktere")} addLabel="Hinzufügen"
              color={C.accent} />
            <TagList items={form.charaktere} onRemove={item => removeItem("charaktere", item)} />
          </div>

          {/* Quests */}
          <div style={{
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 10, padding: "14px", marginBottom: 12,
          }}>
            <SectionHeader icon="flag" label="Quests" count={form.quests.length}
              onAdd={() => setAuswahlModal("quests")} addLabel="Hinzufügen"
              color={C.amber} />
            <TagList items={form.quests} onRemove={item => removeItem("quests", item)} color={C.amber} />
          </div>

          {/* Sounds */}
          <div style={{
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 10, padding: "14px", marginBottom: 12,
          }}>
            <SectionHeader icon="music" label="Sounds" count={form.sounds.length}
              onAdd={() => setAuswahlModal("sounds")} addLabel="Hinzufügen"
              color={C.green} />
            <TagList items={form.sounds} onRemove={item => removeItem("sounds", item)} color={C.green} />
          </div>

          {/* Wiki-Einträge */}
          <div style={{
            background: C.bgHover, border: `1px solid ${C.border}`,
            borderRadius: 10, padding: "14px", marginBottom: 4,
          }}>
            <SectionHeader icon="book" label="Wiki-Einträge" count={form.wiki.length}
              onAdd={() => setAuswahlModal("wiki")} addLabel="Hinzufügen"
              color={C.purple} />
            <TagList items={form.wiki} onRemove={item => removeItem("wiki", item)} color={C.purple} />
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
            {isNeu ? "Szene erstellen" : "Speichern"}
          </button>
        </div>
      </div>

      {/* Auswahl Modal */}
      {auswahlModal && (
        <AuswahlModal
          titel={{
            charaktere: "Charaktere verknüpfen",
            quests: "Quests verknüpfen",
            sounds: "Sounds verknüpfen",
            wiki: "Wiki-Einträge verknüpfen",
          }[auswahlModal]}
          optionen={{
            charaktere: MOCK_CHARAKTERE,
            quests: MOCK_QUESTS,
            sounds: MOCK_SOUNDS,
            wiki: MOCK_WIKI,
          }[auswahlModal]}
          ausgewaehlt={form[auswahlModal]}
          onToggle={item => toggleItem(auswahlModal, item)}
          onClose={() => setAuswahlModal(null)}
          C={C} isDark={isDark}
        />
      )}

      <style>{`
        @keyframes fadeIn { from { opacity:0 } to { opacity:1 } }
        @keyframes slideInRight { from { transform:translateX(100%) } to { transform:translateX(0) } }
        textarea { font-family: inherit; }
        * { box-sizing: border-box; }
        input::placeholder, textarea::placeholder { color: ${C.textSoft}; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
      `}</style>
    </>
  );
};

// ── DEMO WRAPPER ──────────────────────────────────────────────────────────────
export default function SzeneEditorDemo() {
  const [isDark, setIsDark] = useState(false);
  const [offen, setOffen] = useState(true);
  const C = THEMES[isDark ? "dark" : "light"];

  return (
    <div style={{
      fontFamily: "-apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif",
      background: C.bg, height: "100vh", overflow: "hidden",
      color: C.text, fontSize: 13,
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      transition: "background 0.25s",
    }}>
      <button onClick={() => setIsDark(d => !d)} style={{
        position: "absolute", top: 16, right: 16,
        width: 32, height: 32, borderRadius: 7,
        background: C.bgPanel, border: `1px solid ${C.border}`,
        cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
      }}>
        <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
      </button>

      {!offen && (
        <button onClick={() => setOffen(true)} style={{
          display: "flex", alignItems: "center", gap: 6,
          padding: "10px 20px", borderRadius: 8,
          background: C.accent, border: "none",
          color: "#fff", fontSize: 13, fontWeight: 600,
          cursor: "pointer", fontFamily: "inherit",
        }}>
          <Icon name="plus" size={14} color="#fff" />
          Neue Szene erstellen
        </button>
      )}

      {offen && (
        <SzeneEditor
          szene={null}
          C={C} isDark={isDark}
          onClose={() => setOffen(false)}
          onSave={(form) => { console.log("Gespeichert:", form); setOffen(false); }}
        />
      )}
    </div>
  );
}
