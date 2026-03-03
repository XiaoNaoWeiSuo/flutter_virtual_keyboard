import 'package:flutter/material.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

VirtualControlTheme buildExampleVirtualControlTheme() {
  return RuleBasedVirtualControlTheme(
    base: const ExampleVirtualControlTheme(),
    post: [
      ControlRule(
        when: ControlMatchers.joystick(stick: GamepadStickId.left),
        transform: (c) {
          const overrides = ControlStyle(
            shape: BoxShape.circle,
            borderColor: Color(0x33FFFFFF),
            pressedBorderColor: Color(0xFFFFCC00),
            borderWidth: 1.0,
            color: Color(0xFF2F2F31),
            pressedColor: Color(0xCCFFFFFF),
            pressedOpacity: 0.95,
            labelStyle: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, overrides);
          return cloneControlWithOverrides(c, style: nextStyle);
        },
      ),
      ControlRule(
        when: ControlMatchers.joystick(stick: GamepadStickId.right),
        transform: (c) {
          const overrides = ControlStyle(
            shape: BoxShape.circle,
            borderColor: Color(0x33FFFFFF),
            pressedBorderColor: Color(0xFFFFCC00),
            borderWidth: 1.0,
            color: Color(0xFF2F2F31),
            pressedColor: Color(0xCCFFFFFF),
            pressedOpacity: 0.95,
            labelStyle: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, overrides);
          return cloneControlWithOverrides(c, style: nextStyle);
        },
      ),
      ControlRule(
        when: ControlMatchers.macroButton(),
        transform: (c) {
          final nextLayout = layoutWithAspectRatio(c.layout, 1.08964);
          const style = ControlStyle(
            shape: BoxShape.rectangle,
            borderRadius: 999.0,
            borderColor: Colors.black26,
            pressedBorderColor: Colors.black38,
            borderWidth: 1.0,
            color: Color(0xFFFFCC00),
            pressedColor: Color(0xFFE6B800),
            pressedOpacity: 0.98,
            labelStyle: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, style);
          return cloneControlWithOverrides(
            c,
            layout: nextLayout,
            style: nextStyle,
          );
        },
      ),
      ControlRule(
        when: ControlMatchers.keyboardKey(KeyboardKeys.space),
        transform: (c) {
          final nextLayout = layoutSquare(c.layout);
          const style = ControlStyle(
            shape: BoxShape.circle,
            borderColor: Colors.white24,
            pressedBorderColor: Colors.white38,
            borderWidth: 1.0,
            color: Color(0xFF3A3A3C),
            pressedColor: Color(0xFF4A4A4C),
            pressedOpacity: 0.95,
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, style);
          return cloneControlWithOverrides(
            c,
            layout: nextLayout,
            style: nextStyle,
          );
        },
      ),
      ControlRule(
        when: ControlMatchers.joystick(mode: JoystickMode.keyboard),
        transform: (c) {
          const overrides = ControlStyle(
            shape: BoxShape.circle,
            borderColor: Color(0x33FFFFFF),
            pressedBorderColor: Color(0xFFFFCC00),
            borderWidth: 1.0,
            color: Color(0xFF2F2F31),
            pressedColor: Color(0xCCFFFFFF),
            pressedOpacity: 0.95,
            labelStyle: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, overrides);
          return cloneControlWithOverrides(c, style: nextStyle);
        },
      ),
      ControlRule(
        when: (c) => c is VirtualScrollStick,
        transform: (c) {
          const overrides = ControlStyle(
            shape: BoxShape.rectangle,
            borderRadius: 999.0,
            borderColor: Colors.white24,
            pressedBorderColor: Colors.white38,
            borderWidth: 1.0,
            color: Color(0x263A3A3C),
            pressedColor: Color(0x334A4A4C),
            pressedOpacity: 1.0,
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, overrides);
          return cloneControlWithOverrides(c, style: nextStyle);
        },
      ),
      ControlRule(
        when: (c) => c is VirtualMouseWheel,
        transform: (c) {
          const overrides = ControlStyle(
            shape: BoxShape.circle,
            borderColor: Colors.white24,
            pressedBorderColor: Colors.white38,
            borderWidth: 1.0,
            color: Color(0xFF3A3A3C),
            pressedColor: Color(0xFF4A4A4C),
            pressedOpacity: 0.95,
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, overrides);
          return cloneControlWithOverrides(c, style: nextStyle);
        },
      ),
      ControlRule(
        when: (c) => c is VirtualSplitMouse,
        transform: (c) {
          const overrides = ControlStyle(
            shape: BoxShape.circle,
            borderColor: Colors.white24,
            pressedBorderColor: Colors.white38,
            borderWidth: 1.0,
            color: Color(0xFF3A3A3C),
            pressedColor: Color(0xFF4A4A4C),
            pressedOpacity: 0.95,
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, overrides);
          return cloneControlWithOverrides(c, style: nextStyle);
        },
      ),
      ControlRule(
        when: (c) => c is VirtualDpad,
        transform: (c) {
          const overrides = ControlStyle(
            borderColor: Colors.black26,
            borderWidth: 1.0,
            color: Color(0xFF2F2F31),
            pressedColor: Color(0xFF3A3A3C),
            pressedOpacity: 0.98,
            imageFit: BoxFit.contain,
          );
          final nextStyle = _mergeStyle(c.style, overrides);
          return cloneControlWithOverrides(c, style: nextStyle);
        },
      ),
    ],
  );
}

