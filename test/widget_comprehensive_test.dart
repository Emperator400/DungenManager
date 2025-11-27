import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/models/session.dart';
import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/models/sound.dart';

void main() {
  group('DungenManager Widget Tests', () {

    testWidgets('Campaign Model Widget Test', (WidgetTester tester) async {
      final campaign = Campaign.create(
        title: 'Test Campaign',
        description: 'Test Description',
      ).copyWith(id: 'test-id');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(campaign.title),
                Text(campaign.description),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Campaign'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('Player Character Widget Test', (WidgetTester tester) async {
      final character = PlayerCharacter(
        name: 'Test Character',
        playerName: 'Test Player',
        className: 'Warrior',
        raceName: 'Human',
        id: '123',
        campaignId: 'campaign-id',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        initiativeBonus: 0,
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10,
        proficientSkills: const [],
        attackList: const [],
        inventory: const [],
        gold: 0,
        silver: 0,
        copper: 0,
        sourceType: 'manual',
        version: '1.0',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text(character.name),
              subtitle: Text('${character.className} (${character.raceName})'),
              trailing: Text(character.playerName),
            ),
          ),
        ),
      );

      expect(find.text('Test Character'), findsOneWidget);
      expect(find.text('Warrior (Human)'), findsOneWidget);
      expect(find.text('Test Player'), findsOneWidget);
    });

    testWidgets('Session Widget Test', (WidgetTester tester) async {
      final session = Session(
        title: 'Test Session',
        campaignId: 'campaign-id',
        id: 'session-id',
        liveNotes: 'Test live notes',
        inGameTimeInMinutes: 480,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Column(
                children: [
                  Text(session.title),
                  Text(session.liveNotes),
                  Text('${session.inGameTimeInMinutes} minutes'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Session'), findsOneWidget);
      expect(find.text('Test live notes'), findsOneWidget);
      expect(find.text('480 minutes'), findsOneWidget);
    });

    testWidgets('Quest Widget Test', (WidgetTester tester) async {
      final quest = Quest(
        title: 'Test Quest',
        description: 'Test Quest Description',
        id: 123,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Column(
                children: [
                  Text(quest.title),
                  Text(quest.description),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Quest'), findsOneWidget);
      expect(find.text('Test Quest Description'), findsOneWidget);
    });

    testWidgets('Sound Widget Test', (WidgetTester tester) async {
      final sound = Sound(
        name: 'Test Sound',
        filePath: '/path/to/sound.mp3',
        soundType: SoundType.Ambiente,
        id: 'sound-id',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: Icon(Icons.music_note),
              title: Text(sound.name),
              subtitle: Text(sound.filePath),
            ),
          ),
        ),
      );

      expect(find.text('Test Sound'), findsOneWidget);
      expect(find.text('/path/to/sound.mp3'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('Form Input Validation Test', (WidgetTester tester) async {
      String? textValue;
      final formKey = GlobalKey<FormState>();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Test Field'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field cannot be empty';
                      }
                      return null;
                    },
                    onSaved: (value) => textValue = value,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState?.save();
                      formKey.currentState?.validate();
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test empty validation
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Field cannot be empty'), findsOneWidget);

      // Test valid input
      await tester.enterText(find.byType(TextFormField), 'Valid Input');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      
      expect(textValue, 'Valid Input');
      expect(find.text('Field cannot be empty'), findsNothing);
    });

    testWidgets('List View Performance Test', (WidgetTester tester) async {
      final items = List.generate(10, (index) => 'Item $index'); // Reduced for performance
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify first item is rendered
      expect(find.text('Item 0'), findsOneWidget);
      
      // Test scrolling to see more items
      await tester.fling(find.byType(ListView), const Offset(0, -300), 10000);
      await tester.pumpAndSettle();
      
      // After scrolling, we should see later items
      expect(find.text('Item 5'), findsOneWidget);
      
      // Scroll back up
      await tester.fling(find.byType(ListView), const Offset(0, 300), 10000);
      await tester.pumpAndSettle();
      
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('Dialog Widget Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Test Dialog'),
                      content: Text('Dialog Content'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsNothing);
    });

    testWidgets('Tab Bar Widget Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    Tab(text: 'Tab 1'),
                    Tab(text: 'Tab 2'),
                    Tab(text: 'Tab 3'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  Center(child: Text('Content 1')),
                  Center(child: Text('Content 2')),
                  Center(child: Text('Content 3')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Content 1'), findsOneWidget);

      // Switch to tab 2
      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(find.text('Content 2'), findsOneWidget);
      expect(find.text('Content 1'), findsNothing);

      // Switch to tab 3
      await tester.tap(find.text('Tab 3'));
      await tester.pumpAndSettle();

      expect(find.text('Content 3'), findsOneWidget);
      expect(find.text('Content 2'), findsNothing);
    });

    testWidgets('Theme Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: Colors.blue,
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          home: Scaffold(
            appBar: AppBar(title: Text('Test App')),
            body: Builder(
              builder: (context) => Text(
                'Test Content',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      );

      // Check that app has a theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.theme?.primaryColor, Colors.blue);

      // Check that text style is applied
      final text = tester.widget<Text>(find.text('Test Content'));
      expect(text.style?.fontSize, 16);
      expect(text.style?.color, Colors.black);
    });
  });
}
