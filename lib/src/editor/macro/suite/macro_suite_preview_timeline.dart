part of '../macro_suite_page.dart';

class _PreviewTimeline extends StatefulWidget {
  const _PreviewTimeline({
    required this.steps,
    required this.durationMs,
    required this.displayDurationMs,
    required this.axisWarpOpsByLaneKey,
    required this.axisSelectionSpanMs,
    required this.rulerScrollController,
    required this.trackHorizontalScrollController,
    required this.axisScrollController,
    required this.trackScrollController,
    required this.zoom,
    required this.selected,
    required this.onSelectedChanged,
    required this.onResizeDownUp,
    required this.onAdjustAxisWarp,
    required this.onCommitAxisWarp,
    required this.onZoomChanged,
  });

  final List<_StepEntry> steps;
  final int durationMs;
  final int displayDurationMs;
  final Map<String, List<_AxisWarpOp>> axisWarpOpsByLaneKey;
  final int axisSelectionSpanMs;
  final ScrollController rulerScrollController;
  final ScrollController trackHorizontalScrollController;
  final ScrollController axisScrollController;
  final ScrollController trackScrollController;
  final double zoom;
  final _SelectedSegment? selected;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;
  final void Function(
    String downId,
    String upId, {
    required int deltaStartMs,
    required int deltaEndMs,
  }) onResizeDownUp;
  final void Function(
    String laneKey, {
    required int deltaStartMs,
    required int deltaEndMs,
  }) onAdjustAxisWarp;
  final ValueChanged<_SelectedSegment> onCommitAxisWarp;
  final ValueChanged<double> onZoomChanged;

  @override
  State<_PreviewTimeline> createState() => _PreviewTimelineState();
}

class _PreviewTimelineState extends State<_PreviewTimeline> {
  double _zoomGestureBase = 1.0;
  bool _pinching = false;
  int _activePointers = 0;
  ScrollHoldController? _holdH;
  ScrollHoldController? _holdV;
  ScrollHoldController? _holdR;
  ScrollHoldController? _holdA;

  void _beginPinchMode() {
    _holdH ??= widget.trackHorizontalScrollController.hasClients
        ? widget.trackHorizontalScrollController.position.hold(() {})
        : null;
    _holdV ??= widget.trackScrollController.hasClients
        ? widget.trackScrollController.position.hold(() {})
        : null;
    _holdR ??= widget.rulerScrollController.hasClients
        ? widget.rulerScrollController.position.hold(() {})
        : null;
    _holdA ??= widget.axisScrollController.hasClients
        ? widget.axisScrollController.position.hold(() {})
        : null;
  }

  void _endPinchMode() {
    _holdH?.cancel();
    _holdV?.cancel();
    _holdR?.cancel();
    _holdA?.cancel();
    _holdH = null;
    _holdV = null;
    _holdR = null;
    _holdA = null;
  }

