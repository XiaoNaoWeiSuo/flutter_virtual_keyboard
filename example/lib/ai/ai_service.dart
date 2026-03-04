import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';
import '../ai_config.dart';

enum AIProvider {
  deepseek,
  openai,
}

class AIService {
  static const _systemPrompt = '''
You are an expert Virtual Controller Layout Designer.
You will chat with the user and optionally modify the layout.

You MUST ALWAYS return a single JSON object. Do not wrap it in markdown code blocks.
Do not include any other text.

Response schema:
{
  "reply": "string, natural language reply for the user (Chinese preferred)",
  "commands": [ LayoutAICommand, ... ],
  "agent": {
    "plan": ["step 1", "step 2"],
    "step": 0,
    "continue": true,
    "done": true,
    "blocked": false
  }
}

Rules:
- "reply" is required and should be human-friendly.
- "commands" can be empty if the user is just chatting or if you need clarification.
- If you generate an "add" command, you MUST include a valid "type".
- For keyboard keys, DO NOT invent key names. Only use the supported key codes listed below.
- For gamepad buttons, DO NOT invent codes like "shoot". Only use codes from CAPABILITIES.gamepadButtons[].code.
- If you are unsure about an exact key/button code, set commands=[] and ask the user to pick from candidates.
- If user asks for transparency/opacity, use updateProperty with properties.opacity (0.0 to 1.0).
- You will receive a system message starting with "CAPABILITIES:" which contains valid candidates. Prefer those values and do not invent unknown buttons/sticks.
- "agent" is OPTIONAL. Only include it when the user's request is multi-step or requires iteration/verification.
- To call built-in tools, use "request" (and DO NOT output commands in the same response):
  - Get candidates list:
    { "reply": "我将获取可用按钮/按键候选列表。", "commands": [], "request": { "candidates": true } }
  - Inspect a control binding by id (id must be an existing control id like btn_xxx / dpad_xxx / joystick_xxx):
    { "reply": "我将读取该控件的绑定信息。", "commands": [], "request": { "inspectBinding": { "id": "btn_xxx" } } }
- If you need deeper reasoning, respond with:
  { "reply": "需要更强推理能力继续。", "commands": [], "request": { "think": true } }
- If you request think=true, do not output commands in the same response.
- If you need to see the current rendered layout, respond with:
  { "reply": "需要查看当前布局截图。", "commands": [], "request": { "screenshot": true } }
  Do not output commands in the same response when requesting a screenshot.

The available commands are:

1. Add Control:
{ "action": "add", "type": "button", "id": "btn_jump", "label": "Jump", "x": 0.5, "y": 0.5, "width": 0.15, "height": 0.15 }
- Types: "button", "joystick", "dpad", "mouse_button", "key"
- x, y, width, height are normalized coordinates (0.0 to 1.0).
- For type "key", you MUST set properties.key to one of the supported key codes.
- For type "button", use properties.button as the gamepad button code from CAPABILITIES.gamepadButtons.
- For type "joystick":
  - Gamepad stick: set properties.mode="gamepad" and properties.stickType="left"|"right"
  - Keyboard stick: set properties.mode="keyboard" and properties.scheme="wasd"|"arrows"

2. Move Control:
{ "action": "move", "id": "btn_jump", "x": 0.6, "y": 0.6 }

3. Resize Control:
{ "action": "resize", "id": "btn_jump", "width": 0.2, "height": 0.2 }
OR
{ "action": "resize", "id": "btn_jump", "scale": 1.2 }

4. Rename Control:
{ "action": "rename", "id": "btn_jump", "label": "Fire" }

5. Remove Control:
{ "action": "remove", "id": "btn_jump" }

6. Clear Layout:
{ "action": "clear" }

7. Update Property (opacity / config):
{ "action": "updateProperty", "id": "btn_jump", "properties": { "opacity": 0.6 } }
{ "action": "updateProperty", "id": "btn_jump", "properties": { "config": { "label": "Fire" } } }

Keyboard key codes (use in add key: properties.key):
- Letters: "A".."Z"
- Digits: "0".."9"
- Arrows: "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"
- Common: "Space", "Enter", "Tab", "Escape", "Backspace"
- Navigation: "Insert", "Delete", "Home", "End", "PageUp", "PageDown"
- Toggles: "CapsLock", "NumLock", "ScrollLock"
- Others: "PrintScreen", "Pause"
- Modifiers: "ShiftLeft", "ControlLeft", "AltLeft", "MetaLeft"
You may also use function keys "F1".."F12" if needed.

Example User Input: "Add a jump button on the right and a joystick on the left"
Example Output:
{
  "reply": "好的，我会在左侧添加一个摇杆，并在右侧添加一个跳跃按钮。",
  "commands": [
    { "action": "add", "type": "joystick", "id": "joy_left", "x": 0.1, "y": 0.6, "width": 0.25, "height": 0.25 },
    { "action": "add", "type": "button", "id": "btn_jump", "label": "Jump", "x": 0.75, "y": 0.65, "width": 0.15, "height": 0.15 }
  ]
}
''';

