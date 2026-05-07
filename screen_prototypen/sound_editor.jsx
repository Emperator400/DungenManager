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

const KAT_CFG = {
  Ambiente: { color: "#0891b2", bg_l: "#ecfbff", bg_d: "#0a1f28" },
  Effekt:   { color: "#c93a3a", bg_l: "#fdf0f0", bg_d: "#2a1212" },
  Musik:    { color: "#7c3aed", bg_l: "#f3effe", bg_d: "#1e1330" },
};

const KATEGORIEN = ["Ambiente", "Effekt", "Musik"];

const initSounds = [
  { id: 1, name: "cave-1", kategorie: "Effekt", beschreibung: "", tags: [], dauer: "1:23", groesse: "71723.0 MB", pfad: "C:\\Users\\timkr\\Documents\\DungenManager\\sounds\\cave-1.mp3", favorit: false },
  { id: 2, name: "cave-2", kategorie: "Ambiente", beschreibung: "Höhlenatmosphäre", tags: ["höhle", "dungeon"], dauer: "3:45", groesse: "12.4 MB", pfad: "C:\\Users\\timkr\\Documents\\DungenManager\\sounds\\cave-2.mp3", favorit: true },
  { id: 3, name: "thunder-1", kategorie: "Effekt", beschreibung: "", tags: ["wetter"], dauer: "0:32", groesse: "3.1 MB", pfad: "C:\\Users\\timkr\\Documents\\DungenManager\\sounds\\thunder-1.mp3", favorit: false },
  { id: 4, name: "summer-atmosphere", kategorie: "Ambiente", beschreibung: "Sommerliche Atmosphäre", tags: ["sommer", "natur"], dauer: "4:12", groesse: "18.7 MB", pfad: "C:\\Users\\timkr\\Documents\\DungenManager\\sounds\\summer.mp3", favorit: false },
];

const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    close: "M4 4l8 8M12 4l-8 8",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
    plus: "M8 3v10M3 8h10",
    search: "M7 3a4 4 0 100 8 4 4 0 000-8zM13 13l-3-3",
    edit: "M11 3l2 2-8 8H3v-2l8-8z",
    music: "M9 3v8.5a2.5 2.5 0 11-1-2V6L5 7V4l4-1z",
    play: "M4 3l10 5-10 5V3z",
    heart: "M8 13s-5-3.5-5-7a3 3 0 016 0 3 3 0 016 0c0 3.5-5 7-5 7z",
    file: "M4 2h6l4 4v10H4V2zm6 0v4h4",
    tag: "M2 8l6-6h5a1 1 0 011 1v5L8 14a1 1 0 01-1.4 0L2 8.6A1 1 0 012 8z",
    clock: "M8 3a5 5 0 100 10A5 5 0 008 3zm0 3v2.5l2 1",
    copy: "M5 5V3h8v8h-2M3 5h8v8H3z",
    trash: "M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9",
    chevDown: "M4 6l4 4 4-4",
    back: "M10 3L5 8l5 5",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} fill={name === "play" ? color : "none"} />
    </svg>
  );
};

const KatBadge = ({ kat, isDark }) => {
  const cfg = KAT_CFG[kat] || KAT_CFG["Ambiente"];
  return (
    <span style={{
      fontSize: 10, fontWeight: 500, color: cfg.color,
      background: isDark ? cfg.bg_d : cfg.bg_l,
      padding: "2px 7px", borderRadius: 4,
      display: "inline-flex", alignItems: "center", gap: 4,
    }}>
      <span style={{ width: 5, height: 5, borderRadius: "50%", background: cfg.color }} />
      {kat}
    </span>
  );
};

