import 'package:flutter/material.dart';
import '../core/dynamic_control_factory.dart';
import '../models/identifiers.dart';
import '../models/virtual_controller_models.dart';
import '../utils/control_geometry.dart';
import '../utils/layout_state_protocol.dart';
import 'ai/layout_ai_command.dart';
import 'resize_direction.dart';

class VirtualControllerLayoutEditorController extends ChangeNotifier {
  VirtualControllerLayoutEditorController({
    required VirtualControllerLayout definition,
    required VirtualControllerState state,
    this.geometryDecorator,
    this.readOnly = false,
    this.allowAddRemove = false,
    this.allowResize = true,
    this.allowMove = true,
    this.allowRename = false,
  })  : _definition = _computeInitialDefinition(
          definition: definition,
          state: state,
          allowAddRemove: allowAddRemove,
        ),
        _definitionIds = _computeInitialDefinition(
                definition: definition,
                state: state,
                allowAddRemove: allowAddRemove)
            .controls
            .map((c) => c.id)
            .toSet(),
        _state = state,
        _layout = _applyState(
            _computeInitialDefinition(
              definition: definition,
              state: state,
              allowAddRemove: allowAddRemove,
            ),
            state);

  static VirtualControllerLayout _computeInitialDefinition({
    required VirtualControllerLayout definition,
    required VirtualControllerState state,
    required bool allowAddRemove,
  }) {
    if (!allowAddRemove) return definition;
    return buildDefinitionFromState(
      state,
      runtimeDefaults: false,
      fallbackName: definition.name,
    );
  }

  VirtualControllerLayout _definition;
  Set<String> _definitionIds;
  VirtualControllerState _state;
  VirtualControllerLayout _layout;
  VirtualControl? _selected;
  ControlLayout? _selectedBaseLayout;
  double _selectedScale = 1.0;
  bool _isDirty = false;

  final bool readOnly;
  final bool allowAddRemove;
  final bool allowResize;
  final bool allowMove;
  final bool allowRename;
  final VirtualControllerLayout Function(VirtualControllerLayout layout)?
      geometryDecorator;

  VirtualControllerLayout get layout => _layout;
  VirtualControllerLayout get definition => _definition;
  VirtualControllerState get state => _state;
  VirtualControl? get selectedControl => _selected;
  double get selectedScale => _selectedScale;
  bool get selectedStickClickEnabled {
    final selected = _selected;
    if (selected is! VirtualJoystick) return false;
    final v = _state.stateFor(selected.id)?.config['stickClickEnabled'];
    return v == true;
  }

  bool get selectedStickLockEnabled {
    final selected = _selected;
    if (selected is! VirtualJoystick) return false;
    final v = _state.stateFor(selected.id)?.config['stickLockEnabled'];
    return v == true;
  }

  bool get selectedSprintEnabled {
    final selected = _selected;
    if (selected is! VirtualJoystick) return false;
    final v = _state.stateFor(selected.id)?.config['sprintEnabled'];
    if (v is bool) return v;
    final keys = selected.keys;
    final isWasd = keys.length >= 4 &&
        keys[0].normalized().code == 'W' &&
        keys[1].normalized().code == 'A' &&
        keys[2].normalized().code == 'S' &&
        keys[3].normalized().code == 'D';
    return selected.mode == JoystickMode.keyboard && isWasd;
  }

  bool get selectedDpad3dEnabled {
    final selected = _selected;
    if (selected is! VirtualDpad) return false;
    final v = _state.stateFor(selected.id)?.config['enable3D'];
    if (v is bool) return v;
    return selected.enable3D;
  }

  bool get canDeleteSelected {
    if (readOnly || !allowAddRemove) return false;
    final selected = _selected;
    if (selected == null) return false;
    return true;
  }

  double get selectedOpacity {
    final id = _selected?.id;
    if (id == null) return 1.0;
    return (_state.stateFor(id)?.opacity ?? 1.0).clamp(0.0, 1.0);
  }

  bool get isDirty => _isDirty;


