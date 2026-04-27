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
  },
};

const KAT_CFG = {
  Ambiente: { color: "#0891b2", bg_l: "#ecfbff", bg_d: "#0a1f28" },
  Effekt:   { color: "#c93a3a", bg_l: "#fdf0f0", bg_d: "#2a1212" },
  Musik:    { color: "#7c3aed", bg_l: "#f3effe", bg_d: "#1e1330" },
};

const initSounds = [
  { id: 1, name: "cave-1", kategorie: "Effekt", favorit: false, dauer: "1:23" },
  { id: 2, name: "cave-2", kategorie: "Ambiente", favorit: false, dauer: "3:45" },
  { id: 3, name: "loading", kategorie: "Ambiente", favorit: true, dauer: "0:45" },
  { id: 4, name: "music-on-the-piano-when-the-game-is-completed", kategorie: "Musik", favorit: false, dauer: "2:30" },
  { id: 5, name: "summer-summer-atmosphere", kategorie: "Ambiente", favorit: false, dauer: "4:12" },
  { id: 6, name: "the-chirping-of-grasshoppers-in-the-night-forest", kategorie: "Ambiente", favorit: true, dauer: "5:00" },
  { id: 7, name: "thunder-1", kategorie: "Effekt", favorit: false, dauer: "0:32" },
  { id: 8, name: "valiant-awakening_94553", kategorie: "Ambiente", favorit: false, dauer: "3:18" },
];

const initSzenen = [
  { id: 1, name: "Taverne bei Nacht", beschreibung: "Ruhige Tavernenatmosphäre für Abende.", sounds: ["cave-2", "summer-summer-atmosphere"], favorit: true },
  { id: 2, name: "Dungeon Erkunden", beschreibung: "Finstere Atmosphäre für Kellergewölbe.", sounds: ["cave-1", "cave-2"], favorit: false },
];

// ── ICONS ─────────────────────────────────────────────────────────────────────
const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    back: "M10 3L5 8l5 5",
    search: "M7 3a4 4 0 100 8 4 4 0 000-8zM13 13l-3-3",
    plus: "M8 3v10M3 8h10",
    play: "M4 3l10 5-10 5V3z",
    pause: "M4 3h3v10H4zm5 0h3v10H9z",
    stop: "M3 3h10v10H3z",
    heart: "M8 13s-5-3.5-5-7a3 3 0 016 0 3 3 0 016 0c0 3.5-5 7-5 7z",
    heartFill: "M8 13s-5-3.5-5-7a3 3 0 016 0 3 3 0 016 0c0 3.5-5 7-5 7z",
    edit: "M11 3l2 2-8 8H3v-2l8-8z",
    music: "M9 3v8.5a2.5 2.5 0 11-1-2V6L5 7V4l4-1z",
    film: "M2 4h12v8H2zm3 0v8M11 4v8M2 8h3M11 8h3",
    vol: "M6 5L3 8v0l3 3V5zm2 0a4 4 0 010 6M10 3a7 7 0 010 10",
    volLow: "M6 5L3 8v0l3 3V5zm2 1a3 3 0 010 4",
    volMute: "M6 5L3 8v0l3 3V5zm4 1l3 3m0-3l-3 3",
    chevDown: "M4 6l4 4 4-4",
    repeat: "M3 8a5 5 0 009.9-1M13 8a5 5 0 01-9.9 1M11 5l2-2 2 2M3 11l2 2-2 2",
    shuffle: "M3 5h3l5 6h3M3 11h3l2-2.4M11 5h3l-2 2",
    trash: "M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9",
    star: "M8 2l1.8 3.6L14 6.3l-3 2.9.7 4.1L8 11.2l-3.7 2.1.7-4.1-3-2.9 4.2-.7z",
    close: "M4 4l8 8M12 4l-8 8",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} fill={["play","stop","heartFill"].includes(name) ? color : "none"} />
    </svg>
  );
};

// ── KAT BADGE ─────────────────────────────────────────────────────────────────
const KatBadge = ({ kat, isDark }) => {
  const cfg = KAT_CFG[kat] || KAT_CFG["Ambiente"];
  return (
    <span style={{
      fontSize: 10, fontWeight: 500, color: cfg.color,
      background: isDark ? cfg.bg_d : cfg.bg_l,
      padding: "1px 7px", borderRadius: 4,
    }}>{kat}</span>
  );
};

