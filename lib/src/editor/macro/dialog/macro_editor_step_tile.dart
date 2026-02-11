part of '../macro_editor_dialog.dart';

class _MacroStepTile extends StatelessWidget {
  const _MacroStepTile({
    required super.key,
    required this.item,
    required this.onDelete,
    required this.onUpdate,
  });

  final MacroSequenceItem item;
  final VoidCallback onDelete;
  final ValueChanged<MacroSequenceItem> onUpdate;

  @override
  Widget build(BuildContext context) {
    final typeLabel = _getTypeLabel(item.type);
    final detailLabel = _getDetailLabel(item);
    final color = _getTypeColor(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Row(
          children: [
            Text(
              typeLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detailLabel,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.type != 'delay') ...[
              _DelayBadge(delay: item.delay, onTap: () => _editDelay(context)),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
              onPressed: () => _editItem(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.white30),
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'key_down':
        return '按下';
      case 'key_up':
        return '抬起';
      case 'mouse_down':
        return '鼠标按';
      case 'mouse_up':
        return '鼠标抬';
      case 'delay':
        return '延时';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'key_down':
        return Colors.greenAccent;
      case 'key_up':
        return Colors.orangeAccent;
      case 'mouse_down':
        return Colors.lightBlueAccent;
      case 'mouse_up':
        return Colors.purpleAccent;
      case 'delay':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  String _getDetailLabel(MacroSequenceItem item) {
    if (item.type == 'delay') return '${item.delay} ms';
    if (item.type.startsWith('key')) return item.key ?? '?';
    if (item.type.startsWith('mouse')) return item.button ?? '?';
    return '';
  }

  Future<void> _editDelay(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _NumberEditDialog(
        title: '设置延时 (ms)',
        initialValue: item.delay,
      ),
    );
    if (result != null) {
      onUpdate(MacroSequenceItem(
        type: item.type,
        key: item.key,
        button: item.button,
        modifiers: item.modifiers,
        delay: result,
      ));
    }
  }

  Future<void> _editItem(BuildContext context) async {
    if (item.type == 'delay') {
      await _editDelay(context);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _TextEditDialog(
        title: '编辑按键/按钮',
        initialValue: item.key ?? item.button ?? '',
      ),
    );

    if (result != null) {
      onUpdate(MacroSequenceItem(
        type: item.type,
        key: item.type.startsWith('key') ? result : null,
        button: item.type.startsWith('mouse') ? result : null,
        modifiers: item.modifiers,
        delay: item.delay,
      ));
    }
  }
}