class ExampleVirtualControlTheme extends VirtualControlTheme {
  const ExampleVirtualControlTheme({
    this.overrideStyle,
    this.overrideExisting = false,
    this.overrideLayout,
    this.overrideExistingLayout = false,
  });

  final ControlStyle? Function(VirtualControl control)? overrideStyle;
  final bool overrideExisting;
  final ControlLayout? Function(VirtualControl control)? overrideLayout;
  final bool overrideExistingLayout;

  @override
  VirtualControl decorate(VirtualControl control) {
    final injectedConfig = _resolveConfigFor(control);
    final resolvedConfig = injectedConfig ?? control.config;

    final injectedLayout = overrideLayout?.call(control);
    final resolvedLayout = injectedLayout != null && overrideExistingLayout
        ? injectedLayout
        : _resolveLayoutFor(control) ?? control.layout;

    final injected = overrideStyle?.call(control);
    final (bg, pressed) = _assetPathsFrom(resolvedConfig);
    final resolvedStyle =
        injected != null && (overrideExisting || control.style == null)
            ? _mergeImages(injected, bg, pressed)
            : _resolveStyleFor(control, resolvedConfig);

    final nextStyle = resolvedStyle ?? control.style;
    final changedStyle = !identical(nextStyle, control.style);
    final changedLayout = resolvedLayout != control.layout;
    final changedConfig = injectedConfig != null;

    if (!changedStyle && !changedLayout && !changedConfig) return control;
    return cloneControlWithOverrides(
      control,
      style: changedStyle ? nextStyle : null,
      layout: changedLayout ? resolvedLayout : null,
      config: changedConfig ? resolvedConfig : null,
    );
  }
}

