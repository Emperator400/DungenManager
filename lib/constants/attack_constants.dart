class AttackConstants {
  AttackConstants._(); // Private constructor to prevent instantiation

  // Liste der gängigen Schadensarten
  static const List<String> commonDamageTypes = [
    'Stichschaden',
    'Hiebschaden', 
    'Wuchtschaden',
    'Feuerschaden',
    'Kälteschaden',
    'Elektrizitätsschaden',
    'Säureschaden',
    'Giftschaden',
    'Psychischer Schaden',
    'Strahlungsschaden',
    'Nekrotischer Schaden',
    'Lichtschaden',
    'Kraftschaden',
    'Donnerschaden',
  ];

  // Liste der gängigen Würfel
  static const List<String> commonDice = [
    '1W2',
    '1W4', 
    '1W6',
    '1W8',
    '1W10',
    '1W12',
    '2W4',
    '2W6',
    '2W8',
    '2W10',
    '2W12',
    '3W6',
    '3W8',
    '4W6',
    '4W8',
    '6W6',
    '8W6',
  ];

  // Liste der Fähigkeiten
  static const List<String> abilities = [
    'STR',
    'DEX', 
    'CON',
    'INT',
    'WIS',
    'CHA',
  ];

  // Liste der Reichweiten
  static const List<String> commonRanges = [
    'Nahkampf',
    'Fernkampf (30/120)',
    'Fernkampf (60/240)',
    'Fernkampf (80/320)',
    'Fernkampf (100/400)',
    'Berührung',
    'Selbst',
  ];
}
