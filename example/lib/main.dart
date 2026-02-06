import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Controller Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ControllerPage(),
    );
  }
}

class ControllerPage extends StatefulWidget {
  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  // Store last event to display
  String _lastEventLog = 'Waiting for input...';

  // Comprehensive layout with all control types and rich styling
  late final VirtualControllerLayout _layout;

  @override
  void initState() {
    super.initState();
    _layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Keyboard Layout',
      controls: _buildKeyboardControls(),
    );
  }

  List<VirtualControl> _buildKeyboardControls() {
    final controls = <VirtualControl>[];

    // Keyboard Configuration
    const startY = 0.1;
    const rowHeight = 0.15;
    const keyMargin = 0.01;

    // Common Style
    final keyStyle = ControlStyle(
      color: Colors.grey.shade800,
      pressedColor: Colors.grey.shade600,
      borderColor: Colors.grey.shade600,
      borderWidth: 1.0,
      shape: BoxShape.rectangle,
      borderRadius: 4.0,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    // Row 1: Numbers
    final row1 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    controls.addAll(_buildRow(row1, startY, keyStyle));

    // Row 2: QWERTY
    final row2 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    controls.addAll(_buildRow(row2, startY + rowHeight + keyMargin, keyStyle));

    // Row 3: ASDF (Indented)
    final row3 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    controls.addAll(
      _buildRow(
        row3,
        startY + (rowHeight + keyMargin) * 2,
        keyStyle,
        indent: 0.04,
      ),
    );

    // Row 4: ZXCV (More Indented)
    final row4 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];
    controls.addAll(
      _buildRow(
        row4,
        startY + (rowHeight + keyMargin) * 3,
        keyStyle,
        indent: 0.08,
      ),
    );

    // Spacebar
    controls.add(
      VirtualKey(
        id: 'key_space',
        label: 'SPACE',
        key: ' ',
        layout: const ControlLayout(
          x: 0.25,
          y: startY + (rowHeight + keyMargin) * 4,
          width: 0.5,
          height: rowHeight,
        ),
        trigger: TriggerType.tap,
        style: keyStyle,
      ),
    );

    // Scroll Stick (Right Side)
    controls.add(
      VirtualScrollStick(
        id: 'scroll_stick',
        label: 'SCROLL',
        layout: const ControlLayout(x: 0.88, y: 0.2, width: 0.08, height: 0.6),
        trigger: TriggerType.hold,
        sensitivity: 1.5,
        style: ControlStyle(
          color: Colors.black45,
          borderColor: Colors.white24,
          borderWidth: 2.0,
          shape: BoxShape
              .rectangle, // Hot dog shape handled by borderRadius in widget
        ),
      ),
    );

    return controls;
  }

  List<VirtualControl> _buildRow(
    List<String> keys,
    double y,
    ControlStyle style, {
    double indent = 0.0,
  }) {
    final rowControls = <VirtualControl>[];
    const keyWidth = 0.085; // Approx width to fit 10 keys with margins
    const keyHeight = 0.15;
    const spacing = 0.01;

    double currentX = 0.05 + indent; // Start with some left padding + indent

    for (final keyChar in keys) {
      rowControls.add(
        VirtualKey(
          id: 'key_${keyChar.toLowerCase()}',
          label: keyChar,
          key: keyChar.toLowerCase(),
          layout: ControlLayout(
            x: currentX,
            y: y,
            width: keyWidth,
            height: keyHeight,
          ),
          trigger: TriggerType.tap,
          style: style,
        ),
      );
      currentX += keyWidth + spacing;
    }

    return rowControls;
  }

  void _handleInputEvent(InputEvent event) {
    setState(() {
      _lastEventLog = event.toString();
    });
    // Print to console for debugging
    debugPrint('Input Event: $event');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Dark background for better controller visibility
      body: Stack(
        children: [
          // Background content (game view simulation)
          Center(
            child: Text(
              'Game View',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Debug info at the top
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Last Event: $_lastEventLog',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // The Virtual Controller Overlay
          VirtualControllerOverlay(
            layout: _layout,
            onInputEvent: _handleInputEvent,
            opacity: 0.8, // Make it fairly visible
            showLabels: true,
          ),
        ],
      ),
    );
  }
}
