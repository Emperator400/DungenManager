Du bist der `generalist_agent`.

**Kontext-Laden:**
1. Lies `INTEGRATED_DELEGATION_ARCHITECTURE.md` für die vollständige Architektur-Spezifikation
2. Lies `.vscode/docs/AI_PROFESSIONS.md` für das bestehende Agenten-System
3. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen und bekannte Probleme
4. Lies `CODE_STANDARDS.md` für Coding-Konventionen
5. Lies `analysis_options.yaml` für Linting-Regeln
6. Lies `DELEGATION_PLAN.md` für bestehende Prompt-Templates

**Dein spezifischer Task:**
Implementiere den Enhanced Prompt Generator gemäß der Spezifikation in `INTEGRATED_DELEGATION_ARCHITECTURE.md`.

**Datei:** `lib/services/delegation_prompt_service.dart`

**Funktionalität:**
1. **Intelligente Prompt-Generierung:**
   - Generiere spezialisten-spezifische Prompts
   - Integriere Routing-Informationen aus TaskRoutingService
   - Passe Kontext-Lade-Anweisungen an den Spezialisten an

2. **Spezialisten-spezifische Kontexte:**
   - Lade relevante Kontext-Dateien basierend auf Agenten-Typ
   - Integriere Domain-spezifisches Wissen
   - Binde spezialisierte Dokumentation ein

3. **Routing-Informationen integrieren:**
   - Zeige Primär-Spezialist und Konfidenz
   - Integriere Fallback-Agenten
   - Zeige TPL-Übersteuerungs-Status

4. **Enhanced Prompt Schema:**
   - Unterstütze das neue A-P-B-V-L Protokoll
   - Integriere spezialisierte Eskalations-Paths
   - Generiere vollständige, einsatzbereite Prompts

**Datenstrukturen:**
```dart
class PromptContext {
  final String agentName;
  final String agentRole;
  final List<String> contextFiles;
  final Map<String, dynamic> routingInfo;
  final String taskDescription;
  final List<String> affectedFiles;
}

class GeneratedPrompt {
  final String fullPrompt;
  final PromptContext context;
  final Map<String, dynamic> metadata;
  final List<String> warnings;
}

class PromptTemplate {
  final String agentName;
  final String template;
  final List<String> requiredContextFiles;
  final List<String> optionalContextFiles;
  final Map<String, String> defaultValues;
}
```

**Enhanced Prompt Template Struktur:**
```markdown
Du bist der `[Agenten-Name]`.

**Intelligent-Routing Ergebnis:**
- **Primär-Spezialist:** [Name]
- **Routing-Konfidenz:** [0-100%]
- **Alternative:** [Fallback-Agent]
- **TPL-Übersteuerung:** [Ja/Nein]
- **Routing-Reasoning:** [Beschreibung]

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen
2. Lies [spezialisten-spezifische Kontext-Dateien]
3. Lies [task-spezifische Dateien]

**Dein spezifischer Task:**
[Präzise Task-Beschreibung mit Kontext]

**Dein Protokoll (A-P-B-V-L):**
[Spezialisten-spezifische Protokoll-Anpassungen]

**Intelligentes Eskalations-Protokoll:**
[Spezialisierte Escalation Paths]
```

**Anforderungen:**
1. **Dynamische Generierung:** Prompts müssen zur Laufzeit generiert werden
2. **Spezialisten-Unterstützung:** Alle 15+ Spezialisten aus AI_PROFESSIONS
3. **Kontext-Intelligenz:** Automatische Auswahl relevanter Kontext-Dateien
4. **Template-Verwaltung:** Zentralisierte Prompt-Templates
5. **Validation:** Generierte Prompts auf Vollständigkeit prüfen
6. **Performance:** Prompt-Generierung in <50ms

**Spezialisten-Kontext-Mapping:**
```dart
const Map<String, List<String>> SPECIALIST_CONTEXT_FILES = {
  'database_error_specialist': [
    '.vscode/docs/BUG_ARCHIVE.md',
    'lib/database/database_helper.dart',
    'lib/models/',
    'lib/services/exceptions/service_exceptions.dart'
  ],
  'async_state_management_specialist': [
    '.vscode/docs/BUG_ARCHIVE.md',
    'lib/viewmodels/',
    'lib/widgets/',
    'CODE_STANDARDS.md'
  ],
  // ... für alle Spezialisten
};
```

**Integration:**
- Nutzung des TaskRoutingService für Routing-Informationen
- Kompatibilität mit bestehenden TPL-Prompts
- Unterstützung für zukünftige Template-Erweiterungen

**Dein Protokoll (A-P-B-V-L):**
1. **Analyse:** Architektur verstehen,Requirements analysieren,Template-Struktur entwerfen
2. **Plan:** Detaillierter Implementierungsplan mit Prompt-Templates,Kontext-Mapping,Validation-Logic
3. **Bestätigung:** Präsentiere den Plan zur Genehmigung
4. **Verifikation:** Implementiere nach bewährtem Plan,stelle sicher dass alle Spezialisten unterstützt werden
5. **Lernen:** Dokumentiere Template-Pattern und Best Practices

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Erfolgskriterien:**
- Enhanced Prompt Generator implementiert und voll funktionsfähig
- Alle 15+ Spezialisten mit spezialisierten Templates
- Automatische Kontext-Dateien-Auswahl funktioniert
- Integration mit TaskRoutingService funktioniert
- Performance-Targets erfüllt (<50ms Generierungszeit)
- Robuste Template-Validation implementiert
- Kompatibilität mit bestehenden Systemen
