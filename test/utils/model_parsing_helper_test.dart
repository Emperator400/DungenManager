import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/utils/model_parsing_helper.dart';
import 'package:dungen_manager/models/item.dart';

void main() {
  group('ModelParsingHelper Tests', () {
    late Map<String, dynamic> testMap;
    late Map<String, dynamic> emptyMap;

    setUp(() {
      testMap = {
        'id': 'test-id',
        'name': 'Test Item',
        'weight': 10.5,
        'cost': 25.0,
        'item_type': 'ItemType.Weapon',
        'damage': '2d6',
        'strength_requirement': 14,
        'requires_attunement': true,
        'is_spell': false,
        'max_durability': 100,
        'invalid_field': null,
        'string_number': '42',
        'double_number': 3.14,
        'bool_string_true': 'true',
        'bool_string_false': 'false',
        'bool_number': 1,
        'bool_zero': 0,
        'enum_invalid': 'ItemType.InvalidType',
      };
      
      emptyMap = {};
    });

    group('safeString Tests', () {
      test('should return existing string value', () {
        expect(ModelParsingHelper.safeString(testMap, 'name', ''), equals('Test Item'));
      });

      test('should return default value for missing key', () {
        expect(ModelParsingHelper.safeString(testMap, 'missing', 'default'), equals('default'));
      });

      test('should convert non-string values to string', () {
        expect(ModelParsingHelper.safeString(testMap, 'weight', ''), equals('10.5'));
      });

      test('should handle null values', () {
        expect(ModelParsingHelper.safeString(testMap, 'invalid_field', 'default'), equals('default'));
      });
    });

    group('safeStringOrNull Tests', () {
      test('should return existing string value', () {
        expect(ModelParsingHelper.safeStringOrNull(testMap, 'damage', null), equals('2d6'));
      });

      test('should return null for missing key', () {
        expect(ModelParsingHelper.safeStringOrNull(testMap, 'missing', null), isNull);
      });

      test('should return null for empty string', () {
        final mapWithEmpty = {'empty': ''};
        expect(ModelParsingHelper.safeStringOrNull(mapWithEmpty, 'empty', null), isNull);
      });
    });

    group('safeInt Tests', () {
      test('should return existing int value', () {
        expect(ModelParsingHelper.safeInt(testMap, 'strength_requirement', 0), equals(14));
      });

      test('should parse string to int', () {
        expect(ModelParsingHelper.safeInt(testMap, 'string_number', 0), equals(42));
      });

      test('should convert double to int', () {
        expect(ModelParsingHelper.safeInt(testMap, 'double_number', 0), equals(3));
      });

      test('should return default for missing key', () {
        expect(ModelParsingHelper.safeInt(testMap, 'missing', 99), equals(99));
      });

      test('should return default for invalid value', () {
        expect(ModelParsingHelper.safeInt(testMap, 'name', 0), equals(0));
      });
    });

    group('safeIntOrNull Tests', () {
      test('should return existing int value', () {
        expect(ModelParsingHelper.safeIntOrNull(testMap, 'strength_requirement', null), equals(14));
      });

      test('should return null for missing key', () {
        expect(ModelParsingHelper.safeIntOrNull(testMap, 'missing', null), isNull);
      });

      test('should return null for zero value', () {
        final mapWithZero = {'zero': 0};
        expect(ModelParsingHelper.safeIntOrNull(mapWithZero, 'zero', null), isNull);
      });
    });

    group('safeDouble Tests', () {
      test('should return existing double value', () {
        expect(ModelParsingHelper.safeDouble(testMap, 'weight', 0.0), equals(10.5));
      });

      test('should convert int to double', () {
        expect(ModelParsingHelper.safeDouble(testMap, 'strength_requirement', 0.0), equals(14.0));
      });

      test('should parse string to double', () {
        expect(ModelParsingHelper.safeDouble(testMap, 'double_number', 0.0), equals(3.14));
      });

      test('should return default for missing key', () {
        expect(ModelParsingHelper.safeDouble(testMap, 'missing', 99.0), equals(99.0));
      });
    });

    group('safeBool Tests', () {
      test('should return existing bool value', () {
        expect(ModelParsingHelper.safeBool(testMap, 'requires_attunement', false), isTrue);
        expect(ModelParsingHelper.safeBool(testMap, 'is_spell', false), isFalse);
      });

      test('should parse string true values', () {
        expect(ModelParsingHelper.safeBool(testMap, 'bool_string_true', false), isTrue);
        expect(ModelParsingHelper.safeBool(testMap, 'bool_string_false', false), isFalse);
      });

      test('should convert int to bool', () {
        expect(ModelParsingHelper.safeBool(testMap, 'bool_number', false), isTrue);
        expect(ModelParsingHelper.safeBool(testMap, 'bool_zero', false), isFalse);
      });

      test('should return default for missing key', () {
        expect(ModelParsingHelper.safeBool(testMap, 'missing', true), isTrue);
      });
    });

    group('safeEnum Tests', () {
      test('should parse valid enum value', () {
        final result = ModelParsingHelper.safeEnum<ItemType>(
          testMap, 
          'item_type', 
          ItemType.values, 
          ItemType.Weapon,
        );
        expect(result, equals(ItemType.Weapon));
      });

      test('should return default for invalid enum value', () {
        final result = ModelParsingHelper.safeEnum<ItemType>(
          testMap, 
          'enum_invalid', 
          ItemType.values, 
          ItemType.Weapon,
        );
        expect(result, equals(ItemType.Weapon));
      });

      test('should return default for missing key', () {
        final result = ModelParsingHelper.safeEnum<ItemType>(
          testMap, 
          'missing', 
          ItemType.values, 
          ItemType.Armor,
        );
        expect(result, equals(ItemType.Armor));
      });
    });

    group('safeId Tests', () {
      test('should return existing id', () {
        expect(ModelParsingHelper.safeId(testMap, 'id'), equals('test-id'));
      });

      test('should generate new id for empty string', () {
        final mapWithEmptyId = {'id': ''};
        final id = ModelParsingHelper.safeId(mapWithEmptyId, 'id');
        expect(id, isNotEmpty);
        expect(id, isNot(equals('')));
      });

      test('should generate new id for missing key', () {
        final id = ModelParsingHelper.safeId(emptyMap, 'id');
        expect(id, isNotEmpty);
        expect(id, hasLength(36)); // UUID v4 length
      });
    });

    group('hasRequiredKeys Tests', () {
      test('should return true for all required keys present', () {
        final requiredKeys = ['id', 'name', 'item_type'];
        expect(ModelParsingHelper.hasRequiredKeys(testMap, requiredKeys), isTrue);
      });

      test('should return false for missing required key', () {
        final requiredKeys = ['id', 'name', 'missing_key'];
        expect(ModelParsingHelper.hasRequiredKeys(testMap, requiredKeys), isFalse);
      });

      test('should return false for null required key', () {
        final mapWithNull = {'id': null, 'name': 'test'};
        final requiredKeys = ['id', 'name'];
        expect(ModelParsingHelper.hasRequiredKeys(mapWithNull, requiredKeys), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle completely empty map', () {
        expect(ModelParsingHelper.safeString(emptyMap, 'key', 'default'), equals('default'));
        expect(ModelParsingHelper.safeInt(emptyMap, 'key', 0), equals(0));
        expect(ModelParsingHelper.safeDouble(emptyMap, 'key', 0.0), equals(0.0));
        expect(ModelParsingHelper.safeBool(emptyMap, 'key', false), isFalse);
      });

      test('should handle map with only null values', () {
        final nullMap = {'key': null};
        expect(ModelParsingHelper.safeString(nullMap, 'key', 'default'), equals('default'));
        expect(ModelParsingHelper.safeInt(nullMap, 'key', 0), equals(0));
        expect(ModelParsingHelper.safeDouble(nullMap, 'key', 0.0), equals(0.0));
        expect(ModelParsingHelper.safeBool(nullMap, 'key', false), isFalse);
      });
    });

    group('Performance Tests', () {
      test('should handle large maps efficiently', () {
        final largeMap = <String, dynamic>{};
        for (int i = 0; i < 1000; i++) {
          largeMap['key_$i'] = 'value_$i';
        }
        
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 100; i++) {
          ModelParsingHelper.safeString(largeMap, 'key_${i % 1000}', 'default');
        }
        stopwatch.stop();
        
        // Should complete 100 operations in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });

  group('Real-world Integration Tests', () {
    test('should handle typical Item data safely', () {
      final itemData = {
        'name': 'Longsword',
        'description': 'A classic martial weapon',
        'item_type': 'ItemType.Weapon',
        'weight': 3.0,
        'cost': 15.0,
        'damage': '1d8 slashing',
        'properties': 'Versatile (1d10)',
        'rarity': 'Common',
      };

      final item = Item.fromMap(itemData);
      
      expect(item.name, equals('Longsword'));
      expect(item.itemType, equals(ItemType.Weapon));
      expect(item.weight, equals(3.0));
      expect(item.damage, equals('1d8 slashing'));
      expect(item.properties, equals('Versatile (1d10)'));
      expect(item.rarity, equals('Common'));
    });

    test('should handle corrupted Item data gracefully', () {
      final corruptedData = {
        'name': null,
        'item_type': 'InvalidType',
        'weight': 'invalid',
        'cost': null,
        'damage': 123, // Should be string
        'strength_requirement': 'not_a_number',
      };

      final item = Item.fromMap(corruptedData);
      
      expect(item.name, equals('')); // Default value
      expect(item.itemType, equals(ItemType.Weapon)); // Default enum value
      expect(item.weight, equals(0.0)); // Default value
      expect(item.cost, equals(0.0)); // Default value
      expect(item.damage, equals('123')); // Converted to string
      expect(item.strengthRequirement, isNull); // Invalid int becomes null
    });
  });
}
