# Feedback Components

Wiederverwendbare Widgets für konsistentes Feedback an den Benutzer in der App.

## Übersicht

Diese Komponenten bieten standardisierte UI-Elemente für Feedback:
- **ConfirmationDialog** - Bestätigungsdialoge für kritische Aktionen
- **SnackBarHelper** - SnackBar-Nachrichten für schnelles Feedback

## ConfirmationDialog

Bietet eine konsistente Benutzeroberfläche für Bestätigungsdialoge mit optionalen Icons und verschiedenen Stilen.

### Nutzung

```dart
// Einfacher Bestätigungsdialog
final confirmed = await ConfirmationDialog.show(
  context: context,
  title: 'Aktion bestätigen',
  message: 'Möchtest du wirklich fortfahren?',
  confirmText: 'Ja',
  cancelText: 'Nein',
);

if (confirmed == true) {
  // Aktion ausführen
}

// Lösch-Dialog
final confirmed = await ConfirmationDialog.showDelete(
  context: context,
  title: 'Kampagne löschen?',
  message: 'Diese Aktion kann nicht rückgängig gemacht werden.',
  confirmText: 'Löschen',
);

if (confirmed == true) {
  await viewModel.deleteCampaign();
}
```

### Verfügbare Methoden

#### `show()`
Zeigt einen einfachen Bestätigungsdialog.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `title` (erforderlich) - Titel des Dialogs
- `message` (optional) - Nachricht
- `confirmText` - Text für Bestätigungs-Button (Standard: "Bestätigen")
- `cancelText` - Text für Abbrechen-Button (Standard: null)
- `isDangerous` - Ob die Aktion gefährlich ist (Standard: false)
- `icon` - Icon für den Titel
- `iconColor` - Farbe des Icons

#### `showDelete()`
Bestätigungsdialog für Lösch-Operationen mit rotem Icon.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `title` (erforderlich) - Titel
- `message` (optional) - Nachricht
- `confirmText` - Text für Lösch-Button (Standard: "Löschen")

#### `showSave()`
Bestätigungsdialog für Speicher-Operationen.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `title` - Titel (Standard: "Änderungen speichern?")
- `message` - Nachricht (Standard: "Möchtest du die Änderungen speichern?")
- `confirmText` - Text für Speichern-Button (Standard: "Speichern")

#### `showWarning()`
Bestätigungsdialog für Warnungen mit orangenem Icon.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `title` (erforderlich) - Titel
- `message` (optional) - Nachricht
- `confirmText` - Text für Fortfahren-Button (Standard: "Fortfahren")

#### `showInfo()`
Bestätigungsdialog für Informationen.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `title` (erforderlich) - Titel
- `message` (optional) - Nachricht
- `confirmText` - Text für OK-Button (Standard: "OK")
- `showCancel` - Ob Abbrechen-Button angezeigt wird (Standard: false)

## SnackBarHelper

Helper-Klasse für konsistente SnackBar-Nachrichten mit verschiedenen Typen.

### Nutzung

```dart
// Erfolgsmeldung
SnackBarHelper.showSuccess(
  context,
  'Kampagne erfolgreich gespeichert',
  duration: const Duration(seconds: 2),
);

// Fehlermeldung
SnackBarHelper.showError(
  context,
  'Fehler beim Speichern',
  duration: const Duration(seconds: 3),
);

// Warnung
SnackBarHelper.showWarning(
  context,
  'Verbindung ist instabil',
);

// Info
SnackBarHelper.showInfo(
  context,
  'Neue Version verfügbar',
);

// Mit Aktion
SnackBarHelper.showWithAction(
  context,
  'Änderungen nicht gespeichert',
  'Jetzt speichern',
  () => _saveChanges(),
  backgroundColor: Colors.blue,
);

// Löschen mit Undo
SnackBarHelper.showDeleteWithUndo(
  context,
  'Kampagne gelöscht',
  () => viewModel.undoDelete(),
);

// Alle SnackBars entfernen
SnackBarHelper.clear(context);
```

### Verfügbare Methoden

#### `showSuccess()`
Zeigt eine Erfolgsmeldung mit grünem Hintergrund und Check-Icon.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `message` (erforderlich) - Nachricht
- `duration` - Anzeigedauer (Standard: 2 Sekunden)

#### `showError()`
Zeigt eine Fehlermeldung mit rotem Hintergrund und Fehler-Icon.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `message` (erforderlich) - Nachricht
- `duration` - Anzeigedauer (Standard: 3 Sekunden)

#### `showWarning()`
Zeigt eine Warnung mit orangem Hintergrund und Warnungs-Icon.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `message` (erforderlich) - Nachricht
- `duration` - Anzeigedauer (Standard: 3 Sekunden)

#### `showInfo()`
Zeigt eine Info-Nachricht mit blauem Hintergrund und Info-Icon.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `message` (erforderlich) - Nachricht
- `duration` - Anzeigedauer (Standard: 2 Sekunden)

#### `showWithAction()`
Zeigt eine SnackBar mit benutzerdefinierter Aktion.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `message` (erforderlich) - Nachricht
- `actionLabel` (erforderlich) - Label für die Aktion
- `onAction` (erforderlich) - Callback für die Aktion
- `backgroundColor` - Hintergrundfarbe (Standard: Theme-Primärfarbe)
- `duration` - Anzeigedauer (Standard: 4 Sekunden)

#### `showDeleteWithUndo()`
Zeigt eine Lösch-Bestätigung mit Undo-Option.

**Parameter:**
- `context` (erforderlich) - BuildContext
- `message` (erforderlich) - Nachricht
- `onUndo` (erforderlich) - Callback für Undo
- `duration` - Anzeigedauer (Standard: 4 Sekunden)

