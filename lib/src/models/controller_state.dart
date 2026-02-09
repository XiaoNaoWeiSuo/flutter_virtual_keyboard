import 'style/control_layout.dart';

class VirtualControlState {
  const VirtualControlState({
    required this.id,
    required this.layout,
    this.opacity = 1.0,
  });

  factory VirtualControlState.fromJson(Map<String, dynamic> json) {
    return VirtualControlState(
      id: json['id'] as String,
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  final String id;
  final ControlLayout layout;
  final double opacity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'layout': layout.toJson(),
        'opacity': opacity,
      };

  VirtualControlState copyWith({
    ControlLayout? layout,
    double? opacity,
  }) {
    return VirtualControlState(
      id: id,
      layout: layout ?? this.layout,
      opacity: opacity ?? this.opacity,
    );
  }
}

class VirtualControllerState {
  const VirtualControllerState({
    required this.schemaVersion,
    required this.controls,
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
    );
  }

  final int schemaVersion;
  final List<VirtualControlState> controls;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'controls': controls.map((c) => c.toJson()).toList(),
      };

  Map<String, VirtualControlState> get byId => {
        for (final c in controls) c.id: c,
      };

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
    return VirtualControllerState(schemaVersion: schemaVersion, controls: next);
  }

  VirtualControlState? stateFor(String id) {
    for (final c in controls) {
      if (c.id == id) return c;
    }
    return null;
  }
}
