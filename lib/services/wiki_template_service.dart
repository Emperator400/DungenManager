// lib/services/wiki_template_service.dart
import 'dart:async';
import '../models/wiki_entry.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import 'exceptions/service_exceptions.dart';

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
    mainEntry: mainEntry,
    subEntries: subEntries,
  );

  @override
  String toString() => '$icon $name';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'mainEntry': mainEntry.toMap(),
      'subEntries': subEntries.map((e) => e.toMap()).toList(),
    };
  }

  factory CampaignTemplate.fromMap(Map<String, dynamic> map) {
    return CampaignTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String? ?? '📋',
      mainEntry: WikiEntry.fromMap(map['mainEntry'] as Map<String, dynamic>),
      subEntries: (map['subEntries'] as List<dynamic>)
          .map((e) => WikiEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Service für Campaign Templates und vordefinierte Wiki-Strukturen mit Repository-Architektur
/// 
/// Erstellt Wiki-Einträge basierend auf vordefinierten Templates.
/// Verwendet Repository-Architektur und spezifische Exceptions.
class WikiTemplateService {
  final WikiEntryModelRepository _wikiRepository;

  WikiTemplateService({
    WikiEntryModelRepository? wikiRepository,
  })  : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance);

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
  Future<ServiceResult<List<WikiEntry>>> createEntriesFromTemplate(
    CampaignTemplate template, 
    String campaignId
  ) async {
    return performServiceOperation('createEntriesFromTemplate', () async {
      if (campaignId.isEmpty) {
        throw ValidationException(
          'Campaign ID ist erforderlich',
          operation: 'createEntriesFromTemplate',
        );
      }

      final entries = <WikiEntry>[];
      
      // Erstelle Haupt-Eintrag für die Kampagne
      final mainEntry = WikiEntry(
        id: '', // Wird von Repository generiert
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
      
      final createdMainEntry = await _wikiRepository.create(mainEntry);
      entries.add(createdMainEntry);
      
      // Erstelle untergeordnete Einträge
      final subEntryIds = <String>[];
      for (final subEntry in template.subEntries) {
        final wikiEntry = WikiEntry(
          id: '', // Wird von Repository generiert
          title: subEntry.title,
          content: _populateTemplate(subEntry.content, campaignId),
          entryType: subEntry.entryType,
          tags: subEntry.tags ?? [],
          campaignId: campaignId,
          parentId: createdMainEntry.id,
          createdBy: 'Template System',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          childIds: [],
          isMarkdown: true,
          isFavorite: false,
        );
        
        final createdSubEntry = await _wikiRepository.create(wikiEntry);
        entries.add(createdSubEntry);
        subEntryIds.add(createdSubEntry.id);
      }
      
      return entries;
    });
  }

  /// Validiert ein Template vor der Erstellung
  Future<ServiceResult<bool>> validateTemplate(CampaignTemplate template) async {
    return performServiceOperation('validateTemplate', () async {
      // Prüfe Haupt-Eintrag
      if (template.mainEntry.title.isEmpty) {
        throw ValidationException(
          'Haupt-Eintrag braucht einen Titel',
          operation: 'validateTemplate',
        );
      }

      if (template.mainEntry.content.isEmpty) {
        throw ValidationException(
          'Haupt-Eintrag braucht Inhalt',
          operation: 'validateTemplate',
        );
      }

      // Prüfe Untereinträge
      for (int i = 0; i < template.subEntries.length; i++) {
        final subEntry = template.subEntries[i];
        
        if (subEntry.title.isEmpty) {
          throw ValidationException(
            'Untereintrag ${i + 1} braucht einen Titel',
            operation: 'validateTemplate',
          );
        }

        if (subEntry.content.isEmpty) {
          throw ValidationException(
            'Untereintrag ${i + 1} braucht Inhalt',
            operation: 'validateTemplate',
          );
        }
      }

      // Prüfe auf Duplizierte Titel
      final allTitles = [template.mainEntry.title, ...template.subEntries.map((e) => e.title)];
      final uniqueTitles = allTitles.toSet();
      
      if (allTitles.length != uniqueTitles.length) {
        throw ValidationException(
          'Template enthält duplizierte Titel',
          operation: 'validateTemplate',
        );
      }

      return true;
    });
  }

  /// Erstellt eine Vorschau der Template-Einträge ohne sie zu speichern
  List<WikiEntry> previewTemplateEntries(CampaignTemplate template, String campaignId) {
    final entries = <WikiEntry>[];
    
    // Haupt-Eintrag
    final populatedMainContent = _populateTemplate(template.mainEntry.content, campaignId);
    final mainEntry = WikiEntry(
      id: 'preview-main',
      title: template.mainEntry.title,
      content: populatedMainContent,
      entryType: template.mainEntry.entryType,
      tags: template.mainEntry.tags,
      campaignId: campaignId,
      createdBy: template.mainEntry.createdBy,
      createdAt: template.mainEntry.createdAt,
      updatedAt: DateTime.now(),
      childIds: [],
      isMarkdown: template.mainEntry.isMarkdown,
      isFavorite: template.mainEntry.isFavorite,
    );
    entries.add(mainEntry);
    
    // Untereinträge
    for (int i = 0; i < template.subEntries.length; i++) {
      final subTemplate = template.subEntries[i];
      final populatedContent = _populateTemplate(subTemplate.content, campaignId);
      final subEntry = WikiEntry(
        id: 'preview-sub-$i',
        title: subTemplate.title,
        content: populatedContent,
        entryType: subTemplate.entryType,
        tags: subTemplate.tags,
        campaignId: campaignId,
        parentId: 'preview-main',
        createdBy: subTemplate.createdBy,
        createdAt: subTemplate.createdAt,
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: subTemplate.isMarkdown,
        isFavorite: subTemplate.isFavorite,
      );
      entries.add(subEntry);
    }
    
    return entries;
  }

  /// Ersetzt Platzhalter im Template-Content
  String _populateTemplate(String content, String campaignId) => content
      .replaceAll('{{CAMPAIGN_ID}}', campaignId)
      .replaceAll('{{CAMPAIGN_NAME}}', 'Kampagne')
      .replaceAll('{{DATE}}', DateTime.now().toString().substring(0, 10))
      .replaceAll('{{DM_NAME}}', 'Dungeon Master')
      .replaceAll('{{PARTY_SIZE}}', '4-5')
      .replaceAll('{{LEVEL_RANGE}}', '1-5');

  /// Holt Template nach ID
  CampaignTemplate? getTemplateById(String templateId) {
    try {
      return getAvailableTemplates().firstWhere(
        (template) => template.id == templateId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Sucht Templates nach Namen oder Beschreibung
  List<CampaignTemplate> searchTemplates(String query) {
    if (query.isEmpty) return getAvailableTemplates();
    
    final lowerQuery = query.toLowerCase();
    return getAvailableTemplates().where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
             template.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Erstellt ein benutzerdefiniertes Template aus vorhandenen Einträgen
  Future<ServiceResult<CampaignTemplate>> createCustomTemplate(
    String name,
    String description,
    List<WikiEntry> entries,
    String campaignId,
  ) async {
    return performServiceOperation('createCustomTemplate', () async {
      if (name.isEmpty) {
        throw ValidationException(
          'Template-Name ist erforderlich',
          operation: 'createCustomTemplate',
        );
      }

      if (entries.isEmpty) {
        throw ValidationException(
          'Mindestens ein Eintrag ist erforderlich',
          operation: 'createCustomTemplate',
        );
      }

      // Finde den Haupt-Eintrag (erster ohne Parent)
      final mainEntry = entries.firstWhere(
        (entry) => entry.parentId == null || entry.parentId!.isEmpty,
        orElse: () => entries.first,
      );

      // Finde Untereinträge (leere Liste, da ParentID noch nicht existiert)
      final subEntries = <WikiEntry>[];

      final templateObj = CampaignTemplate(
        id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        icon: '📋',
        mainEntry: mainEntry,
        subEntries: subEntries,
      );

      return templateObj;
    });
  }

  /// Exportiert ein Template als JSON
  Future<ServiceResult<Map<String, dynamic>>> exportTemplate(CampaignTemplate template) async {
    return performServiceOperation('exportTemplate', () async {
      return {
        'id': template.id,
        'name': template.name,
        'description': template.description,
        'icon': template.icon,
        'mainEntry': template.mainEntry.toMap(),
        'subEntries': template.subEntries.map((e) => e.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    });
  }

  /// Importiert ein Template aus JSON
  Future<ServiceResult<CampaignTemplate>> importTemplate(Map<String, dynamic> templateData) async {
    return performServiceOperation('importTemplate', () async {
      try {
        // Validiere JSON-Struktur
        if (!templateData.containsKey('id') ||
            !templateData.containsKey('name') ||
            !templateData.containsKey('mainEntry')) {
          throw ValidationException(
            'Ungültiges Template-Format',
            operation: 'importTemplate',
          );
        }

        final mainEntry = WikiEntry.fromMap(templateData['mainEntry'] as Map<String, dynamic>);
        final subEntriesData = templateData['subEntries'] as List<dynamic>? ?? [];
        final subEntries = subEntriesData
            .map((data) => WikiEntry.fromMap(data as Map<String, dynamic>))
            .toList();

        return CampaignTemplate(
          id: templateData['id'] as String,
          name: templateData['name'] as String,
          description: templateData['description'] as String? ?? 'Importiertes Template',
          icon: templateData['icon'] as String? ?? '📋',
          mainEntry: mainEntry,
          subEntries: subEntries,
        );
      } catch (e) {
        throw ValidationException(
          'Fehler beim Importieren des Templates: $e',
          operation: 'importTemplate',
        );
      }
    });
  }

  /// Prüft ob ein Template mit bestimmten Einträgen kompatibel ist
  Future<ServiceResult<bool>> checkTemplateCompatibility(
    CampaignTemplate template,
    List<WikiEntry> existingEntries,
  ) async {
    return performServiceOperation('checkTemplateCompatibility', () async {
      // Prüfe auf Titel-Konflikte
      final existingTitles = existingEntries.map((e) => e.title.toLowerCase()).toSet();
      final templateTitles = [
        template.mainEntry.title,
        ...template.subEntries.map((e) => e.title)
      ].map((t) => t.toLowerCase()).toSet();

      final conflicts = existingTitles.intersection(templateTitles);
      
      if (conflicts.isNotEmpty) {
        throw ValidationException(
          'Template hat Titel-Konflikte: ${conflicts.join(', ')}',
          operation: 'checkTemplateCompatibility',
        );
      }

      return true;
    });
  }

  // ========== TEMPLATE-DEFINITIONEN ==========

  /// Fantasy-Kampagnen Template
  CampaignTemplate _createFantasyTemplate() {
    return CampaignTemplate(
      id: 'fantasy',
      name: 'Klassische Fantasy',
      description: 'Traditionelle D&D Fantasy-Kampagne mit Magie, Monstern und Abenteuern',
      icon: '🏰',
      mainEntry: WikiEntry(
        id: '',
        title: 'Willkommen in {{CAMPAIGN_NAME}}',
        content: '''# Willkommen in {{CAMPAIGN_NAME}}

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

*Diese Kampagne wurde am {{DATE}} erstellt. DM: {{DM_NAME}}*''',
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
  }

  /// Urban-Kampagnen Template
  CampaignTemplate _createUrbanTemplate() {
    return CampaignTemplate(
      id: 'urban',
      name: 'Urban Fantasy',
      description: 'Fantasy-Kampagne in einer modernen Stadt',
      icon: '🏙️',
      mainEntry: WikiEntry(
        id: '',
        title: 'Willkommen in der Stadt',
        content: '# Willkommen in der Stadt\n\nUrban Fantasy Kampagne.',
        entryType: WikiEntryType.Place,
        tags: ['urban', 'stadt', 'fantasy'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
      subEntries: [],
    );
  }
  
  /// Wilderness-Kampagnen Template
  CampaignTemplate _createWildernessTemplate() {
    return CampaignTemplate(
      id: 'wilderness',
      name: 'Wilderness Abenteuer',
      description: 'Abenteuer in der unberührten Wildnis',
      icon: '🌲',
      mainEntry: WikiEntry(
        id: '',
        title: 'Willkommen in der Wildnis',
        content: '# Willkommen in der Wildnis\n\nWilderness Abenteuer Kampagne.',
        entryType: WikiEntryType.Place,
        tags: ['wilderness', 'wildnis', 'natur'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
      subEntries: [],
    );
  }
  
  /// Dungeon-Kampagnen Template
  CampaignTemplate _createDungeonTemplate() {
    return CampaignTemplate(
      id: 'dungeon',
      name: 'Dungeon Crawl',
      description: 'Klassische Dungeon-Abenteuer',
      icon: '🏚️',
      mainEntry: WikiEntry(
        id: '',
        title: 'Willkommen im Dungeon',
        content: '# Willkommen im Dungeon\n\nDungeon Crawl Kampagne.',
        entryType: WikiEntryType.Place,
        tags: ['dungeon', 'abenteuer', 'katakomben'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
      subEntries: [],
    );
  }
  
  /// Political-Kampagnen Template
  CampaignTemplate _createPoliticalTemplate() {
    return CampaignTemplate(
      id: 'political',
      name: 'Politische Intrigen',
      description: 'Kampagne voller politischer Intrigen',
      icon: '⚖️',
      mainEntry: WikiEntry(
        id: '',
        title: 'Willkommen in der Hauptstadt',
        content: '# Willkommen in der Hauptstadt\n\nPolitische Intrigen Kampagne.',
        entryType: WikiEntryType.Faction,
        tags: ['political', 'politik', 'intrigen'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
      subEntries: [],
    );
  }
  
  /// Mystery-Kampagnen Template
  CampaignTemplate _createMysteryTemplate() {
    return CampaignTemplate(
      id: 'mystery',
      name: 'Detektiv Mystery',
      description: 'Mystery-Kampagne mit Rätseln und Geheimnissen',
      icon: '🔍',
      mainEntry: WikiEntry(
        id: '',
        title: 'Ein mysteriöser Fall',
        content: '# Ein mysteriöser Fall\n\nMystery Detektiv Kampagne.',
        entryType: WikiEntryType.Place,
        tags: ['mystery', 'rätsel', 'detektiv'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
      subEntries: [],
    );
  }
  
  /// War-Kampagnen Template
  CampaignTemplate _createWarTemplate() {
    return CampaignTemplate(
      id: 'war',
      name: 'Kriegsfront',
      description: 'Epic Kriegs-Kampagne',
      icon: '⚔️',
      mainEntry: WikiEntry(
        id: '',
        title: 'An der Front',
        content: '# An der Front\n\nEpic Kriegs-Kampagne.',
        entryType: WikiEntryType.Faction,
        tags: ['war', 'krieg', 'militär'],
        campaignId: '',
        createdBy: 'Template System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childIds: [],
        isMarkdown: true,
        isFavorite: false,
      ),
      subEntries: [],
    );
  }
}
