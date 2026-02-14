import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../macro/macro_recorder_controller.dart';
import '../../models/identifiers.dart';
import '../../models/binding/binding.dart' as vcbind;
import '../../models/input_event.dart';
import '../../models/virtual_controller_models.dart';
import '../virtual_controller_overlay.dart';
import '../system_ui_mode_scope.dart';

class VirtualControllerMacroRecordingSession extends StatefulWidget {
  const VirtualControllerMacroRecordingSession({
    super.key,
    required this.definition,
    required this.state,
    required this.onInputEvent,
    this.opacity = 1.0,
    this.showLabels = true,
    this.initialMixHardwareInput = true,
    this.immersive = true,
  });

  final VirtualControllerLayout definition;
  final VirtualControllerState state;
  final void Function(InputEvent event) onInputEvent;
  final double opacity;
  final bool showLabels;
  final bool initialMixHardwareInput;
  final bool immersive;

  @override
  State<VirtualControllerMacroRecordingSession> createState() =>
      _VirtualControllerMacroRecordingSessionState();
}

class _VirtualControllerMacroRecordingSessionState
    extends State<VirtualControllerMacroRecordingSession> {
  final _recorder = MacroRecorderController();
  bool _mixHardwareInput = true;
  int _lastMouseButtons = 0;
  Offset _dockOffset = const Offset(12, 12);

  @override
  void initState() {
    super.initState();
    _mixHardwareInput = widget.initialMixHardwareInput;
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    _recorder.dispose();
    super.dispose();
  }

  void _onOverlayInput(InputEvent event) {
    _recorder.record(event);
    widget.onInputEvent(event);
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    if (!_mixHardwareInput) return false;
    if (!_recorder.isRecording) return false;

    final mapped = _inputEventFromHardwareKeyEvent(event);
    if (mapped == null) return false;
    _recorder.record(mapped);
    widget.onInputEvent(mapped);
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_mixHardwareInput) return;
    if (!_recorder.isRecording) return;
    if (event.kind != PointerDeviceKind.mouse) return;

    final newlyPressed = event.buttons & ~_lastMouseButtons;
    _lastMouseButtons = event.buttons;
    for (final button in _mouseButtonsFromMask(newlyPressed)) {
      final mapped = MouseButtonInputEvent.down(button);
      _recorder.record(mapped);
      widget.onInputEvent(mapped);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_mixHardwareInput) return;
    if (!_recorder.isRecording) return;
    if (event.kind != PointerDeviceKind.mouse) return;

    final released = _lastMouseButtons & ~event.buttons;
    _lastMouseButtons = event.buttons;
    for (final button in _mouseButtonsFromMask(released)) {
      final mapped = MouseButtonInputEvent.up(button);
      _recorder.record(mapped);
      widget.onInputEvent(mapped);
    }
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    if (!_mixHardwareInput) return;
    if (!_recorder.isRecording) return;
    if (event.kind != PointerDeviceKind.mouse) return;

    final delta = event.scrollDelta;
    if (delta.dx == 0 && delta.dy == 0) return;
    final mapped = MouseWheelVectorInputEvent(
        dx: delta.dx.toDouble(), dy: delta.dy.toDouble());
    _recorder.record(mapped);
    widget.onInputEvent(mapped);
  }

  @override
  Widget build(BuildContext context) {
    return SystemUiModeScope(
      mode: widget.immersive ? SystemUiMode.immersiveSticky : null,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Listener(
          onPointerDown: _handlePointerDown,
          onPointerUp: _handlePointerUp,
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) _handlePointerScroll(signal);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: VirtualControllerOverlay(
                  definition: widget.definition,
                  state: widget.state,
                  onInputEvent: _onOverlayInput,
                  opacity: widget.opacity,
                  showLabels: widget.showLabels,
                ),
              ),
              Positioned(
                left: _dockOffset.dx,
                top: _dockOffset.dy,
                child: SafeArea(
                  bottom: false,
                  child: AnimatedBuilder(
                    animation: _recorder,
                    builder: (context, _) {
                      return _Dock(
                        isRecording: _recorder.isRecording,
                        mixHardwareInput: _mixHardwareInput,
                        steps: _recorder.steps.length,
                        onToggleMixHardware: () => setState(
                            () => _mixHardwareInput = !_mixHardwareInput),
                        onStart: () => _recorder.start(clearFirst: true),
                        onStop: _recorder.stop,
                        onClear: _recorder.clear,
                        onFinish: () => Navigator.of(context).pop(
                          _recorder.toJsonList(),
                        ),
                        onDragDelta: (delta) {
                          final size = MediaQuery.sizeOf(context);
                          final insets = MediaQuery.paddingOf(context);
                          setState(() {
                            final next = _dockOffset + delta;
                            final maxX = (size.width - insets.right - 12)
                                .clamp(0.0, 999999.0);
                            final maxY = (size.height - insets.bottom - 12)
                                .clamp(0.0, 999999.0);
                            _dockOffset = Offset(
                              next.dx.clamp(insets.left + 12, maxX),
                              next.dy.clamp(insets.top + 12, maxY),
                            );
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: SafeArea(
                  bottom: false,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: '退出录制',
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

class _Dock extends StatelessWidget {
  const _Dock({
    required this.isRecording,
    required this.mixHardwareInput,
    required this.steps,
    required this.onToggleMixHardware,
    required this.onStart,
    required this.onStop,
    required this.onClear,
    required this.onFinish,
    required this.onDragDelta,
  });

  final bool isRecording;
  final bool mixHardwareInput;
  final int steps;
  final VoidCallback onToggleMixHardware;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final VoidCallback onFinish;
  final ValueChanged<Offset> onDragDelta;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => onDragDelta(d.delta),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.redAccent : Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRecording ? '录制中...' : '录制',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$steps 步',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DockButton(
                    onPressed: onToggleMixHardware,
                    icon: mixHardwareInput ? Icons.usb : Icons.usb_off,
                    label: mixHardwareInput ? '混录' : '仅虚拟',
                    color: Colors.white70,
                  ),
                  _DockButton(
                    onPressed: isRecording ? null : onStart,
                    icon: Icons.fiber_manual_record,
                    label: '开始',
                    color: Colors.redAccent,
                  ),
                  _DockButton(
                    onPressed: isRecording ? onStop : null,
                    icon: Icons.stop,
                    label: '停止',
                    color: Colors.redAccent,
                  ),
                  _DockButton(
                    onPressed: onClear,
                    icon: Icons.backspace_outlined,
                    label: '清空',
                    color: Colors.white70,
                  ),
                  _DockButton(
                    onPressed: steps == 0 ? null : onFinish,
                    icon: Icons.done,
                    label: '完成',
                    color: Colors.lightBlueAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? color : Colors.white24;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: enabled ? Colors.white24 : Colors.white10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        minimumSize: const Size(0, 34),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, height: 1)),
    );
  }
}

List<MouseButtonId> _mouseButtonsFromMask(int mask) {
  final buttons = <MouseButtonId>[];
  if ((mask & kPrimaryMouseButton) != 0) buttons.add(MouseButtonId.left);
  if ((mask & kSecondaryMouseButton) != 0) buttons.add(MouseButtonId.right);
  if ((mask & kMiddleMouseButton) != 0) buttons.add(MouseButtonId.middle);
  return buttons;
}

InputEvent? _inputEventFromHardwareKeyEvent(KeyEvent event) {
  final isDown = event is KeyDownEvent;
  final isUp = event is KeyUpEvent;
  if (!isDown && !isUp) return null;

  final code = _keyCodeFromLogicalKey(event.logicalKey);
  if (code == null) return null;

  final modifiers = _modifierCodes(excluding: event.logicalKey);

  return KeyboardInputEvent(
    key: code,
    isDown: isDown,
    modifiers: modifiers,
  );
}

List<vcbind.KeyboardKey> _modifierCodes({LogicalKeyboardKey? excluding}) {
  final pressed = HardwareKeyboard.instance.logicalKeysPressed;
  bool has(LogicalKeyboardKey k) => pressed.contains(k) && excluding != k;

  final codes = <vcbind.KeyboardKey>[];
  final ctrl = has(LogicalKeyboardKey.controlLeft) ||
      has(LogicalKeyboardKey.controlRight);
  final shift =
      has(LogicalKeyboardKey.shiftLeft) || has(LogicalKeyboardKey.shiftRight);
  final alt =
      has(LogicalKeyboardKey.altLeft) || has(LogicalKeyboardKey.altRight);
  final meta =
      has(LogicalKeyboardKey.metaLeft) || has(LogicalKeyboardKey.metaRight);

  if (ctrl) codes.add(vcbind.KeyboardKeys.controlLeft);
  if (shift) codes.add(vcbind.KeyboardKeys.shiftLeft);
  if (alt) codes.add(vcbind.KeyboardKeys.altLeft);
  if (meta) codes.add(vcbind.KeyboardKeys.metaLeft);
  return codes;
}

vcbind.KeyboardKey? _keyCodeFromLogicalKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.escape) return vcbind.KeyboardKeys.escape;
  if (key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter) {
    return vcbind.KeyboardKeys.enter;
  }
  if (key == LogicalKeyboardKey.backspace) return vcbind.KeyboardKeys.backspace;
  if (key == LogicalKeyboardKey.tab) return vcbind.KeyboardKeys.tab;
  if (key == LogicalKeyboardKey.space) return vcbind.KeyboardKeys.space;

  if (key == LogicalKeyboardKey.arrowUp) return vcbind.KeyboardKeys.arrowUp;
  if (key == LogicalKeyboardKey.arrowDown) return vcbind.KeyboardKeys.arrowDown;
  if (key == LogicalKeyboardKey.arrowLeft) return vcbind.KeyboardKeys.arrowLeft;
  if (key == LogicalKeyboardKey.arrowRight) {
    return vcbind.KeyboardKeys.arrowRight;
  }

  if (key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight) {
    return vcbind.KeyboardKeys.shiftLeft;
  }
  if (key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight) {
    return vcbind.KeyboardKeys.controlLeft;
  }
  if (key == LogicalKeyboardKey.altLeft || key == LogicalKeyboardKey.altRight) {
    return vcbind.KeyboardKeys.altLeft;
  }
  if (key == LogicalKeyboardKey.metaLeft ||
      key == LogicalKeyboardKey.metaRight) {
    return vcbind.KeyboardKeys.metaLeft;
  }

  final label = key.keyLabel.trim();
  if (label.isNotEmpty) {
    return vcbind.KeyboardKey(label).normalized();
  }

  final name = key.debugName?.trim();
  if (name == null || name.isEmpty) return null;
  return vcbind.KeyboardKey(name).normalized();
}
