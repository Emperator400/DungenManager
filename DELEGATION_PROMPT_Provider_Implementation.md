Du bist der `Campaign Manager Specialist`.

**Kontext-Laden:**
1. Lies `DELEGATION_PROMPT_Provider_Fix.md` für den bisherigen Analyse-Kontext
2. Lies `lib/screens/campaign_selection_screen.dart` und `lib/screens/enhanced_main_navigation_screen.dart` für die aktuelle Implementierung

**Dein spezifischer Task:**
**Task 2 & 3: Provider-Korrektur implementieren**

Basierend auf der vorherigen Analyse implementiere jetzt die Lösung:

**Task 2: CampaignSelectionScreen Provider-Wrapper anpassen**
- Ändere die Navigation in `_navigateToCampaign()` um `ChangeNotifierProvider.value` zu verwenden
- Stelle sicher dass das `CampaignViewModel` korrekt an `EnhancedMainNavigationScreen` weitergegeben wird

**Task 3: EnhancedMainNavigationScreen Provider erweitern**
- Füge `CampaignViewModel` zum `MultiProvider` hinzu
- Verwende `ChangeNotifierProvider.value` um das existierende ViewModel zu übernehmen
- Stelle sicher dass keine Provider-Konflikte entstehen

**Implementierungs-Anforderungen:**
1. CampaignViewModel muss in der gesamten kampagnenspezifischen Navigation verfügbar sein
2. Bestehende Funktionalität darf nicht beeinträchtigt werden
3. Hot-reload Kompatibilität erhalten

**Dein Protokoll (A-P-B-V-L):**
(Analyse, Plan (mit konkreten Code-Diffs), Bestätigung (User-Gate), Verifikation, Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Bei Problemen: `[ESKALATION]` mit neuer Problem-Spezifikation.

**Erwartetes Ergebnis:** Funktionierende Provider-Vererbungskette ohne ProviderNotFoundException.