  @override
  void dispose() {
    _endPinchMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordered = widget.steps.toList()
      ..sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
    final lanes = _buildLanes(ordered, durationMs: widget.durationMs);
    final selected = widget.selected;

    const axisWidth = 70.0;
    const rulerHeight = 30.0;
    const baseRowHeight = 32.0;
    const axisRowHeight = 44.0;
    final laneHeights = lanes
        .map((l) => (l.type == 'joystick' || l.type == 'gamepad_axis')
            ? axisRowHeight
            : baseRowHeight)
        .toList(growable: false);
    final laneTopByKey = <String, double>{};
    final laneHeightByKey = <String, double>{};
    var acc = 0.0;
    for (var i = 0; i < lanes.length; i++) {
      final lane = lanes[i];
      final h = laneHeights[i];
      laneTopByKey[lane.key] = acc;
      laneHeightByKey[lane.key] = h;
      acc += h;
    }
    final totalHeight = acc;
    const leftPad = 12.0;
    const rightPad = 20.0;
    final pxPerMs = 0.14 * widget.zoom;
    final contentWidth = (widget.displayDurationMs.clamp(0, 999999) * pxPerMs) +
        leftPad +
        rightPad;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _activePointers++;
        if (_activePointers == 2) {
          _zoomGestureBase = widget.zoom;
          _beginPinchMode();
          setState(() => _pinching = true);
        }
      },
      onPointerUp: (_) {
        _activePointers = (_activePointers - 1).clamp(0, 999);
        if (_activePointers < 2 && _pinching) {
          _endPinchMode();
          setState(() => _pinching = false);
        }
      },
      onPointerCancel: (_) {
        _activePointers = (_activePointers - 1).clamp(0, 999);
        if (_activePointers < 2 && _pinching) {
          _endPinchMode();
          setState(() => _pinching = false);
        }
      },
      onPointerSignal: (signal) {
        if (signal is PointerScaleEvent) {
          final next = (widget.zoom * signal.scale).clamp(0.4, 20.0);
          widget.onZoomChanged(next);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelectedChanged(null),
        onScaleStart: (d) {
          if (d.pointerCount < 2) return;
          _zoomGestureBase = widget.zoom;
          if (!_pinching) {
            _beginPinchMode();
            setState(() => _pinching = true);
          }
        },
        onScaleUpdate: (d) {
          if (d.pointerCount < 2) return;
          final next = (_zoomGestureBase * d.scale).clamp(0.4, 20.0);
          widget.onZoomChanged(next);
        },
        onScaleEnd: (_) {
          if (_activePointers < 2 && _pinching) {
            _endPinchMode();
            setState(() => _pinching = false);
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: ClipRRect(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: [
                SizedBox(
                  height: rulerHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: axisWidth,
                        height: rulerHeight,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              width: axisWidth / 2,
                              height: rulerHeight,
                              child: InkWell(
                                onTap: () => widget.onZoomChanged(
                                  (widget.zoom / 1.15).clamp(0.4, 20.0),
                                ),
                                child: const Icon(Icons.remove,
                                    color: Colors.white60, size: 12),
                              ),
                            ),
                            SizedBox(
                              width: axisWidth / 2,
                              height: rulerHeight,
                              child: InkWell(
                                onTap: () => widget.onZoomChanged(
                                  (widget.zoom * 1.15).clamp(0.4, 20.0),
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white60, size: 12),
                              ),
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
                              durationMs: widget.displayDurationMs,
                              pxPerMs: pxPerMs,
                              leftPad: leftPad,
                              height: rulerHeight,
                            ),
                          ),
                        ),
                      )),
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
                            itemBuilder: (context, index) => SizedBox(
                              height: laneHeights[index],
                              child: _PreviewLaneLabelRow(
                                  lane: lanes[index], index: index),
                            ),
                          )),
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
                                      durationMs: widget.displayDurationMs,
                                      pxPerMs: pxPerMs,
                                      leftPad: leftPad,
                                      height: totalHeight,
                                    ),
                                  ),
                                ),
                                ListView.builder(
                                  controller: widget.trackScrollController,
                                  physics: _pinching
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                                  itemCount: lanes.length,
                                  itemBuilder: (context, index) {
                                    final lane = lanes[index];
                                    if (lane.type == 'joystick' ||
                                        lane.type == 'gamepad_axis') {
                                      return SizedBox(
                                        height: laneHeights[index],
                                        child: _AxisLaneInteractive(
                                          lane: lane,
                                          laneIndex: index,
                                          rowHeight: laneHeights[index],
                                          leftPad: leftPad,
                                          pxPerMs: pxPerMs,
                                          displayDurationMs:
                                              widget.displayDurationMs,
                                          axisWarpOps:
                                              widget.axisWarpOpsByLaneKey[
                                                      lane.key] ??
                                                  [],
                                          axisSelectionSpanMs:
                                              widget.axisSelectionSpanMs,
                                          selected: widget.selected,
                                          onSelectedChanged:
                                              widget.onSelectedChanged,
                                        ),
                                      );
                                    }
                                    return SizedBox(
                                      height: laneHeights[index],
                                      child: _PreviewLaneRow(
                                        lane: lane,
                                        laneIndex: index,
                                        rowHeight: laneHeights[index],
                                        leftPad: leftPad,
                                        pxPerMs: pxPerMs,
                                        selected: widget.selected,
                                        onSelectedChanged:
                                            widget.onSelectedChanged,
                                      ),
                                    );
                                  },
                                ),
                                if (selected != null)
                                  _NeedleOverlay(
                                    lanes: lanes,
                                    selected: selected,
                                    leftPad: leftPad,
                                    pxPerMs: pxPerMs,
                                    laneTopByKey: laneTopByKey,
                                    laneHeightByKey: laneHeightByKey,
                                    contentHeight: totalHeight,
                                    onSelectedChanged: widget.onSelectedChanged,
                                    onResizeDownUp: widget.onResizeDownUp,
                                    onAdjustAxisWarp: widget.onAdjustAxisWarp,
                                    onCommitAxisWarp: widget.onCommitAxisWarp,
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
          samplesX: s.samplesX.toList(growable: false),
          samplesY: s.samplesY.toList(growable: false),
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

        double? valX;
        double? valY;

        if (e.type == 'gamepad_axis') {
          valX = (e.data['x'] as num?)?.toDouble() ?? 0;
          valY = (e.data['y'] as num?)?.toDouble() ?? 0;
        } else if (e.type == 'joystick') {
          valX = (e.data['dx'] as num?)?.toDouble() ?? 0;
          valY = (e.data['dy'] as num?)?.toDouble() ?? 0;
        }

        if (valX != null) {
          next.samplesX.add((ms: at, val: valX));
        }
        if (valY != null) {
          next.samplesY.add((ms: at, val: valY));
        }

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

    // Sort lanes by type and key
    laneOrder.sort((a, b) {
      final laneA = lanesByKey[a]!;
      final laneB = lanesByKey[b]!;

      // Order: Joystick > Gamepad Axis > Keyboard > Gamepad Button > Mouse Button > Others
      int typeScore(String type) {
        if (type == 'joystick') return 0;
        if (type == 'gamepad_axis') return 1;
        if (type == 'keyboard') return 2;
        if (type == 'gamepad_button') return 3;
        if (type == 'mouse_button') return 4;
        return 99;
      }

      final scoreA = typeScore(laneA.type);
      final scoreB = typeScore(laneB.type);
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);

      return laneA.label.compareTo(laneB.label);
    });

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
  });

  final _PreviewLane lane;
  final int laneIndex;
  final double rowHeight;
  final double leftPad;
  final double pxPerMs;
  final _SelectedSegment? selected;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;

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
                segment: seg,
                lane: lane,
                selected: selected,
                onSelectedChanged: onSelectedChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class _AxisLaneInteractive extends StatefulWidget {
  const _AxisLaneInteractive({
    required this.lane,
    required this.laneIndex,
    required this.rowHeight,
    required this.leftPad,
    required this.pxPerMs,
    required this.displayDurationMs,
    required this.axisWarpOps,
    required this.axisSelectionSpanMs,
    required this.selected,
    required this.onSelectedChanged,
  });

  final _PreviewLane lane;
  final int laneIndex;
  final double rowHeight;
  final double leftPad;
  final double pxPerMs;
  final int displayDurationMs;
  final List<_AxisWarpOp> axisWarpOps;
  final int axisSelectionSpanMs;
  final _SelectedSegment? selected;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;

  @override
  State<_AxisLaneInteractive> createState() => _AxisLaneInteractiveState();
}

