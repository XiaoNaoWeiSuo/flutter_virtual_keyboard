import 'style/control_layout.dart';

class VirtualControlState {
  const VirtualControlState({
    required this.id,
    required this.layout,
    this.opacity = 1.0,
    this.config = const {},
  });

  factory VirtualControlState.fromJson(Map<String, dynamic> json) {
    return VirtualControlState(
      id: json['id'] as String,
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      config: json['config'] is Map
          ? Map<String, dynamic>.from(json['config'] as Map)
          : const {},
    );
  }

  final String id;
  final ControlLayout layout;
  final double opacity;
  final Map<String, dynamic> config;

  Map<String, dynamic> toJson() => {
        'id': id,
        'layout': layout.toJson(),
        'opacity': double.parse(opacity.toStringAsFixed(6)),
        if (config.isNotEmpty) 'config': config,
      };

  VirtualControlState copyWith({
    ControlLayout? layout,
    double? opacity,
    Map<String, dynamic>? config,
  }) {
    return VirtualControlState(
      id: id,
      layout: layout ?? this.layout,
      opacity: opacity ?? this.opacity,
      config: config ?? this.config,
    );
  }
}

class VirtualControllerState {
  const VirtualControllerState({
    required this.schemaVersion,
    required this.controls,
    this.name,
  });

  factory VirtualControllerState.fromJson(Map<String, dynamic> json) {
    final controlsJson = json['controls'] as List? ?? const [];
    return VirtualControllerState(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      controls: controlsJson
          .whereType<Map>()
          .map((c) =>
              VirtualControlState.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
      name: json['name'] as String?,
    );
  }

  final int schemaVersion;
  final List<VirtualControlState> controls;
  final String? name;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'controls': controls.map((c) => c.toJson()).toList(),
        if (name != null) 'name': name,
      };

  Map<String, VirtualControlState> get byId => {
        for (final c in controls) c.id: c,
      };

  VirtualControllerState copyWith({
    int? schemaVersion,
    List<VirtualControlState>? controls,
    String? name,
  }) {
    return VirtualControllerState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      controls: controls ?? this.controls,
      name: name ?? this.name,
    );
  }

  VirtualControllerState upsert(VirtualControlState state) {
    final next = <VirtualControlState>[];
    var replaced = false;
    for (final c in controls) {
      if (c.id == state.id) {
        next.add(state);
        replaced = true;
      } else {
        next.add(c);
      }
    }
    if (!replaced) next.add(state);
    return VirtualControllerState(
      schemaVersion: schemaVersion,
      controls: next,
      name: name,
    );
  }

  VirtualControllerState remove(String id) {
    return VirtualControllerState(
      schemaVersion: schemaVersion,
      controls: controls.where((c) => c.id != id).toList(),
      name: name,
    );
  }

  VirtualControlState? stateFor(String id) {
    for (final c in controls) {
      if (c.id == id) return c;
    }
    return null;
  }
}
