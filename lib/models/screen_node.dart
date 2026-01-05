/// Model für einen Screen-Knoten im Navigation-Graph
class ScreenNode {
  final String name;
  final String fileName;
  final String category;
  final List<ScreenConnection> connections;
  final bool requiresParameters;
  final String? parameterInfo;

  ScreenNode({
    required this.name,
    required this.fileName,
    required this.category,
    this.connections = const [],
    this.requiresParameters = false,
    this.parameterInfo,
  });

  ScreenNode copyWith({
    String? name,
    String? fileName,
    String? category,
    List<ScreenConnection>? connections,
    bool? requiresParameters,
    String? parameterInfo,
  }) {
    return ScreenNode(
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      category: category ?? this.category,
      connections: connections ?? this.connections,
      requiresParameters: requiresParameters ?? this.requiresParameters,
      parameterInfo: parameterInfo ?? this.parameterInfo,
    );
  }
}

/// Model für eine Verbindung zwischen Screens
class ScreenConnection {
  final String targetScreen;
  final String? triggerAction;
  final String? description;
  final ConnectionType type;

  ScreenConnection({
    required this.targetScreen,
    this.triggerAction,
    this.description,
    this.type = ConnectionType.navigation,
  });
}

/// Typ der Verbindung
enum ConnectionType {
  navigation, // Normale Navigation
  modal, // Modal/Dialog
  deepLink, // Deep Link mit Parameter
  action, // Button/Action Trigger
}
