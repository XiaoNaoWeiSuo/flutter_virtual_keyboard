# Virtual Gamepad Pro

[![pub package](https://img.shields.io/pub/v/virtual_gamepad_pro.svg)](https://pub.dev/packages/virtual_gamepad_pro)
[![license](https://img.shields.io/github/license/XiaoNaoWeiSuo/flutter_virtual_keyboard)](https://github.com/XiaoNaoWeiSuo/flutter_virtual_keyboard/blob/main/LICENSE)

一个纯 Flutter 的虚拟控制器组件库（Joystick / D-Pad / Buttons / Mouse 等），附带运行时布局编辑器。

这个插件把“**控件定义**”（按键绑定、样式、业务语义）与“**可编辑状态**”（位置/大小/透明度）分离，便于：
- 只把可分享的数据存成 JSON（不会携带绑定/回调/业务语义）
- 业务侧用代码统一控制样式与输入绑定
- 运行时渲染只做必要计算（少字符串推断/少动态 Map）

> 坐标体系：所有控件的位置与大小均采用百分比坐标 (0.0 - 1.0)，可跨分辨率复用布局数据。

---

## Features（功能清单）
- 控件：Joystick / D-Pad / Buttons / Mouse Button / Wheel / Split Mouse / Scroll Stick / Key / KeyCluster
- 输入：强类型 `InputBinding`（键盘/手柄），支持注册自定义按钮
- 样式：`ControlStyle`（shape/border/radius/shadow/image/label 等）
- 编辑器：运行时拖拽/缩放/透明度；保存为最小化 `VirtualControllerState` JSON
- 主题：`VirtualControlTheme`（可按规则批量覆盖 style/layout/label/config）

---

## 🚀 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  virtual_gamepad_pro: ^0.3.0
```

---

## Concepts（必读：定义 vs 状态）

- **Definition**：`VirtualControllerLayout`，由业务代码创建，包含控件类型、输入绑定、样式、默认位置等。
- **State**：`VirtualControllerState`，只包含编辑器允许修改的信息：`layout(x/y/width/height)` + `opacity`，适合存储与分享。

State JSON 例子（可直接分享/落盘）：

```json
{
  "schemaVersion": 1,
  "controls": [
    { "id": "a", "layout": { "x": 0.77, "y": 0.66, "width": 0.11, "height": 0.07 }, "opacity": 0.5 }
  ]
}
```

## ⚡ Quick Start (快速上手)

### 1) 渲染 Overlay（definition + state）

建议把布局拆成两部分：
- `VirtualControllerLayout`：控件定义（binding/style/默认 layout 等，业务代码控制）
- `VirtualControllerState`：用户可编辑状态（只包含 position/size/opacity，可序列化分享）

```dart
import 'package:flutter/material.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

class GamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final definition = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Default',
      controls: [
        VirtualJoystick(
          id: 'ls',
          label: 'LS',
          layout: ControlLayout(x: 0.1, y: 0.6, width: 0.2, height: 0.2), 
          trigger: TriggerType.hold,
          mode: JoystickMode.gamepad,
          stickType: GamepadStickId.left,
        ),
        VirtualButton(
          id: 'btn_a',
          label: 'A',
          layout: ControlLayout(x: 0.8, y: 0.7, width: 0.1, height: 0.1),
          trigger: TriggerType.tap,
          binding: const GamepadButtonBinding(GamepadButtonId.a),
        ),
      ],
    );

    final state = const VirtualControllerState(schemaVersion: 1, controls: []);

    return Scaffold(
      body: Stack(
        children: [
          // Your Game View (Video stream, RDP, etc.)
          Center(child: Text('Game Content')),
          
          // Controller Overlay
          VirtualControllerOverlay(
            definition: definition,
            state: state,
            onInputEvent: (event) {
              if (event is GamepadAxisInputEvent) {
                print('Axis ${event.axisId}: ${event.x}, ${event.y}');
              } else if (event is GamepadButtonInputEvent) {
                print('Button ${event.button}: ${event.isDown}');
              } else if (event is KeyboardInputEvent) {
                print('Key ${event.key}: ${event.isDown}');
              }
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Example（pub 展示用示例）

仓库内置了一个完整的示例 App（包含布局管理 + 运行时编辑器 + 宏录制/编辑入口），发布到 pub 后会在页面的 Example 选项卡展示：
- 目录：`example/`
- 入口：`example/lib/main.dart`

### 2) 强类型绑定（InputBinding）

All interactive controls emit input via `InputBinding`.
所有交互控件通过 `InputBinding` 来描述“按下的是什么”，避免 `String + Map` 的隐式约定。

```dart
final kbd = VirtualKey(
  id: 'kbd_space',
  label: 'Space',
  layout: const ControlLayout(x: 0.2, y: 0.8, width: 0.2, height: 0.1),
  trigger: TriggerType.tap,
  binding: const KeyboardBinding(key: KeyboardKey('Space')),
);

final a = VirtualButton(
  id: 'btn_a',
  label: 'A',
  layout: const ControlLayout(x: 0.8, y: 0.7, width: 0.1, height: 0.1),
  trigger: TriggerType.tap,
  binding: const GamepadButtonBinding(GamepadButtonId.a),
);
```

---

### 3) 样式定制（宽高比、圆角、边框等）

控件的宽高比由 `ControlLayout(width/height)` 决定；形状与边框由 `ControlStyle` 决定：

```dart
final pillStyle = ControlStyle(
  shape: BoxShape.rectangle,
  borderRadius: 999,
  borderWidth: 2,
  borderColor: Colors.white54,
  color: Colors.black.withOpacity(0.45),
);
```

#### label 支持 icon + text（上下布局）

`ControlStyle` 支持独立配置图标与文字：两者都有则上下布局；缺一个则另一个居中。

```dart
final style = ControlStyle(
  labelIcon: Icons.local_fire_department,
  labelIconColor: Colors.orangeAccent,
  labelIconScale: 0.62,
  labelText: '开火',
  labelStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
);
```

#### 宏按键默认尺寸（v0.2.4）
- 新增宏按键的默认尺寸已调整为：`width: 0.06`, `height: 0.10`（更窄的药丸形态，便于在界面上排布）。
- 该默认尺寸在调色板原型、工厂方法以及“宏套件添加”入口已统一；已存在布局不受影响（尺寸保存在用户状态中）。
- 如需自定义，直接修改 `VirtualMacroButton.layout` 的 `width/height`。

#### 主题（VirtualControlTheme）

你可以在渲染时对控件做“装饰”（覆盖 style/layout/label/config），而不修改原始 definition/state：

```dart
final theme = RuleBasedVirtualControlTheme(
  base: const DefaultVirtualControlTheme(),
  post: [
    ControlRule(
      when: ControlMatchers.gamepadButtonId(GamepadButtonId.a),
      transform: (c) => (c as VirtualButton).copyWith(
        style: const ControlStyle(color: Colors.green),
      ),
    ),
  ],
);

VirtualControllerOverlay(
  definition: definition,
  state: state,
  theme: theme,
  onInputEvent: onInputEvent,
);
```

---

## 📚 API Documentation (API 文档)

### 1. `VirtualControllerOverlay`
渲染器入口（definition + state）。

| Property | Type | Description (CN) |
|----------|------|------------------|
| `definition` | `VirtualControllerLayout` | 控件定义（binding/style/默认 layout 等）。 |
| `state` | `VirtualControllerState` | 可编辑状态（仅 position/size/opacity，适合 JSON 分享）。 |
| `onInputEvent` | `Function(InputEvent)` | Callback for receiving input events. (输入事件回调) |
| `opacity` | `double` | Global opacity of the overlay (0.0 - 1.0). (全局透明度) |
| `showLabels` | `bool` | Whether to show text labels on controls. (是否显示标签) |
| `immersive` | `bool` | Hide system UI (status/navigation) with immersive mode. (沉浸式全屏) |

### 2. `VirtualControllerLayoutEditor`
运行时布局编辑器：只编辑 state（位置/大小/透明度），不会修改 binding/style/actions。

| Property | Type | Description (CN) |
|----------|------|------------------|
| `layoutId` | `String` | Unique ID for the layout being edited. (布局ID) |
| `loadDefinition` | `Future<VirtualControllerLayout> Function(id)` | 加载控件定义（代码控制）。 |
| `loadState` | `Future<VirtualControllerState> Function(id)` | 加载 state（JSON）。 |
| `saveState` | `Future<void> Function(id, state)` | 保存 state（JSON）。 |
| `previewDecorator` | `Function` | Optional hook to modify layout before preview (e.g. apply themes). (预览装饰器) |
| `immersive` | `bool` | Hide system UI (status/navigation) with immersive mode. (沉浸式全屏) |

### 3. 宏录制与宏编辑

正常“运行时渲染”只需要 `VirtualControllerOverlay`。  
宏相关的录制/编辑属于“工具能力”，只在你显式进入宏编辑/录制流程时出现。

#### `MacroSuitePage`
宏编辑器（主体编辑 + 录制快速录入工具）。用于编辑一段可回放的 `InputEvent` 序列，并最终生成/更新宏按键的数据（写入 `VirtualControllerState.controls[].config['recordingV2']`）。支持 `immersive` 沉浸式全屏。

#### `VirtualControllerMacroRecordingSession`
宏录制会话页：进入当前布局渲染器录制输入事件（可配置混录真实键盘/鼠标），完成后返回一段 `recordingV2` JSON 列表供宏编辑器可视化编辑（每条事件带 `atMs`）。

#### `VirtualControllerMacroRecorder`
一个“带左上角录制 Dock”的录制页面组件（用于调试或你自己做录制入口）。  
如果你把它当成正常渲染器来用，左上角会一直显示录制 Dock；如果你只想渲染控制器，请使用 `VirtualControllerOverlay`。

### 3. `ControlStyle`
Defines the visual appearance of a control.

| Property | Type | Description (CN) |
|----------|------|------------------|
| `shape` | `BoxShape` | `circle` or `rectangle`. (形状) |
| `color` | `Color?` | Background color. (背景色) |
| `borderColor` | `Color?` | Border color. (边框色) |
| `lockedColor` | `Color?` | Color when control is in "locked" state (e.g. joystick lock). (锁定状态颜色) |
| `backgroundImagePath` | `String?` | Asset path or URL for background image. (背景图路径) |
| `shadows` | `List<BoxShadow>` | Shadow list for neon/glow effects. (阴影列表) |
| `imageFit` | `BoxFit` | How the image should be inscribed. (图片填充模式) |

### 4. `VirtualJoystick`
A virtual thumbstick.

| Property | Type | Description (CN) |
|----------|------|------------------|
| `deadzone` | `double` | Minimum input value to register (0.0 - 1.0). Default: 0.1. (死区) |
| `stickType` | `String` | `'left'` or `'right'`. Determines the event ID. (摇杆类型) |
| `mode` | `String` | `'keyboard'` (WASD keys) or `'gamepad'` (axis events). (模式) |

### 5. `VirtualButton`
A standard push button.

| Property | Type | Description (CN) |
|----------|------|------------------|
| `trigger` | `TriggerType` | `tap` (press/release), `hold` (continuous), `doubleTap`. (触发类型) |
| `label` | `String` | Text displayed on the button. (标签文本) |
| `binding` | `InputBinding` | Strong-typed binding for emitted input. (强类型绑定) |

#### 5.1 Ultra Strong Typed Helper (极致强类型辅助)

```dart
final GamepadButtonId id = button.gamepadButton; // throws if not gamepad
final GamepadButtonId? maybe = button.gamepadButtonOrNull;
```

---

## 🧩 Layout Editor Integration (布局编辑器接入)

To use the editor, you must implement the persistence layer (load/save).
要使用编辑器，您必须实现持久化层（加载/保存）。

```dart
// Example using SharedPreferences
Future<void> saveState(String id, VirtualControllerState state) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = jsonEncode(state.toJson());
  await prefs.setString('layout_state_$id', jsonStr);
}

Future<VirtualControllerState> loadState(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString('layout_state_$id');
  if (jsonStr == null) {
    return const VirtualControllerState(schemaVersion: 1, controls: []);
  }
  return VirtualControllerState.fromJson(jsonDecode(jsonStr));
}

Future<VirtualControllerLayout> loadDefinition(String id) async {
  return VirtualControllerLayout.xbox();
}

// In your Widget:
VirtualControllerLayoutEditor(
  layoutId: 'user_custom_1',
  loadDefinition: loadDefinition,
  loadState: loadState,
  saveState: saveState,
)
```

### Custom Gamepad Buttons (自定义手柄按钮)

如果你希望支持额外按钮（例如 Turbo/截屏/OEM 键），在代码中先注册一个强类型按钮 ID，然后把它用于你的 definition（以及编辑器调色板）。

```dart
void main() {
  InputBindingRegistry.registerGamepadButton(code: 'turbo', label: 'Turbo');
  InputBindingRegistry.registerGamepadButton(code: 'screenshot', label: 'Shot');
  runApp(const MyApp());
}
```

Notes:
- The editor palette will automatically show registered custom buttons.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
