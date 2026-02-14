import '../models/style/control_layout.dart';

ControlLayout layoutWithAspectRatio(
  ControlLayout layout,
  double aspectRatio, {
  bool lockHeight = true,
}) {
  final ratio = aspectRatio <= 0 ? 1.0 : aspectRatio;
  final width = lockHeight ? (layout.height * ratio) : layout.width;
  final height = lockHeight ? layout.height : (layout.width / ratio);

  final centerX = layout.x + layout.width / 2;
  final centerY = layout.y + layout.height / 2;
  final newX = (centerX - width / 2).clamp(0.0, 1.0 - width);
  final newY = (centerY - height / 2).clamp(0.0, 1.0 - height);

  return ControlLayout(
    x: newX,
    y: newY,
    width: width.clamp(0.0, 1.0),
    height: height.clamp(0.0, 1.0),
  );
}

ControlLayout layoutSquare(ControlLayout layout, {bool lockHeight = true}) {
  return layoutWithAspectRatio(layout, 1.0, lockHeight: lockHeight);
}
