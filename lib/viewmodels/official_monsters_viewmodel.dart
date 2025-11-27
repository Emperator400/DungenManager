import 'package:flutter/foundation.dart';
import '../models/official_monster.dart';
import '../services/exceptions/service_exceptions.dart';

/// ViewModel für offizielle Monster mit Provider-Pattern
class OfficialMonstersViewModel extends ChangeNotifier {
  // State Management
  List<OfficialMonster> _monsters = [];
  List<OfficialMonster> _filteredMonsters = [];
  bool _isLoading = false;
  bool _isImporting = false;
  String? _errorMessage;
  
  // Filter-Status
  String _searchQuery = '';
  String? _selectedType;
  double? _minCr;
  double? _maxCr;
  List<String> _availableTypes = [];

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreData = true;

  // Getter
  List<OfficialMonster> get monsters => List.unmodifiable(_monsters);
  List<OfficialMonster> get filteredMonsters => List.unmodifiable(_filteredMonsters);
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String? get errorMessage => _errorMessage;
  bool get hasMonsters => _monsters.isNotEmpty;
  bool get hasFilteredMonsters => _filteredMonsters.isNotEmpty;
  bool get hasMoreData => _hasMoreData;
  List<String> get availableTypes => List.unmodifiable(_availableTypes);
  
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  double? get minCr => _minCr;
  double? get maxCr => _maxCr;

