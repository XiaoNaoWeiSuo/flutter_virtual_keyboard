# Virtual Gamepad Pro

[![pub package](https://img.shields.io/pub/v/virtual_gamepad_pro.svg)](https://pub.dev/packages/virtual_gamepad_pro)
[![license](https://img.shields.io/github/license/XiaoNaoWeiSuo/flutter_virtual_keyboard)](https://github.com/XiaoNaoWeiSuo/flutter_virtual_keyboard/blob/main/LICENSE)

**The most advanced virtual controller suite for Flutter.**
Designed for cloud gaming, remote desktop, and emulators. It features a rich set of controls (Joystick, D-Pad, Buttons) and a powerful **Runtime Layout Editor** with JSON serialization support.

**Flutter 平台最先进的虚拟控制器套件。**
专为云游戏、远程桌面及模拟器应用打造。不仅包含摇杆、按键、D-Pad 等基础组件，更内置了强大的**运行时布局编辑器**，支持从 JSON 加载/保存布局。

> **Design Philosophy**: All controls use **normalized coordinates** (0.0 - 1.0) for position and size, ensuring consistent gameplay experience across different screen resolutions and aspect ratios (phones, tablets, foldables).
>
> **设计理念**: 所有控件的位置与大小均采用**百分比坐标** (0.0 - 1.0)，确保在不同分辨率和屏幕比例的设备上（手机、平板、折叠屏）都能保持一致的操作体验。

---

## ✨ Features (核心特性)

### 🎮 Rich Controls (丰富的控件库)
- **Joystick**: Analog output, customizable deadzone, lock mode, L3/R3 support. (模拟量输出、死区调节、锁定模式)
- **D-Pad**: 8-way directional input (Up, Down, Left, Right + Diagonals). (8方向输入)
- **Buttons**: Tap, Hold, Double-Tap triggers. Support for Turbo/Macro. (多种触发模式、连发/宏)
- **Mouse**: Left/Right click, Scroll Wheel, Touchpad area. (鼠标键、滚轮、触控板)
- **Scroll Stick**: Linear controller optimized for side-scrolling. (侧边滚动条)

### 🎨 Pro Styling (专业级定制)
- **Visuals**: Custom colors, borders, shadows (neon/glow effects), and gradients. (自定义颜色、边框、阴影/霓虹效果)
- **Textures**: Support for image backgrounds (sprites) for normal and pressed states. (支持图片纹理/皮肤)
- **Feedback**: Haptic feedback (vibration) on interaction. (触觉反馈)

### 🛠 Runtime Editor (内置布局编辑器)
- **Drag & Drop**: Move, resize, and configure controls at runtime. (运行时拖拽、缩放)
- **Storage Agnostic**: Load/Save layouts from JSON, compatible with SharedPreferences, Hive, or backend APIs. (存储无关，支持 JSON 导入导出)
- **Magnetism**: Auto-snap alignment. (自动吸附)

---

## 🚀 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  virtual_gamepad_pro: ^0.1.1
```

---

## ⚡ Quick Start (快速上手)

### 1. Basic Usage (基础用法)

Render a simple controller overlay on top of your game view.

```dart
import 'package:flutter/material.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

class GamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Define a layout programmatically
    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Default',
      controls: [
        VirtualJoystick(
          id: 'ls',
          label: 'LS',
          layout: ControlLayout(x: 0.1, y: 0.6, width: 0.2, height: 0.2), 
          stickType: 'left',
        ),
        VirtualButton(
          id: 'btn_a',
          label: 'A',
          layout: ControlLayout(x: 0.8, y: 0.7, width: 0.1, height: 0.1),
          trigger: TriggerType.tap,
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          // Your Game View (Video stream, RDP, etc.)
          Center(child: Text('Game Content')),
          
          // Controller Overlay
          VirtualControllerOverlay(
            layout: layout,
            onInputEvent: (event) {
              if (event is GamepadAxisInputEvent) {
                print('Axis ${event.axisId}: ${event.x}, ${event.y}');
              } else if (event is GamepadButtonInputEvent) {
                print('Button ${event.button}: ${event.isPressed}');
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### 2. Styling (样式定制)

Create a "Neon" style button.

```dart
final neonStyle = ControlStyle(
  shape: BoxShape.circle,
  color: Colors.black.withOpacity(0.8),
  borderColor: Colors.cyanAccent,
  shadows: [
    BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10),
  ],
  labelStyle: TextStyle(color: Colors.cyanAccent, fontSize: 20),
);
```

---

## 📚 API Documentation (API 文档)

### 1. `VirtualControllerOverlay`
The main widget to render the controller.

| Property | Type | Description (CN) |
|----------|------|------------------|
| `layout` | `VirtualControllerLayout` | The layout configuration object containing all controls. (布局配置对象) |
| `onInputEvent` | `Function(InputEvent)` | Callback for receiving input events. (输入事件回调) |
| `opacity` | `double` | Global opacity of the overlay (0.0 - 1.0). (全局透明度) |
| `showLabels` | `bool` | Whether to show text labels on controls. (是否显示标签) |

### 2. `VirtualControllerLayoutEditor`
A full-screen widget for creating/editing layouts.

| Property | Type | Description (CN) |
|----------|------|------------------|
| `layoutId` | `String` | Unique ID for the layout being edited. (布局ID) |
| `load` | `Future<Layout> Function(id)` | Callback to load layout data. (加载回调) |
| `save` | `Future<void> Function(id, layout)` | Callback to save layout data. (保存回调) |
| `previewDecorator` | `Function` | Optional hook to modify layout before preview (e.g. apply themes). (预览装饰器) |

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
| `mode` | `String` | `'gamepad'` (axis events) or `'keyboard'` (WASD keys). (模式) |

### 5. `VirtualButton`
A standard push button.

| Property | Type | Description (CN) |
|----------|------|------------------|
| `trigger` | `TriggerType` | `tap` (press/release), `hold` (continuous), `doubleTap`. (触发类型) |
| `label` | `String` | Text displayed on the button. (标签文本) |

---

## 🧩 Layout Editor Integration (布局编辑器接入)

To use the editor, you must implement the persistence layer (load/save).
要使用编辑器，您必须实现持久化层（加载/保存）。

```dart
// Example using SharedPreferences
Future<void> saveLayout(String id, VirtualControllerLayout layout) async {
  final prefs = await SharedPreferences.getInstance();
  // Serialize to JSON string
  // 序列化为 JSON 字符串
  final jsonStr = jsonEncode(layout.toJson()); 
  await prefs.setString('layout_$id', jsonStr);
}

Future<VirtualControllerLayout> loadLayout(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString('layout_$id');
  if (jsonStr == null) return VirtualControllerLayout.xbox(); // Default
  // Deserialize from JSON
  // 反序列化
  return VirtualControllerLayout.fromJson(jsonDecode(jsonStr));
}

// In your Widget
VirtualControllerLayoutEditor(
  layoutId: 'user_custom_1',
  load: loadLayout,
  save: saveLayout,
)
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
