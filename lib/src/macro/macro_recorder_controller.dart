import 'package:flutter/foundation.dart';
import '../models/input_event.dart';
import 'recorded_timeline_event.dart';

class MacroRecorderController extends ChangeNotifier {
  bool get isRecording => _isRecording;
  List<RecordedTimelineEvent> get steps => List.unmodifiable(_steps);

  bool _isRecording = false;
  DateTime? _startAt;
  final List<RecordedTimelineEvent> _steps = [];
  static const int _quantumMs = 10;

  void start({bool clearFirst = true}) {
    if (clearFirst) _steps.clear();
    _isRecording = true;
    _startAt = null;
    notifyListeners();
  }

  void stop() {
    if (!_isRecording) return;
    _isRecording = false;
    _startAt = null;
    notifyListeners();
  }

  void clear() {
    _steps.clear();
    notifyListeners();
  }

  void record(InputEvent event) {
    if (!_isRecording) return;
    final now = DateTime.now();
    final startAt = _startAt ?? now;
    _startAt ??= now;
    final elapsedMs = now.difference(startAt).inMilliseconds.clamp(0, 999999);
    final atMs = ((elapsedMs + (_quantumMs / 2)) ~/ _quantumMs) * _quantumMs;

    final recorded = RecordedTimelineEvent.tryFromInputEvent(
      event,
      atMs: atMs,
    );
    if (recorded == null) return;
    _steps.add(recorded);
    notifyListeners();
  }

  List<Map<String, dynamic>> toJsonList() =>
      _steps.map((e) => e.toJson()).toList();

  void loadFromJsonList(List<dynamic> jsonList) {
    _steps
      ..clear()
      ..addAll(
        jsonList.whereType<Map>().map((e) =>
            RecordedTimelineEvent.fromJson(Map<String, dynamic>.from(e))),
      );
    notifyListeners();
  }
}
