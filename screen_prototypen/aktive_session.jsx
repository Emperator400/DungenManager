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

const initSzenen = [
  {
    id: 1, nr: 1, titel: "Vorstellung des Abenteuers", typ: "Einführung",
    beschreibung: "Jeder stellt seinen Charakter ein mal vor. Am besten beschreibt jeder wie er aussieht warum er sich nun entschlossen hat, sich einer Gruppe anzuschließen usw.\n\nDie Helden befinden sich auf dem Marktplatz vor dem Schwarzen Brett.\nDraußen. Es laufen Dorfbewohner herum.\nWas wollt ihr tuen?",
    charaktere: ["Benedict ex Sancitas (Lvl 1)", "Lüthien Eireannon (Lvl 1)", "Johann (Lvl 1)", "Ayleen (Lvl 1)", "Jören (Lvl 1)"],
    wiki: ["Phandalin"],
    expanded: true,
  },
  {
    id: 2, nr: 2, titel: "Vorstellung der Einzelnen Helden", typ: "Sozial",
    beschreibung: "", charaktere: [], wiki: [], expanded: false,
  },
  {
    id: 3, nr: 3, titel: "Erkunden von Phandalin", typ: "Erforschung",
    beschreibung: "Die Spieler erkunden nun Phandalin\nLeite diese zu erst zum Rathaus damit sie sich dort die Karte von Phandalin und Umgebung sowie die ersten drei Quest abholen können",
    charaktere: [], wiki: ["Gasthaus Steinhügel","Barthens Proviant","Rathaus","Schrein des Glücks","Minenbörse Phandalin","Geschichten aus Phandalin","Löwenschilds Waren"],
    expanded: false,
  },
  {
    id: 4, nr: 4, titel: "Das Radhaus", typ: "Erforschung",
    beschreibung: "", charaktere: [], wiki: [], expanded: false,
  },
];

const initQuests = [
  { id: 1, name: "Der Haderhügel", typ: "Haupt", status: "Aufgegeben", beschreibung: "Die Örtliche Hebamme und Chauntea-Tempeldienerin Adabra Gwynn lebt alleine in einer steinernen Windmüle..." },
  { id: 2, name: "Gnomengrad", typ: "Haupt", status: "Aufgegeben", beschreibung: "In den Bergen südöstlich von hier haust ein Klan zurückgezogener Felsengnome in Gnomengrad..." },
  { id: 3, name: "Die Zwergenausgrabung", typ: "Haupt", status: "Aufgegeben", beschreibung: "Zwergengoldsucher sind in den Bergen Südwestlich von hier auf der Suche nach Ruinen von Zwergen gestoßen..." },
];

const TYP_FARBE = {
  Einführung: "#2f6feb", Sozial: "#7c3aed", Erforschung: "#1a7f4b",
  Kampf: "#c93a3a", Rätsel: "#b45309", Abschluss: "#0891b2",
};

const STATUS_CFG = {
  Aktiv:      { color: "#1a7f4b", bg_l: "#eaf4ee", bg_d: "#0f2a1c" },
  Aufgegeben: { color: "#b45309", bg_l: "#fdf6ec", bg_d: "#2a1f08" },
  Erledigt:   { color: "#6b6b66", bg_l: "#f0f0ed", bg_d: "#232320" },
};

const Icon = ({ name, size = 14, color }) => {
  const paths = {
    sun: "M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z",
    moon: "M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z",
    back: "M10 3L5 8l5 5",
    plus: "M8 3v10M3 8h10",
    play: "M4 3l10 5-10 5V3z",
    sword: "M3 13l8-8m0 0l2-2 2 2-2 2M5 11l-2 2",
    music: "M9 3v8.5a2.5 2.5 0 11-1-2V6L5 7V4l4-1z",
    note: "M6 3h6M8 3v10M6 13h4",
    scroll: "M4 2h8a1 1 0 011 1v12l-4.5-2L4 15V3a1 1 0 011-1z",
    user: "M8 7a3 3 0 100-6 3 3 0 000 6zm-5 9a5 5 0 0110 0",
    book: "M3 3h8l2 2v10H3V3zm4 5h4M7 11h4",
    chevDown: "M4 6l4 4 4-4",
    chevUp: "M4 10l4-4 4 4",
    vol: "M6 5L3 8v0l3 3V5zm2 0a4 4 0 010 6",
    check: "M4 8l3 3 5-5",
    clock: "M8 3a5 5 0 100 10A5 5 0 008 3zm0 3v2.5l2 1",
    location: "M8 2a4 4 0 014 4c0 3-4 8-4 8S4 9 4 6a4 4 0 014-4z",
    flag: "M3 14V3l10 4-10 4",
    dots: "M4 8a1 1 0 100-2 1 1 0 000 2zm4 0a1 1 0 100-2 1 1 0 000 2zm4 0a1 1 0 100-2 1 1 0 000 2z",
    save: "M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z",
  };
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill="none"
      stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || ""} fill={name === "play" ? color : "none"} />
    </svg>
  );
};