ControlStyle? _resolveStyleFor(
  VirtualControl control,
  Map<String, dynamic> config,
) {
  final (assetPath, pressedAssetPath) = _assetPathsFrom(config);

  const baseKeyStyle = ControlStyle(
    shape: BoxShape.circle,
    borderColor: Colors.white24,
    pressedBorderColor: Colors.white38,
    borderWidth: 1.0,
    color: Color(0xFF3A3A3C),
    pressedColor: Color(0xFF4A4A4C),
    pressedOpacity: 0.95,
    labelStyle: TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.0,
    ),
    imageFit: BoxFit.contain,
  );

  const baseMouseStyle = ControlStyle(
    shape: BoxShape.circle,
    borderColor: Colors.white24,
    pressedBorderColor: Colors.white38,
    borderWidth: 1.0,
    color: Color(0xFF3A3A3C),
    pressedColor: Color(0xFF4A4A4C),
    pressedOpacity: 0.95,
    labelStyle: TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.0,
    ),
    imageFit: BoxFit.contain,
  );

  const baseGamepadStyle = ControlStyle(
    shape: BoxShape.circle,
    borderColor: Colors.white24,
    pressedBorderColor: Colors.white38,
    borderWidth: 1.0,
    color: Color(0xFF3A3A3C),
    pressedColor: Color(0xFF4A4A4C),
    pressedOpacity: 0.95,
    labelStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      height: 1.0,
    ),
    imageFit: BoxFit.contain,
  );

  const baseScrollStickStyle = ControlStyle(
    shape: BoxShape.rectangle,
    borderRadius: 999.0,
    borderColor: Colors.white24,
    pressedBorderColor: Colors.white38,
    borderWidth: 1.0,
    color: Color(0x263A3A3C),
    pressedColor: Color(0x334A4A4C),
    pressedOpacity: 1.0,
    imageFit: BoxFit.contain,
  );

  if (control is VirtualKey) {
    final existing = control.style;
    if (existing != null) {
      return _mergeImages(
        _withShape(existing, BoxShape.circle),
        assetPath,
        pressedAssetPath,
      );
    }
    return _withImages(baseKeyStyle, assetPath, pressedAssetPath);
  }
  if (control is VirtualKeyCluster) {
    final existing = control.style;
    if (existing != null) {
      return _mergeImages(
        _withShape(existing, BoxShape.circle),
        assetPath,
        pressedAssetPath,
      );
    }
    return _withImages(baseKeyStyle, assetPath, pressedAssetPath);
  }
  if (control is VirtualMouseButton) {
    final existing = control.style;
    if (existing != null) {
      return _mergeImages(
        _withShape(existing, BoxShape.circle),
        assetPath,
        pressedAssetPath,
      );
    }
    return _withImages(baseMouseStyle, assetPath, pressedAssetPath);
  }
  if (control is VirtualMouseWheel) {
    final existing = control.style;
    if (existing != null) {
      return _mergeImages(
        _withShape(existing, BoxShape.circle),
        assetPath,
        pressedAssetPath,
      );
    }
    return _withImages(baseMouseStyle, assetPath, pressedAssetPath);
  }
  if (control is VirtualSplitMouse) {
    final existing = control.style;
    if (existing != null) {
      return _mergeImages(
        _withShape(existing, BoxShape.circle),
        assetPath,
        pressedAssetPath,
      );
    }
    return _withImages(baseMouseStyle, assetPath, pressedAssetPath);
  }

  final existing = control.style;
  if (existing != null) {
    return _mergeImages(existing, assetPath, pressedAssetPath);
  }

  if (control is VirtualScrollStick) {
    return _withImages(baseScrollStickStyle, assetPath, pressedAssetPath);
  }
  if (control is VirtualJoystick) {
    const base = ControlStyle(
      shape: BoxShape.circle,
      borderColor: Colors.white24,
      pressedBorderColor: Colors.white38,
      borderWidth: 1.0,
      color: Color(0xFF3A3A3C),
      pressedColor: Color(0xFF4A4A4C),
      pressedOpacity: 0.95,
      imageFit: BoxFit.contain,
    );
    return _withImages(base, assetPath, pressedAssetPath);
  }
  if (control is VirtualDpad) {
    const base = ControlStyle(
      borderColor: Colors.black26,
      borderWidth: 1.0,
      color: Color(0xFF2F2F31),
      pressedColor: Color(0xFF3A3A3C),
      pressedOpacity: 0.98,
      imageFit: BoxFit.contain,
    );
    return _withImages(base, assetPath, pressedAssetPath);
  }
  if (control is VirtualButton) {
    final padKey = _padKeyFrom(control);
    final isFaceButton = padKey == 'a' ||
        padKey == 'b' ||
        padKey == 'x' ||
        padKey == 'y' ||
        padKey == 'triangle' ||
        padKey == 'circle' ||
        padKey == 'square' ||
        padKey == 'cross';
    if (isFaceButton) {
      return _withImages(baseGamepadStyle, assetPath, pressedAssetPath);
    }
    const base = ControlStyle(
      shape: BoxShape.circle,
      borderColor: Colors.white24,
      pressedBorderColor: Colors.white38,
      borderWidth: 1.0,
      color: Color(0xFF3A3A3C),
      pressedColor: Color(0xFF4A4A4C),
      pressedOpacity: 0.95,
      labelStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        height: 1.0,
      ),
      imageFit: BoxFit.contain,
    );
    return _withImages(base, assetPath, pressedAssetPath);
  }

  if (assetPath != null || pressedAssetPath != null) {
    return _withImages(const ControlStyle(), assetPath, pressedAssetPath);
  }

  return null;
}

