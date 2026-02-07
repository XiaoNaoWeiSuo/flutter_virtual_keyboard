# Virtual Gamepad Pro (虚拟游戏手柄专业版)

Flutter 平台最先进的虚拟控制器套件。不仅包含摇杆、按键、D-Pad 等基础组件，更内置了强大的**运行时布局编辑器**，支持从 JSON 加载/保存布局，专为云游戏、远程桌面及模拟器类应用打造。

> **Design Philosophy**: 所有的控件位置与大小均采用**百分比布局** (0.0 - 1.0)，确保在不同分辨率和屏幕比例的设备上（手机、平板、折叠屏）都能保持一致的操作手感。

---

## 核心特性 (Features)

- **丰富的控件库**:
  - 🕹️ **摇杆 (Joystick)**: 支持模拟量输出、锁定模式、按压 (L3/R3)。
  - ➕ **方向键 (D-Pad)**: 传统的十字键，支持 8 方向输入。
  - 🔘 **按键 (Buttons)**: 普通按键、宏按键 (Macro)、连发键。
  - 🖱️ **鼠标模拟**: 鼠标左/右键、滚轮 (Wheel)、触控板区域。
  - 📜 **滚动棒 (Scroll Stick)**: 专为侧边滚轮设计的线性控制器。

- **专业级定制 (Pro Styling)**:
  - 支持圆形、矩形外观。
  - 自定义背景色、边框、圆角、阴影 (Shadows)。
  - 支持**图片纹理** (Image Textures) 和按下状态切换。
  - 支持**锁定状态高亮** (Locked Color)。

- **内置布局编辑器 (Runtime Editor)**:
  - 完整的拖拽、缩放、属性编辑 UI。
  - 自动吸附、对齐辅助。
  - 存储无关性 (Storage Agnostic): 自由对接 SharedPreferences、Hive 或云端 API。

- **高性能 (High Performance)**:
  - 零原生依赖 (Pure Flutter)。
  - 优化的事件分发机制。
  - 支持多点触控 (Multitouch)。

---

## 安装 (Installation)

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  virtual_gamepad_pro: ^0.1.0
```

---

## 快速上手 (Quick Start)

最简单的用法是直接在屏幕上覆盖一个虚拟手柄层。

```dart
import 'package:flutter/material.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

void main() {
  runApp(const MaterialApp(home: GamepadPage()));
}

class GamepadPage extends StatelessWidget {
  const GamepadPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 定义一个简单的布局
    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'My Layout',
      controls: [
        // 左摇杆 (Left Stick)
        VirtualJoystick(
          id: 'ls',
          label: 'LS',
          // x, y, width, height 都是 0.0-1.0 的百分比
          layout: const ControlLayout(x: 0.1, y: 0.6, width: 0.2, height: 0.2), 
          stickType: 'left',
        ),
        // A 键
        VirtualButton(
          id: 'btn_a',
          label: 'A',
          layout: const ControlLayout(x: 0.8, y: 0.7, width: 0.1, height: 0.1),
          trigger: TriggerType.tap,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          // 你的游戏画面或远程桌面画面
          const Center(child: Text('Game View', style: TextStyle(color: Colors.white))),
          
          // 2. 覆盖虚拟手柄
          VirtualControllerOverlay(
            layout: layout,
            onInputEvent: (event) {
              // 3. 处理输入事件
              if (event is GamepadAxisInputEvent) {
                print('摇杆 ${event.axisId}: ${event.x}, ${event.y}');
              } else if (event is GamepadButtonInputEvent) {
                print('按键 ${event.button}: ${event.isPressed ? "按下" : "抬起"}');
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

## 样式定制 (Styling Customization)

本插件提供保姆级的样式定制能力，通过 `ControlStyle` 类实现。你可以让手柄看起来像 Xbox、PS5 或者复古掌机。

### 示例：创建一个酷炫的霓虹风格按键

```dart
final neonStyle = ControlStyle(
  shape: BoxShape.circle,
  // 基础颜色
  color: Colors.black.withOpacity(0.8),
  pressedColor: Colors.cyan.withOpacity(0.5),
  // 边框
  borderColor: Colors.cyanAccent,
  borderWidth: 2.0,
  // 阴影（发光效果）
  shadows: [
    BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
  ],
  pressedShadows: [
    BoxShadow(color: Colors.cyanAccent, blurRadius: 20, spreadRadius: 4),
  ],
  // 文本样式
  labelStyle: TextStyle(
    color: Colors.cyanAccent,
    fontWeight: FontWeight.bold,
    fontSize: 24,
  ),
);

// 应用到控件
VirtualButton(
  id: 'neon_btn',
  label: 'X',
  style: neonStyle,
  // ...
)
```

### 使用图片纹理 (Image Textures)

如果你有美术资源，可以使用图片作为按键背景：

```dart
final imageStyle = ControlStyle(
  backgroundImagePath: 'assets/buttons/btn_normal.png',
  pressedBackgroundImagePath: 'assets/buttons/btn_pressed.png',
  imageFit: BoxFit.contain,
);
```

---

## 接入布局编辑器 (Layout Editor)

这是本插件的核心大招。允许用户在 App 内直接修改键位，体验秒杀同类产品。

编辑器组件 `VirtualControllerLayoutEditor` 需要你提供 `load` 和 `save` 回调，这意味着你可以将布局保存在任何地方（本地数据库、文件、或者上传到服务器）。

### 完整接入示例

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  // 加载布局
  Future<VirtualControllerLayout> _loadLayout(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('layout_$id');
    if (jsonString != null) {
      return VirtualControllerLayout.fromJson(jsonDecode(jsonString));
    }
    // 默认返回一个标准 Xbox 布局
    return VirtualControllerLayout.xbox();
  }

  // 保存布局
  Future<void> _saveLayout(String id, VirtualControllerLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(layout.toJson());
    await prefs.setString('layout_$id', jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VirtualControllerLayoutEditor(
        layoutId: 'custom_layout_1',
        load: _loadLayout,
        save: _saveLayout,
        // 可选：自定义编辑器配置
        allowAddRemove: true, // 允许添加/删除控件
        allowResize: true,    // 允许调整大小
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
```

---

## JSON 序列化 (Serialization)

所有的布局对象都支持标准的 `toJson()` 和 `fromJson()`，方便持久化。

```dart
// 序列化
Map<String, dynamic> json = layout.toJson();
String jsonString = jsonEncode(json);

// 反序列化
VirtualControllerLayout restoredLayout = VirtualControllerLayout.fromJson(jsonDecode(jsonString));
```

---

## 贡献与支持 (Contribution)

欢迎提交 Issue 和 PR！
GitHub: [https://github.com/XiaoNaoWeiSuo/flutter_virtual_keyboard](https://github.com/XiaoNaoWeiSuo/flutter_virtual_keyboard)