  /// Executes a list of AI commands.
  void executeAICommands(List<LayoutAICommand> commands) {
    if (readOnly) return;
    for (final cmd in commands) {
      switch (cmd.action) {
        case LayoutAIAction.add:
          _aiAddControl(cmd);
          break;
        case LayoutAIAction.remove:
          if (cmd.id != null) {
            _aiRemoveControl(cmd.id!);
          }
          break;
        case LayoutAIAction.move:
          if (cmd.id != null) {
            _aiMoveControl(cmd);
          }
          break;
        case LayoutAIAction.resize:
          if (cmd.id != null) {
            _aiResizeControl(cmd);
          }
          break;
        case LayoutAIAction.rename:
          if (cmd.id != null && cmd.label != null) {
            _aiRenameControl(cmd.id!, cmd.label!);
          }
          break;
        case LayoutAIAction.updateProperty:
          if (cmd.id != null) {
            _aiUpdateProperty(cmd);
          }
          break;
        case LayoutAIAction.clear:
          _aiClear();
          break;
        default:
          break;
      }
    }
    notifyListeners();
  }

  void _aiAddControl(LayoutAICommand cmd) {
    if (!allowAddRemove) return;
    final id = cmd.id;
    var type = cmd.type?.trim().toLowerCase();
    if (type == null || type.isEmpty) {
      final lowerId = id?.trim().toLowerCase() ?? '';
      if (lowerId.startsWith('btn_')) {
        type = 'button';
      } else if (lowerId.startsWith('joy_') || lowerId.startsWith('joystick_')) {
        type = 'joystick';
      } else if (lowerId.startsWith('dpad_')) {
        type = 'dpad';
      } else if (lowerId.startsWith('mouse_')) {
        type = 'mouse_button';
      } else if (lowerId.startsWith('key_')) {
        type = 'key';
      }
    }
    final label = cmd.label?.trim();
    final Map<String, dynamic>? config =
        (label != null && label.isNotEmpty) ? {'label': label} : null;
    final props = cmd.properties ?? const <String, dynamic>{};
    VirtualControl? control;

    ControlLayout createLayout() => ControlLayout(
          x: (cmd.x ?? 0.4).clamp(0.0, 0.9),
          y: (cmd.y ?? 0.4).clamp(0.0, 0.9),
          width: (cmd.width ?? 0.1).clamp(0.05, 0.5),
          height: (cmd.height ?? 0.1).clamp(0.05, 0.5),
        );

    if (type == 'button') {
      final rawCode = props['button'] ?? props['code'];
      final parts = id?.split('_') ?? const <String>[];
      final inferred = parts.length >= 2 ? parts[1] : null;
      final code = rawCode?.toString().trim().isNotEmpty == true
          ? rawCode.toString().trim()
          : (inferred?.trim().isNotEmpty == true ? inferred!.trim() : 'a');
      final btn = InputBindingRegistry.tryGetGamepadButton(code) ??
          InputBindingRegistry.tryGetGamepadButton('a')!;
      final nextId = (id != null && id.startsWith('btn_') && id.split('_').length >= 2)
          ? id
          : 'btn_${btn.code}_${DateTime.now().microsecondsSinceEpoch}';
      control = VirtualButton(
        id: nextId,
        label: label ?? btn.label ?? btn.code,
        layout: createLayout(),
        trigger: TriggerType.tap,
        binding: GamepadButtonBinding(btn),
        config: config ?? const {},
      );
    } else if (type == 'joystick') {
      final modeRaw = props['mode']?.toString().trim().toLowerCase();
      final stickRaw = props['stickType']?.toString() ?? '';
      final stick = GamepadStickId.tryParse(stickRaw);
      if (modeRaw == 'keyboard') {
        final scheme = props['scheme']?.toString().trim().toLowerCase();
        final prefix = scheme == 'arrows' ? 'joystick_arrows_' : 'joystick_wasd_';
        final nextId = (id != null && id.startsWith(prefix))
            ? id
            : '$prefix${DateTime.now().microsecondsSinceEpoch}';
        control = VirtualJoystick(
          id: nextId,
          label: label ?? '',
          layout: createLayout(),
          trigger: TriggerType.hold,
          config: config ?? const {},
        );
      } else {
        final useStick = stick ?? GamepadStickId.left;
        final prefix = useStick == GamepadStickId.right
            ? 'joystick_gamepad_right_'
            : 'joystick_gamepad_left_';
        final nextId = (id != null && id.startsWith(prefix))
            ? id
            : '$prefix${DateTime.now().microsecondsSinceEpoch}';
        final base = useStick == GamepadStickId.right
            ? const {
                'centerLabel': 'R',
                'overlayStyle': 'center',
                'stickClickEnabled': false,
                'stickLockEnabled': false,
              }
            : const {
                'centerLabel': 'L',
                'overlayStyle': 'center',
                'stickClickEnabled': false,
                'stickLockEnabled': false,
              };
        final nextConfig = <String, dynamic>{...base, ...(config ?? const {})};
        control = VirtualJoystick(
          id: nextId,
          label: label ?? (useStick == GamepadStickId.right ? 'RS' : 'LS'),
          layout: createLayout(),
          trigger: TriggerType.hold,
          mode: JoystickMode.gamepad,
          stickType: useStick,
          config: nextConfig,
        );
      }
    } else if (type == 'dpad') {
      final enable3D = props['enable3D'];
      control = VirtualDpad(
        id: id ?? 'dpad_${DateTime.now().millisecondsSinceEpoch}',
        label: label ?? 'D-Pad',
        layout: createLayout(),
        trigger: TriggerType.hold,
        enable3D: enable3D is bool ? enable3D : false,
        config: config ?? const {},
      );
    } else if (type == 'mouse_button') {
      final rawBtn = props['button'] ?? id?.split('_').last;
      final parsed = rawBtn is String ? MouseButtonId.tryParse(rawBtn) : null;
      final button = parsed ?? MouseButtonId.left;
      final clickType = props['clickType']?.toString();
      control = VirtualMouseButton(
        id: id ?? 'mouse_${button.code}_${DateTime.now().millisecondsSinceEpoch}',
        label: label ?? button.code.toUpperCase(),
        layout: createLayout(),
        trigger: TriggerType.tap,
        button: button,
        clickType: clickType ?? 'single',
        config: config ?? const {},
      );
    } else if (type == 'key') {
      final rawKey = props['key'] ?? label ?? id?.split('_').last ?? '';
      final key = KeyboardKey(rawKey.toString()).normalized();
      final encodedKey = Uri.encodeComponent(key.code);
      final encodedMods = 'none';
      final nextId = (id != null && id.split('_').length >= 4)
          ? id
          : 'key_${encodedKey}_${encodedMods}_${DateTime.now().microsecondsSinceEpoch}';
      control = VirtualKey(
        id: nextId,
        label: label ?? key.code,
        layout: createLayout(),
        trigger: TriggerType.tap,
        binding: KeyboardBinding(key: key),
        config: config ?? const {},
      );
    }

    if (control != null) {
      addControl(control);
    }
  }