// ── SOUND EDITOR SEITENLEISTE ─────────────────────────────────────────────────
const SoundEditor = ({ sound, C, isDark, onClose, onSave }) => {
  const isNeu = !sound?.id;
  const [form, setForm] = useState({
    name: sound?.name || "",
    kategorie: sound?.kategorie || "Ambiente",
    beschreibung: sound?.beschreibung || "",
    tags: sound?.tags || [],
    pfad: sound?.pfad || "",
    neuerTag: "",
  });
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const handleTagAdd = () => {
    if (form.neuerTag.trim()) {
      set("tags", [...form.tags, form.neuerTag.trim()]);
      set("neuerTag", "");
    }
  };

  const removeTag = (tag) => set("tags", form.tags.filter(t => t !== tag));

  const cfg = KAT_CFG[form.kategorie] || KAT_CFG["Ambiente"];

  const inputStyle = {
    width: "100%", padding: "9px 10px",
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

  const Section = ({ children, style = {} }) => (
    <div style={{
      background: C.bgHover, border: `1px solid ${C.border}`,
      borderRadius: 10, padding: "14px", marginBottom: 12, ...style,
    }}>{children}</div>
  );

  const SectionTitle = ({ children }) => (
    <div style={{ fontSize: 11, fontWeight: 600, color: C.textSoft, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 12 }}>
      {children}
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
        width: "min(420px, 92vw)", zIndex: 50,
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
              width: 30, height: 30, borderRadius: 8,
              background: cfg.color + "20", border: `1.5px solid ${cfg.color}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <Icon name="music" size={14} color={cfg.color} />
            </div>
            <div>
              <h2 style={{ margin: 0, fontSize: 15, fontWeight: 600, color: C.text }}>
                {isNeu ? "Neuer Sound" : "Sound bearbeiten"}
              </h2>
              {!isNeu && (
                <p style={{ margin: "1px 0 0", fontSize: 11, color: C.textSoft }}>{sound.name}</p>
              )}
            </div>
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
          <Section>
            <SectionTitle>Grundinformationen</SectionTitle>
            <div style={{ marginBottom: 10 }}>
              <Label>Name *</Label>
              <input value={form.name} onChange={e => set("name", e.target.value)}
                placeholder="Sound-Name" style={inputStyle}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
            </div>

            <div>
              <Label>Sound-Typ</Label>
              <div style={{ display: "flex", gap: 6 }}>
                {KATEGORIEN.map(k => {
                  const kCfg = KAT_CFG[k];
                  const aktiv = form.kategorie === k;
                  return (
                    <button key={k} onClick={() => set("kategorie", k)} style={{
                      flex: 1, padding: "7px 8px", borderRadius: 7,
                      background: aktiv ? (isDark ? kCfg.bg_d : kCfg.bg_l) : "transparent",
                      border: `1px solid ${aktiv ? kCfg.color : C.border}`,
                      color: aktiv ? kCfg.color : C.textMid,
                      fontSize: 12, fontWeight: aktiv ? 500 : 400,
                      cursor: "pointer", fontFamily: "inherit",
                      transition: "all 0.15s",
                      display: "flex", alignItems: "center", justifyContent: "center", gap: 5,
                    }}>
                      <span style={{ width: 6, height: 6, borderRadius: "50%", background: kCfg.color }} />
                      {k}
                    </button>
                  );
                })}
              </div>
            </div>
          </Section>

          {/* Dateipfad */}
          <Section>
            <SectionTitle>Datei</SectionTitle>
            <div style={{ marginBottom: sound?.pfad ? 10 : 0 }}>
              <Label>Dateipfad</Label>
              <div style={{
                display: "flex", alignItems: "center", gap: 8,
                padding: "8px 10px", borderRadius: 7,
                background: C.bgPanel, border: `1px solid ${C.border}`,
              }}>
                <Icon name="file" size={13} color={C.textSoft} />
                <span style={{
                  flex: 1, fontSize: 11, color: form.pfad ? C.textMid : C.textSoft,
                  overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
                }}>
                  {form.pfad || "Keine Datei ausgewählt"}
                </span>
              </div>
            </div>

            {/* Datei Info */}
            {!isNeu && (
              <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
                {[
                  { icon: "clock", label: "Dauer", value: sound.dauer || "Unbekannt" },
                  { icon: "file", label: "Größe", value: sound.groesse || "—" },
                ].map((info, i) => (
                  <div key={i} style={{
                    flex: 1, padding: "8px 10px", borderRadius: 7,
                    background: C.bgPanel, border: `1px solid ${C.border}`,
                    display: "flex", alignItems: "center", gap: 6,
                  }}>
                    <Icon name={info.icon} size={12} color={C.textSoft} />
                    <div>
                      <div style={{ fontSize: 9, color: C.textSoft, textTransform: "uppercase", letterSpacing: 0.3 }}>{info.label}</div>
                      <div style={{ fontSize: 12, fontWeight: 500, color: C.text }}>{info.value}</div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Section>

          {/* Sound Details */}
          <Section>
            <SectionTitle>Sound-Details</SectionTitle>
            <div style={{ marginBottom: 10 }}>
              <Label>Beschreibung</Label>
              <textarea value={form.beschreibung} onChange={e => set("beschreibung", e.target.value)}
                placeholder="Beschreibung des Sounds..." rows={3}
                style={{ ...inputStyle, resize: "vertical", lineHeight: 1.5 }}
                onFocus={e => e.target.style.borderColor = C.accent}
                onBlur={e => e.target.style.borderColor = C.border} />
            </div>

            <div>
              <Label>Tags</Label>
              {/* Bestehende Tags */}
              {form.tags.length > 0 && (
                <div style={{ display: "flex", flexWrap: "wrap", gap: 5, marginBottom: 8 }}>
                  {form.tags.map((tag, i) => (
                    <span key={i} style={{
                      display: "flex", alignItems: "center", gap: 5,
                      fontSize: 11, color: C.textMid,
                      background: C.bgPanel, border: `1px solid ${C.border}`,
                      padding: "3px 8px", borderRadius: 5,
                    }}>
                      {tag}
                      <button onClick={() => removeTag(tag)} style={{
                        background: "none", border: "none", cursor: "pointer",
                        color: C.textSoft, padding: 0, fontSize: 14, lineHeight: 1,
                        display: "flex", alignItems: "center",
                      }}>×</button>
                    </span>
                  ))}
                </div>
              )}
              {/* Neuen Tag hinzufügen */}
              <div style={{ display: "flex", gap: 6 }}>
                <input
                  value={form.neuerTag}
                  onChange={e => set("neuerTag", e.target.value)}
                  onKeyDown={e => e.key === "Enter" && handleTagAdd()}
                  placeholder="Tag hinzufügen..." style={{ ...inputStyle, flex: 1 }}
                  onFocus={e => e.target.style.borderColor = C.accent}
                  onBlur={e => e.target.style.borderColor = C.border} />
                <button onClick={handleTagAdd} style={{
                  width: 36, height: 36, borderRadius: 7, flexShrink: 0,
                  background: C.bgPanel, border: `1px solid ${C.border}`,
                  cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
                }}
                  onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
                  onMouseLeave={e => e.currentTarget.style.background = C.bgPanel}
                >
                  <Icon name="plus" size={14} color={C.textMid} />
                </button>
              </div>
            </div>
          </Section>
        </div>

        {/* Footer */}
        <div style={{
          padding: "12px 16px", borderTop: `1px solid ${C.border}`,
          display: "flex", gap: 8, flexShrink: 0,
        }}>
          {!isNeu && (
            <button style={{
              padding: "9px 10px", borderRadius: 7,
              background: "transparent", border: `1px solid ${C.border}`,
              color: C.textMid, fontSize: 12, cursor: "pointer",
              fontFamily: "inherit", display: "flex", alignItems: "center", gap: 5,
            }}
              onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
              onMouseLeave={e => e.currentTarget.style.background = "transparent"}
            >
              <Icon name="copy" size={12} color={C.textMid} />
              Duplizieren
            </button>
          )}
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

// ── DEMO ──────────────────────────────────────────────────────────────────────
export default function SoundEditorDemo() {
  const [isDark, setIsDark] = useState(false);
  const [sounds, setSounds] = useState(initSounds);
  const [suche, setSuche] = useState("");
  const [editor, setEditor] = useState(null);

  const C = THEMES[isDark ? "dark" : "light"];

  const gefiltert = sounds.filter(s =>
    s.name.toLowerCase().includes(suche.toLowerCase())
  );

  const handleSave = (form) => {
    if (editor === "neu") {
      setSounds(prev => [...prev, { ...form, id: Date.now(), dauer: "—", groesse: "—", favorit: false }]);
    } else {
      setSounds(prev => prev.map(s => s.id === editor.id ? { ...s, ...form } : s));
    }
  };

  return (
    <div style={{
      fontFamily: "-apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif",
      background: C.bg, height: "100vh", overflow: "hidden",
      color: C.text, fontSize: 13, display: "flex", flexDirection: "column",
      transition: "background 0.25s",
    }}>

      {/* Topbar */}
      <div style={{
        height: 48, background: C.bgPanel, borderBottom: `1px solid ${C.border}`,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 20px", flexShrink: 0,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <Icon name="music" size={16} color={C.accent} />
          <span style={{ fontSize: 14, fontWeight: 600 }}>Sound Bibliothek</span>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
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
            Neuer Sound
          </button>
        </div>
      </div>

      {/* Suche */}
      <div style={{ padding: "12px 20px", flexShrink: 0 }}>
        <div style={{ position: "relative", maxWidth: 400 }}>
          <div style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)" }}>
            <Icon name="search" size={13} color={C.textSoft} />
          </div>
          <input value={suche} onChange={e => setSuche(e.target.value)}
            placeholder="Sounds suchen..."
            style={{
              width: "100%", padding: "8px 10px 8px 30px",
              background: C.bgPanel, border: `1px solid ${C.border}`,
              borderRadius: 7, fontSize: 12, color: C.text,
              outline: "none", fontFamily: "inherit", boxSizing: "border-box",
            }}
            onFocus={e => e.target.style.borderColor = C.accent}
            onBlur={e => e.target.style.borderColor = C.border} />
        </div>
      </div>

      {/* Sound Liste */}
      <div style={{ flex: 1, overflow: "auto", padding: "0 20px 20px" }}>
        {gefiltert.map(sound => {
          const cfg = KAT_CFG[sound.kategorie] || KAT_CFG["Ambiente"];
          return (
            <div key={sound.id} style={{
              display: "flex", alignItems: "center", gap: 12,
              padding: "10px 14px", marginBottom: 6,
              background: C.bgPanel, border: `1px solid ${C.border}`,
              borderLeft: `3px solid ${cfg.color}`,
              borderRadius: 8, transition: "all 0.15s",
            }}
              onMouseEnter={e => e.currentTarget.style.borderColor = C.borderStrong}
              onMouseLeave={e => { e.currentTarget.style.borderColor = C.border; e.currentTarget.style.borderLeftColor = cfg.color; }}
            >
              {/* Play */}
              <button style={{
                width: 32, height: 32, borderRadius: "50%",
                background: cfg.color, border: "none",
                cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <Icon name="play" size={12} color="#fff" />
              </button>

              {/* Info */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 500, color: C.text, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {sound.name}
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 3 }}>
                  <KatBadge kat={sound.kategorie} isDark={isDark} />
                  <span style={{ fontSize: 10, color: C.textSoft }}>{sound.dauer}</span>
                  {sound.tags.length > 0 && (
                    <span style={{ fontSize: 10, color: C.textSoft }}>
                      {sound.tags.slice(0, 2).join(", ")}
                    </span>
                  )}
                </div>
              </div>

              {/* Favorit + Edit */}
              <div style={{ display: "flex", gap: 4, flexShrink: 0 }}>
                <button style={{
                  width: 28, height: 28, borderRadius: 6, border: "none",
                  background: "transparent", cursor: "pointer",
                  display: "flex", alignItems: "center", justifyContent: "center",
                }}
                  onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
                  onMouseLeave={e => e.currentTarget.style.background = "transparent"}
                >
                  <Icon name="heart" size={13} color={sound.favorit ? C.red : C.textSoft} />
                </button>
                <button onClick={() => setEditor(sound)} style={{
                  width: 28, height: 28, borderRadius: 6, border: "none",
                  background: "transparent", cursor: "pointer",
                  display: "flex", alignItems: "center", justifyContent: "center",
                }}
                  onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
                  onMouseLeave={e => e.currentTarget.style.background = "transparent"}
                >
                  <Icon name="edit" size={13} color={C.textSoft} />
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Editor Seitenleiste */}
      {editor !== null && (
        <SoundEditor
          sound={editor === "neu" ? null : editor}
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