const SectionLabel = ({ children, C }) => (
  <div style={{ fontSize: 10, fontWeight: 600, color: C.textSoft, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 6 }}>
    {children}
  </div>
);

export default function AktiveSession() {
  const [isDark, setIsDark] = useState(true);
  const [szenen, setSzenen] = useState(initSzenen);
  const [quests, setQuests] = useState(initQuests);
  const [notizen, setNotizen] = useState("- Meta und Bruno kommen mit einem Pferdewagen an und werden auf den Boden geschmissen wo sie auf die anderen Treffen. Diese stehen vor ihnen und wundern sich wer diese sind und was sie da machen\n\n-");
  const [questFilter, setQuestFilter] = useState("Alle");
  const [masterVol, setMasterVol] = useState(100);
  const [zeit, setZeit] = useState({ h: 8, min: 0 });

  const C = THEMES[isDark ? "dark" : "light"];

  const toggleSzene = (id) => setSzenen(prev => prev.map(s => s.id === id ? { ...s, expanded: !s.expanded } : s));

  const gefilterteQuests = quests.filter(q =>
    questFilter === "Alle" || q.status === questFilter
  );

  const statusCounts = {
    Alle: quests.length,
    Aktiv: quests.filter(q => q.status === "Aktiv").length,
    Aufgegeben: quests.filter(q => q.status === "Aufgegeben").length,
    Erledigt: quests.filter(q => q.status === "Erledigt").length,
  };

  const setQuestStatus = (id, status) => {
    setQuests(prev => prev.map(q => q.id === id ? { ...q, status } : q));
  };

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
          <div>
            <div style={{ fontSize: 14, fontWeight: 600, color: C.text }}>Das Ankommen</div>
            <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
              <Icon name="clock" size={11} color={C.textSoft} />
              <span style={{ fontSize: 11, color: C.textSoft }}>In-Game Zeit: {zeit.h}h {zeit.min}min</span>
            </div>
          </div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          {/* Live Badge */}
          <div style={{
            display: "flex", alignItems: "center", gap: 5,
            padding: "4px 10px", borderRadius: 6,
            background: C.greenSoft, border: `1px solid ${C.green}33`,
          }}>
            <div style={{ width: 6, height: 6, borderRadius: "50%", background: C.green }} />
            <span style={{ fontSize: 11, fontWeight: 500, color: C.green }}>Aktiv</span>
          </div>

          {/* Kampagne */}
          <div style={{
            padding: "4px 10px", borderRadius: 6,
            background: C.bgHover, border: `1px solid ${C.border}`,
            fontSize: 11, color: C.textMid,
          }}>
            Der Drach vom Eisnadelgipfel
          </div>

          <button onClick={() => setIsDark(d => !d)} style={{
            width: 32, height: 32, borderRadius: 7,
            background: C.bgHover, border: `1px solid ${C.border}`,
            cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name={isDark ? "sun" : "moon"} size={14} color={C.textMid} />
          </button>

          {/* Kampf Button */}
          <button style={{
            display: "flex", alignItems: "center", gap: 6,
            padding: "7px 14px", borderRadius: 7,
            background: C.red, border: "none",
            color: "#fff", fontSize: 12, fontWeight: 600,
            cursor: "pointer", fontFamily: "inherit",
          }}>
            <Icon name="sword" size={13} color="#fff" />
            Kampf
          </button>
        </div>
      </div>

      {/* HAUPTBEREICH */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>

        {/* ══ LINKE SEITE — Szenen ══ */}
        <div style={{
          flex: 1, display: "flex", flexDirection: "column",
          background: C.bg, borderRight: `1px solid ${C.border}`,
          overflow: "hidden",
        }}>
          {/* Szenen Header */}
          <div style={{
            padding: "12px 16px 10px", flexShrink: 0,
            background: C.bgPanel, borderBottom: `1px solid ${C.border}`,
            display: "flex", alignItems: "center", justifyContent: "space-between",
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
              <Icon name="scroll" size={14} color={C.accent} />
              <span style={{ fontSize: 13, fontWeight: 600, color: C.text }}>Szenen-Ablauf</span>
              <span style={{
                fontSize: 10, color: C.textSoft,
                background: C.bgHover, padding: "1px 7px", borderRadius: 4,
              }}>{szenen.length} Szenen</span>
            </div>
            <button style={{
              display: "flex", alignItems: "center", gap: 5,
              padding: "5px 10px", borderRadius: 6,
              background: C.accent, border: "none",
              color: "#fff", fontSize: 11, fontWeight: 500,
              cursor: "pointer", fontFamily: "inherit",
            }}>
              <Icon name="plus" size={12} color="#fff" />
              Neue Szene
            </button>
          </div>

          {/* Szenen Liste */}
          <div style={{ flex: 1, overflow: "auto", padding: "10px 12px" }}>
            {szenen.map((szene, idx) => {
              const farbe = TYP_FARBE[szene.typ] || C.accent;
              return (
                <div key={szene.id} style={{
                  background: C.bgPanel, border: `1px solid ${szene.expanded ? C.borderStrong : C.border}`,
                  borderLeft: `3px solid ${farbe}`,
                  borderRadius: 8, marginBottom: 8, overflow: "hidden",
                  transition: "all 0.15s",
                }}>
                  {/* Szene Header */}
                  <div
                    onClick={() => toggleSzene(szene.id)}
                    style={{
                      display: "flex", alignItems: "center", gap: 10,
                      padding: "10px 12px", cursor: "pointer",
                    }}
                    onMouseEnter={e => e.currentTarget.style.background = C.bgHover}
                    onMouseLeave={e => e.currentTarget.style.background = "transparent"}
                  >
                    <div style={{
                      width: 26, height: 26, borderRadius: 6, flexShrink: 0,
                      background: farbe, display: "flex",
                      alignItems: "center", justifyContent: "center",
                      fontSize: 12, fontWeight: 700, color: "#fff",
                    }}>{szene.nr}</div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 500, color: C.text }}>{szene.titel}</div>
                      <div style={{ fontSize: 11, color: C.textSoft, marginTop: 1 }}>{szene.typ}</div>
                    </div>
                    <div style={{ display: "flex", gap: 4 }}>
                      <button onClick={e => e.stopPropagation()} style={{
                        width: 24, height: 24, borderRadius: 5, border: "none",
                        background: "transparent", cursor: "pointer",
                        display: "flex", alignItems: "center", justifyContent: "center",
                      }}>
                        <Icon name="dots" size={12} color={C.textSoft} />
                      </button>
                      <Icon name={szene.expanded ? "chevUp" : "chevDown"} size={13} color={C.textSoft} />
                    </div>
                  </div>

                  {/* Szene Detail */}
                  {szene.expanded && (
                    <div style={{
                      padding: "0 12px 12px",
                      borderTop: `1px solid ${C.border}`,
                    }}>
                      {szene.beschreibung && (
                        <div style={{ marginTop: 10, marginBottom: 10 }}>
                          <SectionLabel C={C}>Beschreibung</SectionLabel>
                          <p style={{ margin: 0, fontSize: 12, color: C.textMid, lineHeight: 1.6, whiteSpace: "pre-wrap" }}>
                            {szene.beschreibung}
                          </p>
                        </div>
                      )}
                      {szene.charaktere.length > 0 && (
                        <div style={{ marginBottom: 10 }}>
                          <SectionLabel C={C}>Verknüpfte Charaktere</SectionLabel>
                          <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
                            {szene.charaktere.map((ch, i) => (
                              <span key={i} style={{
                                display: "flex", alignItems: "center", gap: 5,
                                fontSize: 11, color: C.textMid,
                                background: C.bgHover, border: `1px solid ${C.border}`,
                                padding: "3px 8px", borderRadius: 5,
                              }}>
                                <Icon name="user" size={10} color={C.textSoft} />
                                {ch}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                      {szene.wiki.length > 0 && (
                        <div>
                          <SectionLabel C={C}>Verknüpfte Wiki-Einträge</SectionLabel>
                          <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
                            {szene.wiki.map((w, i) => (
                              <span key={i} style={{
                                display: "flex", alignItems: "center", gap: 5,
                                fontSize: 11, color: C.purple,
                                background: isDark ? C.purpleSoft : "#f3effe",
                                border: `1px solid ${C.purple}33`,
                                padding: "3px 8px", borderRadius: 5,
                              }}>
                                <Icon name="book" size={10} color={C.purple} />
                                {w}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* ══ RECHTE SEITE ══ */}
        <div style={{
          width: "38%", display: "flex", flexDirection: "column",
          background: C.bgPanel, overflow: "hidden",
          minWidth: 320,
        }}>

          {/* Live Notizen */}
          <div style={{
            flexShrink: 0, borderBottom: `1px solid ${C.border}`,
            display: "flex", flexDirection: "column",
          }}>
            <div style={{
              padding: "10px 14px 8px",
              display: "flex", alignItems: "center", gap: 6,
            }}>
              <Icon name="note" size={13} color={C.amber} />
              <span style={{ fontSize: 12, fontWeight: 600, color: C.text }}>Live-Notizen</span>
            </div>
            <textarea
              value={notizen}
              onChange={e => setNotizen(e.target.value)}
              style={{
                padding: "8px 14px", border: "none", outline: "none",
                background: "transparent", color: C.text, fontSize: 12,
                fontFamily: "inherit", lineHeight: 1.6, resize: "none",
                height: 120,
              }}
              placeholder="Notizen während der Session..."
            />
            <div style={{
              padding: "4px 14px 8px",
              display: "flex", alignItems: "center", justifyContent: "space-between",
            }}>
              <span style={{ fontSize: 10, color: C.textSoft }}>Auto-Save</span>
              <span style={{
                fontSize: 10, color: C.green,
                display: "flex", alignItems: "center", gap: 4,
              }}>
                <Icon name="check" size={10} color={C.green} />
                Gespeichert
              </span>
            </div>
          </div>

          {/* Atmosphäre */}
          <div style={{
            flexShrink: 0, borderBottom: `1px solid ${C.border}`,
            padding: "10px 14px 12px",
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 10 }}>
              <Icon name="music" size={13} color={C.accent} />
              <span style={{ fontSize: 12, fontWeight: 600, color: C.text }}>Atmosphäre</span>
            </div>

            {/* Sound Mixer */}
            <div style={{
              display: "flex", alignItems: "center", gap: 10,
              padding: "8px 10px", borderRadius: 8,
              background: C.bgHover, border: `1px solid ${C.border}`,
              marginBottom: 10,
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8,
                background: C.green + "22", border: `1px solid ${C.green}44`,
                display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <Icon name="vol" size={14} color={C.green} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 500, color: C.text }}>Sound Mixer</div>
                <div style={{ fontSize: 10, color: C.textSoft }}>0 von 0 spielen</div>
              </div>
            </div>

            {/* Master Volume */}
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 10 }}>
              <Icon name="vol" size={13} color={C.textSoft} />
              <span style={{ fontSize: 11, color: C.textMid, minWidth: 44 }}>Master</span>
              <div style={{
                flex: 1, height: 3, background: C.border, borderRadius: 2, cursor: "pointer",
              }} onClick={e => {
                const rect = e.currentTarget.getBoundingClientRect();
                setMasterVol(Math.round(((e.clientX - rect.left) / rect.width) * 100));
              }}>
                <div style={{ height: "100%", width: `${masterVol}%`, background: C.green, borderRadius: 2 }} />
              </div>
              <span style={{ fontSize: 10, color: C.textSoft, minWidth: 28, textAlign: "right" }}>{masterVol}%</span>
            </div>

            {/* Ambiente + Effekt Buttons */}
            <div style={{ display: "flex", gap: 8 }}>
              {[
                { label: "Ambiente", icon: "music", color: C.green },
                { label: "Effekt", icon: "vol", color: C.accent },
              ].map(b => (
                <button key={b.label} style={{
                  flex: 1, padding: "8px",
                  background: b.color + "18",
                  border: `1px solid ${b.color}33`,
                  borderRadius: 7, color: b.color,
                  fontSize: 12, fontWeight: 500,
                  cursor: "pointer", fontFamily: "inherit",
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 5,
                  transition: "background 0.15s",
                }}
                  onMouseEnter={e => e.currentTarget.style.background = b.color + "30"}
                  onMouseLeave={e => e.currentTarget.style.background = b.color + "18"}
                >
                  <Icon name={b.icon} size={12} color={b.color} />
                  {b.label}
                </button>
              ))}
            </div>
          </div>

          {/* Quests */}
          <div style={{ flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" }}>
            <div style={{ padding: "10px 14px 8px", flexShrink: 0 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8 }}>
                <Icon name="flag" size={13} color={C.purple} />
                <span style={{ fontSize: 12, fontWeight: 600, color: C.text }}>Quests</span>
              </div>

              {/* Quest Filter */}
              <div style={{ display: "flex", gap: 4 }}>
                {["Alle", "Aktiv", "Aufgegeben", "Erledigt"].map(f => {
                  const aktiv = questFilter === f;
                  const cfg = STATUS_CFG[f];
                  return (
                    <button key={f} onClick={() => setQuestFilter(f)} style={{
                      padding: "3px 8px", borderRadius: 5,
                      background: aktiv ? (cfg ? (isDark ? cfg.bg_d : cfg.bg_l) : C.accentSoft) : "transparent",
                      border: `1px solid ${aktiv ? (cfg ? cfg.color : C.accent) : C.border}`,
                      color: aktiv ? (cfg ? cfg.color : C.accent) : C.textSoft,
                      fontSize: 10, cursor: "pointer", fontFamily: "inherit",
                      display: "flex", alignItems: "center", gap: 3,
                    }}>
                      {f}
                      <span style={{ opacity: 0.7 }}>{statusCounts[f]}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Quest Liste */}
            <div style={{ flex: 1, overflow: "auto", padding: "0 12px 12px" }}>
              {gefilterteQuests.map(q => {
                const cfg = STATUS_CFG[q.status] || STATUS_CFG["Aktiv"];
                return (
                  <div key={q.id} style={{
                    background: C.bgHover, border: `1px solid ${C.border}`,
                    borderRadius: 8, padding: "10px 12px", marginBottom: 7,
                  }}>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 5 }}>
                      <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
                        <div style={{ width: 8, height: 8, borderRadius: "50%", background: cfg.color, flexShrink: 0 }} />
                        <span style={{ fontSize: 12, fontWeight: 500, color: C.text }}>{q.name}</span>
                      </div>
                      <span style={{
                        fontSize: 9, fontWeight: 500, color: C.purple,
                        background: isDark ? C.purpleSoft : "#f3effe",
                        padding: "1px 6px", borderRadius: 4,
                      }}>{q.typ}</span>
                    </div>

                    {/* Status Buttons */}
                    <div style={{ display: "flex", gap: 5 }}>
                      {["Aufgegeben", "Aktiv", "Erledigt"].map(s => {
                        const sCfg = STATUS_CFG[s];
                        const isAktiv = q.status === s;
                        return (
                          <button key={s} onClick={() => setQuestStatus(q.id, s)} style={{
                            flex: 1, padding: "4px 4px",
                            background: isAktiv ? (isDark ? sCfg.bg_d : sCfg.bg_l) : "transparent",
                            border: `1px solid ${isAktiv ? sCfg.color : C.border}`,
                            borderRadius: 5, color: isAktiv ? sCfg.color : C.textSoft,
                            fontSize: 10, fontWeight: isAktiv ? 500 : 400,
                            cursor: "pointer", fontFamily: "inherit",
                            transition: "all 0.15s",
                          }}>{s}</button>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      <style>{`
        * { box-sizing: border-box; }
        textarea::placeholder { color: ${C.textSoft}; }
        textarea { font-family: inherit; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: ${C.border}; border-radius: 2px; }
      `}</style>
    </div>
  );
}
