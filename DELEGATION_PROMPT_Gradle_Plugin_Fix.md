# Delegation Prompt: Gradle Plugin Fehler beheben

"Du bist der **Backend-API-Agent**.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `pubspec.yaml` für Flutter-Version und Dependencies.

**Dein spezifischer Task:**
Behebe den kritischen Gradle Plugin Fehler, der den kompletten Build blockiert:

**Fehlerbeschreibung:**
- **Fehler**: "You are applying Flutter's app_plugin_loader Gradle plugin imperatively using the apply script method, which is not possible anymore. Migrate to applying Gradle plugins with the declarative plugins block"
- **Datei**: android/app/build.gradle
- **Blockiert**: Kompletten App-Build (flutter build apk --debug schlägt fehl)
- **Priorität**: 🔴 KRITISCH

**Dein Protokoll (A-P-B-V-L):**

**A - Analyse:**
1. Untersuche die aktuelle android/app/build.gradle Datei
2. Identifiziere die veraltete `apply script` Methode für Flutter Plugins
3. Prüfe Flutter-Version und unterstützte Gradle-Plugin-Migration
4. Analysiere die android/settings.gradle Datei für plugin Management

**P - Plan (mit Diffs + Verifikation):**
1. Migriere zu declarative plugins block in android/app/build.gradle
2. Aktualisiere android/settings.gradle für plugin Management
3. Verifiziere Kompatibilität mit aktueller Flutter-Version
4. Teste mit `flutter clean` und `flutter build apk --debug`

**B - Bestätigung (User-Gate):**
Präsentiere die exakten Änderungen für die Migration zur Bestätigung vor der Implementierung.

**V - Verifikation:**
Nach Implementierung:
1. Führe `flutter clean` aus
2. Teste `flutter build apk --debug` - muss erfolgreich sein
3. Überprüfe, dass keine weiteren Gradle-Fehler auftreten

**L - Lernen (Vorschlag für Bug-Archiv):**
Dokumentiere die genaue Vorgehensweise für zukünftige Flutter-Gradle Migrationen.

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du (Sub-Agent) während deiner Analyse feststellst, dass dieser Task nicht gelöst werden kann ODER dass die Ursache außerhalb deines Fachgebiets liegt (z.B. Flutter-Version incompatible):
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann."
