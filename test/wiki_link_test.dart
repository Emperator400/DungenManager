// 1. Externe Packages
import 'package:flutter_test/flutter_test.dart';

// 2. Eigene Projekte (absolute Pfade)
import 'package:dungen_manager/models/wiki_link.dart';
import 'package:dungen_manager/models/wiki_entry.dart';
import 'package:dungen_manager/models/wiki_hierarchy.dart';
import 'package:dungen_manager/models/linked_wiki_entry.dart';
import 'package:dungen_manager/utils/wiki_link_parser.dart';

void main() {
  group('WikiLink Model Tests', () {
    test('WikiLink creation', () {
      final link = WikiLink(
        sourceEntryId: 'source1',
        targetEntryId: 'target1',
        linkType: WikiLinkType.reference,
        createdBy: 'test_user',
      );

      expect(link.sourceEntryId, 'source1');
      expect(link.targetEntryId, 'target1');
      expect(link.linkType, WikiLinkType.reference);
      expect(link.createdBy, 'test_user');
      expect(link.id, isNotEmpty);
      expect(link.createdAt, isNotNull);
    });

    test('WikiLink copyWith', () {
      final original = WikiLink(
        sourceEntryId: 'source1',
        targetEntryId: 'target1',
        linkType: WikiLinkType.reference,
      );

      final updated = original.copyWith(
        linkType: WikiLinkType.related,
        createdBy: 'new_user',
      );

      expect(updated.sourceEntryId, original.sourceEntryId);
      expect(updated.targetEntryId, original.targetEntryId);
      expect(updated.linkType, WikiLinkType.related);
      expect(updated.createdBy, 'new_user');
      expect(updated.id, original.id);
    });

    test('WikiLink equality', () {
      final link1 = WikiLink(
        sourceEntryId: 'source1',
        targetEntryId: 'target1',
        linkType: WikiLinkType.reference,
      );

      final link2 = WikiLink(
        id: link1.id,
        sourceEntryId: 'source1',
        targetEntryId: 'target1',
        linkType: WikiLinkType.reference,
      );

      final link3 = WikiLink(
        sourceEntryId: 'source2',
        targetEntryId: 'target1',
        linkType: WikiLinkType.reference,
      );

      expect(link1, equals(link2));
      expect(link1, isNot(equals(link3)));
    });
  });

  group('WikiLinkParser Tests', () {
    test('Parse simple wiki links', () {
      final text = 'Dies ist ein [[Test Link]] im Text.';
      final links = WikiLinkParser.parseLinks(text);

      expect(links.length, 1);
      expect(links.first.linkText, 'Test Link');
      expect(links.first.originalText, '[[Test Link]]');
      expect(links.first.displayName, 'Test Link');
    });

    test('Parse multiple wiki links', () {
      final text = 'Links: [[Erster]], [[Zweiter]], und [[Dritter]].';
      final links = WikiLinkParser.parseLinks(text);

      expect(links.length, 3);
      expect(links.map((l) => l.linkText), 
             containsAll(['Erster', 'Zweiter', 'Dritter']));
    });

    test('Parse complex wiki links with spaces', () {
      final text = 'Hier ist ein [[Komplexer Link mit Leerzeichen]].';
      final links = WikiLinkParser.parseLinks(text);

      expect(links.length, 1);
      expect(links.first.linkText, 'Komplexer Link mit Leerzeichen');
    });

    test('Extract link texts only', () {
      final text = 'Links: [[A]], [[B]], [[C]]';
      final linkTexts = WikiLinkParser.extractLinkTexts(text);

      expect(linkTexts, ['A', 'B', 'C']);
    });

    test('Check for wiki links existence', () {
      expect(WikiLinkParser.hasWikiLinks('Text ohne [[Links]]'), isTrue);
      expect(WikiLinkParser.hasWikiLinks('Normaler Text'), isFalse);
      expect(WikiLinkParser.hasWikiLinks('[[Nur Link]]'), isTrue);
    });

    test('Replace with display text', () {
      final text = 'Hier ist ein [[Test Link]] im Text.';
      final display = WikiLinkParser.replaceWithDisplayText(text);

      expect(display, contains('🔗 Test Link'));
      expect(display, isNot(contains('[[')));
    });

    test('String extension methods', () {
      final text = 'Text mit [[Wiki Link]] und noch einem [[Anderen Link]].';

      expect(text.hasWikiLinks, isTrue);
      expect(text.wikiLinks.length, 2);
      expect(text.wikiLinkTexts, contains('Wiki Link'));
      expect(text.wikiLinkTexts, contains('Anderen Link'));
      expect(text.withWikiLinkDisplay, contains('🔗 Wiki Link'));
    });
  });

  group('WikiHierarchy Tests', () {
    late WikiHierarchy hierarchy;

    setUp(() {
      hierarchy = WikiHierarchy();
    });

    test('Add root entries', () {
      final entry1 = WikiEntry.create(
        title: 'Root 1',
        content: '',
        entryType: WikiEntryType.Person,
      );

      final entry2 = WikiEntry.create(
        title: 'Root 2',
        content: '',
        entryType: WikiEntryType.Place,
      );

      hierarchy.addRoot(entry1);
      hierarchy.addRoot(entry2);

      expect(hierarchy.roots.length, 2);
      expect(hierarchy.roots, contains(entry1));
      expect(hierarchy.roots, contains(entry2));
    });

    test('Add child entries', () {
      final parent = WikiEntry.create(
        title: 'Parent',
        content: '',
        entryType: WikiEntryType.Person,
      );

      final child = WikiEntry.create(
        title: 'Child',
        content: '',
        entryType: WikiEntryType.Place,
      );

      hierarchy.addRoot(parent);
      hierarchy.addChild(parent.id, child);

      expect(hierarchy.getChildren(parent.id), contains(child));
      expect(hierarchy.hasChildren(parent.id), isTrue);
      expect(hierarchy.hasChildren(child.id), isFalse);
    });

    test('Detect cycles', () {
      final entry1 = WikiEntry.create(title: '1', content: '', entryType: WikiEntryType.Person);
      final entry2 = WikiEntry.create(title: '2', content: '', entryType: WikiEntryType.Person);
      final entry3 = WikiEntry.create(title: '3', content: '', entryType: WikiEntryType.Person);

      hierarchy.addRoot(entry1);
      hierarchy.addChild(entry1.id, entry2);
      hierarchy.addChild(entry2.id, entry3);
      hierarchy.addChild(entry3.id, entry1); // Zyklus!

      final cycles = hierarchy.detectCycles();
      // Wir prüfen nur, dass Zyklen erkannt werden, nicht die spezifischen IDs
      expect(cycles, isNotEmpty);
      expect(cycles.length, greaterThan(1));
    });

    test('Get flattened hierarchy', () {
      final root = WikiEntry.create(title: 'Root', content: '', entryType: WikiEntryType.Person);
      final child1 = WikiEntry.create(title: 'Child 1', content: '', entryType: WikiEntryType.Person);
      final child2 = WikiEntry.create(title: 'Child 2', content: '', entryType: WikiEntryType.Person);

      hierarchy.addRoot(root);
      hierarchy.addChild(root.id, child1);
      hierarchy.addChild(root.id, child2);

      final flattened = hierarchy.getFlattenedHierarchy();
      expect(flattened.length, 3);
      expect(flattened, contains(root));
      expect(flattened, contains(child1));
      expect(flattened, contains(child2));
    });
  });

  group('LinkedWikiEntry Tests', () {
    test('Create linked wiki entry', () {
      final targetEntry = WikiEntry.create(
        title: 'Target Entry',
        content: 'Content',
        entryType: WikiEntryType.Lore,
      );

      final link = WikiLink(
        sourceEntryId: 'source1',
        targetEntryId: 'target1',
        linkType: WikiLinkType.reference,
      );

      final linkedEntry = LinkedWikiEntry(
        link: link,
        targetEntry: targetEntry,
      );

      expect(linkedEntry.targetEntry, targetEntry);
      expect(linkedEntry.link, link);
      expect(linkedEntry.toString(), contains('Target Entry'));
      expect(linkedEntry.toString(), contains('reference'));
    });
  });

  group('WikiLinkType Tests', () {
    test('All enum values exist', () {
      final allTypes = WikiLinkType.values;
      
      expect(allTypes, contains(WikiLinkType.reference));
      expect(allTypes, contains(WikiLinkType.parent));
      expect(allTypes, contains(WikiLinkType.related));
      expect(allTypes, contains(WikiLinkType.seeAlso));
    });

    test('Enum toString works correctly', () {
      expect(WikiLinkType.reference.toString(), contains('reference'));
      expect(WikiLinkType.parent.toString(), contains('parent'));
      expect(WikiLinkType.related.toString(), contains('related'));
      expect(WikiLinkType.seeAlso.toString(), contains('seeAlso'));
    });
  });

  group('Edge Cases', () {
    test('Empty string parsing', () {
      final links = WikiLinkParser.parseLinks('');
      expect(links, isEmpty);
    });

    test('String without wiki links', () {
      final text = 'Dies ist ein normaler Text ohne Links.';
      expect(text.hasWikiLinks, isFalse);
      expect(text.wikiLinks, isEmpty);
    });

    test('Malformed wiki links', () {
      final text = 'Links: [[unclosed und [[double]] Links.';
      final links = WikiLinkParser.parseLinks(text);
      
      // Nur korrekt formatierte Links sollten erkannt werden
      expect(links.length, 1); // Nur "double" ist korrekt formatiert
      expect(links.first.linkText, 'double');
    });

    test('Nested brackets', () {
      final text = 'Link mit [[[[verschachtelten]]]] Klammern.';
      final links = WikiLinkParser.parseLinks(text);
      
      // Der Parser sollte den innersten korrekten Link finden
      expect(links.length, 1);
      expect(links.first.linkText, 'verschachtelten');
    });

    test('Special characters in links', () {
      final text = 'Links mit [[Sonderzeichen & Symbole!]] und [[Umlautäöü]].';
      final links = WikiLinkParser.parseLinks(text);
      
      expect(links.length, 2);
      expect(links.map((l) => l.linkText), 
             containsAll(['Sonderzeichen & Symbole!', 'Umlautäöü']));
    });
  });
}
