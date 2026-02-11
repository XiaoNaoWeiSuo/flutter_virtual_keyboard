part of '../macro_editor_dialog.dart';

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.isRecording,
    required this.onToggle,
  });

  final bool isRecording;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onToggle,
      style: OutlinedButton.styleFrom(
        foregroundColor: isRecording ? Colors.redAccent : Colors.white70,
        side: BorderSide(color: isRecording ? Colors.redAccent : Colors.white24),
      ),
      icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
      label: Text(isRecording ? '停止录制' : '开始录制'),
    );
  }
}

class _DelayBadge extends StatelessWidget {
  const _DelayBadge({required this.delay, required this.onTap});
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '+${delay}ms',
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ),
    );
  }
}

class _NumberEditDialog extends StatefulWidget {
  const _NumberEditDialog({required this.title, required this.initialValue});
  final String title;
  final int initialValue;

  @override
  State<_NumberEditDialog> createState() => _NumberEditDialogState();
}

class _NumberEditDialogState extends State<_NumberEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        autofocus: true,
        decoration: const InputDecoration(
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(color: Colors.white60)),
        ),
        TextButton(
          onPressed: () {
            final v = int.tryParse(_controller.text);
            if (v != null) Navigator.of(context).pop(v);
          },
          child: const Text('确定', style: TextStyle(color: Colors.lightBlueAccent)),
        ),
      ],
    );
  }
}

class _TextEditDialog extends StatefulWidget {
  const _TextEditDialog({required this.title, required this.initialValue});
  final String title;
  final String initialValue;

  @override
  State<_TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<_TextEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        autofocus: true,
        decoration: const InputDecoration(
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(color: Colors.white60)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
          child:
              const Text('确定', style: TextStyle(color: Colors.lightBlueAccent)),
        ),
      ],
    );
  }
}