  void _aiRemoveControl(String id) {
    if (!allowAddRemove) return;
    _state = _state.remove(id);
    _rebuildDefinition();
    _layout = _applyState(_definition, _state);
    _isDirty = true;
  }

  void _aiMoveControl(LayoutAICommand cmd) {
    if (!allowMove) return;
    final id = cmd.id!;
    _mutateControl(id, (control) {
      final l = control.layout;
      final newX = cmd.x ?? l.x;
      final newY = cmd.y ?? l.y;
      return _cloneWithLayout(
        control,
        ControlLayout(
          x: newX.clamp(0.0, 1.0 - l.width),
          y: newY.clamp(0.0, 1.0 - l.height),
          width: l.width,
          height: l.height,
        ),
      );
    });
  }

  void _aiResizeControl(LayoutAICommand cmd) {
    if (!allowResize) return;
    final id = cmd.id!;
    _mutateControl(id, (control) {
      final l = control.layout;
      var newW = cmd.width ?? l.width;
      var newH = cmd.height ?? l.height;
      if (cmd.scale != null) {
        newW *= cmd.scale!;
        newH *= cmd.scale!;
      }
      return _cloneWithLayout(
        control,
        ControlLayout(
          x: l.x,
          y: l.y,
          width: newW.clamp(0.05, 1.0 - l.x),
          height: newH.clamp(0.05, 1.0 - l.y),
        ),
      );
    });
  }

  void _aiRenameControl(String id, String label) {
    final idx = _layout.controls.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final prev = _state.stateFor(id);
    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);
    nextConfig['label'] = label;