ControlStyle _withShape(ControlStyle base, BoxShape shape) {
  if (base.shape == shape) return base;
  return ControlStyle(
    shape: shape,
    borderRadius: base.borderRadius,
    color: base.color,
    pressedColor: base.pressedColor,
    borderColor: base.borderColor,
    pressedBorderColor: base.pressedBorderColor,
    lockedColor: base.lockedColor,
    borderWidth: base.borderWidth,
    backgroundImage: base.backgroundImage,
    pressedBackgroundImage: base.pressedBackgroundImage,
    backgroundImagePath: base.backgroundImagePath,
    pressedBackgroundImagePath: base.pressedBackgroundImagePath,
    opacity: base.opacity,
    pressedOpacity: base.pressedOpacity,
    labelText: base.labelText,
    labelIcon: base.labelIcon,
    labelIconColor: base.labelIconColor,
    labelIconScale: base.labelIconScale,
    useGamepadSymbol: base.useGamepadSymbol,
    labelStyle: base.labelStyle,
    shadows: base.shadows,
    pressedShadows: base.pressedShadows,
    imageFit: base.imageFit,
  );
}

ControlStyle _mergeStyle(ControlStyle? base, ControlStyle overrides) {
  final resolvedBase = base ?? const ControlStyle();
  return ControlStyle(
    shape: overrides.shape,
    borderRadius: overrides.borderRadius,
    color: overrides.color ?? resolvedBase.color,
    pressedColor: overrides.pressedColor ?? resolvedBase.pressedColor,
    borderColor: overrides.borderColor ?? resolvedBase.borderColor,
    pressedBorderColor:
        overrides.pressedBorderColor ?? resolvedBase.pressedBorderColor,
    lockedColor: overrides.lockedColor ?? resolvedBase.lockedColor,
    borderWidth: overrides.borderWidth,
    backgroundImage: resolvedBase.backgroundImage,
    pressedBackgroundImage: resolvedBase.pressedBackgroundImage,
    backgroundImagePath: resolvedBase.backgroundImagePath,
    pressedBackgroundImagePath: resolvedBase.pressedBackgroundImagePath,
    opacity: overrides.opacity,
    pressedOpacity: overrides.pressedOpacity,
    labelText: overrides.labelText ?? resolvedBase.labelText,
    labelIcon: overrides.labelIcon ?? resolvedBase.labelIcon,
    labelIconColor: overrides.labelIconColor ?? resolvedBase.labelIconColor,
    labelIconScale: overrides.labelIconScale,
    useGamepadSymbol: overrides.useGamepadSymbol,
    labelStyle: overrides.labelStyle ?? resolvedBase.labelStyle,
    shadows:
        overrides.shadows.isNotEmpty ? overrides.shadows : resolvedBase.shadows,
    pressedShadows: overrides.pressedShadows.isNotEmpty
        ? overrides.pressedShadows
        : resolvedBase.pressedShadows,
    imageFit: overrides.imageFit,
  );
}

ControlStyle _mergeImages(
  ControlStyle base,
  String? background,
  String? pressed,
) {
  final hasAnyBg =
      base.backgroundImage != null || base.backgroundImagePath != null;
  final hasAnyPressed = base.pressedBackgroundImage != null ||
      base.pressedBackgroundImagePath != null;
  if (hasAnyBg && hasAnyPressed) return base;
  if (background == null && pressed == null) return base;
  return _withImages(base, background, pressed);
}

