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
    overlay: "rgba(0,0,0,0.6)",
  },
};

const KLASSEN = ["Barbar", "Barde", "Kleriker", "Druide", "Kämpfer", "Mönch", "Paladin", "Waldläufer", "Schurke", "Zauberer", "Hexenmeister", "Magier"];
const KLASSE_FARBE = {
  Barbar: "#c93a3a", Barde: "#7c3aed", Kleriker: "#d4890a",
  Druide: "#1a7f4b", Kämpfer: "#6b6b66", Mönch: "#0891b2",
  Paladin: "#2f6feb", Waldläufer: "#065f46", Schurke: "#4a4a4a",
  Zauberer: "#be185d", Hexenmeister: "#4A235A", Magier: "#1B4F72",
};

const initHelden = [
  { id: 1, name: "Gorim Eisenfaust", klasse: "Kämpfer", level: 5, spieler: "Max" },
  { id: 2, name: "Lyria Mondschein", klasse: "Magier", level: 5, spieler: "Anna" },
  { id: 3, name: "Finn der Leise", klasse: "Schurke", level: 4, spieler: "Tom" },
];

const initSessions = [
  { id: 1, titel: "Der erste Aufbruch", datum: "12.1.2026", status: "done" },
  { id: 2, titel: "Die Taverne brennt", datum: "26.1.2026", status: "done" },
  { id: 3, titel: "Im Dunkel des Tempels", datum: "14.4.2026", status: "aktiv" },
];

const kampagne = {
  name: "Die Verlorene Krone",
  system: "D&D 5e", status: "Aktiv",
  erstellt: "12.1.2026", farbe: "#2f6feb",
};

// ── ICONS ─────────────────────────────────────────────────────────────────────
const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    back: "M10 3L5 8l5 5",
    plus: "M8 3v10M3 8h10",
    user: "M8 7a3 3 0 100-6 3 3 0 000 6zm-5 9a5 5 0 0110 0",
    play: "M4 3l10 5-10 5V3z",
    close: "M4 4l8 8M12 4l-8 8",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
    chevronDown: "M4 6l4 4 4-4",
    edit: "M11 3l2 2-8 8H3v-2l8-8z",
    calendar: "M3 5h10a1 1 0 011 1v8a1 1 0 01-1 1H3a1 1 0 01-1-1V6a1 1 0 011-1zm0 0V3m10 2V3",
    check: "M4 8l3 3 5-5",
    scroll: "M4 2h8a1 1 0 011 1v12l-4.5-2L4 15V3a1 1 0 011-1z",
    trash: "M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} fill={name === "play" ? color : "none"} />
    </svg>
  );
};

