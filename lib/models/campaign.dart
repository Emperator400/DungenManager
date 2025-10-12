// lib/models/campaign.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class Campaign {
  final String id;
  final String title;
  final String description;

  Campaign({
    String? id,
    required this.title,
    required this.description,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }
}