  /// Initialisiert das ViewModel
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();
      await _loadMonsterTypes();
      await _loadMonsters(reset: true);
    } catch (e) {
      _setError('Initialisierung fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Lädt Monster-Typen für Filter
  Future<void> _loadMonsterTypes() async {
    try {
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
      
      // Simulierte Typen
      _availableTypes = [
        'Humanoid',
        'Beast',
        'Undead',
        'Dragon',
        'Monstrosity',
        'Fiend',
        'Celestial',
        'Elemental',
        'Fey',
        'Aberration',
        'Construct',
        'Ooze',
        'Plant',
      ];
      notifyListeners();
    } catch (e) {
      _setError('Laden der Typen fehlgeschlagen: ${e.toString()}');
    }
  }

  /// Lädt Monster von der Datenbank
  Future<void> _loadMonsters({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _hasMoreData = true;
      _monsters.clear();
      _filteredMonsters.clear();
    }

    if (!_hasMoreData || _isLoading) return;

    try {
      _setLoading(true);
      
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
      
      // Simulierte Monster-Daten
      final newMonsters = _generateMockMonsters(_currentPage, _itemsPerPage);
      
      _monsters.addAll(newMonsters);
      _applyFilters();
      
      _hasMoreData = newMonsters.length >= _itemsPerPage;
      _currentPage++;
      
      notifyListeners();
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Laden fehlgeschlagen: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Generiert Mock-Monster-Daten
  List<OfficialMonster> _generateMockMonsters(int page, int limit) {
    final startIndex = page * limit;
    final mockData = [
      OfficialMonster(
        id: '1',
        name: 'Goblin',
        size: 'Small',
        type: 'Humanoid',
        subtype: 'goblinoid',
        alignment: 'Neutral Evil',
        armorClass: '15',
        hitPoints: 7,
        hitDice: '2d6',
        speed: '30 ft.',
        challengeRating: 0.25,
        xp: 50,
        strength: 8,
        dexterity: 14,
        constitution: 10,
        intelligence: 10,
        wisdom: 8,
        charisma: 6,
        savingThrows: [],
        skills: {'Stealth': 6},
        damageImmunities: [],
        damageResistances: [],
        damageVulnerabilities: [],
        conditionImmunities: [],
        senses: {'Darkvision': '60'},
        languages: 'Common, Goblin',
        specialAbilities: [],
        actions: [
          MonsterAction(
            name: 'Scimitar',
            description: 'Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 5 (1d6 + 2) slashing damage.',
          ),
          MonsterAction(
            name: 'Shortbow',
            description: 'Ranged Weapon Attack: +4 to hit, range 80/320 ft., one target. Hit: 5 (1d6 + 2) piercing damage.',
          ),
        ],
        legendaryActions: [],
        source: 'Basic Rules',
      ),
      OfficialMonster(
        id: '2',
        name: 'Orc',
        size: 'Medium',
        type: 'Humanoid',
        subtype: 'orc',
        alignment: 'Chaotic Evil',
        armorClass: '13',
        hitPoints: 15,
        hitDice: '2d8 + 6',
        speed: '30 ft.',
        challengeRating: 0.5,
        xp: 100,
        strength: 16,
        dexterity: 12,
        constitution: 16,
        intelligence: 7,
        wisdom: 11,
        charisma: 10,
        savingThrows: [],
        skills: {'Intimidation': 2},
        damageImmunities: [],
        damageResistances: [],
        damageVulnerabilities: [],
        conditionImmunities: [],
        senses: {'Darkvision': '60'},
        languages: 'Common, Orc',
        specialAbilities: [
          MonsterAbility(
            name: 'Aggressive',
            description: 'As a bonus action, this orc can move up to its speed toward a hostile creature that it can see.',
          ),
        ],
        actions: [
          MonsterAction(
            name: 'Greataxe',
            description: 'Melee Weapon Attack: +5 to hit, reach 5 ft., one target. Hit: 12 (1d12 + 6) slashing damage.',
          ),
          MonsterAction(
            name: 'Javelin',
            description: 'Melee or Ranged Weapon Attack: +5 to hit, reach 5 ft. or range 30/120 ft., one target. Hit: 7 (1d6 + 4) piercing damage.',
          ),
        ],
        legendaryActions: [],
        source: 'Basic Rules',
      ),
    ];

    final endIndex = (startIndex + limit).clamp(0, mockData.length);
    return startIndex < mockData.length ? mockData.sublist(startIndex, endIndex) : [];
  }

  /// Lädt weitere Monster (Pagination)
  Future<void> loadMoreMonsters() async {
    await _loadMonsters();
  }

  /// Importiert Monster von externer Quelle
  Future<bool> importMonsters() async {
    if (_isImporting) return false;

    try {
      _setImporting(true);
      _clearError();
      
      // Simuliere Import-Operation
      await _simulateDatabaseOperation();
      
      // Daten neu laden
      await _loadMonsters(reset: true);
      
      return true;
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Import fehlgeschlagen: ${e.toString()}');
      }
      return false;
    } finally {
      _setImporting(false);
    }
  }

  /// Setzt Suchquery
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Setzt Monster-Typ Filter
  void setSelectedType(String? type) {
    if (_selectedType != type) {
      _selectedType = type;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Setzt CR-Filter (Challenge Rating)
  void setCrRange(double? min, double? max) {
    if (_minCr != min || _maxCr != max) {
      _minCr = min;
      _maxCr = max;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Setzt alle Filter zurück
  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _minCr = null;
    _maxCr = null;
    _applyFilters();
    notifyListeners();
  }

  /// Wendet alle Filter an
  void _applyFilters() {
    _filteredMonsters = _monsters.where((monster) {
      // Suchfilter
      final matchesSearch = _searchQuery.isEmpty || 
          monster.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Typ-Filter
      final matchesType = _selectedType == null || 
          monster.type == _selectedType ||
          monster.subtype?.toLowerCase().contains(_selectedType!.toLowerCase()) == true;
      
      // CR-Filter
      final matchesCr = (_minCr == null || monster.challengeRating >= _minCr!) &&
                     (_maxCr == null || monster.challengeRating <= _maxCr!);
      
      return matchesSearch && matchesType && matchesCr;
    }).toList();
  }

  /// Sucht nach Monster
  List<OfficialMonster> searchMonsters(String query) {
    if (query.isEmpty) return monsters;
    
    return monsters.where((monster) {
      return monster.name.toLowerCase().contains(query.toLowerCase()) ||
             monster.type.toLowerCase().contains(query.toLowerCase()) ||
             (monster.subtype?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  /// Sortiert Monster
  void sortMonsters(MonsterSortCriteria criteria) {
    switch (criteria) {
      case MonsterSortCriteria.nameAsc:
        _filteredMonsters.sort((a, b) => a.name.compareTo(b.name));
        break;
      case MonsterSortCriteria.nameDesc:
        _filteredMonsters.sort((a, b) => b.name.compareTo(a.name));
        break;
      case MonsterSortCriteria.crAsc:
        _filteredMonsters.sort((a, b) => a.challengeRating.compareTo(b.challengeRating));
        break;
      case MonsterSortCriteria.crDesc:
        _filteredMonsters.sort((a, b) => b.challengeRating.compareTo(a.challengeRating));
        break;
      case MonsterSortCriteria.hpAsc:
        _filteredMonsters.sort((a, b) => a.hitPoints.compareTo(b.hitPoints));
        break;
      case MonsterSortCriteria.hpDesc:
        _filteredMonsters.sort((a, b) => b.hitPoints.compareTo(a.hitPoints));
        break;
    }
    notifyListeners();
  }

  /// Aktualisiert die Monster-Liste
  Future<void> refreshMonsters() async {
    await _loadMonsters(reset: true);
  }

  /// Löscht die Fehlermeldung
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private Helper-Methoden
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setImporting(bool importing) {
    if (_isImporting != importing) {
      _isImporting = importing;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Simuliert eine Datenbankoperation
  Future<void> _simulateDatabaseOperation() async {
    // Simuliere Netzwerkverzögerung
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Sortierkriterien für Monster
enum MonsterSortCriteria {
  nameAsc,
  nameDesc,
  crAsc,
  crDesc,
  hpAsc,
  hpDesc,
}
