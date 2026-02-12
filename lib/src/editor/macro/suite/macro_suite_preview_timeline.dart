part of '../macro_suite_page.dart';

class _PreviewTimeline extends StatefulWidget {
  const _PreviewTimeline({
    required this.steps,
    required this.durationMs,
    required this.rulerScrollController,
    required this.trackHorizontalScrollController,
    required this.axisScrollController,
    required this.trackScrollController,
    required this.zoom,
    required this.selected,
    required this.onSelectedChanged,
    required this.onMoveSegment,
    required this.onResizeDownUp,
    required this.onZoomChanged,
  });

  final List<_StepEntry> steps;
  final int durationMs;
  final ScrollController rulerScrollController;
  final ScrollController trackHorizontalScrollController;
  final ScrollController axisScrollController;
  final ScrollController trackScrollController;
  final double zoom;
  final _SelectedSegment? selected;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;
  final void Function(List<String> entryIds, int deltaMs) onMoveSegment;
  final void Function(
    String downId,
    String upId, {
    required int deltaStartMs,
    required int deltaEndMs,
  }) onResizeDownUp;
  final ValueChanged<double> onZoomChanged;

  @override
  State<_PreviewTimeline> createState() => _PreviewTimelineState();
}

class _PreviewTimelineState extends State<_PreviewTimeline> {
  double _zoomGestureBase = 1.0;
  bool _pinching = false;