    _state = _state.upsert(
      VirtualControlState(
        id: id,
        layout: prev?.layout ?? _layout.controls[idx].layout,
        opacity: prev?.opacity ?? 1.0,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
  }

  void _aiUpdateProperty(LayoutAICommand cmd) {
    final id = cmd.id!;
    final props = cmd.properties;
    if (props == null || props.isEmpty) return;

    final prev = _state.stateFor(id);
    final idx = _layout.controls.indexWhere((c) => c.id == id);
    if (prev == null && idx == -1) return;

    final layout = prev?.layout ?? _layout.controls[idx].layout;
    final opacityRaw = props['opacity'];
    final nextOpacity = opacityRaw is num
        ? opacityRaw.toDouble().clamp(0.0, 1.0)
        : (prev?.opacity ?? 1.0);

    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);

    final configRaw = props['config'];
    if (configRaw is Map) {
      nextConfig.addAll(Map<String, dynamic>.from(configRaw));
    }

    _state = _state.upsert(
      VirtualControlState(
        id: id,
        layout: layout,
        opacity: nextOpacity,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
  }

  void _aiClear() {
    if (!allowAddRemove) return;
    _state = _state.copyWith(controls: []);
    _rebuildDefinition();
    _layout = _applyState(_definition, _state);
    _isDirty = true;
  }

  void _rebuildDefinition() {
    if (allowAddRemove) {
      _definition = buildDefinitionFromState(
        _state,
        runtimeDefaults: false,
        fallbackName: _definition.name,
      );
      _definitionIds = _definition.controls.map((c) => c.id).toSet();
    }
  }

  void replaceState(VirtualControllerState state, {bool markDirty = false}) {
    _state = state;
    if (allowAddRemove) {
      _definition = buildDefinitionFromState(
        _state,
        runtimeDefaults: false,
        fallbackName: _definition.name,
      );
      _definitionIds = _definition.controls.map((c) => c.id).toSet();
    }
    _layout = _applyState(_definition, _state);
    _isDirty = markDirty;
    if (_selected != null) {
      final next = _layout.controls
          .where((c) => c.id == _selected!.id)
          .cast<VirtualControl?>()
          .firstOrNull;
      _selected = next;
      _selectedBaseLayout = next?.layout;
    }
    notifyListeners();
  }

  void renameLayout(String name) {
    if (readOnly || !allowRename) return;
    final next = name.trim();
    if (next.isEmpty) return;
    _state = _state.copyWith(name: next);
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    notifyListeners();
  }

  void selectControl(VirtualControl? control) {
    _selected = control;
    _selectedScale = 1.0;
    _selectedBaseLayout = control?.layout;
    notifyListeners();
  }

  void addControl(VirtualControl control) {
    if (readOnly || !allowAddRemove) return;
    if (_definitionIds.contains(control.id)) return;
    final config = _extractStateConfig(control);
    _state = _state.upsert(
      VirtualControlState(
        id: control.id,
        layout: control.layout,
        opacity: 1.0,
        config: config,
      ),
    );
    if (allowAddRemove) {
      _definition = buildDefinitionFromState(
        _state,
        runtimeDefaults: false,
        fallbackName: _definition.name,
      );
      _definitionIds = _definition.controls.map((c) => c.id).toSet();
    }
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    final next = _layout.controls
        .where((c) => c.id == control.id)
        .cast<VirtualControl?>()
        .firstOrNull;
    selectControl(next);
  }

  void deleteSelected() {
    if (readOnly || !allowAddRemove) return;
    final selected = _selected;
    if (selected == null) return;
    _state = _state.remove(selected.id);
    if (allowAddRemove) {
      _definition = buildDefinitionFromState(
        _state,
        runtimeDefaults: false,
        fallbackName: _definition.name,
      );
      _definitionIds = _definition.controls.map((c) => c.id).toSet();
    }
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    selectControl(null);
  }

  void updateControl(VirtualControl updated) {
    final opacityRaw = updated.config['opacity'];
    final opacity = (opacityRaw is num ? opacityRaw.toDouble() : null) ??
        (_state.stateFor(updated.id)?.opacity ?? 1.0);
    final prevConfig = _state.stateFor(updated.id)?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);
    final stickClickEnabled = updated.config['stickClickEnabled'];
    if (stickClickEnabled is bool) {
      nextConfig['stickClickEnabled'] = stickClickEnabled;
    }
    final stickLockEnabled = updated.config['stickLockEnabled'];
    if (stickLockEnabled is bool) {
      nextConfig['stickLockEnabled'] = stickLockEnabled;
    }
    if (updated is VirtualDpad) {
      nextConfig['enable3D'] = updated.enable3D;
    }
    _state = _state.upsert(
      VirtualControlState(
        id: updated.id,
        layout: updated.layout,
        opacity: opacity.clamp(0.0, 1.0),
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    if (_selected?.id == updated.id) {
      _selected = _layout.controls
          .where((c) => c.id == updated.id)
          .cast<VirtualControl?>()
          .firstOrNull;
    }
    notifyListeners();
  }

  void moveControlBy(String controlId, Offset delta, Size canvasSize) {
    if (readOnly || !allowMove) return;
    _mutateControl(controlId, (control) {
      final dx = delta.dx / canvasSize.width;
      final dy = delta.dy / canvasSize.height;
      final l = control.layout;
      final tentative = ControlLayout(
        x: l.x + dx,
        y: l.y + dy,
        width: l.width,
        height: l.height,
      );
      final constrained = _constrainLayout(control, tentative, canvasSize);
      return _cloneWithLayout(control, constrained);
    });
  }

  void resizeControlBy(
    String controlId,
    Offset delta,
    Size canvasSize,
    ResizeDirection direction,
  ) {
    if (readOnly || !allowResize) return;
    _mutateControl(controlId, (control) {
      final dx = delta.dx / canvasSize.width;
      final dy = delta.dy / canvasSize.height;
      const minSize = 0.02;

      final l = control.layout;
      double newX = l.x;
      double newY = l.y;
      double newWidth = l.width;
      double newHeight = l.height;

      switch (direction) {
        case ResizeDirection.topLeft:
          final actualDx = dx.clamp(-newX, newWidth - minSize);
          final actualDy = dy.clamp(-newY, newHeight - minSize);
          newX += actualDx;
          newWidth -= actualDx;
          newY += actualDy;
          newHeight -= actualDy;
          break;
        case ResizeDirection.topRight:
          final actualDx =
              dx.clamp(minSize - newWidth, 1.0 - (newX + newWidth));
          final actualDy = dy.clamp(-newY, newHeight - minSize);
          newWidth += actualDx;
          newY += actualDy;
          newHeight -= actualDy;
          break;
        case ResizeDirection.bottomLeft:
          final actualDx = dx.clamp(-newX, newWidth - minSize);
          final actualDy =
              dy.clamp(minSize - newHeight, 1.0 - (newY + newHeight));
          newX += actualDx;
          newWidth -= actualDx;
          newHeight += actualDy;
          break;
        case ResizeDirection.bottomRight:
          final actualDx =
              dx.clamp(minSize - newWidth, 1.0 - (newX + newWidth));
          final actualDy =
              dy.clamp(minSize - newHeight, 1.0 - (newY + newHeight));
          newWidth += actualDx;
          newHeight += actualDy;
          break;
      }

      final tentative = ControlLayout(
        x: newX,
        y: newY,
        width: newWidth,
        height: newHeight,
      );
      final constrained = _constrainLayout(control, tentative, canvasSize);
      return _cloneWithLayout(control, constrained);
    });
  }

  void setSelectedScale(double scale, Size canvasSize) {
    if (readOnly || !allowResize) return;
    final selected = _selected;
    final base = _selectedBaseLayout;
    if (selected == null || base == null) return;

    final current = selected.layout;
    final centerX = current.x + current.width / 2;
    final centerY = current.y + current.height / 2;

    const minSize = 0.02;
    var newWidth = (base.width * scale).clamp(minSize, 1.0);
    var newHeight = (base.height * scale).clamp(minSize, 1.0);

    var newX = (centerX - newWidth / 2).clamp(0.0, 1.0 - newWidth);
    var newY = (centerY - newHeight / 2).clamp(0.0, 1.0 - newHeight);

    final tentative = ControlLayout(
      x: newX,
      y: newY,
      width: newWidth,
      height: newHeight,
    );

    final constrained = _constrainLayout(selected, tentative, canvasSize);
    final updated = _cloneWithLayout(selected, constrained);
    updateControl(updated);
    _selectedScale = scale;
    notifyListeners();
  }

  void setSelectedOpacity(double opacity) {
    if (readOnly) return;
    final selected = _selected;
    if (selected == null) return;
    final nextOpacity = opacity.clamp(0.05, 1.0);
    final prevConfig = _state.stateFor(selected.id)?.config ?? const {};
    _state = _state.upsert(
      VirtualControlState(
        id: selected.id,
        layout: selected.layout,
        opacity: nextOpacity,
        config: prevConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    notifyListeners();
  }

  void setSelectedLabel(String label) {
    if (readOnly) return;
    final selected = _selected;
    if (selected == null) return;
    final normalized = _truncateLabel(label.trim());
    if (normalized.isEmpty) return;
    final prev = _state.stateFor(selected.id);
    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);
    nextConfig['label'] = normalized;
    _state = _state.upsert(
      VirtualControlState(
        id: selected.id,
        layout: prev?.layout ?? selected.layout,
        opacity: prev?.opacity ?? 1.0,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    _selected = _layout.controls
        .where((c) => c.id == selected.id)
        .cast<VirtualControl?>()
        .firstOrNull;
    notifyListeners();
  }

  void setSelectedStickClickEnabled(bool enabled) {
    if (readOnly) return;
    final selected = _selected;
    if (selected is! VirtualJoystick) return;
    final prev = _state.stateFor(selected.id);
    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);
    nextConfig['stickClickEnabled'] = enabled;
    _state = _state.upsert(
      VirtualControlState(
        id: selected.id,
        layout: prev?.layout ?? selected.layout,
        opacity: prev?.opacity ?? 1.0,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    notifyListeners();
  }

  void setSelectedStickLockEnabled(bool enabled) {
    if (readOnly) return;
    final selected = _selected;
    if (selected is! VirtualJoystick) return;
    final prev = _state.stateFor(selected.id);
    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);
    nextConfig['stickLockEnabled'] = enabled;
    _state = _state.upsert(
      VirtualControlState(
        id: selected.id,
        layout: prev?.layout ?? selected.layout,
        opacity: prev?.opacity ?? 1.0,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    notifyListeners();
  }

  void setSelectedSprintEnabled(bool enabled) {
    if (readOnly) return;
    final selected = _selected;
    if (selected is! VirtualJoystick) return;
    final prev = _state.stateFor(selected.id);
    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);
    nextConfig['sprintEnabled'] = enabled;
    _state = _state.upsert(
      VirtualControlState(
        id: selected.id,
        layout: prev?.layout ?? selected.layout,
        opacity: prev?.opacity ?? 1.0,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    notifyListeners();
  }

  void setSelectedDpad3dEnabled(bool enabled) {
    if (readOnly) return;
    final selected = _selected;
    if (selected is! VirtualDpad) return;
    final prev = _state.stateFor(selected.id);
    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);
    nextConfig['enable3D'] = enabled;
    _state = _state.upsert(
      VirtualControlState(
        id: selected.id,
        layout: prev?.layout ?? selected.layout,
        opacity: prev?.opacity ?? 1.0,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    notifyListeners();
  }

  void setSelectedMacroRecordingV2({
    required List<Map<String, dynamic>> recordingV2,
    String? label,
  }) {
    if (readOnly) return;
    final selected = _selected;
    if (selected is! VirtualMacroButton) return;

    final prev = _state.stateFor(selected.id);
    final prevConfig = prev?.config ?? const {};
    final nextConfig = Map<String, dynamic>.from(prevConfig);

    nextConfig['recordingV2'] = recordingV2;

    final normalizedLabel = label?.trim();
    if (normalizedLabel != null && normalizedLabel.isNotEmpty) {
      nextConfig['label'] = normalizedLabel;
    }

    _state = _state.upsert(
      VirtualControlState(
        id: selected.id,
        layout: prev?.layout ?? selected.layout,
        opacity: prev?.opacity ?? 1.0,
        config: nextConfig,
      ),
    );
    _layout = _applyState(_definition, _state);
    _isDirty = true;
    notifyListeners();
  }

  void markSaved() {
    _isDirty = false;
    notifyListeners();
  }

  void _mutateControl(
    String controlId,
    VirtualControl Function(VirtualControl control) transformer,
  ) {
    final idx = _layout.controls.indexWhere((c) => c.id == controlId);
    if (idx == -1) return;
    final current = _layout.controls[idx];
    final updated = transformer(current);
    updateControl(updated);
  }

  ControlLayout _constrainLayout(
    VirtualControl control,
    ControlLayout layout,
    Size canvasSize,
  ) {
    final temp = _cloneWithLayout(control, layout);
    final effective = _decorateForGeometry(temp);
    final occupied =
        ControlGeometry.occupiedLayout(effective, effective.layout, canvasSize);
    final x = occupied.x.clamp(0.0, 1.0 - occupied.width);
    final y = occupied.y.clamp(0.0, 1.0 - occupied.height);
    return ControlLayout(
      x: x,
      y: y,
      width: occupied.width.clamp(0.02, 1.0),
      height: occupied.height.clamp(0.02, 1.0),
    );
  }

  VirtualControl _decorateForGeometry(VirtualControl control) {
    final decorator = geometryDecorator;
    if (decorator == null) return control;
    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: '_geometry',
      controls: [control],
    );
    final decorated = decorator(layout);
    if (decorated.controls.isEmpty) return control;
    final c = decorated.controls.first;
    if (c.id != control.id) return control;
    return c;
  }

  VirtualControl _cloneWithLayout(
      VirtualControl control, ControlLayout layout) {
    return _cloneWithOverrides(control, layout: layout);
  }

  VirtualControl _cloneWithOverrides(
    VirtualControl control, {
    ControlLayout? layout,
    ControlStyle? style,
    String? label,
    Map<String, dynamic>? config,
  }) {
    final nextLayout = layout ?? control.layout;
    final nextLabel = label ?? control.label;
    final nextConfig = config ?? control.config;
    if (control is VirtualButton) {
      return VirtualButton(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        binding: control.binding,
        config: nextConfig,
        actions: control.actions,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualJoystick) {
      return VirtualJoystick(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        actions: control.actions,
        deadzone: control.deadzone,
        mode: control.mode,
        stickType: control.stickType,
        keys: control.keys,
        axes: control.axes,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualKey) {
      return VirtualKey(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        binding: control.binding,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualMouseButton) {
      return VirtualMouseButton(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        button: control.button,
        clickType: control.clickType,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualMouseWheel) {
      return VirtualMouseWheel(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        direction: control.direction,
        step: control.step,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualKeyCluster) {
      return VirtualKeyCluster(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        grid: control.grid,
        keySize: control.keySize,
        spacing: control.spacing,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualMacroButton) {
      final configSeq = nextConfig['sequence'] as List?;
      final sequence = configSeq == null
          ? control.sequence
          : configSeq.map((e) {
              if (e is MacroSequenceItem) return e;
              return MacroSequenceItem.fromJson(Map<String, dynamic>.from(e));
            }).toList();

      final configLabel = nextConfig['label'];
      final appliedLabel =
          (configLabel is String && configLabel.trim().isNotEmpty)
              ? configLabel.trim()
              : nextLabel;

      return VirtualMacroButton(
        id: control.id,
        label: appliedLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        sequence: sequence,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualDpad) {
      final enable3D = (nextConfig['enable3D'] is bool)
          ? nextConfig['enable3D'] as bool
          : control.enable3D;
      return VirtualDpad(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        actions: control.actions,
        directions: control.directions,
        enable3D: enable3D,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualScrollStick) {
      return VirtualScrollStick(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        sensitivity: control.sensitivity,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualSplitMouse) {
      return VirtualSplitMouse(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    if (control is VirtualCustomControl) {
      return VirtualCustomControl(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        actions: control.actions,
        customData: control.customData,
        style: style ?? control.style,
        feedback: control.feedback,
      );
    }
    return control;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _truncateLabel(String value) {
  final runes = value.runes.toList(growable: false);
  if (runes.length <= 4) return value;
  return String.fromCharCodes(runes.take(4));
}

String _normalizeDefaultLayoutName(String value) {
  final n = value.trim();
  if (n.isEmpty) return 'unnamed';
  final isCustomAuto = RegExp(r'^custom_\d+$').hasMatch(n);
  if (isCustomAuto) return 'unnamed';
  return n;
}

VirtualControllerLayout _applyState(
  VirtualControllerLayout definition,
  VirtualControllerState state,
) {
  final stateById = state.byId;
  final definitionIds = definition.controls.map((c) => c.id).toSet();
  final controls = <VirtualControl>[];
  for (final c in definition.controls) {
    final s = stateById[c.id];
    if (s == null) {
      controls.add(c);
      continue;
    }
    final nextConfig = Map<String, dynamic>.from(c.config);
    if (s.config.isNotEmpty) {
      nextConfig.addAll(s.config);
    }
    nextConfig['opacity'] = s.opacity;
    controls.add(
      _cloneControlWithOverrides(c, layout: s.layout, config: nextConfig),
    );
  }

  for (final s in state.controls) {
    if (definitionIds.contains(s.id)) continue;
    final dynControl =
        dynamicControlFromId(s.id, s.layout, runtimeDefaults: false);
    if (dynControl == null) continue;
    final nextConfig = Map<String, dynamic>.from(dynControl.config);
    if (s.config.isNotEmpty) {
      nextConfig.addAll(s.config);
    }
    nextConfig['opacity'] = s.opacity;
    controls.add(
      _cloneControlWithOverrides(dynControl,
          layout: s.layout, config: nextConfig),
    );
  }
  return VirtualControllerLayout(
    schemaVersion: definition.schemaVersion,
    name: (state.name?.trim().isNotEmpty ?? false)
        ? state.name!.trim()
        : _normalizeDefaultLayoutName(definition.name),
    controls: controls,
  );
}

Map<String, dynamic> _extractStateConfig(VirtualControl control) {
  final label = control.config['label'];
  final hasLabel = label is String && label.trim().isNotEmpty;
  if (control is VirtualJoystick) {
    final enabled = control.config['stickClickEnabled'];
    final lockEnabled = control.config['stickLockEnabled'];
    return {
      if (hasLabel) 'label': label.trim(),
      'stickClickEnabled': enabled is bool ? enabled : false,
      'stickLockEnabled': lockEnabled is bool ? lockEnabled : false,
    };
  }
  if (control is VirtualDpad) {
    return {
      if (hasLabel) 'label': label.trim(),
      'enable3D': control.enable3D,
    };
  }
  if (control is VirtualMacroButton) {
    final recordingV2 = control.config['recordingV2'];
    final label = control.config['label'];
    return {
      if (label is String && label.trim().isNotEmpty) 'label': label.trim(),
      if (recordingV2 is List) 'recordingV2': recordingV2,
    };
  }
  if (hasLabel) {
    return {'label': label.trim()};
  }
  return const {};
}

VirtualControl _cloneControlWithOverrides(
  VirtualControl control, {
  ControlLayout? layout,
  ControlStyle? style,
  String? label,
  Map<String, dynamic>? config,
}) {
  final nextLayout = layout ?? control.layout;
  final nextLabel = label ?? control.label;
  final nextConfig = config ?? control.config;
  final configLabel = nextConfig['label'];
  final appliedLabel = (configLabel is String && configLabel.trim().isNotEmpty)
      ? configLabel.trim()
      : nextLabel;
  if (control is VirtualButton) {
    return VirtualButton(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      binding: control.binding,
      config: nextConfig,
      actions: control.actions,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualJoystick) {
    return VirtualJoystick(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      actions: control.actions,
      deadzone: control.deadzone,
      mode: control.mode,
      stickType: control.stickType,
      keys: control.keys,
      axes: control.axes,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualKey) {
    return VirtualKey(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      binding: control.binding,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualMouseButton) {
    return VirtualMouseButton(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      button: control.button,
      clickType: control.clickType,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualMouseWheel) {
    return VirtualMouseWheel(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      direction: control.direction,
      step: control.step,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualKeyCluster) {
    return VirtualKeyCluster(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      grid: control.grid,
      keySize: control.keySize,
      spacing: control.spacing,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualMacroButton) {
    final configSeq = nextConfig['sequence'] as List?;
    final sequence = configSeq == null
        ? control.sequence
        : configSeq.map((e) {
            if (e is MacroSequenceItem) return e;
            return MacroSequenceItem.fromJson(Map<String, dynamic>.from(e));
          }).toList();
    final configLabel = nextConfig['label'];
    final appliedLabel =
        (configLabel is String && configLabel.trim().isNotEmpty)
            ? configLabel.trim()
            : nextLabel;
    return VirtualMacroButton(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      sequence: sequence,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualDpad) {
    final enable3D = (nextConfig['enable3D'] is bool)
        ? nextConfig['enable3D'] as bool
        : control.enable3D;
    return VirtualDpad(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      actions: control.actions,
      directions: control.directions,
      enable3D: enable3D,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualScrollStick) {
    return VirtualScrollStick(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      sensitivity: control.sensitivity,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualSplitMouse) {
    return VirtualSplitMouse(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualCustomControl) {
    return VirtualCustomControl(
      id: control.id,
      label: appliedLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      actions: control.actions,
      customData: control.customData,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  return control;
}