#### `clear()`
Entfernt alle aktuellen SnackBars.

**Parameter:**
- `context` (erforderlich) - BuildContext

#### `hideCurrent()`
Entfernt die oberste SnackBar.

**Parameter:**
- `context` (erforderlich) - BuildContext

## Beispiele aus der Praxis

### Kampagne löschen mit Bestätigung und Undo

```dart
Future<void> _deleteCampaign(Campaign campaign) async {
  // Bestätigungsdialog
  final confirmed = await ConfirmationDialog.showDelete(
    context: context,
    title: '${campaign.title} löschen?',
    message: 'Diese Aktion kann nicht rückgängig gemacht werden.',
  );

  if (confirmed != true) return;

  // Löschen
  final deletedCampaign = campaign;
  await viewModel.deleteCampaign(campaign);

  // SnackBar mit Undo-Option
  SnackBarHelper.showDeleteWithUndo(
    context,
    '${deletedCampaign.title} gelöscht',
    () async {
      await viewModel.restoreCampaign(deletedCampaign);
      SnackBarHelper.showSuccess(
        context,
        'Kampagne wiederhergestellt',
      );
    },
  );
}
```

### Änderungen speichern mit Warnung

```dart
Future<void> _saveChanges() async {
  if (!hasUnsavedChanges) return;

  // Warnungsdialog
  final confirmed = await ConfirmationDialog.showSave(
    context: context,
    title: 'Änderungen speichern?',
    message: 'Du hast ungespeicherte Änderungen.',
  );

  if (confirmed != true) {
    SnackBarHelper.showInfo(context, 'Änderungen verworfen');
    return;
  }

  // Speichern
  try {
    await viewModel.saveChanges();
    SnackBarHelper.showSuccess(
      context,
      'Änderungen erfolgreich gespeichert',
    );
  } catch (e) {
    SnackBarHelper.showError(
      context,
      'Fehler beim Speichern: ${e.toString()}',
    );
  }
}
```

### Kritische Aktion mit Warnung

```dart
Future<void> _resetDatabase() async {
  // Warnungsdialog
  final confirmed = await ConfirmationDialog.showWarning(
    context: context,
    title: 'Datenbank zurücksetzen?',
    message: 'Alle Daten werden gelöscht. Diese Aktion kann nicht rückgängig gemacht werden!',
    confirmText: 'Zurücksetzen',
  );

  if (confirmed != true) return;

  // Zurücksetzen
  try {
    await viewModel.resetDatabase();
    SnackBarHelper.showSuccess(
      context,
      'Datenbank erfolgreich zurückgesetzt',
    );
  } catch (e) {
    SnackBarHelper.showError(
      context,
      'Fehler beim Zurücksetzen: ${e.toString()}',
    );
  }
}
```

### Batch-Operation mit Fortschritt

```dart
Future<void> _batchDelete(List<Campaign> campaigns) async {
  // Bestätigungsdialog
  final confirmed = await ConfirmationDialog.showDelete(
    context: context,
    title: '${campaigns.length} Kampagnen löschen?',
    message: 'Dies wird alle ausgewählten Kampagnen löschen.',
  );

  if (confirmed != true) return;

  // Batch-Löschen
  int successCount = 0;
  int errorCount = 0;

  for (final campaign in campaigns) {
    try {
      await viewModel.deleteCampaign(campaign);
      successCount++;
    } catch (e) {
      errorCount++;
    }
  }

  // Ergebnis anzeigen
  if (errorCount == 0) {
    SnackBarHelper.showSuccess(
      context,
      '$successCount Kampagnen erfolgreich gelöscht',
    );
  } else {
    SnackBarHelper.showWarning(
      context,
      '$successCount erfolgreich, $errorCount fehlgeschlagen',
    );
  }
}
```

## Best Practices

### 1. Dialoge
- Verwende immer `ConfirmationDialog` für kritische Aktionen
- Wähle die passende Methode (`showDelete`, `showSave`, etc.)
- Gib klare und verständliche Nachrichten an
- Verwende Icons für visuelle Hinweise

### 2. SnackBars
- Zeige immer Feedback nach Aktionen (Erfolg/Fehler)
- Verwende `showDeleteWithUndo` für destruktive Aktionen
- Halte Nachrichten kurz und prägnant
- Passe die Dauer an die Wichtigkeit an

### 3. UX-Richtlinien
- Erfolgsmeldungen: 2 Sekunden
- Fehlermeldungen: 3-4 Sekunden
- Mit Aktionen: 4 Sekunden
- Verwende `clear()` vor wichtigen Dialogen

### 4. Fehlersuche
- Zeige immer Fehlermeldungen mit `showError()`
- Gib nützliche Informationen über den Fehler
- Biete eine Möglichkeit zur Wiederholung an

## Struktur

```
lib/widgets/ui_components/feedback/
├── confirmation_dialog.dart
├── snackbar_helper.dart
└── README.md
```

## Migration bestehenden Codes

### Vorher (Dialoge):

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Löschen?'),
    content: const Text('Wirklich löschen?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          // Lösch-Logik
        },
        child: const Text('Löschen'),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
      ),
    ],
  ),
);
```

### Nachher:

```dart
final confirmed = await ConfirmationDialog.showDelete(
  context: context,
  title: 'Löschen?',
  message: 'Wirklich löschen?',
);

if (confirmed == true) {
  // Lösch-Logik
}
```

### Vorher (SnackBars):

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Gespeichert'),
    backgroundColor: Colors.green,
  ),
);
```

### Nachher:

```dart
SnackBarHelper.showSuccess(context, 'Gespeichert');
```

Diese Komponenten sorgen für ein konsistentes und professionelles Feedback in der gesamten App.
