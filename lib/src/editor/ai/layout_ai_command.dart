import 'dart:convert';

class LayoutAICommand {
  const LayoutAICommand({
    required this.action,
    this.type,
    this.id,
    this.label,
    this.x,
    this.y,
    this.width,
    this.height,
    this.scale,
    this.properties,
  });

  factory LayoutAICommand.fromJson(Map<String, dynamic> json) {
    return LayoutAICommand(
      action: LayoutAIAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => LayoutAIAction.unknown,
      ),
      type: json['type'] as String?,
      id: json['id'] as String?,
      label: json['label'] as String?,
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
      properties: json['properties'] as Map<String, dynamic>?,
    );
  }

  final LayoutAIAction action;
  final String? type;
  final String? id;
  final String? label;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final double? scale;
  final Map<String, dynamic>? properties;

  Map<String, dynamic> toJson() => {
        'action': action.name,
        if (type != null) 'type': type,
        if (id != null) 'id': id,
        if (label != null) 'label': label,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (scale != null) 'scale': scale,
        if (properties != null) 'properties': properties,
      };

  @override
  String toString() => 'LayoutAICommand(${jsonEncode(toJson())})';
}

enum LayoutAIAction {
  add,
  remove,
  move,
  resize,
  rename,
  updateProperty,
  clear,
  unknown,
}