  String buildCapabilitiesJson() {
    final buttons = InputBindingRegistry.registeredGamepadButtons
        .map((b) => {'code': b.code, 'label': b.label ?? b.code})
        .toList();
    return jsonEncode({
      'gamepadButtons': buttons,
      'gamepadSticks': GamepadStickId.values.map((e) => e.code).toList(),
      'joystickIdPrefixes': [
        'joystick_gamepad_left_',
        'joystick_gamepad_right_',
        'joystick_wasd_',
        'joystick_arrows_',
      ],
      'dpadIdPrefix': 'dpad_',
      'mouseButtons': MouseButtonId.values.map((e) => e.code).toList(),
    });
  }

  Future<AIChatResult> chat(
    String userMessage, {
    String? currentLayoutJson,
    bool agentMode = false,
    bool agentAuto = true,
    List<String>? agentPlan,
    int? agentStepIndex,
    String? agentStepText,
    String? modelOverride,
    AIProvider provider = AIProvider.deepseek,
    Uint8List? screenshotPngBytes,
    List<Map<String, String>> history = const [],
  }) async {
    final prompt = _buildSystemMessages(
      agentMode: agentMode,
      agentAuto: agentAuto,
      agentPlan: agentPlan,
      agentStepIndex: agentStepIndex,
      agentStepText: agentStepText,
      currentLayoutJson: currentLayoutJson,
    );

    final fullHistory = <Map<String, String>>[
      ...history.where((m) => m['role'] != null && m['content'] != null),
      {'role': 'user', 'content': userMessage},
    ];

    if (provider == AIProvider.openai) {
      if (AIConfig.openaiApiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY not configured');
      }
      final raw = await _chatOpenAI(
        systemMessages: prompt,
        messages: fullHistory,
        model: modelOverride ?? AIConfig.openaiVisionModel,
        temperature: AIConfig.temperature,
        screenshotPngBytes: screenshotPngBytes,
      );
      return _decodeResult(raw);
    }

    if (AIConfig.apiKey.isEmpty) {
      throw Exception('DEEPSEEK_API_KEY not configured');
    }
    final raw = await _chatDeepSeek(
      systemMessages: prompt,
      messages: fullHistory,
      model: modelOverride ?? AIConfig.model,
      temperature: AIConfig.temperature,
    );
    return _decodeResult(raw);
  }

  List<Map<String, String>> _buildSystemMessages({
    required bool agentMode,
    required bool agentAuto,
    required List<String>? agentPlan,
    required int? agentStepIndex,
    required String? agentStepText,
    required String? currentLayoutJson,
  }) {
    return [
      {'role': 'system', 'content': _systemPrompt},
      {'role': 'system', 'content': 'CAPABILITIES: ${buildCapabilitiesJson()}'},
      if (agentAuto && !agentMode)
        {
          'role': 'system',
          'content':
              'AGENT_AUTO: If the task is complex, include agent.plan and execute only agent.step=0 in this response. If simple, omit agent.'
        },
      if (agentMode)
        {
          'role': 'system',
          'content':
              'AGENT_MODE: Execute ONLY one step. Set agent.step (0-based), agent.done (true/false), agent.blocked (true/false), and agent.continue (true to proceed, false to stop). Do not repeat finished steps.'
        },
      if (agentMode && agentPlan != null && agentPlan.isNotEmpty)
        {'role': 'system', 'content': 'AGENT_PLAN: ${jsonEncode(agentPlan)}'},
      if (agentMode && agentStepIndex != null)
        {'role': 'system', 'content': 'AGENT_STEP_INDEX: $agentStepIndex'},
      if (agentMode && agentStepText != null && agentStepText.trim().isNotEmpty)
        {'role': 'system', 'content': 'AGENT_STEP_TEXT: ${agentStepText.trim()}'},
      if (currentLayoutJson != null)
        {'role': 'system', 'content': 'Current Layout State: $currentLayoutJson'},
    ];
  }

