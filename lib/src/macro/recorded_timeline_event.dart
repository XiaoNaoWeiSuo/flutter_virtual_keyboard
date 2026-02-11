import '../models/input_event.dart';
import 'recorded_input_event.dart';

class RecordedTimelineEvent {
  const RecordedTimelineEvent({
    required this.atMs,
    required this.type,
    required this.data,
  });

  factory RecordedTimelineEvent.fromJson(Map<String, dynamic> json) {
    return RecordedTimelineEvent(
      atMs: (json['atMs'] as num?)?.toInt() ?? 0,
      type: json['type'] as String,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }

  final int atMs;
  final String type;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
        'atMs': atMs,
        'type': type,
        if (data.isNotEmpty) 'data': data,
      };

  static RecordedTimelineEvent? tryFromInputEvent(
    InputEvent event, {
    required int atMs,
  }) {
    final raw = RecordedInputEvent.tryFromInputEvent(event, delayMs: 0);
    if (raw == null) return null;
    return RecordedTimelineEvent(atMs: atMs, type: raw.type, data: raw.data);
  }

  InputEvent? toInputEvent() =>
      RecordedInputEvent(type: type, delayMs: 0, data: data).toInputEvent();
}
