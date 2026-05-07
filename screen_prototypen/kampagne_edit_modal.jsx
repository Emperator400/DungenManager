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

const STATUS_CFG = {
  Planung:       { color: "#7c3aed", bg_l: "#f3effe", bg_d: "#1e1330" },
  Aktiv:         { color: "#1a7f4b", bg_l: "#eaf4ee", bg_d: "#0f2a1c" },
  Pausiert:      { color: "#b45309", bg_l: "#fdf6ec", bg_d: "#2a1f08" },
  Abgeschlossen: { color: "#6b6b66", bg_l: "#f0f0ed", bg_d: "#232320" },
};

const SYSTEME = ["D&D 5e", "Homebrew", "Pathfinder", "Call of Cthulhu", "Shadowrun"];
const STATUS_OPTIONEN = ["Planung", "Aktiv", "Pausiert", "Abgeschlossen"];
const FARBEN = ["#2f6feb","#7c3aed","#1a7f4b","#b45309","#c93a3a","#0891b2","#be185d","#065f46"];

const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    close: "M4 4l8 8M12 4l-8 8",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
    plus: "M8 3v10M3 8h10",
    chevronDown: "M4 6l4 4 4-4",
    check: "M4 8l3 3 5-5",
    edit: "M11 3l2 2-8 8H3v-2l8-8z",
    scroll: "M4 2h8a1 1 0 011 1v12l-4.5-2L4 15V3a1 1 0 011-1z",
    user: "M8 7a3 3 0 100-6 3 3 0 000 6zm-5 9a5 5 0 0110 0",
    calendar: "M3 5h10a1 1 0 011 1v8a1 1 0 01-1 1H3a1 1 0 01-1-1V6a1 1 0 011-1zm0 0V3m10 2V3",
    trash: "M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9",
    copy: "M5 5V3h8v8h-2M3 5h8v8H3z",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} />
    </svg>
  );
};

const StatusBadge = ({ status, isDark }) => {
  const s = STATUS_CFG[status] || STATUS_CFG["Planung"];
  return (
    <span style={{
      fontSize: 11, fontWeight: 500,
      color: s.color, background: isDark ? s.bg_d : s.bg_l,
      padding: "3px 8px", borderRadius: 5,
      display: "inline-flex", alignItems: "center", gap: 4,
    }}>
      <span style={{ width: 5, height: 5, borderRadius: "50%", background: s.color }} />
      {status}
    </span>
  );
};