  Future<String> _chatDeepSeek({
    required List<Map<String, String>> systemMessages,
    required List<Map<String, String>> messages,
    required String model,
    required double temperature,
  }) async {
    final response = await http.post(
      Uri.parse('${AIConfig.baseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': model,
        'messages': [...systemMessages, ...messages],
        'temperature': temperature,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty response from AI');
    }
    final content = choices[0]['message']['content'] as String?;
    if (content == null) throw Exception('Empty content from AI');
    return content;
  }

  Future<String> _chatOpenAI({
    required List<Map<String, String>> systemMessages,
    required List<Map<String, String>> messages,
    required String model,
    required double temperature,
    Uint8List? screenshotPngBytes,
  }) async {
    final systemText = systemMessages.map((e) => e['content'] ?? '').join('\n\n');
    final openaiMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemText,
      },
    ];

    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final role = (m['role'] ?? '').toString();
      final text = (m['content'] ?? '').toString();
      if (text.trim().isEmpty) continue;
      final isLastUser = role == 'user' && i == messages.length - 1;
      if (isLastUser && screenshotPngBytes != null && screenshotPngBytes.isNotEmpty) {
        openaiMessages.add({
          'role': role,
          'content': [
            {'type': 'text', 'text': text},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/png;base64,${base64Encode(screenshotPngBytes)}',
              }
            },
          ],
        });
      } else {
        openaiMessages.add({
          'role': role,
          'content': text,
        });
      }
    }

    final uri = Uri.parse('${AIConfig.openaiBaseUrl}/chat/completions');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AIConfig.openaiApiKey}',
      },
      body: jsonEncode({
        'model': model,
        'messages': openaiMessages,
        'temperature': temperature,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty response from OpenAI');
    }
    final msg = choices[0]['message'];
    if (msg is! Map) throw Exception('Empty content from OpenAI');
    final content = msg['content'];
    if (content is String) return content;
    if (content is List) {
      final buf = StringBuffer();
      for (final p in content) {
        if (p is Map && p['type'] == 'text' && p['text'] is String) {
          buf.writeln(p['text']);
        }
      }
      return buf.toString().trim();
    }
    return '';
  }

  AIChatResult _decodeResult(String content) {
    var cleanContent = content
        .replaceAll(RegExp(r'^```json\s*'), '')
        .replaceAll(RegExp(r'^```\s*'), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
        .trim();

    final start = cleanContent.indexOf('{');
    final end = cleanContent.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      cleanContent = cleanContent.substring(start, end + 1);
    }
    try {
      final decoded = jsonDecode(cleanContent);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final reply = map['reply']?.toString().trim() ?? '';
        final cmdsRaw = map['commands'];
        final cmds = (cmdsRaw is List)
            ? cmdsRaw
                .whereType<Map>()
                .map((e) =>
                    LayoutAICommand.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : <LayoutAICommand>[];
        final agentRaw = map['agent'];
        List<String>? plan;
        int? step;
        bool? shouldContinue;
        bool? done;
        bool? blocked;
        if (agentRaw is Map) {
          final agentMap = Map<String, dynamic>.from(agentRaw);
          final planRaw = agentMap['plan'];
          if (planRaw is List) {
            plan = planRaw.map((e) => e.toString()).toList();
          }
          final stepRaw = agentMap['step'];
          if (stepRaw is num) step = stepRaw.toInt();
          final cRaw = agentMap['continue'];
          if (cRaw is bool) shouldContinue = cRaw;
          final dRaw = agentMap['done'];
          if (dRaw is bool) done = dRaw;
          final bRaw = agentMap['blocked'];
          if (bRaw is bool) blocked = bRaw;
        }
        var requestScreenshot = false;
        var requestThink = false;
      var requestCandidates = false;
      String? requestInspectBindingId;
        final reqRaw = map['request'];
        if (reqRaw is Map) {
          final req = Map<String, dynamic>.from(reqRaw);
          requestScreenshot = req['screenshot'] == true;
          requestThink = req['think'] == true;
        requestCandidates = req['candidates'] == true;
        final inspect = req['inspectBinding'];
        if (inspect is Map) {
          final m = Map<String, dynamic>.from(inspect);
          requestInspectBindingId = m['id']?.toString().trim();
          if (requestInspectBindingId != null &&
              requestInspectBindingId.isEmpty) {
            requestInspectBindingId = null;
          }
        }
        }
        return AIChatResult(
          reply: reply.isEmpty ? cleanContent : reply,
          commands: cmds,
          agentPlan: plan,
          agentStep: step,
          agentContinue: shouldContinue,
          agentDone: done,
          agentBlocked: blocked,
          requestScreenshot: requestScreenshot,
          requestThink: requestThink,
        requestCandidates: requestCandidates,
        requestInspectBindingId: requestInspectBindingId,
        );
      }
    } catch (_) {}
    return AIChatResult(reply: cleanContent, commands: const []);
  }
}

class AIChatResult {
  const AIChatResult({
    required this.reply,
    required this.commands,
    this.agentPlan,
    this.agentStep,
    this.agentContinue,
    this.agentDone,
    this.agentBlocked,
    this.requestScreenshot,
    this.requestThink,
    this.requestCandidates,
    this.requestInspectBindingId,
  });

  final String reply;
  final List<LayoutAICommand> commands;
  final List<String>? agentPlan;
  final int? agentStep;
  final bool? agentContinue;
  final bool? agentDone;
  final bool? agentBlocked;
  final bool? requestScreenshot;
  final bool? requestThink;
  final bool? requestCandidates;
  final String? requestInspectBindingId;
}
