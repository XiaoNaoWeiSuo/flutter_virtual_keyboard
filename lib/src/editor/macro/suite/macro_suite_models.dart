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

