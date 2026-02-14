part of '../macro_suite_page.dart';

class _TimelineStrip extends StatelessWidget {
  const _TimelineStrip({
    required this.slots,
    required this.scrollController,
    required this.expandedByAtMs,
    required this.selectedId,
    required this.onToggleExpanded,
    required this.onNudgeEntriesAtMs,
    required this.onTapEntry,
    required this.onDeleteEntry,
    required this.onDuplicateEntry,
  });

  final List<_TimeSlot> slots;
  final ScrollController scrollController;
  final Map<int, bool> expandedByAtMs;
  final String? selectedId;
  final ValueChanged<int> onToggleExpanded;
  final void Function(List<String> entryIds, int deltaMs) onNudgeEntriesAtMs;
  final ValueChanged<String> onTapEntry;
  final ValueChanged<String> onDeleteEntry;
  final ValueChanged<String> onDuplicateEntry;

  double _gapForDeltaMs(int deltaMs) {
    if (deltaMs <= 0) return 10;
    final scaled = deltaMs * 0.16;
    return scaled.clamp(10.0, 140.0);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: slots.length,
          separatorBuilder: (context, index) {
            final delta =
                (slots[index + 1].atMs - slots[index].atMs).clamp(0, 999999);
            return SizedBox(
              width: _gapForDeltaMs(delta),
              child: Center(
                child: Container(
                  width: 22,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            );
          },
          itemBuilder: (context, index) {
            final slot = slots[index];
            return RepaintBoundary(
              child: _SlotCard(
                key: ValueKey('slot_${slot.atMs}'),
                slot: slot,
                slotKey: '${slot.atMs}',
                prevAtMs: index == 0 ? 0 : slots[index - 1].atMs,
                selectedId: selectedId,
                expanded: expandedByAtMs[slot.atMs] ?? false,
                onToggleExpanded: () => onToggleExpanded(slot.atMs),
                onNudgeAtMs: (deltaMs) => onNudgeEntriesAtMs(
                  slot.entries.map((e) => e.id).toList(growable: false),
                  deltaMs,
                ),
                onTapEntry: onTapEntry,
                onDeleteEntry: onDeleteEntry,
                onDuplicateEntry: onDuplicateEntry,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlotCard extends StatefulWidget {
  const _SlotCard({
    super.key,
    required this.slot,
    required this.slotKey,
    required this.prevAtMs,
    required this.selectedId,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onNudgeAtMs,
    required this.onTapEntry,
    required this.onDeleteEntry,
    required this.onDuplicateEntry,
  });

  final _TimeSlot slot;
  final String slotKey;
  final int prevAtMs;
  final String? selectedId;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onNudgeAtMs;
  final ValueChanged<String> onTapEntry;
  final ValueChanged<String> onDeleteEntry;
  final ValueChanged<String> onDuplicateEntry;

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> {
  @override
  Widget build(BuildContext context) {
    final deltaMs = (widget.slot.atMs - widget.prevAtMs).clamp(0, 999999);
    final hasSelected = widget.selectedId != null &&
        widget.slot.entries.any((e) => e.id == widget.selectedId);

    final expanded = widget.expanded || hasSelected;
    final width = expanded ? 180.0 : 150.0;
    final entryCount = widget.slot.entries.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      width: width,
      child: Material(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onToggleExpanded,
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${widget.slot.atMs}ms',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                ),
                                const SizedBox(width: 8),
                                _Pill(
                                  label: 'Δ +$deltaMs',
                                  tone: deltaMs > 16
                                      ? _PillTone.warn
                                      : _PillTone.muted,
                                ),
                                const Spacer(),
                                _Pill(
                                  label: '$entryCount',
                                  tone: _PillTone.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _TinyButton(
                                  icon: Icons.remove,
                                  onTap: () => widget.onNudgeAtMs(-10),
                                ),
                                const SizedBox(width: 6),
                                _TinyButton(
                                  icon: Icons.add,
                                  onTap: () => widget.onNudgeAtMs(10),
                                ),
                                const Spacer(),
                                Icon(
                                  expanded
                                      ? Icons.unfold_less
                                      : Icons.unfold_more,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: expanded
                      ? _SlotEntryList(
                          key: ValueKey('${widget.slotKey}_expanded'),
                          entries: widget.slot.entries,
                          selectedId: widget.selectedId,
                          onTapEntry: widget.onTapEntry,
                          onDeleteEntry: widget.onDeleteEntry,
                        )
                      : _SlotEntryPreview(
                          key: ValueKey('${widget.slotKey}_collapsed'),
                          entries: widget.slot.entries,
                          selectedId: widget.selectedId,
                          onTapEntry: widget.onTapEntry,
                          onDeleteEntry: widget.onDeleteEntry,
                          onDuplicateEntry: widget.onDuplicateEntry,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotEntryList extends StatelessWidget {
  const _SlotEntryList({
    super.key,
    required this.entries,
    required this.selectedId,
    required this.onTapEntry,
    required this.onDeleteEntry,
  });

  final List<_StepEntry> entries;
  final String? selectedId;
  final ValueChanged<String> onTapEntry;
  final ValueChanged<String> onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in entries) ...[
            _EntryRow(
              selected: selectedId == e.id,
              type: e.event.type,
              title: _formatTitle(e.event.type, e.event.data),
              subtitle: _formatSubtitle(e.event.type, e.event.data),
              onTap: () => onTapEntry(e.id),
              onDelete: () => onDeleteEntry(e.id),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SlotEntryPreview extends StatelessWidget {
  const _SlotEntryPreview({
    super.key,
    required this.entries,
    required this.selectedId,
    required this.onTapEntry,
    required this.onDeleteEntry,
    required this.onDuplicateEntry,
  });

  final List<_StepEntry> entries;
  final String? selectedId;
  final ValueChanged<String> onTapEntry;
  final ValueChanged<String> onDeleteEntry;
  final ValueChanged<String> onDuplicateEntry;

  @override
  Widget build(BuildContext context) {
    final head = entries.take(2).toList(growable: false);
    final rest = entries.length - head.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in head) ...[
            _EntryRow(
              selected: selectedId == e.id,
              type: e.event.type,
              title: _formatTitle(e.event.type, e.event.data),
              subtitle: null,
              onTap: () => onTapEntry(e.id),
              onDelete: () => onDeleteEntry(e.id),
              compact: true,
            ),
            const SizedBox(height: 8),
          ],
          if (rest > 0)
            Text(
              '…More $rest 条',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

enum _PillTone { neutral, muted, warn }

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.tone});

  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    switch (tone) {
      case _PillTone.warn:
        fg = Colors.orangeAccent;
        bg = Colors.orange.withValues(alpha: 0.18);
        break;
      case _PillTone.muted:
        fg = Colors.white.withValues(alpha: 0.48);
        bg = Colors.white.withValues(alpha: 0.04);
        break;
      case _PillTone.neutral:
        fg = Colors.white.withValues(alpha: 0.75);
        bg = Colors.white.withValues(alpha: 0.06);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  const _TinyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _TinyHoldButton(
        icon: icon,
        onTap: onTap,
      );
}

class _TinyHoldButton extends StatefulWidget {
  const _TinyHoldButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_TinyHoldButton> createState() => _TinyHoldButtonState();
}

class _TinyHoldButtonState extends State<_TinyHoldButton> {
  Timer? _timer;
  int _ticks = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startHold() {
    _timer?.cancel();
    _ticks = 0;
    widget.onTap();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _ticks++;
      final repeats = _ticks < 8
          ? 1
          : _ticks < 20
              ? 2
              : 3;
      for (int i = 0; i < repeats; i++) {
        widget.onTap();
      }
    });
  }

  void _stopHold() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _stopHold(),
      child: Container(
        width: 28,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          widget.icon,
          size: 12,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.selected,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
    this.compact = false,
  });

  final bool selected;
  final String type;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool compact;

  static IconData _iconForType(String type) {
    switch (type) {
      case 'keyboard':
        return Icons.keyboard;
      case 'mouse_button':
        return Icons.mouse;
      case 'gamepad_button':
        return Icons.sports_esports;
      case 'delay':
        return Icons.timer;
      default:
        return Icons.gamepad;
    }
  }

  static Color _accentForType(String type) {
    switch (type) {
      case 'keyboard':
        return const Color(0xFF8AB4F8);
      case 'mouse_button':
        return const Color(0xFFA5D6A7);
      case 'gamepad_button':
        return const Color(0xFFFFD180);
      case 'delay':
        return const Color(0xFFB39DDB);
      default:
        return Colors.white.withValues(alpha: 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.fromLTRB(10, compact ? 8 : 10, 6, compact ? 8 : 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.lightBlueAccent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.lightBlueAccent.withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _accentForType(type).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: _accentForType(type).withValues(alpha: 0.20)),
              ),
              child: Icon(
                _iconForType(type),
                size: 16,
                color: _accentForType(type).withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close, color: Colors.white30),
              visualDensity: VisualDensity.compact,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTitle(String type, Map<String, dynamic> data) {
  switch (type) {
    case 'delay':
      return '延时标记';
    case 'keyboard':
      final isDown = data['isDown'] == true;
      final label = macroInputGlyphLabel(type: 'keyboard', data: {
        'key': data['key'],
        if (data['modifiers'] is List) 'modifiers': data['modifiers'],
      });
      return isDown ? '按下 $label' : '抬起 $label';
    case 'mouse_button':
      final isDown = data['isDown'] == true;
      final label = macroInputGlyphLabel(
          type: 'mouse_button', data: {'button': data['button']});
      return isDown ? '按下 $label' : '抬起 $label';
    case 'gamepad_button':
      final isDown = data['isDown'] == true;
      final label = macroInputGlyphLabel(
          type: 'gamepad_button', data: {'button': data['button']});
      return isDown ? '按下 $label' : '抬起 $label';
    case 'mouse_wheel':
      final dir = data['direction']?.toString() ?? '?';
      final delta = (data['delta'] as num?)?.toInt();
      return delta == null ? dir : '$dir $delta';
    case 'mouse_wheel_vector':
      return '滚轮';
    case 'gamepad_axis':
      final label = macroInputGlyphLabel(
          type: 'gamepad_axis', data: {'axisId': data['axisId']});
      return '摇杆 $label';
    case 'joystick':
      return '摇杆（虚拟）';
    case 'custom':
      final id = data['id']?.toString() ?? '?';
      return '自定义 $id';
    default:
      return type;
  }
}

String? _formatSubtitle(String type, Map<String, dynamic> data) {
  String fmtNum(num? v) {
    if (v == null) return '?';
    final d = v.toDouble();
    final s = d.toStringAsFixed(2);
    return s
        .replaceAll(RegExp(r'\.00$'), '')
        .replaceAll(RegExp(r'(\.\d)0$'), r'$1');
  }

  switch (type) {
    case 'delay':
      return null;
    case 'keyboard':
      final key = data['key']?.toString();
      final mods = List<String>.from(data['modifiers'] as List? ?? const []);
      if (key == null) return mods.isEmpty ? null : mods.join('+');
      if (mods.isEmpty) return 'key=$key';
      return 'key=$key  mods=${mods.join('+')}';
    case 'mouse_button':
      final btn = data['button']?.toString();
      return btn == null ? null : 'button=$btn';
    case 'gamepad_button':
      final btn = data['button']?.toString();
      return btn == null ? null : 'button=$btn';
    case 'mouse_wheel':
      final dir = data['direction']?.toString();
      final delta = (data['delta'] as num?)?.toInt();
      if (dir == null && delta == null) return null;
      if (dir != null && delta != null) return 'dir=$dir  delta=$delta';
      if (dir != null) return 'dir=$dir';
      return 'delta=$delta';
    case 'mouse_wheel_vector':
      final dx = data['dx'] as num?;
      final dy = data['dy'] as num?;
      if (dx == null && dy == null) return null;
      return 'dx=${fmtNum(dx)}  dy=${fmtNum(dy)}';
    case 'gamepad_axis':
      final axisId = data['axisId']?.toString();
      final x = data['x'] as num?;
      final y = data['y'] as num?;
      final parts = <String>[];
      if (axisId != null) parts.add('axis=$axisId');
      if (x != null) parts.add('x=${fmtNum(x)}');
      if (y != null) parts.add('y=${fmtNum(y)}');
      return parts.isEmpty ? null : parts.join('  ');
    case 'joystick':
      final dx = data['dx'] as num?;
      final dy = data['dy'] as num?;
      final activeKeys =
          List<String>.from(data['activeKeys'] as List? ?? const []);
      final parts = <String>[];
      if (dx != null || dy != null) {
        parts.add('dx=${fmtNum(dx)}  dy=${fmtNum(dy)}');
      }
      if (activeKeys.isNotEmpty) {
        final head = activeKeys.take(3).join('+');
        final more = activeKeys.length > 3 ? '…' : '';
        parts.add('keys=$head$more');
      }
      return parts.isEmpty ? null : parts.join('  ');
    case 'custom':
      final id = data['id']?.toString();
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : const <String, dynamic>{};
      final parts = <String>[];
      if (id != null) parts.add('id=$id');
      if (payload.isNotEmpty) {
        final keys = payload.keys.take(3).join(',');
        final more = payload.length > 3 ? ',…' : '';
        parts.add('data=$keys$more');
      }
      return parts.isEmpty ? null : parts.join('  ');
    default:
      return data.isEmpty ? null : data.toString();
  }
}
