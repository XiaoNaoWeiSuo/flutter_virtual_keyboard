part of '../virtual_controller_layout_editor_palette.dart';

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(6),
  });
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return _PaletteTile(
      onTap: onTap,
      padding: padding,
      child: IgnorePointer(child: child),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(6),
  });
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}
