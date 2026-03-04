import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';
import '../../ai_config.dart';
import '../../ai/ai_service.dart';
import '../../repo/ai_chat_repository.dart';

class AIChatPanel extends StatefulWidget {
  const AIChatPanel({
    super.key,
    required this.layoutId,
    required this.layoutJson,
    required this.getLayoutJson,
    required this.captureScreenshotPng,
    required this.onCommands,
    required this.onClose,
    required this.repo,
  });

  final String layoutId;
  final String layoutJson;
  final Future<String> Function() getLayoutJson;
  final Future<Uint8List?> Function() captureScreenshotPng;
  final Future<void> Function(List<LayoutAICommand>) onCommands;
  final VoidCallback onClose;
  final AIChatRepo repo;

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final _aiService = AIService();
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[];
  final _scrollCtrl = ScrollController();
  bool _isLoading = false;
  bool _stopRequested = false;
  List<String>? _agentPlan;
  int _agentDoneCount = 0;
  bool _agentRunning = false;
  List<AIChatSessionMeta> _sessions = const [];
  String? _sessionId;
  String _sessionTitle = '新会话';
  int _sessionCreatedAt = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialSession();
  }

  @override
  void didUpdateWidget(covariant AIChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layoutId != widget.layoutId) {
      _loadInitialSession();
    }
  }

  Future<void> _loadInitialSession() async {
    final metas = await widget.repo.listSessions(widget.layoutId);
    if (!mounted) return;
    setState(() {
      _sessions = metas;
    });

    if (metas.isNotEmpty) {
      await _openSession(metas.first.id);
      return;
    }
    final created = await widget.repo.createSession(widget.layoutId);
    if (!mounted) return;
    setState(() {
      _sessions = [AIChatSessionMeta(
        id: created.id,
        title: created.title,
        createdAt: created.createdAt,
        updatedAt: created.updatedAt,
      )];
    });
    await _openSession(created.id);
  }

  Future<void> _openSession(String sessionId) async {
    final s = await widget.repo.loadSession(widget.layoutId, sessionId);
    if (!mounted) return;
    if (s == null) return;
    setState(() {
      _sessionId = s.id;
      _sessionTitle = s.title;
      _sessionCreatedAt = s.createdAt;
      _agentPlan = s.agentPlan.isEmpty ? null : s.agentPlan;
      _agentDoneCount = s.agentDoneCount;
      _agentRunning = false;
      _messages
        ..clear()
        ..addAll(s.messages.map(_fromStoredMessage));
    });
    _scrollToBottom();
  }

  Future<void> _newSession() async {
    final created = await widget.repo.createSession(widget.layoutId);
    final meta = AIChatSessionMeta(
      id: created.id,
      title: created.title,
      createdAt: created.createdAt,
      updatedAt: created.updatedAt,
    );
    if (!mounted) return;
    setState(() {
      _sessions = [meta, ..._sessions.where((e) => e.id != meta.id)];
    });
    await _openSession(created.id);
  }

  Future<void> _persistSession() async {
    final id = _sessionId;
    if (id == null) return;
    final plan = _agentPlan ?? const <String>[];
    final session = AIChatSession(
      id: id,
      title: _sessionTitle,
      createdAt: _sessionCreatedAt == 0
          ? DateTime.now().millisecondsSinceEpoch
          : _sessionCreatedAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      messages: _messages.map(_toStoredMessage).toList(growable: false),
      provider: AIProvider.deepseek.name,
      useThinkingModel: false,
      agentPlan: plan,
      agentDoneCount: _agentDoneCount,
    );
    await widget.repo.saveSession(widget.layoutId, session);
    final metas = await widget.repo.listSessions(widget.layoutId);
    if (!mounted) return;
    setState(() {
      _sessions = metas;
    });
  }

  _ChatMessage _fromStoredMessage(AIChatStoredMessage m) {
    return _ChatMessage(
      role: m.role,
      content: m.content,
      banners: m.banners.map(_fromStoredBanner).toList(growable: false),
      capabilities:
          m.capabilities.map(_capabilityTagFromKind).toList(growable: false),
    );
  }

  AIChatStoredMessage _toStoredMessage(_ChatMessage m) {
    return AIChatStoredMessage(
      role: m.role,
      content: m.content,
      banners: m.banners.map(_toStoredBanner).toList(growable: false),
      capabilities: m.capabilities.map((e) => e.kind).toList(growable: false),
    );
  }

  _EditBanner _fromStoredBanner(AIChatStoredBanner b) {
    final (icon, color) = _bannerStyle(b.kind);
    return _EditBanner(
      kind: b.kind,
      label: b.label,
      count: b.count,
      icon: icon,
      color: color,
    );
  }

  AIChatStoredBanner _toStoredBanner(_EditBanner b) {
    return AIChatStoredBanner(kind: b.kind, label: b.label, count: b.count);
  }

  (IconData, Color) _bannerStyle(String kind) {
    return switch (kind) {
      'opacity' => (Icons.opacity, Colors.purple),
      'config' => (Icons.tune, Colors.purple),
      'add' => (Icons.add_circle_outline, Colors.blue),
      'move' => (Icons.open_with, Colors.blue),
      'resize' => (Icons.photo_size_select_small, Colors.blue),
      'rename' => (Icons.edit_outlined, Colors.blue),
      'remove' => (Icons.delete_outline, Colors.red),
      'clear' => (Icons.delete_sweep_outlined, Colors.red),
      _ => (Icons.info_outline, Colors.black54),
    };
  }

  _CapabilityTag _capabilityTagFromKind(String kind) {
    final (icon, color) = _capabilityStyle(kind);
    return _CapabilityTag(kind: kind, icon: icon, color: color);
  }

  (IconData, Color) _capabilityStyle(String kind) {
    return switch (kind) {
      'candidates' => (Icons.list_alt, Colors.black54),
      'agent' => (Icons.playlist_play, Colors.purple),
      'think' => (Icons.psychology_outlined, Colors.purple),
      'screenshot' => (Icons.image_outlined, Colors.blue),
      'vision' => (Icons.visibility_outlined, Colors.blue),
      _ => (Icons.info_outline, Colors.black54),
    };
  }

  String _toolCandidatesText() {
    final buttons = InputBindingRegistry.registeredGamepadButtons;
    final sb = StringBuffer();
    sb.writeln('可用候选（来自运行时注册表）：');
    sb.writeln('');
    sb.writeln('游戏手柄按钮（gamepad_button.button）：');
    for (final b in buttons) {
      sb.writeln(
          '- ${b.code}${(b.label == null || b.label == b.code) ? '' : ' (${b.label})'}');
    }
    sb.writeln('');
    sb.writeln('鼠标按钮（mouse_button.config.button）：');
    for (final m in MouseButtonId.values) {
      sb.writeln('- ${m.code}');
    }
    sb.writeln('');
    sb.writeln('键盘键值（keyboard.key / properties.key）：');
    sb.writeln('- A..Z, 0..9, F1..F12');
    sb.writeln('- ArrowUp/ArrowDown/ArrowLeft/ArrowRight');
    sb.writeln('- Space/Enter/Tab/Escape/Backspace');
    sb.writeln('- Insert/Delete/Home/End/PageUp/PageDown');
    sb.writeln('- CapsLock/NumLock/ScrollLock/PrintScreen/Pause');
    sb.writeln('- ShiftLeft/ControlLeft/AltLeft/MetaLeft');
    return sb.toString().trim();
  }

  String _toolInspectBindingTextFromLayout(String layoutJson, String id) {
    try {
      final decoded = jsonDecode(layoutJson);
      if (decoded is! Map) return '无法解析当前布局 JSON。';
      final controls = decoded['controls'];
      if (controls is! List) return '当前布局不包含 controls。';
      final control = controls.firstWhere(
        (e) => e is Map && e['id']?.toString() == id,
        orElse: () => null,
      );
      if (control is! Map) return '未找到控件 $id。';
      final binding = control['binding'];
      final config = control['config'];
      final sb = StringBuffer();
      sb.writeln('控件 $id 的绑定信息：');
      if (binding is Map) {
        final type = binding['type']?.toString() ?? '';
        if (type.isNotEmpty) sb.writeln('- binding.type: $type');
        final key = binding['key']?.toString();
        final mods = binding['modifiers'];
        if (key != null && key.trim().isNotEmpty) sb.writeln('- binding.key: $key');
        if (mods is List && mods.isNotEmpty) {
          sb.writeln(
              '- binding.modifiers: ${mods.map((e) => e.toString()).join(', ')}');
        }
        final btn = binding['button']?.toString();
        if (btn != null && btn.trim().isNotEmpty) sb.writeln('- binding.button: $btn');
      } else {
        sb.writeln('- binding: 未配置');
      }
      if (config is Map && config.isNotEmpty) {
        final cKey = config['key']?.toString();
        final cBtn = config['button']?.toString();
        if (cKey != null && cKey.trim().isNotEmpty) sb.writeln('- config.key: $cKey');
        if (cBtn != null && cBtn.trim().isNotEmpty) sb.writeln('- config.button: $cBtn');
      }
      return sb.toString().trim();
    } catch (_) {
      return '无法解析当前布局 JSON。';
    }
  }

  Future<void> _appendToolRequestAndResult({
    required String toolName,
    required String toolResult,
    required List<_CapabilityTag> caps,
    Uint8List? imageBytes,
  }) async {
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
        role: 'tool',
        content: 'tool:$toolName\n$toolResult',
        capabilities: caps,
        imageBytes: imageBytes,
      ));
    });
    await _persistSession();
    _scrollToBottom();
  }

  List<String> _validateCommands(List<LayoutAICommand> commands) {
    final errors = <String>[];
    final mouseCodes = MouseButtonId.values.map((e) => e.code).toSet();

    for (final c in commands) {
      switch (c.action) {
        case LayoutAIAction.add:
          final type = (c.type ?? '').trim();
          if (type.isEmpty) {
            errors.add('add 缺少 type（id=${c.id ?? ''}）');
            break;
          }
          if (!const {
            'button',
            'joystick',
            'dpad',
            'mouse_button',
            'key',
          }.contains(type)) {
            errors.add('add.type 不支持：$type（id=${c.id ?? ''}）');
            break;
          }
          if ((c.id ?? '').trim().isEmpty) {
            errors.add('add 缺少 id（type=$type）');
          }
          final props = c.properties ?? const <String, dynamic>{};
          if (type == 'button') {
            final code =
                (props['button'] ?? props['code'] ?? '').toString().trim();
            if (code.isEmpty) {
              errors.add('button 缺少 properties.button（id=${c.id ?? ''}）');
            } else if (!InputBindingRegistry.isKnownGamepadButton(code)) {
              errors.add('无效 gamepad button：$code（id=${c.id ?? ''}）');
            }
          } else if (type == 'mouse_button') {
            final code = (props['button'] ?? '').toString().trim();
            if (code.isEmpty) {
              errors.add('mouse_button 缺少 properties.button（id=${c.id ?? ''}）');
            } else if (!mouseCodes.contains(code)) {
              errors.add('无效 mouse button：$code（id=${c.id ?? ''}）');
            }
          } else if (type == 'key') {
            final key = (props['key'] ?? '').toString().trim();
            if (key.isEmpty) {
              errors.add('key 缺少 properties.key（id=${c.id ?? ''}）');
            } else if (!_isKnownKeyboardCode(key)) {
              errors.add('无效 keyboard key：$key（id=${c.id ?? ''}）');
            }
          } else if (type == 'joystick') {
            final mode = (props['mode'] ?? '').toString().trim();
            if (mode == 'gamepad') {
              final stick = (props['stickType'] ?? '').toString().trim();
              if (stick != 'left' && stick != 'right') {
                errors.add('joystick gamepad stickType 只能是 left/right（id=${c.id ?? ''}）');
              }
            } else if (mode == 'keyboard') {
              final scheme = (props['scheme'] ?? '').toString().trim();
              if (scheme != 'wasd' && scheme != 'arrows') {
                errors.add('joystick keyboard scheme 只能是 wasd/arrows（id=${c.id ?? ''}）');
              }
            } else if (mode.isNotEmpty) {
              errors.add('joystick mode 不支持：$mode（id=${c.id ?? ''}）');
            }
          }
          break;
        case LayoutAIAction.updateProperty:
          final props = c.properties ?? const <String, dynamic>{};
          final cfg = props['config'];
          if (cfg is Map) {
            final key = cfg['key']?.toString().trim();
            if (key != null && key.isNotEmpty && !_isKnownKeyboardCode(key)) {
              errors.add('无效 config.key：$key（id=${c.id ?? ''}）');
            }
            final btn =
                (cfg['button'] ?? cfg['padKey'] ?? cfg['gamepadButton'])
                    ?.toString()
                    .trim();
            if (btn != null &&
                btn.isNotEmpty &&
                !InputBindingRegistry.isKnownGamepadButton(btn)) {
              errors.add('无效 config.button：$btn（id=${c.id ?? ''}）');
            }
            final mBtn = cfg['button']?.toString().trim();
            if (mBtn != null &&
                mBtn.isNotEmpty &&
                cfg['clickType'] != null &&
                !mouseCodes.contains(mBtn)) {
              errors.add('无效 mouse config.button：$mBtn（id=${c.id ?? ''}）');
            }
            final binding = cfg['binding'];
            if (binding is Map) {
              final bType = binding['type']?.toString().trim().toLowerCase();
              if (bType == 'keyboard') {
                final bKey = binding['key']?.toString().trim() ?? '';
                if (bKey.isNotEmpty && !_isKnownKeyboardCode(bKey)) {
                  errors.add('无效 binding.key：$bKey（id=${c.id ?? ''}）');
                }
              } else if (bType == 'gamepad_button') {
                final bBtn = binding['button']?.toString().trim() ?? '';
                if (bBtn.isNotEmpty &&
                    !InputBindingRegistry.isKnownGamepadButton(bBtn)) {
                  errors.add('无效 binding.button：$bBtn（id=${c.id ?? ''}）');
                }
              }
            }
          }
          break;
        default:
          break;
      }
    }
    return errors;
  }

  bool _isKnownKeyboardCode(String raw) {
    final code = KeyboardKey(raw).normalized().code;
    if (RegExp(r'^[A-Z]$').hasMatch(code)) return true;
    if (RegExp(r'^[0-9]$').hasMatch(code)) return true;
    if (RegExp(r'^F([1-9]|1[0-2])$').hasMatch(code)) return true;
    return const {
      'ArrowUp',
      'ArrowDown',
      'ArrowLeft',
      'ArrowRight',
      'Space',
      'Enter',
      'Tab',
      'Escape',
      'Backspace',
      'Insert',
      'Delete',
      'Home',
      'End',
      'PageUp',
      'PageDown',
      'CapsLock',
      'NumLock',
      'ScrollLock',
      'PrintScreen',
      'Pause',
      'ShiftLeft',
      'ControlLeft',
      'AltLeft',
      'MetaLeft',
    }.contains(code);
  }

  List<Map<String, String>> _buildHistory({required bool excludeLastUser}) {
    final items = _messages
        .where((m) => m.role == 'user' || m.role == 'assistant')
        .map((m) => {'role': m.role, 'content': m.content})
        .toList(growable: false);
    if (excludeLastUser && items.isNotEmpty && items.last['role'] == 'user') {
      return items.sublist(0, items.length - 1);
    }
    return items;
  }

  Future<(AIChatResult, List<_CapabilityTag>)> _chatWithAutoEscalation(
    String userMessage, {
    required String? currentLayoutJson,
    required bool agentMode,
    required bool agentAuto,
    List<String>? agentPlan,
    int? agentStepIndex,
    String? agentStepText,
    required String modelOverride,
    required List<Map<String, String>> history,
  }) async {
    Future<AIChatResult> retryForValidation({
      required AIChatResult bad,
      required List<String> errors,
      required AIProvider provider,
      required String model,
      Uint8List? screenshotPngBytes,
    }) async {
      final errText = errors.map((e) => '- $e').join('\n');
      final retryMsg = '''
$userMessage

SYSTEM_VALIDATION_FAILED:
$errText

You MUST regenerate a valid JSON response.
- Do NOT mention validation errors or candidates to the user.
- Use ONLY supported codes from CAPABILITIES.
- Do NOT request screenshot/think/tools again. Output final JSON now.
''';
      return _aiService.chat(
        retryMsg.trim(),
        currentLayoutJson: currentLayoutJson,
        agentMode: agentMode,
        agentAuto: agentAuto,
        agentPlan: agentPlan,
        agentStepIndex: agentStepIndex,
        agentStepText: agentStepText,
        modelOverride: model,
        provider: provider,
        history: history,
        screenshotPngBytes: screenshotPngBytes,
      );
    }

    var first = await _aiService.chat(
      userMessage,
      currentLayoutJson: currentLayoutJson,
      agentMode: agentMode,
      agentAuto: agentAuto,
      agentPlan: agentPlan,
      agentStepIndex: agentStepIndex,
      agentStepText: agentStepText,
      modelOverride: modelOverride,
      provider: AIProvider.deepseek,
      history: history,
    );

    final caps = <_CapabilityTag>[];
    if (first.requestCandidates == true) {
      final tag = _capabilityTagFromKind('candidates');
      await _appendToolRequestAndResult(
        toolName: '候选列表',
        toolResult: _toolCandidatesText(),
        caps: [tag],
      );
      first = await _aiService.chat(
        '$userMessage\n\nTOOL_RESULT(get_candidates):\n${_toolCandidatesText()}\n\n请基于 TOOL_RESULT 继续完成回答，且严格输出 JSON。',
        currentLayoutJson: currentLayoutJson,
        agentMode: agentMode,
        agentAuto: agentAuto,
        agentPlan: agentPlan,
        agentStepIndex: agentStepIndex,
        agentStepText: agentStepText,
        modelOverride: modelOverride,
        provider: AIProvider.deepseek,
        history: history,
      );
    }

    final inspectId = first.requestInspectBindingId;
    if (inspectId != null && inspectId.isNotEmpty && currentLayoutJson != null) {
      await _appendToolRequestAndResult(
        toolName: '绑定查询',
        toolResult: _toolInspectBindingTextFromLayout(currentLayoutJson, inspectId),
        caps: [_capabilityTagFromKind('candidates')],
      );
      final toolText = _toolInspectBindingTextFromLayout(currentLayoutJson, inspectId);
      first = await _aiService.chat(
        '$userMessage\n\nTOOL_RESULT(inspect_binding):\n$toolText\n\n请基于 TOOL_RESULT 继续完成回答，且严格输出 JSON。',
        currentLayoutJson: currentLayoutJson,
        agentMode: agentMode,
        agentAuto: agentAuto,
        agentPlan: agentPlan,
        agentStepIndex: agentStepIndex,
        agentStepText: agentStepText,
        modelOverride: modelOverride,
        provider: AIProvider.deepseek,
        history: history,
      );
    }

    final firstErrors = _validateCommands(first.commands);
    if (firstErrors.isNotEmpty) {
      final retried = await retryForValidation(
        bad: first,
        errors: firstErrors,
        provider: AIProvider.deepseek,
        model: modelOverride,
      );
      final errs2 = _validateCommands(retried.commands);
      if (errs2.isEmpty) {
        first = retried;
      } else {
        first = const AIChatResult(reply: '已自动纠错，但仍无法生成可执行指令。', commands: []);
      }
    }

    if (first.requestScreenshot == true) {
      Uint8List? shot;
      Object? captureError;
      try {
        shot = await widget.captureScreenshotPng();
      } catch (e) {
        captureError = e;
      }
      final len = shot?.length ?? 0;
      await _appendToolRequestAndResult(
        toolName: '截图',
        toolResult: captureError != null
            ? 'capture failed: $captureError'
            : 'captured image/png ($len bytes)',
        caps: [_capabilityTagFromKind('screenshot')],
        imageBytes: shot,
      );
      if (shot == null || shot.isEmpty) {
        return (
          AIChatResult(
            reply: '截图失败，无法继续使用视觉能力。请确认画布可见且已渲染完成后重试。',
            commands: const [],
          ),
          [_capabilityTagFromKind('screenshot')]
        );
      }
      if (AIConfig.openaiApiKey.isEmpty) {
        await _appendToolRequestAndResult(
          toolName: '视觉解析',
          toolResult: 'missing OPENAI_API_KEY',
          caps: [_capabilityTagFromKind('vision')],
        );
        return (
          AIChatResult(
            reply: '未配置 OPENAI_API_KEY，无法使用视觉能力。请用 --dart-define=OPENAI_API_KEY=... 配置后重试。',
            commands: const [],
          ),
          [_capabilityTagFromKind('screenshot'), _capabilityTagFromKind('vision')]
        );
      }
      await _appendToolRequestAndResult(
        toolName: '视觉解析',
        toolResult: 'vision model: ${AIConfig.openaiVisionModel}',
        caps: [_capabilityTagFromKind('vision')],
      );
      final second = await _aiService.chat(
        userMessage,
        currentLayoutJson: currentLayoutJson,
        agentMode: agentMode,
        agentAuto: agentAuto,
        agentPlan: agentPlan,
        agentStepIndex: agentStepIndex,
        agentStepText: agentStepText,
        modelOverride: AIConfig.openaiVisionModel,
        provider: AIProvider.openai,
        history: history,
        screenshotPngBytes: shot,
      );
      caps.add(_capabilityTagFromKind('screenshot'));
      caps.add(_capabilityTagFromKind('vision'));
      final errs = _validateCommands(second.commands);
      if (errs.isEmpty) return (second, caps);
      final retried = await retryForValidation(
        bad: second,
        errors: errs,
        provider: AIProvider.openai,
        model: AIConfig.openaiVisionModel,
        screenshotPngBytes: shot,
      );
      final errs2 = _validateCommands(retried.commands);
      if (errs2.isEmpty) return (retried, caps);
      return (
        const AIChatResult(reply: '已自动纠错，但仍无法生成可执行指令。', commands: []),
        caps
      );
    }

    if (first.requestThink != true) return (first, caps);
    if (agentMode && (first.agentBlocked == true)) return (first, caps);

    await _appendToolRequestAndResult(
      toolName: '推理升级',
      toolResult: 'using deepseek reasoning model: ${AIConfig.thinkingModel}',
      caps: [_capabilityTagFromKind('think')],
    );
    final second = await _aiService.chat(
      userMessage,
      currentLayoutJson: currentLayoutJson,
      agentMode: agentMode,
      agentAuto: agentAuto,
      agentPlan: agentPlan,
      agentStepIndex: agentStepIndex,
      agentStepText: agentStepText,
      modelOverride: AIConfig.thinkingModel,
      provider: AIProvider.deepseek,
      history: history,
    );
    caps.add(_capabilityTagFromKind('think'));
    final errs = _validateCommands(second.commands);
    if (errs.isEmpty) return (second, caps);
    final retried = await retryForValidation(
      bad: second,
      errors: errs,
      provider: AIProvider.deepseek,
      model: AIConfig.model,
    );
    final errs2 = _validateCommands(retried.commands);
    if (errs2.isEmpty) return (retried, caps);
    return (
      const AIChatResult(reply: '已自动纠错，但仍无法生成可执行指令。', commands: []),
      caps
    );
  }

  Future<void> _showCapabilities() async {
    final border = Colors.grey.withValues(alpha: 0.15);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('当前支持的能力'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CapabilityInfoRow(
                  icon: Icons.list_alt,
                  title: '候选列表',
                  desc: '提供可用按钮/摇杆等候选，避免胡造',
                ),
                _CapabilityInfoRow(
                  icon: Icons.playlist_play,
                  title: '规划执行',
                  desc: '多步任务自动分解并按步骤推进',
                ),
                _CapabilityInfoRow(
                  icon: Icons.psychology_outlined,
                  title: '推理升级',
                  desc: '需要深度推理时自动切一次推理模型',
                ),
                _CapabilityInfoRow(
                  icon: Icons.image_outlined,
                  title: '布局截图',
                  desc: '捕获当前渲染效果作为图片输入',
                ),
                _CapabilityInfoRow(
                  icon: Icons.visibility_outlined,
                  title: '视觉解析',
                  desc: '需要“眼睛”时自动切一次 OpenAI 视觉模型',
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 1,
                  color: border,
                ),
                const SizedBox(height: 8),
                Text(
                  '能力调用会在对应消息气泡上显示小图标。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_sessionId == null) {
      await _loadInitialSession();
      if (_sessionId == null) return;
    }
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _stopRequested = false;
      _controller.clear();
    });
    _maybeUpdateSessionTitleFrom(text);
    await _persistSession();
    _scrollToBottom();

    try {
      setState(() {
        _agentPlan = null;
        _agentDoneCount = 0;
        _agentRunning = false;
      });
      await _runAuto(text);
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'error',
          content: 'Error: $e',
        ));
      });
      await _persistSession();
      _scrollToBottom();
    } finally {
      setState(() {
        _isLoading = false;
        _agentRunning = false;
      });
      await _persistSession();
    }
  }

  Future<void> _runAuto(String userGoal) async {
    var currentLayoutJson = await widget.getLayoutJson();
    final selectedModel = AIConfig.model;
    final history = _buildHistory(excludeLastUser: true);

    final (first, firstCaps0) = await _chatWithAutoEscalation(
      userGoal,
      currentLayoutJson: currentLayoutJson,
      agentAuto: true,
      agentMode: false,
      modelOverride: selectedModel,
      history: history,
    );

    final firstCaps = <_CapabilityTag>[...firstCaps0];
    if (first.agentPlan != null && first.agentPlan!.isNotEmpty) {
      firstCaps.add(_capabilityTagFromKind('agent'));
    }
    currentLayoutJson = await _applyResult(first, currentLayoutJson, capabilities: firstCaps);
    if (!mounted || _stopRequested) return;

    final plan = first.agentPlan;
    if (plan == null || plan.isEmpty) return;

    var doneCount =
        (first.commands.isNotEmpty || first.agentDone == true) ? 1 : 0;
    if (doneCount > plan.length) doneCount = plan.length;

    setState(() {
      _agentPlan = plan;
      _agentDoneCount = doneCount;
      _agentRunning = doneCount < plan.length;
    });

    const maxAttemptsPerStep = 3;
    while (!_stopRequested && doneCount < plan.length) {
      final stepIndex = doneCount;
      final stepText = plan[stepIndex];

      setState(() {
        _agentDoneCount = doneCount;
        _agentRunning = true;
      });

      var attempts = 0;
      String? lastHash;
      var stepDone = false;

      while (!_stopRequested && attempts < maxAttemptsPerStep && !stepDone) {
        final (res, caps) = await _chatWithAutoEscalation(
          '执行第 ${stepIndex + 1}/${plan.length} 步：$stepText。只做这一步，完成后将 agent.done=true；如无法完成，将 agent.blocked=true 并说明原因。',
          currentLayoutJson: currentLayoutJson,
          agentAuto: false,
          agentMode: true,
          agentPlan: plan,
          agentStepIndex: stepIndex,
          agentStepText: stepText,
          modelOverride: selectedModel,
          history: _buildHistory(excludeLastUser: false),
        );

        if (res.agentBlocked == true) {
          currentLayoutJson = await _applyResult(res, currentLayoutJson);
          setState(() {
            _agentRunning = false;
          });
          return;
        }

        final hash = _hashCommands(res.commands);
        final isRepeat = lastHash != null && hash == lastHash;
        lastHash = hash;

        currentLayoutJson = await _applyResult(res, currentLayoutJson, capabilities: caps);
        if (!mounted) return;

        stepDone = res.agentDone == true || res.commands.isNotEmpty;
        if (stepDone) break;

        attempts = isRepeat ? maxAttemptsPerStep : (attempts + 1);
      }

      if (!stepDone) {
        setState(() {
          _messages.add(const _ChatMessage(
            role: 'error',
            content: 'Agent 在当前步骤未能取得进展，已停止执行。',
          ));
          _agentRunning = false;
        });
        _scrollToBottom();
        return;
      }

      doneCount++;
      setState(() {
        _agentDoneCount = doneCount;
        _agentRunning = doneCount < plan.length;
      });
    }

    setState(() {
      _agentRunning = false;
    });
  }

  Future<String> _applyResult(
    AIChatResult result,
    String currentLayoutJson, {
    List<_CapabilityTag> capabilities = const [],
  }) async {
    final commands = result.commands;
    final errors = _validateCommands(commands);
    if (errors.isNotEmpty) {
      if (!mounted) return currentLayoutJson;
      setState(() {
        _messages.add(const _ChatMessage(
          role: 'assistant',
          content: '我这次生成的指令无法执行，我会自动纠错后再继续。请重试一次。',
        ));
      });
      await _persistSession();
      _scrollToBottom();
      return currentLayoutJson;
    }
    if (commands.isNotEmpty) {
      await widget.onCommands(commands);
      currentLayoutJson = await widget.getLayoutJson();
    }

    if (!mounted) return currentLayoutJson;
    setState(() {
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: result.reply.trim().isEmpty ? '好的。' : result.reply.trim(),
        capabilities: capabilities,
        banners: _summariesFor(commands),
      ));
    });
    await _persistSession();
    _scrollToBottom();
    return currentLayoutJson;
  }

  void _maybeUpdateSessionTitleFrom(String userText) {
    if (_sessionTitle.trim().isNotEmpty && _sessionTitle != '新会话') return;
    final t = userText.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return;
    final next = t.length > 16 ? '${t.substring(0, 16)}…' : t;
    setState(() {
      _sessionTitle = next;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      _scrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _hashCommands(List<LayoutAICommand> commands) =>
      jsonEncode(commands.map((e) => e.toJson()).toList());

  List<_EditBanner> _summariesFor(List<LayoutAICommand> commands) {
    if (commands.isEmpty) return const [];
    var opacity = 0;
    var config = 0;
    var add = 0;
    var remove = 0;
    var move = 0;
    var resize = 0;
    var rename = 0;
    var clear = 0;

    for (final c in commands) {
      switch (c.action) {
        case LayoutAIAction.updateProperty:
          final props = c.properties ?? const <String, dynamic>{};
          if (props['opacity'] is num) opacity++;
          final cfg = props['config'];
          if (cfg is Map && cfg.isNotEmpty) config++;
          break;
        case LayoutAIAction.add:
          add++;
          break;
        case LayoutAIAction.remove:
          remove++;
          break;
        case LayoutAIAction.move:
          move++;
          break;
        case LayoutAIAction.resize:
          resize++;
          break;
        case LayoutAIAction.rename:
          rename++;
          break;
        case LayoutAIAction.clear:
          clear++;
          break;
        default:
          break;
      }
    }

    final list = <_EditBanner>[];
    void addBanner(
      String kind,
      int count,
      String label,
      IconData icon,
      Color color,
    ) {
      if (count <= 0) return;
      list.add(_EditBanner(
        kind: kind,
        label: label,
        count: count,
        icon: icon,
        color: color,
      ));
    }

    addBanner('opacity', opacity, '透明度编辑', Icons.opacity, Colors.purple);
    addBanner('config', config, '属性更新', Icons.tune, Colors.purple);
    addBanner('add', add, '新增', Icons.add_circle_outline, Colors.blue);
    addBanner('move', move, '移动', Icons.open_with, Colors.blue);
    addBanner('resize', resize, '缩放', Icons.photo_size_select_small, Colors.blue);
    addBanner('rename', rename, '重命名', Icons.edit_outlined, Colors.blue);
    addBanner('remove', remove, '删除', Icons.delete_outline, Colors.red);
    addBanner('clear', clear, '清空', Icons.delete_sweep_outlined, Colors.red);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.withValues(alpha: 0.2);
    final surface = Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          left: BorderSide(color: borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(-2, 0),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI 助手',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _sessionTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '历史会话',
                  icon: const Icon(Icons.history, size: 20),
                  itemBuilder: (context) {
                    return _sessions
                        .map(
                          (s) => PopupMenuItem<String>(
                            value: s.id,
                            child: SizedBox(
                              width: 200,
                              child: Text(
                                s.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false);
                  },
                  onSelected: (id) => _openSession(id),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _newSession,
                  icon: const Icon(Icons.add_comment_outlined, size: 20),
                  tooltip: '新建会话',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                IconButton(
                  onPressed: _showCapabilities,
                  icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: '能力',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  IconButton(
                    onPressed: () => setState(() => _stopRequested = true),
                    icon: const Icon(Icons.stop_circle_outlined),
                    tooltip: '停止',
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '收起',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          if (_agentPlan != null && _agentPlan!.isNotEmpty)
            _AgentPlanPanel(
              plan: _agentPlan!,
              step: _agentDoneCount,
              running: _agentRunning,
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '输入指令...',
                      hintStyle: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.content,
    this.banners = const [],
    this.capabilities = const [],
    this.imageBytes,
  });
  final String role;
  final String content;
  final List<_EditBanner> banners;
  final List<_CapabilityTag> capabilities;
  final Uint8List? imageBytes;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isError = message.role == 'error';
    final isTool = message.role == 'tool';
    final borderColor = Colors.grey.withValues(alpha: 0.15);
    final banners = message.banners;
    final caps = message.capabilities;

    return LayoutBuilder(
      builder: (context, constraints) {
      final maxWidth = (constraints.maxWidth * 0.85).clamp(200.0, 520.0);
      final capIcons = caps.isEmpty
          ? null
          : Positioned(
              right: 8,
              top: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...caps.take(3).map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Tooltip(
                            message: c.label,
                            child: Icon(c.icon, size: 14, color: c.color),
                          ),
                        ),
                      ),
                  if (caps.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message: '更多能力',
                        child: Icon(
                          Icons.more_horiz,
                          size: 14,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            );

      final bubble = isTool
          ? _ToolCallBubble(
              message: message,
              maxWidth: maxWidth,
              borderColor: borderColor,
              capIcons: capIcons,
            )
          : Stack(
              children: [
                Container(
                  padding:
                      EdgeInsets.fromLTRB(12, 10, caps.isEmpty ? 12 : 40, 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.purple.withValues(alpha: 0.12)
                        : (isError
                            ? Colors.red.withValues(alpha: 0.1)
                            : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(12),
                    border: isError
                        ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                        : Border.all(color: borderColor),
                  ),
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageBytes != null &&
                          message.imageBytes!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            message.imageBytes!,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: isError ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (capIcons != null) capIcons,
              ],
            );

      final bannerRow = banners.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: banners
                    .map((b) => _EditBannerPill(banner: b))
                    .toList(growable: false),
              ),
            );

      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              bubble,
              if (bannerRow != null) bannerRow,
            ],
          ),
        ),
      );
      },
    );
  }
}

class _ToolCallBubble extends StatefulWidget {
  const _ToolCallBubble({
    required this.message,
    required this.maxWidth,
    required this.borderColor,
    required this.capIcons,
  });

  final _ChatMessage message;
  final double maxWidth;
  final Color borderColor;
  final Widget? capIcons;

  @override
  State<_ToolCallBubble> createState() => _ToolCallBubbleState();
}

class _ToolCallBubbleState extends State<_ToolCallBubble> {
  bool _expanded = false;

  (String, String) _parse(String content) {
    var t = content.trim();
    if (t.startsWith('tool:')) t = t.substring(5);
    if (t.startsWith('tool.')) t = t.substring(5);
    final idx = t.indexOf('\n');
    if (idx == -1) return (t.trim(), '');
    return (t.substring(0, idx).trim(), t.substring(idx + 1).trim());
  }

  @override
  Widget build(BuildContext context) {
    final (name, details) = _parse(widget.message.content);
    final summaryLine =
        details.isEmpty ? '已完成' : details.split('\n').first.trim();
    return Stack(
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 40, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.construction_outlined,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '调用 $name 能力',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summaryLine,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withValues(alpha: 0.75),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.message.imageBytes != null &&
                              widget.message.imageBytes!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                widget.message.imageBytes!,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          SelectableText(
                            details,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.capIcons != null) widget.capIcons!,
      ],
    );
  }
}


class _EditBanner {
  const _EditBanner({
    required this.kind,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String kind;
  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _EditBannerPill extends StatelessWidget {
  const _EditBannerPill({required this.banner});

  final _EditBanner banner;

  @override
  Widget build(BuildContext context) {
    final border = Colors.grey.withValues(alpha: 0.15);
    final bg = const Color(0xFFF2F2F7);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(banner.icon, size: 14, color: banner.color),
            const SizedBox(width: 6),
            Text(
              '${banner.label} ${banner.count} 个',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ));
  }
}

class _CapabilityTag {
  const _CapabilityTag({
    required this.kind,
    required this.icon,
    required this.color,
  });

  final String kind;
  final IconData icon;
  final Color color;

  String get label => switch (kind) {
        'candidates' => '已提供候选列表',
        'agent' => '规划执行',
        'think' => '推理升级',
        'screenshot' => '查看渲染效果',
        'vision' => '视觉解析',
        _ => '能力',
      };
}

class _CapabilityInfoRow extends StatelessWidget {
  const _CapabilityInfoRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentPlanPanel extends StatelessWidget {
  const _AgentPlanPanel({
    required this.plan,
    required this.step,
    required this.running,
  });

  final List<String> plan;
  final int step;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF2F2F7);
    final borderColor = Colors.grey.withValues(alpha: 0.15);
    final safeStep = step.clamp(0, plan.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
        color: Colors.white,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '计划',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(plan.length, (i) {
              final isDone = i < safeStep;
              final isActive = !isDone && i == safeStep && running;
              Widget leading;
              if (isDone) {
                leading = const Icon(Icons.check_circle,
                    size: 16, color: Colors.green);
              } else if (isActive) {
                leading = const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.purple),
                  ),
                );
              } else {
                leading = Icon(
                  Icons.radio_button_unchecked,
                  size: 16,
                  color: Colors.grey.withValues(alpha: 0.6),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: isDone ? Colors.black87 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
