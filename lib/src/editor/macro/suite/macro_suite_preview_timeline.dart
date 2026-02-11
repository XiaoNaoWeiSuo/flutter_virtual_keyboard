part of '../macro_suite_page.dart';

class _PreviewTimeline extends StatelessWidget {
  const _PreviewTimeline({
    required this.steps,
    required this.durationMs,
    required this.rulerScrollController,
    required this.trackHorizontalScrollController,
    required this.axisScrollController,
    required this.trackScrollController,
    required this.onTapEntry,
  });

  final List<_StepEntry> steps;
  final int durationMs;
  final ScrollController rulerScrollController;
  final ScrollController trackHorizontalScrollController;
  final ScrollController axisScrollController;
  final ScrollController trackScrollController;
  final ValueChanged<String> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final ordered = steps.toList()
      ..sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
    final lanes = _buildLanes(ordered, durationMs: durationMs);

    const axisWidth = 120.0;
    const rulerHeight = 30.0;
    const rowHeight = 32.0;
    const leftPad = 12.0;
    const rightPad = 20.0;
    const pxPerMs = 0.14;
    final contentWidth =
        (durationMs.clamp(0, 999999) * pxPerMs) + leftPad + rightPad;

    return DecoratedBox(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '轨道',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: rulerScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: contentWidth,
                        height: rulerHeight,
                        child: CustomPaint(
                          painter: _TimeRulerPainter(
                            durationMs: durationMs,
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
                      controller: axisScrollController,
                      itemCount: lanes.length,
                      itemExtent: rowHeight,
                      itemBuilder: (context, index) => _PreviewLaneLabelRow(
                        lane: lanes[index],
                        index: index,
                        onTapEntry: onTapEntry,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: trackHorizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: contentWidth,
                        child: CustomPaint(
                          painter: _TimeGridPainter(
                            durationMs: durationMs,
                            pxPerMs: pxPerMs,
                            leftPad: leftPad,
                            height: lanes.length * rowHeight,
                          ),
                          child: ListView.builder(
                            controller: trackScrollController,
                            itemCount: lanes.length,
                            itemExtent: rowHeight,
                            itemBuilder: (context, index) => _PreviewLaneRow(
                              lane: lanes[index],
                              laneIndex: index,
                              rowHeight: rowHeight,
                              leftPad: leftPad,
                              pxPerMs: pxPerMs,
                              onTapEntry: onTapEntry,
                            ),
                          ),
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
        final axisId = normalizeMacroInputToken(e.data['axisId']?.toString() ?? '');
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
    required this.onTapEntry,
  });

  final _PreviewLane lane;
  final int laneIndex;
  final double rowHeight;
  final double leftPad;
  final double pxPerMs;
  final ValueChanged<String> onTapEntry;

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
              child: GestureDetector(
                onTap: () => onTapEntry(seg.entryIds.first),
                child: Container(
                  decoration: BoxDecoration(
                    color: _EntryRow._accentForType(seg.type)
                        .withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _EntryRow._accentForType(seg.type)
                          .withValues(alpha: 0.28),
                    ),
                  ),
                ),
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
    required this.onTapEntry,
  });

  final _PreviewLane lane;
  final int index;
  final ValueChanged<String> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withValues(alpha: index.isEven ? 0.00 : 0.015);
    final count = lane.segments.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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

  int _pickStepMs() {
    const candidates = [50, 100, 200, 500, 1000, 2000, 5000, 10000];
    for (final s in candidates) {
      if (s * pxPerMs >= 46) return s;
    }
    return 10000;
  }

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

    final step = _pickStepMs();
    final majorEvery = step * 5;

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
              fontSize: 11,
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

  int _pickStepMs() {
    const candidates = [50, 100, 200, 500, 1000, 2000, 5000, 10000];
    for (final s in candidates) {
      if (s * pxPerMs >= 46) return s;
    }
    return 10000;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintMinor = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final paintMajor = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    final step = _pickStepMs();
    final majorEvery = step * 5;

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
