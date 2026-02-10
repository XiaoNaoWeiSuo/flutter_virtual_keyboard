import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import 'virtual_control.dart';
import 'virtual_key.dart';
import '../binding/binding.dart';

/// Virtual Key Cluster Control.
///
/// Represents a grid of keys (e.g., QWERTY layout section) that expands into
/// individual [VirtualKey] instances.
class VirtualKeyCluster extends VirtualControl {
  /// Creates a virtual key cluster.
  VirtualKeyCluster({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.style,
    super.feedback,
    required this.grid,
    required this.keySize,
    this.spacing = 0.005,
  }) : super(type: 'key_cluster');

  /// Creates a [VirtualKeyCluster] from a JSON map.
  factory VirtualKeyCluster.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    final gridJson = config['grid'] as List? ?? [];
    final grid = gridJson.map((row) {
      return (row as List).map((cell) => cell as String?).toList();
    }).toList();

    final keySizeJson = config['keySize'] as Map<String, dynamic>? ??
        {'width': 0.04, 'height': 0.06};

    return VirtualKeyCluster(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      grid: grid,
      keySize: ControlLayout(
        x: 0,
        y: 0,
        width: (keySizeJson['width'] as num).toDouble(),
        height: (keySizeJson['height'] as num).toDouble(),
      ),
      spacing: (config['spacing'] as num?)?.toDouble() ?? 0.005,
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Grid of key names (null for empty space).
  final List<List<String?>> grid;

  /// Size of each individual key in the cluster.
  final ControlLayout keySize;

  /// Spacing between keys.
  final double spacing;

  /// Expand the cluster into individual VirtualKey instances.
  List<VirtualKey> expandToKeys(ControlLayout clusterLayout) {
    final keys = <VirtualKey>[];
    final baseX = clusterLayout.x;
    final baseY = clusterLayout.y;

    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        final keyName = grid[row][col];
        if (keyName == null) continue;

        final keyX = baseX + col * (keySize.width + spacing);
        final keyY = baseY + row * (keySize.height + spacing);

        keys.add(VirtualKey(
          id: '${id}_$keyName',
          label: keyName,
          layout: ControlLayout(
            x: keyX,
            y: keyY,
            width: keySize.width,
            height: keySize.height,
          ),
          trigger: trigger,
          binding: KeyboardBinding(key: KeyboardKey(keyName).normalized()),
          style: style, // Inherit style
          feedback: feedback, // Inherit feedback
        ));
      }
    }
    return keys;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'grid': grid,
          'keySize': {'width': keySize.width, 'height': keySize.height},
          'spacing': spacing,
        },
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