  @override
  Widget build(BuildContext context) {
    final ordered = widget.steps.toList()
      ..sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
    final lanes = _buildLanes(ordered, durationMs: widget.durationMs);
    final selected = widget.selected;
    final showNeedle = selected != null &&
        selected.type != 'joystick' &&
        selected.type != 'gamepad_axis';

    const axisWidth = 80.0;
    const rulerHeight = 30.0;
    const rowHeight = 32.0;
    const leftPad = 12.0;
    const rightPad = 20.0;
    final pxPerMs = 0.14 * widget.zoom;
    final contentWidth =
        (widget.durationMs.clamp(0, 999999) * pxPerMs) + leftPad + rightPad;

    return GestureDetector(
      onTap: () => widget.onSelectedChanged(null),
      onScaleStart: (d) {
        if (d.pointerCount < 2) return;
        _zoomGestureBase = widget.zoom;
        setState(() => _pinching = true);
      },
      onScaleUpdate: (d) {
        if (d.pointerCount < 2) return;
        final next = (_zoomGestureBase * d.scale).clamp(0.4, 4.0);
        widget.onZoomChanged(next);
      },
      onScaleEnd: (_) => setState(() => _pinching = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              SizedBox(
                height: rulerHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: axisWidth,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => widget.onZoomChanged(
                              (widget.zoom / 1.15).clamp(0.4, 4.0),
                            ),
                            icon: const Icon(Icons.remove,
                                color: Colors.white60, size: 12),
                            visualDensity: VisualDensity.compact,
                            tooltip: '缩小',
                          ),
                          IconButton(
                            onPressed: () => widget.onZoomChanged(
                              (widget.zoom * 1.15).clamp(0.4, 4.0),
                            ),
                            icon: const Icon(Icons.add,
                                color: Colors.white60, size: 12),
                            visualDensity: VisualDensity.compact,
                            tooltip: '放大',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: widget.rulerScrollController,
                        physics: _pinching
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: contentWidth,
                          height: rulerHeight,
                          child: CustomPaint(
                            painter: _TimeRulerPainter(
                              durationMs: widget.durationMs,
                              pxPerMs: pxPerMs,
                              leftPad: leftPad,
                              height: rulerHeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: axisWidth,
                      child: ListView.builder(
                        controller: widget.axisScrollController,
                        physics: _pinching
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        itemCount: lanes.length,
                        itemExtent: rowHeight,
                        itemBuilder: (context, index) => _PreviewLaneLabelRow(
                            lane: lanes[index], index: index),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: widget.trackHorizontalScrollController,
                        physics: _pinching
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: contentWidth,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _TimeGridPainter(
                                    durationMs: widget.durationMs,
                                    pxPerMs: pxPerMs,
                                    leftPad: leftPad,
                                    height: lanes.length * rowHeight,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                controller: widget.trackScrollController,
                                physics: _pinching
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                itemCount: lanes.length,
                                itemExtent: rowHeight,
                                itemBuilder: (context, index) =>
                                    _PreviewLaneRow(
                                  lane: lanes[index],
                                  laneIndex: index,
                                  rowHeight: rowHeight,
                                  leftPad: leftPad,
                                  pxPerMs: pxPerMs,
                                  selected: widget.selected,
                                  onSelectedChanged: widget.onSelectedChanged,
                                  onMoveSegment: widget.onMoveSegment,
                                ),
                              ),
                              if (showNeedle)
                                _NeedleOverlay(
                                  lanes: lanes,
                                  selected: selected,
                                  leftPad: leftPad,
                                  pxPerMs: pxPerMs,
                                  contentHeight: lanes.length * rowHeight,
                                  onSelectedChanged: widget.onSelectedChanged,
                                  onMoveSegment: widget.onMoveSegment,
                                  onResizeDownUp: widget.onResizeDownUp,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_PreviewLane> _buildLanes(
    List<_StepEntry> ordered, {
    required int durationMs,
  }) {
    final lanesByKey = <String, _PreviewLane>{};
    final laneOrder = <String>[];

    _PreviewLane laneFor(String key, _PreviewLane lane) {
      final existing = lanesByKey[key];
      if (existing != null) return existing;
      lanesByKey[key] = lane;
      laneOrder.add(key);
      return lane;
    }

    final openDown = <String, _StepEntry>{};
    final laneGlyphData = <String, Map<String, dynamic>>{};
    final axisSession = <String, _AxisSession>{};

    void flushAxisSession(String key) {
      final s = axisSession.remove(key);
      if (s == null) return;
      if (s.startAtMs == null || s.lastAtMs == null) return;
      final start = s.startAtMs!.clamp(0, 999999);
      final end = s.lastAtMs!.clamp(start, 999999);
      final lane = laneFor(
        key,
        _PreviewLane(
          key: key,
          type: s.type,
          label: s.label,
          glyphData: s.glyphData,
          segments: [],
        ),
      );
      lane.segments.add(
        _PreviewSegment(
          startMs: start,
          endMs: end,
          type: s.type,
          entryIds: s.entryIds.toList(growable: false),
        ),
      );
    }

    for (final step in ordered) {
      final e = step.event;
      final at = e.atMs.clamp(0, 999999);

      final identity = _identityForPreview(e);
      if (identity == null) continue;

      final isAxis = e.type == 'joystick' || e.type == 'gamepad_axis';
      laneGlyphData[identity] ??= _glyphDataForEvent(e);

      if (isAxis) {
        final prev = axisSession[identity];
        final gapOk = prev == null || (at - (prev.lastAtMs ?? at)) <= 120;
        if (!gapOk) {
          flushAxisSession(identity);
        }
        final next = axisSession.putIfAbsent(
          identity,
          () => _AxisSession(
            type: e.type,
            label: _labelForIdentity(e),
            glyphData: _glyphDataForEvent(e),
          ),
        );
        next.startAtMs ??= at;
        next.lastAtMs = at;
        next.entryIds.add(step.id);
        continue;
      }

      final isDown = e.data['isDown'] == true;
      if (isDown) {
        if (!openDown.containsKey(identity)) {
          openDown[identity] = step;
        }
      } else {
        final down = openDown.remove(identity);
        if (down == null) continue;
        final start = down.event.atMs.clamp(0, 999999);
        final end = at.clamp(start, 999999);
        final lane = laneFor(
          identity,
          _PreviewLane(
            key: identity,
            type: e.type,
            label: _labelForIdentity(e),
            glyphData: laneGlyphData[identity] ?? _glyphDataForEvent(e),
            segments: [],
          ),
        );
        lane.segments.add(
          _PreviewSegment(
            startMs: start,
            endMs: end,
            type: e.type,
            entryIds: [down.id, step.id],
          ),
        );
      }
    }

    for (final k in axisSession.keys.toList(growable: false)) {
      flushAxisSession(k);
    }

    for (final kv in openDown.entries) {
      final down = kv.value;
      final start = down.event.atMs.clamp(0, 999999);
      final end =
          (durationMs <= 0 ? start + 80 : durationMs).clamp(start, 999999);
      final lane = laneFor(
        kv.key,
        _PreviewLane(
          key: kv.key,
          type: down.event.type,
          label: _labelForIdentity(down.event),
          glyphData: laneGlyphData[kv.key] ?? _glyphDataForEvent(down.event),
          segments: [],
        ),
      );
      lane.segments.add(
        _PreviewSegment(
          startMs: start,
          endMs: end,
          type: down.event.type,
          entryIds: [down.id],
        ),
      );
    }

    for (final lane in lanesByKey.values) {
      lane.segments.sort((a, b) => a.startMs.compareTo(b.startMs));
    }

    return laneOrder.map((k) => lanesByKey[k]!).toList(growable: false);
  }

  String? _identityForPreview(RecordedTimelineEvent e) {
    switch (e.type) {
      case 'keyboard':
        final key = e.data['key']?.toString();
        if (key == null || key.trim().isEmpty) return null;
        final normalized = KeyboardKey(key).normalized().code;
        return 'k:$normalized';
      case 'mouse_button':
        final btn = e.data['button']?.toString();
        if (btn == null || btn.trim().isEmpty) return null;
        return 'm:${normalizeMacroInputToken(btn)}';
      case 'gamepad_button':
        final btn = e.data['button']?.toString();
        if (btn == null || btn.trim().isEmpty) return null;
        final token = normalizeMacroInputToken(btn);
        return 'g:${normalizeGamepadButtonCode(token)}';
      case 'gamepad_axis':
        final axisId =
            normalizeMacroInputToken(e.data['axisId']?.toString() ?? '');
        return 'ga:$axisId';
      case 'joystick':
        return 'j:virtual';
      default:
        return null;
    }
  }

  String _labelForIdentity(RecordedTimelineEvent e) {
    return macroInputGlyphLabel(type: e.type, data: _glyphDataForEvent(e));
  }

  Map<String, dynamic> _glyphDataForEvent(RecordedTimelineEvent e) {
    switch (e.type) {
      case 'keyboard':
        return {
          'key': e.data['key'],
          if (e.data['modifiers'] is List) 'modifiers': e.data['modifiers'],
        };
      case 'mouse_button':
        return {'button': e.data['button']};
      case 'gamepad_button':
        return {'button': e.data['button']};
      case 'gamepad_axis':
        return {'axisId': e.data['axisId']};
      case 'joystick':
        return const {};
      default:
        return const {};
    }
  }
}

class _PreviewLaneRow extends StatelessWidget {
  const _PreviewLaneRow({
    required this.lane,
    required this.laneIndex,
    required this.rowHeight,
    required this.leftPad,
    required this.pxPerMs,
    required this.selected,
    required this.onSelectedChanged,
    required this.onMoveSegment,
  });

  final _PreviewLane lane;
  final int laneIndex;
  final double rowHeight;
  final double leftPad;
  final double pxPerMs;
  final _SelectedSegment? selected;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;
  final void Function(List<String> entryIds, int deltaMs) onMoveSegment;

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withValues(alpha: laneIndex.isEven ? 0.00 : 0.015);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Stack(
        children: [
          for (final seg in lane.segments)
            Positioned(
              left: leftPad + seg.startMs * pxPerMs,
              top: (rowHeight - 24) / 2,
              width: ((seg.endMs - seg.startMs) * pxPerMs).clamp(6.0, 99999.0),
              height: 24,
              child: _SegmentDraggable(
                pxPerMs: pxPerMs,
                segment: seg,
                lane: lane,
                selected: selected,
                onSelectedChanged: onSelectedChanged,
                onMoveSegment: onMoveSegment,
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewLaneLabelRow extends StatelessWidget {
  const _PreviewLaneLabelRow({
    required this.lane,
    required this.index,
  });

  final _PreviewLane lane;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withValues(alpha: index.isEven ? 0.00 : 0.015);
    final count = lane.segments.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          // right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: macroInputGlyph(
                  type: lane.type,
                  data: lane.glyphData,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${lane.label} ×$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedleOverlay extends StatefulWidget {
  const _NeedleOverlay({
    required this.lanes,
    required this.selected,
    required this.leftPad,
    required this.pxPerMs,
    required this.contentHeight,
    required this.onSelectedChanged,
    required this.onMoveSegment,
    required this.onResizeDownUp,
  });

  final List<_PreviewLane> lanes;
  final _SelectedSegment selected;
  final double leftPad;
  final double pxPerMs;
  final double contentHeight;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;
  final void Function(List<String> entryIds, int deltaMs) onMoveSegment;
  final void Function(
    String downId,
    String upId, {
    required int deltaStartMs,
    required int deltaEndMs,
  }) onResizeDownUp;

  @override
  State<_NeedleOverlay> createState() => _NeedleOverlayState();
}

class _NeedleOverlayState extends State<_NeedleOverlay> {
  double _startResidDx = 0;
  double _endResidDx = 0;

  int _consumeStartDx(double dx) {
    _startResidDx += dx;
    final unit = widget.pxPerMs;
    if (unit <= 0) return 0;
    final deltaMs = (_startResidDx / unit).truncate();
    if (deltaMs != 0) _startResidDx -= deltaMs * unit;
    return deltaMs;
  }

  int _consumeEndDx(double dx) {
    _endResidDx += dx;
    final unit = widget.pxPerMs;
    if (unit <= 0) return 0;
    final deltaMs = (_endResidDx / unit).truncate();
    if (deltaMs != 0) _endResidDx -= deltaMs * unit;
    return deltaMs;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.selected;
    final startX = widget.leftPad + s.startMs * widget.pxPerMs;
    final endX = widget.leftPad + s.endMs * widget.pxPerMs;
    final canResize = s.entryIds.length == 2;

    Widget needle({
      required double x,
      required bool isStart,
    }) {
      return Positioned(
        left: x - 16,
        top: 0,
        width: 32,
        height: widget.contentHeight,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) {
            final deltaMs = isStart
                ? _consumeStartDx(d.delta.dx)
                : _consumeEndDx(d.delta.dx);
            if (deltaMs == 0) return;

            if (canResize) {
              widget.onResizeDownUp(
                s.entryIds.first,
                s.entryIds.last,
                deltaStartMs: isStart ? deltaMs : 0,
                deltaEndMs: isStart ? 0 : deltaMs,
              );
            } else {
              if (isStart) {
                widget.onMoveSegment(s.entryIds, deltaMs);
              } else {
                final nextEnd =
                    (s.endMs + deltaMs).clamp(s.startMs, 999999).toInt();
                widget.onSelectedChanged(
                  _SelectedSegment(
                    id: s.id,
                    laneKey: s.laneKey,
                    type: s.type,
                    startMs: s.startMs,
                    endMs: nextEnd,
                    entryIds: s.entryIds,
                  ),
                );
              }
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      isStart ? Icons.arrow_left : Icons.arrow_right,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          needle(x: startX, isStart: true),
          needle(x: endX, isStart: false),
        ],
      ),
    );
  }
}

class _SegmentDraggable extends StatefulWidget {
  const _SegmentDraggable({
    required this.pxPerMs,
    required this.segment,
    required this.lane,
    required this.selected,
    required this.onSelectedChanged,
    required this.onMoveSegment,
  });

  final double pxPerMs;
  final _PreviewSegment segment;
  final _PreviewLane lane;
  final _SelectedSegment? selected;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;
  final void Function(List<String> entryIds, int deltaMs) onMoveSegment;

  @override
  State<_SegmentDraggable> createState() => _SegmentDraggableState();
}

class _SegmentDraggableState extends State<_SegmentDraggable> {
  double _bodyResidDx = 0;

  bool get _isSelected {
    final s = widget.selected;
    if (s == null) return false;
    return s.id == widget.segment.entryIds.first &&
        s.laneKey == widget.lane.key;
  }

  _SelectedSegment _asSelected() => _SelectedSegment(
        id: widget.segment.entryIds.first,
        laneKey: widget.lane.key,
        type: widget.lane.type,
        startMs: widget.segment.startMs,
        endMs: widget.segment.endMs,
        entryIds: widget.segment.entryIds,
      );

  int _consumeBodyDx(double dx) {
    _bodyResidDx += dx;
    final unit = widget.pxPerMs;
    if (unit <= 0) return 0;
    final deltaMs = (_bodyResidDx / unit).truncate();
    if (deltaMs != 0) {
      _bodyResidDx -= deltaMs * unit;
    }
    return deltaMs;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _isSelected;

    final baseBorderColor = selected
        ? Colors.white.withValues(alpha: 0.32)
        : _EntryRow._accentForType(widget.segment.type).withValues(alpha: 0.28);
    final baseFillColor = selected
        ? _EntryRow._accentForType(widget.segment.type).withValues(alpha: 0.30)
        : _EntryRow._accentForType(widget.segment.type).withValues(alpha: 0.22);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelectedChanged(_asSelected()),
      onHorizontalDragUpdate: (d) {
        if (!selected) widget.onSelectedChanged(_asSelected());
        final deltaMs = _consumeBodyDx(d.delta.dx);
        if (deltaMs != 0) {
          widget.onMoveSegment(widget.segment.entryIds, deltaMs);
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: baseFillColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: baseBorderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  _TimeRulerPainter({
    required this.durationMs,
    required this.pxPerMs,
    required this.leftPad,
    required this.height,
  });

  final int durationMs;
  final double pxPerMs;
  final double leftPad;
  final double height;

  String _fmt(int ms) {
    if (ms < 1000) return '${ms}ms';
    final s = ms / 1000.0;
    final str = s.toStringAsFixed(s >= 10 ? 0 : 1);
    return '${str}s';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintMinor = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final paintMajor = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1;

    const step = 100;
    const majorEvery = 500;

    for (int t = 0; t <= durationMs; t += step) {
      final x = leftPad + t * pxPerMs;
      final isMajor = t % majorEvery == 0;
      final h = isMajor ? height : height * 0.6;
      canvas.drawLine(
          Offset(x, 0), Offset(x, h), isMajor ? paintMajor : paintMinor);

      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: _fmt(t),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 4, height - tp.height - 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) {
    return oldDelegate.durationMs != durationMs ||
        oldDelegate.pxPerMs != pxPerMs ||
        oldDelegate.leftPad != leftPad ||
        oldDelegate.height != height;
  }
}

class _TimeGridPainter extends CustomPainter {
  _TimeGridPainter({
    required this.durationMs,
    required this.pxPerMs,
    required this.leftPad,
    required this.height,
  });

  final int durationMs;
  final double pxPerMs;
  final double leftPad;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final paintMinor = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final paintMajor = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const step = 100;
    const majorEvery = 500;

    for (int t = 0; t <= durationMs; t += step) {
      final x = leftPad + t * pxPerMs;
      final isMajor = t % majorEvery == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        isMajor ? paintMajor : paintMinor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimeGridPainter oldDelegate) {
    return oldDelegate.durationMs != durationMs ||
        oldDelegate.pxPerMs != pxPerMs ||
        oldDelegate.leftPad != leftPad ||
        oldDelegate.height != height;
  }
}

class _PreviewLane {
  _PreviewLane({
    required this.key,
    required this.type,
    required this.label,
    required this.glyphData,
    required this.segments,
  });

  final String key;
  final String type;
  final String label;
  final Map<String, dynamic> glyphData;
  final List<_PreviewSegment> segments;
}

class _PreviewSegment {
  _PreviewSegment({
    required this.startMs,
    required this.endMs,
    required this.type,
    required this.entryIds,
  });

  final int startMs;
  final int endMs;
  final String type;
  final List<String> entryIds;
}

class _AxisSession {
  _AxisSession({
    required this.type,
    required this.label,
    required this.glyphData,
  });

  final String type;
  final String label;
  final Map<String, dynamic> glyphData;
  int? startAtMs;
  int? lastAtMs;
  final List<String> entryIds = [];
}