ControlStyle _withImages(
  ControlStyle base,
  String? background,
  String? pressed,
) {
  if (background == null && pressed == null) return base;
  return ControlStyle(
    shape: base.shape,
    borderRadius: base.borderRadius,
    color: base.color,
    pressedColor: base.pressedColor,
    borderColor: base.borderColor,
    pressedBorderColor: base.pressedBorderColor,
    lockedColor: base.lockedColor,
    borderWidth: base.borderWidth,
    backgroundImage: base.backgroundImage,
    pressedBackgroundImage: base.pressedBackgroundImage,
    backgroundImagePath: background ?? base.backgroundImagePath,
    pressedBackgroundImagePath: pressed ?? base.pressedBackgroundImagePath,
    opacity: base.opacity,
    pressedOpacity: base.pressedOpacity,
    labelText: base.labelText,
    labelIcon: base.labelIcon,
    labelIconColor: base.labelIconColor,
    labelIconScale: base.labelIconScale,
    useGamepadSymbol: base.useGamepadSymbol,
    labelStyle: base.labelStyle,
    shadows: base.shadows,
    pressedShadows: base.pressedShadows,
    imageFit: base.imageFit,
  );
}

(String? background, String? pressed) _assetPathsFrom(
  Map<String, dynamic> config,
) {
  String? readString(Object? v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  final background = readString(
    config['backgroundImagePath'] ??
        config['backgroundImage'] ??
        config['assetPath'] ??
        config['bgAssetPath'] ??
        config['bg'],
  );

  final pressed = readString(
    config['pressedBackgroundImagePath'] ??
        config['pressedBackgroundImage'] ??
        config['pressedAssetPath'] ??
        config['thumbAssetPath'] ??
        config['thumbImagePath'] ??
        config['thumb'],
  );

  return (background, pressed);
}

Map<String, dynamic>? _resolveConfigFor(VirtualControl control) {
  if (control is VirtualMouseButton) {
    final uiStyle = control.config['uiStyle'];
    if (uiStyle is String && uiStyle.trim().isNotEmpty) return null;
    return <String, dynamic>{
      ...control.config,
      'uiStyle': 'button',
    };
  }

  if (control is VirtualJoystick && control.mode == JoystickMode.gamepad) {
    final stick = control.stickType;
    if (stick != GamepadStickId.left && stick != GamepadStickId.right) {
      return null;
    }

    final overlayStyle = control.config['overlayStyle'];
    final hasOverlayStyle =
        overlayStyle is String && overlayStyle.trim().isNotEmpty;
    final centerLabel = control.config['centerLabel'];
    final hasCenterLabel =
        centerLabel is String && centerLabel.trim().isNotEmpty;
    if (hasOverlayStyle && hasCenterLabel) return null;

    return <String, dynamic>{
      ...control.config,
      if (!hasOverlayStyle) 'overlayStyle': 'center',
      if (!hasCenterLabel)
        'centerLabel': stick == GamepadStickId.left ? 'L' : 'R',
    };
  }

  return null;
}

ControlLayout? _resolveLayoutFor(VirtualControl control) {
  if (control is! VirtualScrollStick) return null;

  final l = control.layout;
  final ratio = l.height / (l.width == 0 ? 1 : l.width);
  if (ratio >= 2.0 && l.height >= 0.18) return null;

  const defaultWidth = 0.06;
  const minHeight = 0.45;
  final newWidth = l.width.clamp(0.03, defaultWidth);
  final newHeight =
      (l.height < minHeight ? minHeight : l.height).clamp(0.18, 0.8);

  final centerX = l.x + l.width / 2;
  final centerY = l.y + l.height / 2;

  final newX = (centerX - newWidth / 2).clamp(0.0, 1.0 - newWidth);
  final newY = (centerY - newHeight / 2).clamp(0.0, 1.0 - newHeight);

  return ControlLayout(
    x: newX,
    y: newY,
    width: newWidth,
    height: newHeight,
  );
}

String _padKeyFrom(VirtualButton control) {
  final v = control.config['padKey'] ??
      control.config['button'] ??
      control.config['gamepadButton'];
  if (v != null) return v.toString().trim().toLowerCase();
  return control.binding.code.trim().toLowerCase();
}