// ── EDIT MODAL ────────────────────────────────────────────────────────────────
const EditModal = ({ kampagne, C, isDark, onSave, onClose }) => {
  const isNeu = !kampagne?.id;
  const [form, setForm] = useState({
    name: kampagne?.name || "",
    beschreibung: kampagne?.beschreibung || "",
    system: kampagne?.system || "D&D 5e",
    status: kampagne?.status || "Planung",
    farbe: kampagne?.farbe || FARBEN[0],
  });
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const inputStyle = {
    width: "100%", padding: "9px 12px",
    background: C.bgHover, border: `1px solid ${C.border}`,
    borderRadius: 7, fontSize: 13, color: C.text,
    fontFamily: "inherit", outline: "none", boxSizing: "border-box",
    transition: "border-color 0.15s",
  };

  const Label = ({ children }) => (
    <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 5 }}>
      {children}
    </div>
  );

  return (
    <div onClick={onClose} style={{
      position: "fixed", inset: 0, zIndex: 50,
      background: C.overlay, backdropFilter: "blur(4px)",
      display: "flex", alignItems: "center", justifyContent: "center",
      animation: "fadeIn 0.2s ease",
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        width: "min(500px, 92vw)",
        background: C.bgPanel, border: `1px solid ${C.border}`,
        borderRadius: 14, overflow: "hidden",
        boxShadow: isDark ? "0 24px 60px rgba(0,0,0,0.6)" : "0 24px 60px rgba(0,0,0,0.12)",
        animation: "slideUp 0.25s cubic-bezier(0.34,1.56,0.64,1)",
      }}>

        {/* Modal Header */}
        <div style={{
          padding: "16px 20px", borderBottom: `1px solid ${C.border}`,
          display: "flex", alignItems: "center", justifyContent: "space-between",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{
              width: 30, height: 30, borderRadius: 8,
              background: form.farbe + "20", border: `1.5px solid ${form.farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <Icon name="scroll" size={14} color={form.farbe} />
            </div>
            <div>
              <h2 style={{ margin: 0, fontSize: 15, fontWeight: 600, color: C.text }}>
                {isNeu ? "Neue Kampagne" : "Kampagne bearbeiten"}
              </h2>
              {!isNeu && (
                <p style={{ margin: "1px 0 0", fontSize: 11, color: C.textSoft }}>{kampagne.name}</p>
              )}
            </div>
          </div>
          <button onClick={onClose} style={{
            width: 30, height: 30, borderRadius: 7,
            background: "transparent", border: "none",
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          ><Icon name="close" size={14} color={C.textMid} /></button>
        </div>

        {/* Modal Body */}
        <div style={{ padding: "20px", maxHeight: "65vh", overflowY: "auto" }}>

          {/* Name */}
          <div style={{ marginBottom: 14 }}>
            <Label>Name *</Label>
            <input value={form.name} onChange={e => set("name", e.target.value)}
              placeholder="Kampagnen-Name" style={inputStyle}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
          </div>

          {/* Beschreibung */}
          <div style={{ marginBottom: 14 }}>
            <Label>Beschreibung</Label>
            <textarea value={form.beschreibung} onChange={e => set("beschreibung", e.target.value)}
              placeholder="Kurze Beschreibung der Kampagne..." rows={3}
              style={{ ...inputStyle, resize: "vertical", lineHeight: 1.55 }}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border} />
          </div>

          {/* System + Status */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 14 }}>
            <div>
              <Label>System</Label>
              <div style={{ position: "relative" }}>
                <select value={form.system} onChange={e => set("system", e.target.value)} style={{
                  ...inputStyle, appearance: "none", paddingRight: 28, cursor: "pointer",
                }}>
                  {SYSTEME.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
                <div style={{ position: "absolute", right: 10, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
                  <Icon name="chevronDown" size={12} color={C.textSoft} />
                </div>
              </div>
            </div>
            <div>
              <Label>Status</Label>
              <div style={{ position: "relative" }}>
                <select value={form.status} onChange={e => set("status", e.target.value)} style={{
                  ...inputStyle, appearance: "none", paddingRight: 28, cursor: "pointer",
                }}>
                  {STATUS_OPTIONEN.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
                <div style={{ position: "absolute", right: 10, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
                  <Icon name="chevronDown" size={12} color={C.textSoft} />
                </div>
              </div>
            </div>
          </div>

          {/* Farbe */}
          <div style={{ marginBottom: 16 }}>
            <Label>Farbe</Label>
            <div style={{ display: "flex", gap: 8 }}>
              {FARBEN.map(f => (
                <button key={f} onClick={() => set("farbe", f)} style={{
                  width: 30, height: 30, borderRadius: 8,
                  background: f,
                  border: `2px solid ${form.farbe === f ? C.text : "transparent"}`,
                  cursor: "pointer", transition: "border-color 0.15s",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  boxShadow: form.farbe === f ? `0 0 0 3px ${f}44` : "none",
                }}>
                  {form.farbe === f && <Icon name="check" size={12} color="#fff" />}
                </button>
              ))}
            </div>
          </div>

          {/* Vorschau */}
          <div style={{
            padding: "12px 14px", borderRadius: 9,
            background: C.bgHover, border: `1px solid ${C.border}`,
          }}>
            <div style={{ fontSize: 10, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 10 }}>
              Vorschau
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{
                width: 38, height: 38, borderRadius: 9,
                background: form.farbe + "22", border: `1.5px solid ${form.farbe}44`,
                display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <span style={{ fontSize: 16, fontWeight: 700, color: form.farbe }}>
                  {form.name?.[0] || "?"}
                </span>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: C.text, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {form.name || "Kampagnen-Name"}
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 3 }}>
                  <span style={{ fontSize: 11, color: C.textSoft }}>{form.system}</span>
                  <span style={{ color: C.border }}>·</span>
                  <StatusBadge status={form.status} isDark={isDark} />
                </div>
              </div>
            </div>
          </div>

          {/* Statistiken (nur bei bestehender Kampagne) */}
          {!isNeu && (
            <div style={{
              display: "grid", gridTemplateColumns: "1fr 1fr",
              gap: 8, marginTop: 14,
            }}>
              {[
                { label: "Spieler", value: kampagne.spieler || 0, icon: "user" },
                { label: "Sessions", value: kampagne.sessions || 0, icon: "calendar" },
              ].map((s, i) => (
                <div key={i} style={{
                  padding: "10px 12px", borderRadius: 8,
                  background: C.bgHover, border: `1px solid ${C.border}`,
                  display: "flex", alignItems: "center", gap: 8,
                }}>
                  <Icon name={s.icon} size={13} color={C.textSoft} />
                  <div>
                    <div style={{ fontSize: 10, color: C.textSoft }}>{s.label}</div>
                    <div style={{ fontSize: 15, fontWeight: 700, color: C.text }}>{s.value}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div style={{
          padding: "14px 20px", borderTop: `1px solid ${C.border}`,
          display: "flex", gap: 8,
        }}>
          {!isNeu && (
            <button style={{
              padding: "9px 12px", borderRadius: 7,
              background: "transparent", border: `1px solid ${C.border}`,
              color: C.red, fontSize: 12, cursor: "pointer",
              fontFamily: "inherit", display: "flex", alignItems: "center", gap: 5,
            }}
              onMouseEnter={e => e.currentTarget.style.background = C.redSoft}
              onMouseLeave={e => e.currentTarget.style.background = "transparent"}
            >
              <Icon name="copy" size={12} color={C.red} />
              Duplizieren
            </button>
          )}
          <div style={{ flex: 1 }} />
          <button onClick={onClose} style={{
            padding: "9px 16px", borderRadius: 7,
            background: "transparent", border: `1px solid ${C.border}`,
            color: C.textMid, fontSize: 13, fontWeight: 500,
            cursor: "pointer", fontFamily: "inherit",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}
          >Abbrechen</button>
          <button onClick={() => { onSave(form); onClose(); }} style={{
            padding: "9px 20px", borderRadius: 7,
            background: C.accent, border: "none",
            color: "#fff", fontSize: 13, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
            display: "flex", alignItems: "center", gap: 6,
            transition: "opacity 0.15s",
          }}
            onMouseEnter={e => e.currentTarget.style.opacity = "0.9"}
            onMouseLeave={e => e.currentTarget.style.opacity = "1"}
          >
            <Icon name="save" size={13} color="#fff" />
            {isNeu ? "Erstellen" : "Speichern"}
          </button>
        </div>
      </div>
    </div>
  );
};

// ── DEMO ──────────────────────────────────────────────────────────────────────
const mockKampagne = {
  id: 1, name: "Die Verlorene Krone", system: "D&D 5e",
  status: "Aktiv", beschreibung: "Ein episches Abenteuer um den verlorenen Thron.",
  farbe: "#2f6feb", spieler: 4, sessions: 8,
};

export default function KampagneEditDemo() {
  const [isDark, setIsDark] = useState(false);
  const [modal, setModal] = useState(null);
  const C = THEMES[isDark ? "dark" : "light"];

  return (
    <div style={{
      fontFamily: "-apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif",
      background: C.bg, height: "100vh",
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      gap: 16, transition: "background 0.25s",
    }}>

      {/* Theme Toggle */}
      <button onClick={() => setIsDark(d => !d)} style={{
        position: "absolute", top: 16, right: 16,
        width: 32, height: 32, borderRadius: 7,
        background: C.bgPanel, border: `1px solid ${C.border}`,
        cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
      }}>
        <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
      </button>

      <p style={{ margin: 0, fontSize: 13, color: C.textSoft }}>Kampagne Edit Modal Demo</p>

      {/* Demo Buttons */}
      <div style={{ display: "flex", gap: 10 }}>
        <button onClick={() => setModal("neu")} style={{
          display: "flex", alignItems: "center", gap: 6,
          padding: "10px 18px", borderRadius: 8,
          background: C.accent, border: "none",
          color: "#fff", fontSize: 13, fontWeight: 600,
          cursor: "pointer", fontFamily: "inherit",
        }}>
          <Icon name="plus" size={14} color="#fff" />
          Neue Kampagne
        </button>
        <button onClick={() => setModal("edit")} style={{
          display: "flex", alignItems: "center", gap: 6,
          padding: "10px 18px", borderRadius: 8,
          background: C.bgPanel, border: `1px solid ${C.border}`,
          color: C.textMid, fontSize: 13, fontWeight: 500,
          cursor: "pointer", fontFamily: "inherit",
        }}>
          <Icon name="edit" size={14} color={C.textMid} />
          Kampagne bearbeiten
        </button>
      </div>

      {/* Kampagnen-Karte Vorschau */}
      <div style={{
        background: C.bgPanel, border: `1px solid ${C.border}`,
        borderRadius: 12, overflow: "hidden", width: 280,
        boxShadow: isDark ? "0 4px 16px rgba(0,0,0,0.3)" : "0 4px 16px rgba(0,0,0,0.06)",
      }}>
        <div style={{ height: 4, background: mockKampagne.farbe }} />
        <div style={{ padding: "14px 16px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 8 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 8,
              background: mockKampagne.farbe + "22",
              border: `1.5px solid ${mockKampagne.farbe}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ fontSize: 15, fontWeight: 700, color: mockKampagne.farbe }}>
                {mockKampagne.name[0]}
              </span>
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>{mockKampagne.name}</div>
              <div style={{ fontSize: 11, color: C.textSoft }}>{mockKampagne.system}</div>
            </div>
          </div>
          <StatusBadge status={mockKampagne.status} isDark={isDark} />
          <div style={{ height: 1, background: C.border, margin: "10px 0" }} />
          <div style={{ display: "flex", gap: 12 }}>
            {[
              { icon: "user", label: `${mockKampagne.spieler} Spieler` },
              { icon: "calendar", label: `${mockKampagne.sessions} Sessions` },
            ].map((m, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 4 }}>
                <Icon name={m.icon} size={11} color={C.textSoft} />
                <span style={{ fontSize: 11, color: C.textSoft }}>{m.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Modal */}
      {modal && (
        <EditModal
          kampagne={modal === "edit" ? mockKampagne : null}
          C={C} isDark={isDark}
          onSave={form => console.log("Gespeichert:", form)}
          onClose={() => setModal(null)}
        />
      )}

      <style>{`
        * { box-sizing: border-box; }
        input::placeholder, textarea::placeholder { color: ${C.textSoft}; }
        select option { background: ${C.bgPanel}; color: ${C.text}; }
        textarea { font-family: inherit; }
        @keyframes fadeIn { from { opacity:0 } to { opacity:1 } }
        @keyframes slideUp { from { opacity:0; transform:translateY(16px) scale(0.97) } to { opacity:1; transform:translateY(0) scale(1) } }
      `}</style>
    </div>
  );
}