// ── HELD MODAL ────────────────────────────────────────────────────────────────
const HeldModal = ({ held, C, isDark, onSave, onClose }) => {
  const isNeu = !held?.id;
  const [form, setForm] = useState({
    name: held?.name || "",
    klasse: held?.klasse || "Kämpfer",
    level: held?.level || 1,
    spieler: held?.spieler || "",
  });
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));
  const farbe = KLASSE_FARBE[form.klasse] || C.accent;

  return (
    <div onClick={onClose} style={{
      position: "fixed", inset: 0, zIndex: 50,
      background: C.overlay, backdropFilter: "blur(4px)",
      display: "flex", alignItems: "center", justifyContent: "center",
      animation: "fadeIn 0.2s ease",
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        width: "min(420px, 92vw)",
        background: C.bgPanel, border: `1px solid ${C.border}`,
        borderRadius: 14, overflow: "hidden",
        boxShadow: isDark ? "0 24px 60px rgba(0,0,0,0.6)" : "0 24px 60px rgba(0,0,0,0.12)",
        animation: "slideUp 0.25s cubic-bezier(0.34,1.56,0.64,1)",
      }}>

        {/* Header */}
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "16px 20px", borderBottom: `1px solid ${C.border}`,
        }}>
          <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: C.text }}>
            {isNeu ? "Neuer Held" : "Held bearbeiten"}
          </h2>
          <button onClick={onClose} style={{
            width: 30, height: 30, borderRadius: 7, background: "transparent",
            border: "none", cursor: "pointer",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          ><Icon name="close" size={14} color={C.textMid} /></button>
        </div>

        {/* Body */}
        <div style={{ padding: 20 }}>

          {/* Vorschau */}
          <div style={{
            display: "flex", alignItems: "center", gap: 12,
            padding: "12px 14px", borderRadius: 10,
            background: C.bgHover, border: `1px solid ${C.border}`,
            marginBottom: 20,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: farbe + "22", border: `1.5px solid ${farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
            }}>
              <span style={{ fontSize: 16, fontWeight: 700, color: farbe }}>
                {form.name?.[0] || "?"}
              </span>
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>
                {form.name || "Heldenname"}
              </div>
              <div style={{ fontSize: 11, color: C.textSoft, marginTop: 1 }}>
                Lvl {form.level} {form.klasse} · {form.spieler || "Spieler"}
              </div>
            </div>
          </div>

          {/* Name */}
          <div style={{ marginBottom: 14 }}>
            <label style={{ display: "block", fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>Name</label>
            <input value={form.name} onChange={e => set("name", e.target.value)}
              placeholder="Heldenname" style={{
                width: "100%", padding: "9px 12px",
                background: C.bgHover, border: `1px solid ${C.border}`,
                borderRadius: 7, fontSize: 13, color: C.text,
                fontFamily: "inherit", outline: "none", boxSizing: "border-box",
              }}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
          </div>

          {/* Spieler */}
          <div style={{ marginBottom: 14 }}>
            <label style={{ display: "block", fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>Spieler</label>
            <input value={form.spieler} onChange={e => set("spieler", e.target.value)}
              placeholder="Name des Spielers" style={{
                width: "100%", padding: "9px 12px",
                background: C.bgHover, border: `1px solid ${C.border}`,
                borderRadius: 7, fontSize: 13, color: C.text,
                fontFamily: "inherit", outline: "none", boxSizing: "border-box",
              }}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 80px", gap: 12 }}>
            {/* Klasse */}
            <div>
              <label style={{ display: "block", fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>Klasse</label>
              <div style={{ position: "relative" }}>
                <select value={form.klasse} onChange={e => set("klasse", e.target.value)} style={{
                  width: "100%", padding: "9px 32px 9px 12px",
                  background: C.bgHover, border: `1px solid ${C.border}`,
                  borderRadius: 7, fontSize: 13, color: C.text,
                  fontFamily: "inherit", outline: "none", appearance: "none",
                  boxSizing: "border-box", cursor: "pointer",
                }}>
                  {KLASSEN.map(k => <option key={k} value={k}>{k}</option>)}
                </select>
                <div style={{ position: "absolute", right: 10, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
                  <Icon name="chevronDown" size={13} color={C.textSoft} />
                </div>
              </div>
            </div>

            {/* Level */}
            <div>
              <label style={{ display: "block", fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>Level</label>
              <input type="number" min={1} max={20} value={form.level}
                onChange={e => set("level", parseInt(e.target.value) || 1)} style={{
                  width: "100%", padding: "9px 12px",
                  background: C.bgHover, border: `1px solid ${C.border}`,
                  borderRadius: 7, fontSize: 13, color: C.text,
                  fontFamily: "inherit", outline: "none", boxSizing: "border-box", textAlign: "center",
                }}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
            </div>
          </div>
        </div>

        {/* Footer */}
        <div style={{ display: "flex", gap: 8, padding: "14px 20px", borderTop: `1px solid ${C.border}` }}>
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
            {isNeu ? "Hinzufügen" : "Speichern"}
          </button>
        </div>
      </div>
    </div>
  );
};

// ── HELD KARTE ────────────────────────────────────────────────────────────────
const HeldCard = ({ held, C, onEdit }) => {
  const farbe = KLASSE_FARBE[held.klasse] || C.accent;
  const [hovered, setHovered] = useState(false);

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: C.bgPanel,
        border: `1px solid ${hovered ? C.borderStrong : C.border}`,
        borderRadius: 10, overflow: "hidden",
        transition: "all 0.18s ease",
        transform: hovered ? "translateY(-2px)" : "translateY(0)",
        boxShadow: hovered ? "0 6px 18px rgba(0,0,0,0.08)" : "none",
        cursor: "pointer",
      }}
    >
      {/* Farbstreifen */}
      <div style={{ height: 4, background: farbe }} />

      <div style={{ padding: "12px 14px" }}>
        {/* Avatar + Edit */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 10 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 9,
            background: farbe + "20", border: `1.5px solid ${farbe}40`,
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <span style={{ fontSize: 15, fontWeight: 700, color: farbe }}>{held.name[0]}</span>
          </div>
          {hovered && (
            <button onClick={e => { e.stopPropagation(); onEdit(held); }} style={{
              width: 26, height: 26, borderRadius: 6, border: "none",
              background: C.bgHover, cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <Icon name="edit" size={12} color={C.textSoft} />
            </button>
          )}
        </div>

        {/* Name */}
        <div style={{ fontSize: 13, fontWeight: 600, color: C.text, marginBottom: 2, lineHeight: 1.2 }}>
          {held.name}
        </div>

        {/* Klasse + Level */}
        <div style={{ fontSize: 11, color: C.textMid, marginBottom: 8 }}>
          Lvl {held.level} · {held.klasse}
        </div>

        {/* Spieler */}
        <div style={{
          display: "flex", alignItems: "center", gap: 5,
          padding: "4px 8px", borderRadius: 5,
          background: C.bgHover,
        }}>
          <Icon name="user" size={11} color={C.textSoft} />
          <span style={{ fontSize: 11, color: C.textSoft }}>{held.spieler}</span>
        </div>
      </div>
    </div>
  );
};

// ── SESSION ZEILE ─────────────────────────────────────────────────────────────
const SessionZeile = ({ session, C, isLast }) => {
  const isAktiv = session.status === "aktiv";
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: "10px 14px",
      borderBottom: isLast ? "none" : `1px solid ${C.border}`,
      cursor: "pointer", transition: "background 0.15s",
    }}
      onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
      onMouseLeave={e => e.currentTarget.style.background = "transparent"}
    >
      {/* Status Dot */}
      <div style={{
        width: 8, height: 8, borderRadius: "50%", flexShrink: 0,
        background: isAktiv ? C.green : C.textSoft,
        boxShadow: isAktiv ? `0 0 6px ${C.green}88` : "none",
      }} />

      {/* Info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, color: C.text, fontWeight: isAktiv ? 500 : 400 }}>
          {session.titel}
        </div>
      </div>

      {/* Datum */}
      <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
        <Icon name="calendar" size={11} color={C.textSoft} />
        <span style={{ fontSize: 11, color: C.textSoft }}>{session.datum}</span>
      </div>

      {/* Badge */}
      {isAktiv && (
        <span style={{
          fontSize: 10, fontWeight: 500, color: C.green,
          background: C.greenSoft, padding: "2px 7px", borderRadius: 4,
        }}>Aktiv</span>
      )}
    </div>
  );
};

// ── HAUPT ─────────────────────────────────────────────────────────────────────
export default function KampagnenHub() {
  const [isDark, setIsDark] = useState(false);
  const [helden, setHelden] = useState(initHelden);
  const [sessions] = useState(initSessions);
  const [modal, setModal] = useState(null); // null | held | "neu"

  const C = THEMES[isDark ? "dark" : "light"];

  const handleSave = (form) => {
    if (modal === "neu") {
      setHelden(prev => [...prev, { ...form, id: Date.now() }]);
    } else {
      setHelden(prev => prev.map(h => h.id === modal.id ? { ...h, ...form } : h));
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
            width: 30, height: 30, borderRadius: 7,
            background: "transparent", border: "none",
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          >
            <Icon name="back" size={16} color={C.textMid} />
          </button>
          <div style={{ width: 1, height: 18, background: C.border }} />
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{
              width: 22, height: 22, borderRadius: 6,
              background: kampagne.farbe + "22",
              border: `1.5px solid ${kampagne.farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ fontSize: 11, fontWeight: 700, color: kampagne.farbe }}>
                {kampagne.name[0]}
              </span>
            </div>
            <span style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{kampagne.name}</span>
            <span style={{ fontSize: 11, color: C.textSoft }}>{kampagne.system}</span>
          </div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{
            fontSize: 11, fontWeight: 500,
            color: C.green, background: C.greenSoft,
            padding: "3px 8px", borderRadius: 5,
          }}>{kampagne.status}</span>
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
      <div style={{ maxWidth: 900, margin: "0 auto", padding: "28px 24px 60px" }}>

        {/* Sessions starten Banner */}
        <button style={{
          width: "100%", padding: "14px 20px",
          background: C.accent, border: "none", borderRadius: 10,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
          cursor: "pointer", marginBottom: 28,
          boxShadow: `0 4px 16px ${C.accent}44`,
          transition: "opacity 0.15s",
        }}
          onMouseEnter={e => e.currentTarget.style.opacity = "0.92"}
          onMouseLeave={e => e.currentTarget.style.opacity = "1"}
        >
          <Icon name="play" size={15} color="#fff" />
          <span style={{ fontSize: 14, fontWeight: 600, color: "#fff" }}>Session starten</span>
        </button>

        {/* HELDEN SEKTION */}
        <div style={{ marginBottom: 28 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14 }}>
            <div>
              <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: C.text }}>Helden</h2>
              <p style={{ margin: "2px 0 0", fontSize: 12, color: C.textSoft }}>
                {helden.length} Charakter{helden.length !== 1 ? "e" : ""} in dieser Kampagne
              </p>
            </div>
            <button onClick={() => setModal("neu")} style={{
              display: "flex", alignItems: "center", gap: 5,
              padding: "7px 12px", borderRadius: 7,
              background: C.bgPanel, border: `1px solid ${C.border}`,
              color: C.textMid, fontSize: 12, fontWeight: 500,
              cursor: "pointer", fontFamily: "inherit",
              transition: "all 0.15s",
            }}
              onMouseEnter={e => { e.currentTarget.style.background = C.bgHover; e.currentTarget.style.borderColor = C.borderStrong; }}
              onMouseLeave={e => { e.currentTarget.style.background = C.bgPanel; e.currentTarget.style.borderColor = C.border; }}
            >
              <Icon name="plus" size={13} color={C.textMid} />
              Held hinzufügen
            </button>
          </div>

          {/* Helden Grid */}
          <div style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))",
            gap: 10,
          }}>
            {helden.map(h => (
              <HeldCard key={h.id} held={h} C={C} onEdit={h => setModal(h)} />
            ))}

            {/* Add Card */}
            <button onClick={() => setModal("neu")} style={{
              background: "transparent",
              border: `1.5px dashed ${C.border}`,
              borderRadius: 10, padding: "20px 14px",
              cursor: "pointer", color: C.textSoft,
              display: "flex", flexDirection: "column",
              alignItems: "center", justifyContent: "center", gap: 6,
              transition: "all 0.15s", minHeight: 110,
            }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = C.borderStrong; e.currentTarget.style.background = C.bgHover; }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = C.border; e.currentTarget.style.background = "transparent"; }}
            >
              <Icon name="plus" size={16} color={C.textSoft} />
              <span style={{ fontSize: 11 }}>Neuer Held</span>
            </button>
          </div>
        </div>

        {/* SESSIONS SEKTION */}
        <div>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14 }}>
            <div>
              <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: C.text }}>Sessions</h2>
              <p style={{ margin: "2px 0 0", fontSize: 12, color: C.textSoft }}>
                {sessions.length} Session{sessions.length !== 1 ? "s" : ""}
              </p>
            </div>
            <button style={{
              display: "flex", alignItems: "center", gap: 5,
              padding: "7px 12px", borderRadius: 7,
              background: C.bgPanel, border: `1px solid ${C.border}`,
              color: C.textMid, fontSize: 12, fontWeight: 500,
              cursor: "pointer", fontFamily: "inherit",
            }}
              onMouseEnter={e => { e.currentTarget.style.background = C.bgHover; }}
              onMouseLeave={e => { e.currentTarget.style.background = C.bgPanel; }}
            >
              <Icon name="plus" size={13} color={C.textMid} />
              Session hinzufügen
            </button>
          </div>

          <div style={{
            background: C.bgPanel, border: `1px solid ${C.border}`,
            borderRadius: 10, overflow: "hidden",
          }}>
            {sessions.map((s, i) => (
              <SessionZeile key={s.id} session={s} C={C} isLast={i === sessions.length - 1} />
            ))}
          </div>
        </div>
      </div>

      {/* MODAL */}
      {modal && (
        <HeldModal
          held={modal === "neu" ? null : modal}
          C={C} isDark={isDark}
          onSave={handleSave}
          onClose={() => setModal(null)}
        />
      )}

      <style>{`
        * { box-sizing: border-box; }
        input::placeholder { color: ${C.textSoft}; }
        select option { background: ${C.bgPanel}; color: ${C.text}; }
        @keyframes fadeIn { from { opacity:0 } to { opacity:1 } }
        @keyframes slideUp { from { opacity:0; transform:translateY(16px) scale(0.97) } to { opacity:1; transform:translateY(0) scale(1) } }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
      `}</style>
    </div>
  );
}
