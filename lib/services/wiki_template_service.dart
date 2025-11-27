// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/wiki_entry.dart';
import '../database/database_helper.dart';
import 'exceptions/service_exceptions.dart';

/// Service für Campaign Templates und vordefinierte Wiki-Strukturen
class WikiTemplateService {
  static final WikiTemplateService _instance = WikiTemplateService._internal();
  factory WikiTemplateService() => _instance;
  WikiTemplateService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Holt alle verfügbaren Templates
  List<CampaignTemplate> getAvailableTemplates() => [
    _createFantasyTemplate(),
    _createUrbanTemplate(),
    _createWildernessTemplate(),
    _createDungeonTemplate(),
    _createPoliticalTemplate(),
    _createMysteryTemplate(),
    _createWarTemplate(),
  ];

  /// Erstellt Wiki-Einträge basierend auf einem Template
  Future<List<WikiEntry>> createEntriesFromTemplate(
    CampaignTemplate template, 
    String campaignId
  ) async {
    try {
      if (campaignId.isEmpty) {
        throw ValidationException(
          'Campaign ID ist erforderlich',
          operation: 'createEntriesFromTemplate',
        );
      }

      final entries = <WikiEntry>[];
      
      // Erstelle Haupt-Eintrag für die Kampagne
      final mainEntry = WikiEntry(
        id: '', // Wird von Datenbank generiert
        title: template.mainEntry.title,
        content: _populateTemplate(template.mainEntry.content, campaignId),
        entryType: template.mainEntry.entryType,
        tags: template.mainEntry.tags ?? [],
        campaignId: campaignId,
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      );
      
      final mainEntryId = await _dbHelper.insertWikiEntry(mainEntry);
      final createdMainEntry = mainEntry.copyWith(id: mainEntryId.toString());
      entries.add(createdMainEntry);
      
      // Erstelle untergeordnete Einträge
      for (final subEntry in template.subEntries) {
        final wikiEntry = WikiEntry(
          id: '', // Wird von Datenbank generiert
          title: subEntry.title,
          content: _populateTemplate(subEntry.content, campaignId),
          entryType: subEntry.entryType,
          tags: subEntry.tags ?? [],
          campaignId: campaignId,
          parentId: mainEntryId.toString(),
          createdBy: 'Template System',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          childIds: [],
          isMarkdown: true,
          isFavorite: false,
        );
        
        final subEntryId = await _dbHelper.insertWikiEntry(wikiEntry);
        final createdSubEntry = wikiEntry.copyWith(id: subEntryId.toString());
        entries.add(createdSubEntry);
      }
      
      return entries;
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw DatabaseException('Unbekannter Fehler: $e', operation: 'createEntriesFromTemplate');
    }
  }

  /// Ersetzt Platzhalter im Template-Content
  String _populateTemplate(String content, String campaignId) => content
      .replaceAll('{{CAMPAIGN_ID}}', campaignId)
      .replaceAll('{{CAMPAIGN_NAME}}', 'Kampagne')
      .replaceAll('{{DATE}}', DateTime.now().toString().substring(0, 10))
      .replaceAll('{{DM_NAME}}', 'Dungeon Master')
      .replaceAll('{{PARTY_SIZE}}', '4-5')
      .replaceAll('{{LEVEL_RANGE}}', '1-5');