class _AxisLaneInteractiveState extends State<_AxisLaneInteractive> {
  void _selectAtMs(int ms) {
    final ops = widget.axisWarpOps;
    final clickedOp = ops.isEmpty
        ? null
        : ops.cast<_AxisWarpOp?>().firstWhere(
              (op) => ms >= op!.mappedStartMs && ms <= op.mappedEndMs,
              orElse: () => null,
            );

    if (clickedOp != null) {
      widget.onSelectedChanged(
        _SelectedSegment(
          id: clickedOp.id,
          laneKey: widget.lane.key,
          type: widget.lane.type,
          startMs: clickedOp.mappedStartMs,
          endMs: clickedOp.mappedEndMs,
          entryIds: const [],
          originStartMs: clickedOp.originStartMs,
          originEndMs: clickedOp.originEndMs,
          applyAxisWarp: true,
          axisWarpId: clickedOp.id,
        ),
      );
      return;
    }

    final span = widget.axisSelectionSpanMs.clamp(200, 20000);
    final start = (ms - span ~/ 2).clamp(0, widget.displayDurationMs);
    final end = (start + span).clamp(start, widget.displayDurationMs);

    widget.onSelectedChanged(
      _SelectedSegment(
        id: 'axis_sel_${DateTime.now().microsecondsSinceEpoch}',
        laneKey: widget.lane.key,
        type: widget.lane.type,
        startMs: start,
        endMs: end,
        entryIds: const [],
        applyAxisWarp: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg =
        Colors.white.withValues(alpha: widget.laneIndex.isEven ? 0.00 : 0.015);
    final s = widget.selected;
    final isSelectedLane = s != null && s.laneKey == widget.lane.key;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (d) {
        final localX = d.localPosition.dx - widget.leftPad;
        if (widget.pxPerMs <= 0) return;
        final ms = (localX / widget.pxPerMs).toInt();
        _selectAtMs(ms);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: SizedBox(
          height: widget.rowHeight,
          child: Stack(
            children: [
              Positioned.fill(
                left: widget.leftPad,
                child: CustomPaint(
                  painter: _AxisLanePainter(
                    lane: widget.lane,
                    pxPerMs: widget.pxPerMs,
                    highlightStartMs: isSelectedLane ? s.startMs : null,
                    highlightEndMs: isSelectedLane ? s.endMs : null,
                    highlightShiftPx: 0,
                    axisWarpOps: widget.axisWarpOps,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                ' ×$count',
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
    required this.laneTopByKey,
    required this.laneHeightByKey,
    required this.contentHeight,
    required this.onSelectedChanged,
    required this.onResizeDownUp,
    this.onAdjustAxisWarp,
    this.onCommitAxisWarp,
  });

  final List<_PreviewLane> lanes;
  final _SelectedSegment selected;
  final double leftPad;
  final double pxPerMs;
  final Map<String, double> laneTopByKey;
  final Map<String, double> laneHeightByKey;
  final double contentHeight;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;
  final void Function(
    String downId,
    String upId, {
    required int deltaStartMs,
    required int deltaEndMs,
  }) onResizeDownUp;
  final void Function(
    String laneKey, {
    required int deltaStartMs,
    required int deltaEndMs,
  })? onAdjustAxisWarp;
  final ValueChanged<_SelectedSegment>? onCommitAxisWarp;

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
    final isAxisLike = s.type == 'joystick' || s.type == 'gamepad_axis';
    final canResize = !isAxisLike && s.entryIds.length == 2;
    final laneTop = (widget.laneTopByKey[s.laneKey] ?? 0.0)
        .clamp(0.0, widget.contentHeight);
    final laneHeight = (widget.laneHeightByKey[s.laneKey] ?? 32.0)
        .clamp(0.0, widget.contentHeight);

    Widget needle({
      required double x,
      required bool isStart,
    }) {
      const knobSize = 22.0;
      final knobTop = (laneTop +
              (isStart ? 0.0 : (laneHeight - knobSize).clamp(0.0, 999999.0)))
          .clamp(0.0, widget.contentHeight - knobSize);

      return Stack(
        children: [
          Positioned(
            left: x - 1,
            top: 0,
            width: 2,
            height: widget.contentHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            left: x - knobSize / 2,
            top: knobTop,
            width: knobSize,
            height: knobSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                _startResidDx = 0;
                _endResidDx = 0;
              },
              onHorizontalDragUpdate: (d) {
                final deltaMs = isStart
                    ? _consumeStartDx(d.delta.dx)
                    : _consumeEndDx(d.delta.dx);
                if (deltaMs == 0) return;

                if (isAxisLike) {
                  if (s.entryIds.isEmpty && widget.onAdjustAxisWarp != null) {
                    widget.onAdjustAxisWarp!(
                      s.laneKey,
                      deltaStartMs: isStart ? deltaMs : 0,
                      deltaEndMs: isStart ? 0 : deltaMs,
                    );
                  }
                  return;
                }

                if (canResize) {
                  widget.onResizeDownUp(
                    s.entryIds.first,
                    s.entryIds.last,
                    deltaStartMs: isStart ? deltaMs : 0,
                    deltaEndMs: isStart ? 0 : deltaMs,
                  );
                }
              },
              onHorizontalDragEnd: (_) {
                if (isAxisLike && widget.onCommitAxisWarp != null) {
                  widget.onCommitAxisWarp!(s);
                }
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(knobSize / 2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  isStart ? Icons.arrow_left : Icons.arrow_right,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget bodyDragArea() {
      if (!isAxisLike) return const SizedBox();
      if (endX <= startX) return const SizedBox();
      return Positioned(
        left: startX + 16,
        top: laneTop,
        width: (endX - startX - 32).clamp(0.0, 99999.0),
        height: laneHeight,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            _startResidDx = 0;
            _endResidDx = 0;
          },
          onHorizontalDragUpdate: (d) {
            final deltaMs = _consumeStartDx(d.delta.dx);
            if (deltaMs == 0) return;

            if (widget.onAdjustAxisWarp != null) {
              widget.onAdjustAxisWarp!(
                s.laneKey,
                deltaStartMs: deltaMs,
                deltaEndMs: deltaMs,
              );
            }
          },
          onHorizontalDragEnd: (_) {
            if (isAxisLike && widget.onCommitAxisWarp != null) {
              widget.onCommitAxisWarp!(s);
            }
          },
          child: Container(color: Colors.transparent),
        ),
      );
    }

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          bodyDragArea(),
          needle(x: startX, isStart: true),
          needle(x: endX, isStart: false),
        ],
      ),
    );
  }
}

class _SegmentDraggable extends StatefulWidget {
  const _SegmentDraggable({
    required this.segment,
    required this.lane,
    required this.selected,
    required this.onSelectedChanged,
  });

  final _PreviewSegment segment;
  final _PreviewLane lane;
  final _SelectedSegment? selected;
  final ValueChanged<_SelectedSegment?> onSelectedChanged;

  @override
  State<_SegmentDraggable> createState() => _SegmentDraggableState();
}

class _SegmentDraggableState extends State<_SegmentDraggable> {
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: baseFillColor,
                borderRadius: BorderRadius.circular(selected ? 1 : 5),
                border: selected
                    ? const Border.symmetric(
                        horizontal:
                            BorderSide(width: 1, color: Colors.amberAccent))
                    : Border.all(color: baseBorderColor),
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

    int chooseMinorStepMs() {
      const candidates = [
        1,
        2,
        5,
        10,
        20,
        50,
        100,
        200,
        500,
        1000,
        2000,
        5000,
        10000
      ];
      const minSpacingPx = 2.0;
      final ppm = pxPerMs <= 0 ? 0.0001 : pxPerMs;
      for (final ms in candidates) {
        if (ms * ppm >= minSpacingPx) return ms;
      }
      return candidates.last;
    }

    int chooseMajorEveryMs(int minorMs) {
      const multipliers = [5, 10, 20, 50, 100];
      const majorSpacingPx = 70.0;
      final ppm = pxPerMs <= 0 ? 0.0001 : pxPerMs;
      for (final m in multipliers) {
        final major = minorMs * m;
        if (major * ppm >= majorSpacingPx) return major;
      }
      return minorMs * multipliers.last;
    }

    final step = chooseMinorStepMs();
    final majorEvery = chooseMajorEveryMs(step);

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

    int chooseMinorStepMs() {
      const candidates = [
        1,
        2,
        5,
        10,
        20,
        50,
        100,
        200,
        500,
        1000,
        2000,
        5000,
        10000
      ];
      const minSpacingPx = 2.0;
      final ppm = pxPerMs <= 0 ? 0.0001 : pxPerMs;
      for (final ms in candidates) {
        if (ms * ppm >= minSpacingPx) return ms;
      }
      return candidates.last;
    }

    int chooseMajorEveryMs(int minorMs) {
      const multipliers = [5, 10, 20, 50, 100];
      const majorSpacingPx = 70.0;
      final ppm = pxPerMs <= 0 ? 0.0001 : pxPerMs;
      for (final m in multipliers) {
        final major = minorMs * m;
        if (major * ppm >= majorSpacingPx) return major;
      }
      return minorMs * multipliers.last;
    }

    final step = chooseMinorStepMs();
    final majorEvery = chooseMajorEveryMs(step);

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

class _AxisLanePainter extends CustomPainter {
  _AxisLanePainter({
    required this.lane,
    required this.pxPerMs,
    required this.highlightStartMs,
    required this.highlightEndMs,
    this.highlightShiftPx = 0,
    required this.axisWarpOps,
  });

  final _PreviewLane lane;
  final double pxPerMs;
  final int? highlightStartMs;
  final int? highlightEndMs;
  final double highlightShiftPx;
  final List<_AxisWarpOp> axisWarpOps;

  int _mapAtMs(int atMs) {
    final t = atMs.clamp(0, 999999).toInt();
    if (axisWarpOps.isEmpty) return t;
    final ordered = axisWarpOps.toList()
      ..sort((a, b) => a.originStartMs.compareTo(b.originStartMs));
    final points = <({int o, int m})>[
      (o: 0, m: 0),
      for (final op in ordered) ...[
        (o: op.originStartMs, m: op.mappedStartMs),
        (o: op.originEndMs, m: op.mappedEndMs),
      ],
    ]..sort((a, b) => a.o.compareTo(b.o));

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (t <= b.o) {
        final denom = (b.o - a.o);
        final ratio = denom == 0 ? 0.0 : (t - a.o) / denom;
        final mapped = a.m + ratio * (b.m - a.m);
        return mapped.round().clamp(0, 999999).toInt();
      }
    }
    final last = points.last;
    final shift = last.m - last.o;
    return (t + shift).clamp(0, 999999).toInt();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    var first = true;

    for (final seg in lane.segments) {
      if (seg.entryIds.isEmpty) continue;
      final t = seg.startMs;
      final mappedT = _mapAtMs(t);
      final x = mappedT * pxPerMs;

      final yBase = size.height / 2;

      // Draw X points
      if (seg.samplesX.isNotEmpty) {
        final paintX = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

        for (var i = 0; i < seg.samplesX.length; i++) {
          final s = seg.samplesX[i];
          final sx = (_mapAtMs(s.ms)) * pxPerMs;
          final sy = yBase - (s.val * 12).clamp(-14.0, 14.0);
          canvas.drawCircle(Offset(sx, sy), 1.2, paintX);
        }
      }

      // Draw Y points
      if (seg.samplesY.isNotEmpty) {
        final paintY = Paint()
          ..color = Colors.pinkAccent.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

        for (var i = 0; i < seg.samplesY.length; i++) {
          final s = seg.samplesY[i];
          final sx = (_mapAtMs(s.ms)) * pxPerMs;
          final sy = yBase - (s.val * 12).clamp(-14.0, 14.0);
          canvas.drawCircle(Offset(sx, sy), 1.2, paintY);
        }
      }

      // If neither, draw center line
      if (seg.samplesX.isEmpty && seg.samplesY.isEmpty) {
        final startX = (_mapAtMs(seg.startMs)) * pxPerMs;
        final endX = (_mapAtMs(seg.endMs)) * pxPerMs;
        final pathLine = Path()
          ..moveTo(startX, yBase)
          ..lineTo(endX, yBase);
        canvas.drawPath(pathLine, paintLine);
      }
    }
    canvas.drawPath(path, paintLine);

    if (highlightStartMs != null && highlightEndMs != null) {
      final paintSel = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      final startX = highlightStartMs! * pxPerMs + highlightShiftPx;
      final endX = highlightEndMs! * pxPerMs + highlightShiftPx;
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        paintSel,
      );

      final paintBorder = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        paintBorder,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AxisLanePainter oldDelegate) {
    return oldDelegate.lane != lane ||
        oldDelegate.pxPerMs != pxPerMs ||
        oldDelegate.highlightStartMs != highlightStartMs ||
        oldDelegate.highlightEndMs != highlightEndMs ||
        oldDelegate.highlightShiftPx != highlightShiftPx ||
        oldDelegate.axisWarpOps !=
            axisWarpOps; // list equality check might be shallow but ok for now
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
    this.samplesX = const [],
    this.samplesY = const [],
  });

  final int startMs;
  final int endMs;
  final String type;
  final List<String> entryIds;
  final List<({int ms, double val})> samplesX;
  final List<({int ms, double val})> samplesY;
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
  final List<({int ms, double val})> samplesX = [];
  final List<({int ms, double val})> samplesY = [];
}