// ── SOUND PLAYER ──────────────────────────────────────────────────────────────
const SoundPlayer = ({ sound, C, isDark, onClose }) => {
  const [playing, setPlaying] = useState(false);
  const [vol, setVol] = useState(70);
  const [progress, setProgress] = useState(30);
  const cfg = KAT_CFG[sound.kategorie] || KAT_CFG["Ambiente"];

  return (
    <div style={{ padding: "20px", height: "100%", display: "flex", flexDirection: "column", overflow: "auto" }}>

      {/* Header */}
      <div style={{
        padding: "16px", borderRadius: 12, marginBottom: 16,
        background: isDark ? cfg.bg_d : cfg.bg_l,
        border: `1px solid ${cfg.color}33`,
        textAlign: "center",
      }}>
        <div style={{
          width: 64, height: 64, borderRadius: 16,
          background: cfg.color + "20", border: `2px solid ${cfg.color}44`,
          display: "flex", alignItems: "center", justifyContent: "center",
          margin: "0 auto 12px",
        }}>
          <Icon name="music" size={28} color={cfg.color} />
        </div>
        <div style={{ fontSize: 15, fontWeight: 600, color: C.text, marginBottom: 4, wordBreak: "break-all" }}>
          {sound.name}
        </div>
        <KatBadge kat={sound.kategorie} isDark={isDark} />
      </div>

      {/* Progress */}
      <div style={{ marginBottom: 16 }}>
        <div style={{
          height: 4, background: C.border, borderRadius: 2,
          marginBottom: 6, cursor: "pointer", overflow: "hidden",
        }} onClick={e => {
          const rect = e.currentTarget.getBoundingClientRect();
          setProgress(Math.round(((e.clientX - rect.left) / rect.width) * 100));
        }}>
          <div style={{
            height: "100%", width: `${progress}%`,
            background: cfg.color, borderRadius: 2,
            transition: "width 0.1s",
          }} />
        </div>
        <div style={{ display: "flex", justifyContent: "space-between" }}>
          <span style={{ fontSize: 10, color: C.textSoft }}>0:{Math.floor(progress * 0.6).toString().padStart(2,"0")}</span>
          <span style={{ fontSize: 10, color: C.textSoft }}>{sound.dauer}</span>
        </div>
      </div>

      {/* Controls */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 16, marginBottom: 20 }}>
        <button style={{ background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", width: 32, height: 32, borderRadius: 8 }}
          onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
          onMouseLeave={e => e.currentTarget.style.background = "none"}
        ><Icon name="shuffle" size={15} color={C.textSoft} /></button>

        <button onClick={() => setPlaying(p => !p)} style={{
          width: 48, height: 48, borderRadius: "50%",
          background: cfg.color, border: "none",
          cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: `0 4px 16px ${cfg.color}44`,
          transition: "transform 0.15s",
        }}
          onMouseEnter={e => e.currentTarget.style.transform = "scale(1.05)"}
          onMouseLeave={e => e.currentTarget.style.transform = "scale(1)"}
        >
          <Icon name={playing ? "pause" : "play"} size={20} color="#fff" />
        </button>

        <button style={{ background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", width: 32, height: 32, borderRadius: 8 }}
          onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
          onMouseLeave={e => e.currentTarget.style.background = "none"}
        ><Icon name="repeat" size={15} color={C.textSoft} /></button>
      </div>

      {/* Volume */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
          <Icon name={vol === 0 ? "volMute" : vol < 50 ? "volLow" : "vol"} size={13} color={C.textSoft} />
          <div style={{
            flex: 1, height: 3, background: C.border, borderRadius: 2, cursor: "pointer",
          }} onClick={e => {
            const rect = e.currentTarget.getBoundingClientRect();
            setVol(Math.round(((e.clientX - rect.left) / rect.width) * 100));
          }}>
            <div style={{ height: "100%", width: `${vol}%`, background: C.accent, borderRadius: 2 }} />
          </div>
          <span style={{ fontSize: 10, color: C.textSoft, minWidth: 28, textAlign: "right" }}>{vol}%</span>
        </div>
      </div>

      {/* Aktionen */}
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 4 }}>Aktionen</div>
        {[
          { label: "Zu Szene hinzufügen", icon: "film" },
          { label: "Als Favorit markieren", icon: "heart" },
          { label: "Bearbeiten", icon: "edit" },
        ].map((a, i) => (
          <button key={i} style={{
            display: "flex", alignItems: "center", gap: 8,
            padding: "9px 12px", borderRadius: 7,
            background: C.bgHover, border: `1px solid ${C.border}`,
            color: C.textMid, fontSize: 12, cursor: "pointer",
            fontFamily: "inherit", transition: "background 0.15s", textAlign: "left",
          }}
            onMouseEnter={e => e.currentTarget.style.background = C.bgActive}
            onMouseLeave={e => e.currentTarget.style.background = C.bgHover}
          >
            <Icon name={a.icon} size={13} color={C.textSoft} />
            {a.label}
          </button>
        ))}
      </div>
    </div>
  );
};

// ── SZENE DETAIL ──────────────────────────────────────────────────────────────
const SzeneDetail = ({ szene, sounds, C, isDark, onEdit }) => (
  <div style={{ padding: "20px", height: "100%", overflow: "auto" }}>
    <div style={{
      padding: "14px 16px", borderRadius: 10, marginBottom: 14,
      background: isDark ? "#1e1330" : "#f3effe",
      border: "1px solid #7c3aed33",
    }}>
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{
            width: 38, height: 38, borderRadius: 9,
            background: "#7c3aed20", border: "1.5px solid #7c3aed44",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name="film" size={18} color="#7c3aed" />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>{szene.name}</div>
            <div style={{ fontSize: 11, color: C.textSoft, marginTop: 2 }}>{szene.sounds.length} Sounds</div>
          </div>
        </div>
        <button onClick={() => onEdit(szene)} style={{
          display: "flex", alignItems: "center", gap: 5,
          padding: "5px 10px", borderRadius: 6,
          background: C.bgPanel, border: `1px solid ${C.border}`,
          color: C.textMid, fontSize: 11, cursor: "pointer", fontFamily: "inherit",
        }}>
          <Icon name="edit" size={11} color={C.textMid} />
          Bearbeiten
        </button>
      </div>
      {szene.beschreibung && (
        <p style={{ margin: "10px 0 0", fontSize: 12, color: C.textMid, lineHeight: 1.5 }}>
          {szene.beschreibung}
        </p>
      )}
    </div>

    <div style={{ marginBottom: 14 }}>
      <div style={{ fontSize: 11, fontWeight: 500, color: C.textSoft, letterSpacing: 0.4, textTransform: "uppercase", marginBottom: 8 }}>Sounds in dieser Szene</div>
      {szene.sounds.map((sName, i) => {
        const s = sounds.find(x => x.name === sName);
        const cfg = s ? (KAT_CFG[s.kategorie] || KAT_CFG["Ambiente"]) : null;
        return (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 10,
            padding: "9px 12px", borderRadius: 7, marginBottom: 5,
            background: C.bgPanel, border: `1px solid ${C.border}`,
          }}>
            <button style={{
              width: 28, height: 28, borderRadius: "50%",
              background: cfg ? cfg.color : C.accent,
              border: "none", cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
            }}>
              <Icon name="play" size={11} color="#fff" />
            </button>
            <span style={{ flex: 1, fontSize: 12, color: C.text }}>{sName}</span>
            {s && <KatBadge kat={s.kategorie} isDark={isDark} />}
          </div>
        );
      })}
      <button style={{
        width: "100%", padding: "8px", marginTop: 4,
        background: "transparent", border: `1px dashed ${C.border}`,
        borderRadius: 7, color: C.textSoft, fontSize: 11,
        cursor: "pointer", fontFamily: "inherit",
        display: "flex", alignItems: "center", justifyContent: "center", gap: 5,
      }}>
        <Icon name="plus" size={12} color={C.textSoft} />
        Sound hinzufügen
      </button>
    </div>

    <button style={{
      width: "100%", padding: "10px",
      background: "#7c3aed", border: "none",
      borderRadius: 8, color: "#fff", fontSize: 13, fontWeight: 600,
      cursor: "pointer", fontFamily: "inherit",
      display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
    }}>
      <Icon name="play" size={14} color="#fff" />
      Szene abspielen
    </button>
  </div>
);

// ── HAUPT ─────────────────────────────────────────────────────────────────────
export default function SoundBibliothek() {
  const [isDark, setIsDark] = useState(false);
  const [tab, setTab] = useState("sounds");
  const [sounds, setSounds] = useState(initSounds);
  const [szenen, setSzenen] = useState(initSzenen);
  const [suche, setSuche] = useState("");
  const [katFilter, setKatFilter] = useState("Alle");
  const [selectedSoundId, setSelectedSoundId] = useState(initSounds[0]?.id || null);
  const [selectedSzeneId, setSelectedSzeneId] = useState(initSzenen[0]?.id || null);

  const C = THEMES[isDark ? "dark" : "light"];

  const gefilterteSounds = sounds.filter(s => {
    const matchSuche = s.name.toLowerCase().includes(suche.toLowerCase());
    const matchKat = katFilter === "Alle" || s.kategorie === katFilter || (katFilter === "Favoriten" && s.favorit);
    return matchSuche && matchKat;
  });

  const gefiltérteSzenen = szenen.filter(s =>
    s.name.toLowerCase().includes(suche.toLowerCase())
  );

  const selectedSound = sounds.find(s => s.id === selectedSoundId);
  const selectedSzene = szenen.find(s => s.id === selectedSzeneId);

  const toggleFavorit = (id) => setSounds(prev => prev.map(s => s.id === id ? { ...s, favorit: !s.favorit } : s));

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
            <Icon name="music" size={16} color={C.accent} />
            <span style={{ fontSize: 14, fontWeight: 600 }}>Sound & Atmosphäre</span>
          </div>
          <span style={{ fontSize: 11, color: C.textSoft }}>
            {sounds.length} Sounds · {sounds.filter(s => s.favorit).length} Favoriten
          </span>
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
            <Icon name="plus" size={13} color="#fff" />
            {tab === "sounds" ? "Sound" : "Szene"}
          </button>
        </div>
      </div>

      {/* TABS */}
      <div style={{
        background: C.bgPanel, borderBottom: `1px solid ${C.border}`,
        display: "flex", padding: "0 20px", flexShrink: 0,
      }}>
        {[
          { id: "sounds", label: "Sounds", icon: "music" },
          { id: "szenen", label: "Szenen", icon: "film" },
        ].map(t => (
          <button key={t.id} onClick={() => { setTab(t.id); setSuche(""); setKatFilter("Alle"); }} style={{
            display: "flex", alignItems: "center", gap: 6,
            padding: "10px 16px", background: "none", border: "none",
            borderBottom: tab === t.id ? `2px solid ${C.accent}` : "2px solid transparent",
            color: tab === t.id ? C.accent : C.textMid,
            fontSize: 13, fontWeight: tab === t.id ? 500 : 400,
            cursor: "pointer", fontFamily: "inherit",
            transition: "color 0.15s", marginBottom: -1,
          }}>
            <Icon name={t.icon} size={14} color={tab === t.id ? C.accent : C.textMid} />
            {t.label}
          </button>
        ))}
      </div>

      {/* HAUPTBEREICH */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>

        {/* ══ LINKE SEITE ══ */}
        <div style={{
          width: "42%", display: "flex", flexDirection: "column",
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
                placeholder={tab === "sounds" ? "Sounds suchen..." : "Szenen suchen..."}
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

          {/* Kategorie Filter (nur Sounds) */}
          {tab === "sounds" && (
            <div style={{ padding: "0 12px 10px", display: "flex", gap: 4, flexShrink: 0 }}>
              {["Alle", "Ambiente", "Effekt", "Musik", "Favoriten"].map(k => {
                const aktiv = katFilter === k;
                const cfg = KAT_CFG[k];
                return (
                  <button key={k} onClick={() => setKatFilter(k)} style={{
                    padding: "3px 9px", borderRadius: 5,
                    background: aktiv ? (cfg ? (isDark ? cfg.bg_d : cfg.bg_l) : C.accent) : "transparent",
                    border: `1px solid ${aktiv ? (cfg ? cfg.color : C.accent) : C.border}`,
                    color: aktiv ? (cfg ? cfg.color : "#fff") : C.textMid,
                    fontSize: 11, cursor: "pointer", fontFamily: "inherit",
                    transition: "all 0.15s",
                  }}>{k}</button>
                );
              })}
            </div>
          )}

          {/* Liste */}
          <div style={{ flex: 1, overflow: "auto" }}>
            {tab === "sounds" && (
              gefilterteSounds.length === 0 ? (
                <div style={{ padding: "40px 20px", textAlign: "center", color: C.textSoft }}>
                  <Icon name="music" size={28} color={C.border} />
                  <div style={{ marginTop: 10 }}>Keine Sounds gefunden</div>
                </div>
              ) : gefilterteSounds.map(s => {
                const isSelected = selectedSoundId === s.id;
                const cfg = KAT_CFG[s.kategorie] || KAT_CFG["Ambiente"];
                return (
                  <div key={s.id} onClick={() => setSelectedSoundId(s.id)} style={{
                    display: "flex", alignItems: "center", gap: 10,
                    padding: "9px 14px",
                    background: isSelected ? C.bgActive : "transparent",
                    borderBottom: `1px solid ${C.border}`,
                    borderLeft: `3px solid ${isSelected ? cfg.color : "transparent"}`,
                    cursor: "pointer", transition: "background 0.15s",
                  }}
                    onMouseEnter={e => { if (!isSelected) e.currentTarget.style.background = C.bgHover; }}
                    onMouseLeave={e => { if (!isSelected) e.currentTarget.style.background = "transparent"; }}
                  >
                    {/* Play Button */}
                    <button onClick={e => e.stopPropagation()} style={{
                      width: 30, height: 30, borderRadius: "50%",
                      background: cfg.color, border: "none",
                      cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
                    }}>
                      <Icon name="play" size={12} color="#fff" />
                    </button>

                    {/* Name */}
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 12, fontWeight: isSelected ? 500 : 400, color: C.text, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                        {s.name}
                      </div>
                      <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 2 }}>
                        <KatBadge kat={s.kategorie} isDark={isDark} />
                        <span style={{ fontSize: 10, color: C.textSoft }}>{s.dauer}</span>
                      </div>
                    </div>

                    {/* Aktionen */}
                    <div style={{ display: "flex", gap: 4, flexShrink: 0 }}>
                      <button onClick={e => { e.stopPropagation(); toggleFavorit(s.id); }} style={{
                        width: 26, height: 26, borderRadius: 5, border: "none",
                        background: "transparent", cursor: "pointer",
                        display: "flex", alignItems: "center", justifyContent: "center",
                      }}>
                        <Icon name="heart" size={13} color={s.favorit ? C.red : C.textSoft} />
                      </button>
                    </div>
                  </div>
                );
              })
            )}

            {tab === "szenen" && (
              gefiltérteSzenen.length === 0 ? (
                <div style={{ padding: "40px 20px", textAlign: "center", color: C.textSoft }}>
                  <Icon name="film" size={28} color={C.border} />
                  <div style={{ marginTop: 10 }}>Keine Szenen gefunden</div>
                  <div style={{ fontSize: 11, marginTop: 4 }}>Erstelle deine erste Szene</div>
                </div>
              ) : gefiltérteSzenen.map(sz => {
                const isSelected = selectedSzeneId === sz.id;
                return (
                  <div key={sz.id} onClick={() => setSelectedSzeneId(sz.id)} style={{
                    display: "flex", alignItems: "center", gap: 10,
                    padding: "10px 14px",
                    background: isSelected ? C.bgActive : "transparent",
                    borderBottom: `1px solid ${C.border}`,
                    borderLeft: `3px solid ${isSelected ? "#7c3aed" : "transparent"}`,
                    cursor: "pointer", transition: "background 0.15s",
                  }}
                    onMouseEnter={e => { if (!isSelected) e.currentTarget.style.background = C.bgHover; }}
                    onMouseLeave={e => { if (!isSelected) e.currentTarget.style.background = "transparent"; }}
                  >
                    <div style={{
                      width: 34, height: 34, borderRadius: 8, flexShrink: 0,
                      background: "#7c3aed18", border: "1px solid #7c3aed30",
                      display: "flex", alignItems: "center", justifyContent: "center",
                    }}>
                      <Icon name="film" size={15} color="#7c3aed" />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: isSelected ? 500 : 400, color: C.text, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                        {sz.name}
                      </div>
                      <div style={{ fontSize: 11, color: C.textSoft, marginTop: 1 }}>
                        {sz.sounds.length} Sounds
                      </div>
                    </div>
                    {sz.favorit && <Icon name="star" size={12} color={C.amber} />}
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* ══ RECHTE SEITE ══ */}
        <div style={{ flex: 1, overflow: "hidden", background: C.bg }}>
          {tab === "sounds" && selectedSound && (
            <SoundPlayer sound={selectedSound} C={C} isDark={isDark} />
          )}
          {tab === "sounds" && !selectedSound && (
            <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: 10, color: C.textSoft }}>
              <Icon name="music" size={32} color={C.border} />
              <div style={{ fontSize: 14 }}>Sound auswählen</div>
            </div>
          )}
          {tab === "szenen" && selectedSzene && (
            <SzeneDetail szene={selectedSzene} sounds={sounds} C={C} isDark={isDark} onEdit={() => {}} />
          )}
          {tab === "szenen" && !selectedSzene && (
            <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: 10, color: C.textSoft }}>
              <Icon name="film" size={32} color={C.border} />
              <div style={{ fontSize: 14 }}>Szene auswählen</div>
            </div>
          )}
        </div>
      </div>

      <style>{`
        * { box-sizing: border-box; }
        input::placeholder { color: ${C.textSoft}; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
      `}</style>
    </div>
  );
}