  /// Fantasy-Kampagnen Template
  CampaignTemplate _createFantasyTemplate() => CampaignTemplate(
    id: 'fantasy',
    name: 'Klassische Fantasy',
    description: 'Traditionelle D&D Fantasy-Kampagne mit Magie, Monstern und Abenteuern',
    icon: '🏰',
    mainEntry: WikiEntry(
      id: '',
      title: 'Willkommen in {{CAMPAIGN_NAME}}',
      content: '''
# Willkommen in {{CAMPAIGN_NAME}}

## Kampagnen-Übersicht
Dies ist eine epische Fantasy-Kampagne in einer Welt voller Magie, gefährlicher Monster und ruhmreicher Abenteurer.

## Die Welt
**Setting:** Traditionelle Fantasy-Welt  
**Zeitalter:** Mittelalter mit Magie  
**Magie-System:** Arkane und göttliche Magie  
**Technologie-Level:** Mittelalterlich  
**Gefahren-Stufe:** Moderat bis Hoch  

## Wichtige Fraktionen
- [[Königreich von Aethel]] - Das mächtigste menschliche Königreich
- [[Der Zirkelbund]] - Geheime Magier-Organisation  
- [[Die Ork-Horden]] - Zersplitterte Stämme der Wildnis
- [[Die Elfische Allianz]] - Uralte Waldelfen

## Aktuelle Situation
Die Welt befindet sich in einer Zeit wachsender Spannungen. Alte Prophezeiungen künden von einer kommenden Dunkelheit, während die Königreiche um knappe Ressourcen kämpfen.

## Kampagnen-Start
Die Abenteurer beginnen als unerfahrene Helden in der kleinen Stadt [[Brückenfurt]] an der Grenze zur Zivilisation.

*Diese Kampagne wurde am {{DATE}} erstellt. DM: {{DM_NAME}}*
      ''',
      entryType: WikiEntryType.Place,
      tags: ['kampagne', 'fantasy', 'setting', 'welt'],
      campaignId: '',
      createdBy: 'Template System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: true,
      isFavorite: false,
    ),
    subEntries: [
      WikiEntry(
        id: '',
        title: 'Brückenfurt',
        content: '''
# Brückenfurt

## Ort des Beginns
Brückenfurt ist eine kleine Grenzstadt mit etwa {{PARTY_SIZE}} Einwohnern an der Brücke des Großen Flusses.

## Bevölkerung
- **Menschen:** 60% (Bauern, Händler, Handwerker)
- **Elfen:** 20% (Waldhüter, Jäger)
- **Zwerge:** 15% (Bergleute, Schmiede)
- **Andere:** 5% (Halblinge, etc.)

## Wichtige Orte
- [[Zur Goldenen Krone]] - Das beste Gasthaus der Stadt
- [[Händlersgilde]] - Zentrum für Handel und Information
- [[Die Alte Brücke]] - Magische Brücke mit besonderen Eigenschaften
- [[Stadtwache]] - Kleine Garnison mit {{PARTY_SIZE}} Wachen

## Geschichte
Brückenfurt wurde vor 200 Jahren von Zwergen als Handelsposten gegründet. Die magische Brücke wurde von Elfen errichtet, um den Handel mit den Waldreichen zu ermöglichen.

*Brückenfurt dient als Ausgangspunkt für eine {{PARTY_SIZE}}-köpfige Gruppe (Stufe {{LEVEL_RANGE}})*
        ''',
        entryType: WikiEntryType.Place,
        tags: ['stadt', 'starting-point', 'handel'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
      WikiEntry(
        id: '',
        title: 'Königreich von Aethel',
        content: '''
# Königreich von Aethel

## Das größte menschliche Königreich
Aethel ist das mächtigste und stabilste Königreich der Region, bekannt für seine gerechten Könige und tapferen Ritter.

## Regierung
- **Monarch:** König Theron III.  
- **Hauptstadt:** [[Aethelgrad]]  
- **Regierungsform:** Feudale Monarchie  
- **Gesetze:** Kodex der Ritterlichkeit  

## Militär
- **Ritterorden:** Die Silbernen Ritter  
- **Stadtmiliz:** Königliche Garde von Aethel  
- **Marine:** Flotte der Silbernen Segel  

## Wichtige Persönlichkeiten
- [[König Theron III]] - Der aktuelle Herrscher
- [[Herzogin Elara]] - Regentin der Nordprovinz
- [[Großmagier Valerius]] - Hofmagier des Königs

## Beziehungen
- **Freundlich:** [[Die Elfische Allianz]], [[Das Zwergenreich von Khazad-dûm]]
- **Feindlich:** [[Der Zirkelbund]], [[Die Ork-Horden]]
- **Neutral:** [[Die Handelsstädte]]

*Königreich von Aethel kontrolliert die zentralen Ebenen und Flüsse*
        ''',
        entryType: WikiEntryType.Faction,
        tags: ['fraktion', 'königreich', 'menschen'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
    ],
  );

  /// Urban-Kampagnen Template
  CampaignTemplate _createUrbanTemplate() => CampaignTemplate(
    id: 'urban',
    name: 'Stadt-Abenteuer',
    description: 'Kampagne in einer großen Metropole mit politischen Intrigen und Gilden-Konflikten',
    icon: '🏙️',
    mainEntry: WikiEntry(
      id: '',
      title: 'Die Stadt der Schatten',
      content: '''
# Die Stadt der Schatten

## Urbane Fantasy-Kampagne
Eine gewaltige Metropole voller Geheimnisse, Gilden und politischer Intrigen.

## Die Stadt
**Name:** Die Stadt der Schatten (vorläufig)  
**Einwohner:** Über 1 Million  
**Regierung:** Stadtrat mit rivalisierenden Fraktionen  
**Wirtschaft:** Handel, Manufakturen, Dienstleistungen  

## Wichtige Gilden
- [[Die Händlersgilde]] - Mächtigste Handelsorganisation
- [[Die Diebesgilde]] - Unterweltliche Netzwerke
- [[Die Magiergilde]] - Regulation der arkanen Künste
- [[Die Söldnergilde]] - Söldner und Auftragsjäger

## Stadtviertel
- **Adelsviertel:** Luxuriös und bewacht
- **Handelsviertel:** Wohlhabend und geschäftig  
- **Armenviertel:** Überbevölkert und gefährlich
- **Gildenviertel:** Zentrum der Organisationen
- **Dockviertel:** International und chaotisch

## Aktuelle Konflikte
Die Stadtparteien kämpfen um die Kontrolle über den [[Stadtrat]], während [[Die Schattenbruderschaft]] ihre territoriale Expansion vorantreibt.

*Stadt-Kampagne für eine Gruppe von Spezialisten und Intriganten*
      ''',
      entryType: WikiEntryType.Place,
      tags: ['stadt', 'urban', 'intrige'],
      campaignId: '',
      createdBy: 'Template System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: true,
      isFavorite: false,
    ),
    subEntries: [
      WikiEntry(
        id: '',
        title: 'Die Schattenbruderschaft',
        content: '''
# Die Schattenbruderschaft

## Kriminelle Organisation
Die Schattenbruderschaft kontrolliert die Unterwelt der Stadt und ist in zahlreiche illegale Aktivitäten verwickelt.

## Hierarchie
- **Der Schattenkönig:** Unbekannter Anführer  
- **Leutnants:** 4 Zone-Kommandeure  
- **Kapitäne:** 12 Teamführer  
- **Mitglieder:** Über 200 Schurken  

## Aktivitäten
- **Schmuggel:** Luxusgüter und verbotene Magie  
- **Erpressung:** Reiche Bürger und Kaufleute  
- **Diebstahl:** Kunstdiebstähle von Tempeln und Villen  
- **Auftragsmorde:** Politische Attentate  

## Territorien
- **Dockviertel:** Hauptquartier  
- **Armenviertel:** Rekrutierungsgebiet  
- **Handelsviertel:** Schutzgelder  
- **Adelsviertel:** Sabotage  

## Rivalen
- [[Die Händlersgilde]] - Kommerzielle Konkurrenz  
- [[Die Stadtwache]] - Law Enforcement  
- [[Die Magiergilde]] - Magische Konkurrenz  

*Die Schattenbruderschaft ist die mächtigste kriminelle Organisation der Stadt*
        ''',
        entryType: WikiEntryType.Faction,
        tags: ['fraktion', 'kriminell', 'unterwelt'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
    ],
  );

  /// Wilderness-Kampagnen Template
  CampaignTemplate _createWildernessTemplate() => CampaignTemplate(
    id: 'wilderness',
    name: 'Wildnis-Entdecker',
    description: 'Kampagne in unzivilisierten Gebieten mit Erkundung und Überleben',
    icon: '🌲️',
    mainEntry: WikiEntry(
      id: '',
      title: 'Die Unbekannten Lande',
      content: '''
# Die Unbekannten Lande

## Wilderness-Exploration
Eine weite, unerforschte Wildnis voller gefährlicher Kreaturen, uralter Ruinen und natürlicher Geheimnisse.

## Geographie
**Gebirge:** Die Eisengipfel im Norden  
**Wälder:** Das Flüsternde Dickicht im Westen  
**Sümpfe:** Die Giftmoore im Süden  
**Flüsse:** Der Große Fluss und Nebenarme  
**Ebenen:** Die goldenen Weizenfelder im Osten  

## Gefahren
- **Wilde Tiere:** Bären, Wölfe, Riesenschlangen  
- **Magische Kreaturen:** Elementare, Feen, Schattenwesen  
- **Natürliche Gefahren:** Wetter, Erdrinken, Hunger  
- **Uralte Ruinen:** Fallen, Flüche, Wächter  

## Uralte Völker
- **Die ersten Menschen:** Steinzeitliche Jäger  
- **Die Waldelben:** Uralte Baumhüter  
- **Die Hügelzwerge:** Eingefressene Stämme  
- **Die Drachen:** Alte, schläfende Wesen  

## Mysteriöse Orte
- [[Die fliegenden Inseln]] - Schwebende Inseln im Himmel  
- [[Der Zeitlose Wald]] - Ort wo Zeit stillsteht  
- [[Die Kristallhöhlen]] - Magische Kristallformationen  
- [[Die singenden Felsen]] - Seltsame akustische Phänomene  

## Verlorene Zivilisationen
- [[Die versunkene Stadt]] - Unterwasserische Ruinen  
- [[Die Hügelstadt]] - Vergessene Zwergenfestung  
- [[Die Elfenruinen]] - Verfallene elfische Architektur  

*Wildnis-Kampagne für Erkundung und Überleben im Gegensatz zur Zivilisation*
      ''',
      entryType: WikiEntryType.Place,
      tags: ['wildnis', 'erkundung', 'natur'],
      campaignId: '',
      createdBy: 'Template System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: true,
      isFavorite: false,
    ),
    subEntries: [
      WikiEntry(
        id: '',
        title: 'Die fliegenden Inseln',
        content: '''
# Die fliegenden Inseln

## Magische Anomalie
Eine Gruppe von schwebenden Landmassen, die 1000 Fuß über dem Boden schweben.

## Beschreibung
- **Anzahl:** 7 Hauptinseln, dutzende kleinere  
- **Höhe:** Konstant 1000 Fuß über Boden  
- **Bewegung:** Langsame Rotation um einen zentralen Punkt  
- **Größe:** Jede Insel 1-5 Meilen im Durchmesser  

## Zugangswege
- **Naturportal:** Aktiv bei Sonnenaufgang  
- **Magische Brücken:** Sichtbar bei Vollmond  
- **Flugwesen:** Reittiere der Windelementare  
- **Schwebende Treppen:** Aus festem Licht erschaffen  

## Bewohner
- **Windgeister:** Native Elementarwesen  
- **Himmelsadler:** Riesige Raubvögel  
- **Wolkenschafe:** Schwebende Säugetiere  
- **Magische Pflanzen:** Luftwurzeln und Himmelsreben  

## Gefahren
- **Stürme:** Jede Veränderung der Wetterlage  
- **Antimagiefelder:** Bereiche, die Magie stören  
- **Schwerkraftanomalien:** Variable Schwerkraft auf Inseln  
- **Temporalstörungen:** Zeitverschiebungen an den Rändern  

*Die fliegenden Inseln sind eine der größten magischen Anomalien der Welt*
        ''',
        entryType: WikiEntryType.Place,
        tags: ['magie', 'geheimnis', 'insel'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
    ],
  );

  /// Dungeon-Kampagnen Template
  CampaignTemplate _createDungeonTemplate() => CampaignTemplate(
    id: 'dungeon',
    name: 'Dungeon-Crawler',
    description: 'Klassische Dungeon-Exploration mit Fallen, Monstern und Schätzen',
    icon: '⚔️',
    mainEntry: WikiEntry(
      id: '',
      title: 'Die Pyramide des Verderbens',
      content: '''
# Die Pyramide des Verderbens

## Dungeon-Adventure
Ein antiker Dungeon voller Fallen, Monster und uralter Schätze in der Wüste der Verdammnis.

## Struktur
- **Oberfläche:** Eingang mit Wächtern  
- **Ebene 1-3:** Untere Ebenen mit Grundfallen  
- **Ebene 4-6:** Mittlere Ebenen mit magischen Gefahren  
- **Ebene 7-9:** Oberere Ebenen mit starken Monstern  
- **Ebene 10:** Thronsaal mit Endgegner  

## Fallen und Hindernisse
- **Mechanische Fallen:** Pitfalls, Speerspitzen, Wurfmaschinen  
- **Magische Fallen:** Fluchrunen, Teleporter, Illusionen  
- **Umweltgefahren:** Giftgas, Lava, überflutete Kammern  
- **Rätsel:** Türen, Schalter, Hebelmechanismen  

## Monster-Typen
- **Untere Ebenen:** Ratten, Kobolde, Skelette  
- **Mittlere Ebenen:** Goblins, Orks, Oger  
- **Obere Ebenen:** Trolle, Ettins, Mantioren  
- **Boss-Gegner:** Lich, Drache, Elementarfürst  

## Schätze
- **Währung:** Goldmünzen und Edelsteine  
- **Magische Gegenstände:** Zauberstäbe, Rüstungen, Artefakte  
- **Verbrauchsgüter:** Tränke, Schriftrollen, Heilmittel  
- **Einzelngegenstände:** Schmuck, Kunstwerke, antike Artefakte  

## Geschichte
Die Pyramide wurde vom [[König der Asche]] vor 1000 Jahren als Grabstätte erbaut, aber wurde später von [[Der Lich-Lord]] übernommen.

*Dungeon für eine 4-5 köpfige Gruppe (Stufe {{LEVEL_RANGE}})*
      ''',
      entryType: WikiEntryType.Place,
      tags: ['dungeon', 'ruinen', 'schatz'],
      campaignId: '',
      createdBy: 'Template System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: true,
      isFavorite: false,
    ),
    subEntries: [
      WikiEntry(
        id: '',
        title: 'Der Lich-Lord',
        content: '''
# Der Lich-Lord

## Endgegner
Ein mächtiger untoter Magier, der die Pyramide als seine Festung usurpiert hat.

## Fähigkeiten
- **Macht über Tod:** Unsterblich untoter  
- **Meisterzauberer:** Zauberspruchlevel 9  
- **Armeekommandant:** Kontrolliert untote Diener  
- **Fluchmagie:** Verflucht Gegner mit schwächenden Flüchen  

## Verteidigung
- **Untode Wachen:** Skelettkrieger und Zombies  
- **Magische Barrieren:** Schutzfelder und Glyphen  
- **Fallenkontrolle:** Kann Fallen aktivieren/deaktivieren  
- **Regeneration:** Heilt sich bei voller Dunkelheit  

## Schwächen
- **Heiliges Licht:** Verwundbar durch heilige Magie  
- **Feuerzauber:** Starke Schäden durch Feuer  
- **Zerstörte Phylakterien:** Heilige Relikte können ihn permanent schaden  

## Strategie
- **Phase 1:** Distanzangriffe mit Todessprüchen  
- **Phase 2:** Nahkampf mit Lebensdrainzaubern  
- **Phase 3:** Transformation und Massenzerstörung  
- **Notfall:** Teleportation und Wiederbelebung  

*Der Lich-Lord ist der ultimative Boss dieses Dungeons*
        ''',
        entryType: WikiEntryType.Person,
        tags: ['boss', 'lich', 'untot'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
    ],
  );

  /// Political-Kampagnen Template
  CampaignTemplate _createPoliticalTemplate() => CampaignTemplate(
    id: 'political',
    name: 'Politische Intrige',
    description: 'Kampagne mit Fokus auf Diplomatie, Spionage und Machtkämpfe',
    icon: '🏛️',
    mainEntry: WikiEntry(
      id: '',
      title: 'Der Rat der Königreiche',
      content: '''
# Der Rat der Königreiche

## Political-Intrigue-Kampagne
Ein Bündnis von Königreichen, in dem diplomatische Beziehungen, Spionage und politischer Verrat an der Tagesordnung sind.

## Mitglieds-Königreiche
- [[Königreich von Aethel]] - Führende Macht  
- [[Das Zwergenreich von Khazad-dûm]] - Wirtschaftliche Supermacht  
- [[Die Elfenkonförderation]] - Magische Autorität  
- [[Die Handelskonföderation]] - Reiche Städtebünde  
- [[Die freien Städte]] - Unabhängige Stadtstaaten  

## Regierungsrat
- **Hoher Rat:** Monarchen und Erzmagier  
- **Militärkabinett:** Generäle und Admiräle  
- **Handelsgericht:** Handelsherren und Gildenmeister  
- **Geheimdienst:** Spione und Informanten  

## Aktuelle Krisen
- **Grenzkonflikt:** Streit um territoriale Expansion  
- **Handelskrieg:** Wirtschaftliche Konkurrenz um Routen  
- **Magierstreit:** Regulation der arkanen Künste  
- **Thronfolge:** Nachfolge in mehreren Königreichen  

## Wichtige Verträge
- **Nichtangriffspakt:** Bündnis gegen äußere Feinde  
- **Handelsabkommen:** Zollfreiheit und bevorzugter Status  
- **Magieshibition:** Kontrolle gefährlicher Zaubersprüche  
- **Heilige Allianz:** Verteidigung gegen gemeinsame Bedrohung  

## Geheime Ziele
- **Heiratsallianzen:** Politische Ehen zwischen Königreichen  
- **Putsche und Verschwörungen:** Destabilisierung von Gegnern  
- **Erbfolgekriege:** Infiltration von Thronfolgelinien  
- **Assassinationen:** Beseitigung politischer Gegner  

*Politische Kampagne für Diplomatie und Intrige auf höchster Ebene*
      ''',
      entryType: WikiEntryType.Faction,
      tags: ['politik', 'diplomatie', 'intrige'],
      campaignId: '',
      createdBy: 'Template System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: true,
      isFavorite: false,
    ),
    subEntries: [
      WikiEntry(
        id: '',
        title: 'Die Elfenkonförderation',
        content: '''
# Die Elfenkonförderation

## Magische Autorität
Ein Bündnis elfischer Königreiche und Städte, das die meiste magische Macht kontrolliert.

## Mitgliedstaaten
- [[Silberwald]] - Hauptstadt der Waldelfen  
- [[Moondorf]] - Heimat der Hochelfen  
- [[Kristallfluss]] - Sitz der Elfenmagier  
- [[Die Alten Wälder]] - Uralte elfische Territorien  

## Regierung
- **Hohe Ratsherrin:** Erzmagierin Lyra Sternenlied  
- **Rat der Weisen:** 9 elbische Weise und Magier  
- **Waldwächter:** Militärischer Arm der Elfen  
- **Moonschatten:** Geheimdienst der Elfen  

## Magische Ressourcen
- **Moondorne:** Kraftquellen für Elfenmagie  
- **Lebensbäume:** Uralte Bäume mit Heilungskraft  
- **Sternenobservatorien:** Himmelsbeobachtung und Weissagung  
- **Elementarportale:** Tore zu den Elementarebenen  

## Beziehungen
- **Freundlich:** [[Die Elfenkonförderation]] (natürlich)  
- **Neutral:** [[Das Zwergenreich von Khazad-dûm]] (Handelspartner)  
- **Kompliziert:** [[Königreich von Aethel]] (Territorialstreit)  
- **Feindlich:** [[Der Ork-Horden]] (traditionelle Feinde)  

## Magische Gesetze
- **Verbotene Magie:** Nekromantie und Dämonenbeschwörung  
- **Regulierte Künste:** Zeitmanipulation und Gedankenkontrolle  
- **Heilige Magie:** Natuumagie und Elementarzauber  
- **Artefakte:** Alte elbische Relikte und Waffen  

*Die Elfenkonförderation ist die größte magische Macht der Region*
        ''',
        entryType: WikiEntryType.Faction,
        tags: ['elfen', 'magie', 'bündnis'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
    ],
  );

  /// Mystery-Kampagnen Template
  CampaignTemplate _createMysteryTemplate() => CampaignTemplate(
    id: 'mystery',
    name: 'Detektiv-Abenteuer',
    description: 'Kampagne mit Ermittlungen, Spionage und dem Aufklären von Geheimnissen',
    icon: '🔍',
    mainEntry: WikiEntry(
      id: '',
      title: 'Die verschwundenen Magier',
      content: '''
# Die verschwundenen Magier

## Mystery-Investigation
Eine Reihe von mysteriösen Verschwindungen in der Magierakademie, die investigative Fähigkeiten erfordert.

## Der Fall
- **Opfer:** 5 Magier der Akademie in 2 Monaten verschwunden  
- **Modus Operandi:** Alle Opfer wurden bei Vollmond entführt  
- **Spuren:** Magische Rückstände, seltsame Symbole, verbrannte Kreise  
- **Muster:** Jedes Opfer hatte Verbindung zu [[verbotenen Wissen]]  

## Ermittlungs-Methoden
- **Spurensuche:** Detektivarbeit und Überlebensfertigkeiten  
- **Magische Analyse:** Identifizierung von Zaubersprüchen und Artefakten  
- **Verhör:** Befragung von Zeugen und Verdächtigen  
- **Undercover:** Infiltration von verdächtigen Organisationen  

## Verdächtige
- [[Der Kurator]] - Verwirrter Bibliothekar mit Geheimnissen  
- [[Der Alchemist]] - Lieferant von seltsamen Substanzen  
- [[Die Schattenhand]] - Kriminelle Organisation mit Magie-Verbindungen  
- [[Der Kult des Wissens]] - Geheime Sekte mit fragwürdigen Zielen  

## Hinweise und Spuren
- **Magische Signaturen:** Jeder Täter hinterlässt unterschiedliche Magie  
- **Zeitplan:** Die Entführungen folgen einem astronomischen Kalender  
- **Verbindungsorte:** Alle Opfer besuchten [[verbotene Orte]]  
- **Kult-Symbole:** Dreieckige Marken an allen Tatorten  

## Mögliche Täter
- **Einzelner:** Psychopathischer Magier mit persönlicher Rache  
- **Organisation:** [[Der Kult des Wissens]] mit kollektivem Ziel  
- **Außerirdische Wesen:** Monster oder Dämonen in Menschengestalt  
- **Zeitreisende:** Jemand aus der Vergangenheit, der die Magier ändern will  

## Investigative Fähigkeiten
- **Arcana Investigation:** Analysiere magische Rückstände  
- **Insight:** Erkenne Lügen und verborgene Absichten  
- **Stealth:** Folge Verdächtigen unerkannt  
- **Persuasion:** Überzeuge Zeugen zum Reden  
- **Research:** Finde verstecktes Wissen in Bibliotheken  

*Mystery-Kampagne für Detektivarbeit und Magie-Untersuchung*
      ''',
      entryType: WikiEntryType.Lore,
      tags: ['mystery', 'ermittlung', 'magie'],
      campaignId: '',
      createdBy: 'Template System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: true,
      isFavorite: false,
    ),
    subEntries: [
      WikiEntry(
        id: '',
        title: 'Der Kult des Wissens',
        content: '''
# Der Kult des Wissens

## Geheime Sekte
Eine gefährliche Organisation, die nach verbotenen Wissen sucht und dafür alles opfert.

## Ideologie
- **Ultimatives Wissen:** Sucht nach der Quelle allen Wissens  
- **Moralischer Relativismus:** Enden heiligen Mittel für gute Zwecke  
- **Exklusivität:** Nur die Auserwählten sind würdig des Wissens  
- **Opferbereitschaft:** Individuen und Gruppen sind opferbar  

## Hierarchie
- **Der Meister des Wissens:** Unbekannter Anführer  
- **Die Aufseher:** 3 hochrangige Priester des Wissens  
- **Wissenswächter:** 12 Krieger mit magischen Waffen  
- **Adepten:** Unbekannte Anzahl von niederen Mitgliedern  

## Methoden
- **Infiltration:** Spione in Organisationen und Bibliotheken  
- **Diebstahl:** Raub von alten Artefakten und Büchern  
- **Entführung:** Verschwinden von Magiern und Gelehrten  
- **Rituale:** Dunkle Zeremonien für Wissenstransfer  

## Versteckte Ziele
- **Die Große Bibliothek:** Ältestes Wissen der Welt  
- **Der Astralturm:** Observationspunkt für göttliche Zeichen  
- **Die Schattenkatakomben:** Magische Waffen für die Wächter  
- **Die Verlorenen Archive:** Uraltes Wissen in vergessenen Ruinen  

## Erkennungsmerkmale
- **Tätowierung:** Dreieckiges Symbol mit Auge in der Mitte  
- **Kleidung:** Rote Roben mit goldenen Stickereien  
- **Jewel:** Karioliertes Auge als Anhänger  
- **Passwort:** "Wissen ist Macht" als Erkennungsphrase  

*Der Kult des Wissens ist eine extremistische Organisation mit gefährlichen Zielen*
        ''',
        entryType: WikiEntryType.Faction,
        tags: ['kult', 'geheim', 'gefährlich'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
    ],
  );

  /// War-Kampagnen Template
  CampaignTemplate _createWarTemplate() => CampaignTemplate(
    id: 'war',
    name: 'Epidische Kriegsführung',
    description: 'Großangelegte militärische Konflikte zwischen Königreichen und Armeen',
    icon: '⚔️',
    mainEntry: WikiEntry(
      id: '',
      title: 'Der große Krieg',
      content: '''
# Der große Krieg

## Military-Campaign-Kampagne
Ein kontinentaler Konflikt zwischen großen Königreichen mit Armeen, Schlachten und strategischer Kriegsführung.

## Konfliktparteien
- **Die Allianz des Lichts:** [[Königreich von Aethel]], [[Die Elfenkonförderation]]  
- **Die Schattenkoalition:** [[Die Ork-Horden]], [[Der Zirkelbund]]  
- **Neutrale Parteien:** [[Die freien Städte]], [[Das Zwergenreich von Khazad-dûm]]  
- **Wilde Fraktionen:** [[Die Horden der Wildnis]], nomadische Stämme  

## Kriegsschauplätze
- **Die nördliche Front:** Konflikt um die Eisengipfel  
- **Die zentrale Ebene:** Kampf um die goldenen Weizenfelder  
- **Die südliche Grenze:** Invasion in die Elfenwälder  
- **Die westliche Küste:** Seekrieg und Invasion von der See  

## Militärische Einheiten
### Infanterie
- **Aethel-Söldner:** Gut ausgerüstete Berufs-Söldner  
- **Elfen-Bogenschützen:** Präzise Fernkämpfer mit magischen Pfeilen  
- **Zwergen-Axtkämpfer:** Schwere Infanterie mit schweren Rüstungen  
- **Ork-Berserker:** Wilde, unkontrollierbare Nahkämpfer  

### Kavallerie
- **Menschliche Ritter:** Gepanzerte schwere Reiter  
- **Elfen-Jäger:** Leichte Kundschafter mit Bogenschützen-Reittieren  
- **Ork-Wolfsreiter:** Schnelle Reiter auf großen Wölfen  

### Spezialeinheiten
- **Magier-Gilden:** Kampfmagier aus verschiedenen Schulen  
- **Belagerungs-Maschinen:** Katapulte und Belagerungstürme  
- **Aeriale Kreaturen:** Elementare und beschwore Monster  

## Strategische Ziele
- **Hauptstädte:** Eroberung der Feind-Hauptstädte  
- **Burgen und Festungen:** Kontrolle strategischer Punkte  
- **Handelsrouten:** Unterbrechung feindlicher Versorgungen  
- **Magische Quellen:** Kontrolle von Moondornen und Kraftquellen  

## Kriegsverlauf
- **Phase 1:** Grenzskirmische und Manöver  
- **Phase 2:** Große Feldschlachten  
- **Phase 3:** Belagerungen und Belagerungen  
- **Phase 4:** Invasion und Eroberung  
- **Phase 5:** Nachkriegsordnung  

## Heldenhelfer
Die Spieler sind eine [[Söldnereinheit]] oder [[Auftragsjäger]], die in diesem Konflikt eine entscheidende Rolle spielen.

*Militär-Kampagne für strategische Kriegsführung und epische Schlachten*
      ''',
      entryType: WikiEntryType.Lore,
      tags: ['krieg', 'militär', 'strategie'],
      campaignId: '',
      createdBy: 'Template System',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: true,
      isFavorite: false,
    ),
    subEntries: [
      WikiEntry(
        id: '',
        title: 'Schlacht am Blutigen Fluss',
        content: '''
# Schlacht am Blutigen Fluss

## Entschiedene Schlacht
Die größte Feldschlacht des Krieges, die den Verlauf des Konflikts bestimmte.

## Vorbereitung
- **Ort:** Die weiten Ebenen östlich des Blumigen Flusses  
- **Zeit:** Früher Morgen bei Nebel und Bodenfrost  
- **Allianz-Truppen:** 15,000 Mann starke Infanterie  
- **Schattenkoalition-Truppen:** 20,000 Mann gemischte Kräfte  

## Schlachtordnung
### Allianz-Flügel
- **Linker Flügel:** Elfen-Bogenschützen unter Lord Valerius  
- **Rechter Flügel:** Aethel-Söldner unter General Kaelan  
- **Reserve:** Schwerreitere Kavallerie unter Sir Marcus  

### Schattenkoalition-Formation
- **Zentrum:** Ork-Berserker unter Warlord Groknar  
- **Linke Flanke:** Goblin-Schleudern unter Schaman Zul'gar  
- **Rechte Flanke:** Magier-Belagerungseinheiten  

## Schlachtverlauf
1. **Erste Phase (Morgengrauen):** Artillerieduell und Infanteriegefecht  
2. **Zweite Phase (Mittag):** Kavallerie-Charge und Flankenmanöver  
3. **Dritte Phase (Nachmittag):** Magische Zerstörung und Entscheidungsschlacht  

## Ergebnisse
- **Allianz-Verluste:** 4,000 Tote, 2,000 Verwundete  
- **Schattenkoalition-Verluste:** 8,000 Tote, 3,000 Verwundete  
- **Entscheidung:** Taktischer Rückzug der Schattenkoalition  
- **Strategische Bedeutung:** Sichert die östlichen Provinzen  

## Berühmte Helden
- [[Sir Marcus der Löwenherz]] - Hielt die rechte Flanke allein  
- [[Lady Elara Sternenschützerin]] - Verhinderte Durchbruch der Magier  
- [[Großschaman Zul'gar]] - Opferte sich für den Rückzug  

## Nachwirkungen
- **Moral:** Enormer Schub für die Allianz-Moral  
- **Territorium:** Allianz sichert die östlichen Ebenen  
- **Politisch:** Schwächung der Schattenkoalition-Verhandlungsposition  

*Die Schlacht am Blutigen Fluss wird als Wendepunkt des Krieges betrachtet*
        ''',
        entryType: WikiEntryType.History,
        tags: ['schlacht', 'geschichte', 'entscheidung'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
    ],
  );
}

/// Kampagnen-Template mit vordefinierten Wiki-Strukturen
class CampaignTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final WikiEntry mainEntry;
  final List<WikiEntry> subEntries;

  const CampaignTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.mainEntry,
    required this.subEntries,
  });

  /// Erstellt eine Kopie des Templates für eine spezifische Kampagne
  CampaignTemplate copyForCampaign(String campaignId) => CampaignTemplate(
    id: id,
    name: name,
    description: description,
    icon: icon,
    mainEntry: mainEntry.copyWith(campaignId: campaignId),
    subEntries: subEntries.map((e) => e.copyWith(campaignId: campaignId)).toList(),
  );

  @override
  String toString() => '$icon $name';
}
