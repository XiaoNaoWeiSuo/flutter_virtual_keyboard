part of '../macro_suite_page.dart';

class _StepEntry {
  _StepEntry({
    required this.id,
    required this.event,
  });

  final String id;
  RecordedTimelineEvent event;
}

class _TimeSlot {
  _TimeSlot({
    required this.atMs,
    required this.entries,
  });

  final int atMs;
  final List<_StepEntry> entries;
}

class _SelectedSegment {
  const _SelectedSegment({
    required this.id,
    required this.laneKey,
    required this.type,
    required this.startMs,
    required this.endMs,
    required this.entryIds,
    this.originStartMs,
    this.originEndMs,
    this.uiShiftPx = 0,
    this.applyAxisWarp = false,
    this.axisWarpId,
  });

  final String id;
  final String laneKey;
  final String type;
  final int startMs;
  final int endMs;
  final List<String> entryIds;
  final int? originStartMs;
  final int? originEndMs;
  final double uiShiftPx;
  final bool applyAxisWarp;
  final String? axisWarpId;
}

class _AxisWarpOp {
  const _AxisWarpOp({
    required this.id,
    required this.originStartMs,
    required this.originEndMs,
    required this.mappedStartMs,
    required this.mappedEndMs,
  });

  final String id;
  final int originStartMs;
  final int originEndMs;
  final int mappedStartMs;
  final int mappedEndMs;
}
