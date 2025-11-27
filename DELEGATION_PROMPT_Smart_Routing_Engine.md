Du bist der `backend_api_agent` mit Unterstützung vom `debugging_error_specialist`.

**Kontext-Laden:**
1. Lies `INTEGRATED_DELEGATION_ARCHITECTURE.md` für die vollständige Architektur-Spezifikation
2. Lies `.vscode/docs/AI_PROFESSIONS.md` für das bestehende Routing-System
3. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen und bekannte Probleme
4. Lies `CODE_STANDARDS.md` für Coding-Konventionen
5. Lies `analysis_options.yaml` für Linting-Regeln

**Dein spezifischer Task:**
Implementiere die Smart Routing Engine gemäß der Spezifikation in `INTEGRATED_DELEGATION_ARCHITECTURE.md`.

**Datei:** `lib/services/task_routing_service.dart`

**Funktionalität:**
1. **Keyword-basierte Agenten-Auswahl:**
   - Extrahiere Keywords aus Task-Beschreibungen
   - Mappe Keywords zu Agenten aus AI_PROFESSIONS
   - Berücksichtige Kontext-Dateien und Dateipfade

2. **Kontext-Analyse:**
   - Analysiere betroffene Dateien auf Muster
   - Identifiziere Fehler-Typen und Komplexitätsmerkmale
   - Bewerte die Vertrauenswürdigkeit der Routing-Entscheidung

3. **Komplexitäts-Bewertung:**
   - Bestimme ob ein Task TPL-Übersteuerung benötigt
   - Identifiziere Multi-System-Szenarien
   - Erkenne architektonische Aufgaben

4. **TPL-Integration:**
   - Generiere AgentSelection-Objekte mit Routing-Info
   - Unterstütze manuelle Agenten-Auswahl
   - Biete Fallback-Mechanismen

**Datenstrukturen:**
```dart
class TaskDescription {
  final String description;
  final List<String> files;
  final Map<String, dynamic> context;
}

class AgentSelection {
  final String primaryAgent;
  final String? fallbackAgent;
  final double confidence;
  final bool requiresTPL;
  final Map<String, dynamic> routingInfo;
}

class RoutingResult {
  final AgentSelection selection;
  final List<String> matchedKeywords;
  final String reasoning;
  final bool needsEscalation;
}
```

**Anforderungen:**
1. **Performance:** Routing in <100ms für typische Tasks
2. **Zuverlässigkeit:** 95%+ Genauigkeit bei Agenten-Auswahl
3. **Erweiterbarkeit:** Leichte Hinzufügung neuer Agenten und Keywords
4. **Error-Handling:** Robuste Fehlerbehandlung mit Fallbacks
5. **Testing:** Unit Tests mit >90% Coverage

**Integration:**
- Nutzung der vorhandenen AI_PROFESSIONS Keywords
- Kompatibilität mit bestehenden TPL-Prompts
- Unterstützung für zukünftige ML-basierte Optimierung

**Dein Protokoll (A-P-B-V-L):**
1. **Analyse:** Architektur verstehen,Requirements analysieren, Dependencies identifizieren
2. **Plan:** Detaillierter Implementierungsplan mit Code-Struktur, Methoden-Signaturen, Test-Strategy
3. **Bestätigung:** Präsentiere den Plan zur Genehmigung
4. **Verifikation:** Implementiere nach bewährtem Plan, stelle sicher dass alle Requirements erfüllt sind
5. **Lernen:** Dokumentiere Erkenntnisse für BUG_ARCHIVE.md

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Erfolgskriterien:**
- Smart Routing Engine implementiert und voll funktionsfähig
- Alle Tests bestehen (>90% Coverage)
- Performance-Targets erfüllt (<100ms Routing-Zeit)
- Integration mit AI_PROFESSIONS funktioniert
- TPL-Übersteuerung unterstützt
- Robustes Error-Handling implementiert
