part of '../models/style/control_style.dart';

class ControlStyleJsonCodec {
  static ControlStyle fromJson(Map<String, dynamic> json) {
    final shape = (json['shape'] as String?) == 'rectangle'
        ? BoxShape.rectangle
        : BoxShape.circle;

    return ControlStyle(
      shape: shape,
      borderRadius: (json['borderRadius'] as num? ?? 8.0).toDouble(),
      color: _ColorJsonCodec.maybeDecode(json['color']),
      pressedColor: _ColorJsonCodec.maybeDecode(json['pressedColor']),
      borderColor: _ColorJsonCodec.maybeDecode(json['borderColor']),
      pressedBorderColor:
          _ColorJsonCodec.maybeDecode(json['pressedBorderColor']),
      borderWidth: (json['borderWidth'] as num? ?? 2.0).toDouble(),
      backgroundImagePath: _readString(json['backgroundImage']),
      pressedBackgroundImagePath: _readString(json['pressedBackgroundImage']),
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(),
      pressedOpacity: (json['pressedOpacity'] as num? ?? 0.8).toDouble(),
      labelStyle: json['labelStyle'] is Map<String, dynamic>
          ? _TextStyleJsonCodec.maybeDecode(
              Map<String, dynamic>.from(json['labelStyle'] as Map),
            )
          : null,
      shadows: json['shadows'] is List
          ? (json['shadows'] as List)
              .whereType<Map>()
              .map((m) =>
                  _BoxShadowJsonCodec.decode(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      pressedShadows: json['pressedShadows'] is List
          ? (json['pressedShadows'] as List)
              .whereType<Map>()
              .map((m) =>
                  _BoxShadowJsonCodec.decode(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      imageFit: _BoxFitJsonCodec.decode(json['imageFit']),
    );
  }

  static Map<String, dynamic> toJson(ControlStyle style) {
    final bgPath = style.backgroundImagePath ??
        _ImageProviderCodec.tryEncode(style.backgroundImage);
    final pressedBgPath = style.pressedBackgroundImagePath ??
        _ImageProviderCodec.tryEncode(style.pressedBackgroundImage);

    return <String, dynamic>{
      'shape': style.shape == BoxShape.rectangle ? 'rectangle' : 'circle',
      'borderRadius': style.borderRadius,
      if (style.color != null) 'color': _ColorJsonCodec.encode(style.color!),
      if (style.pressedColor != null)
        'pressedColor': _ColorJsonCodec.encode(style.pressedColor!),
      if (style.borderColor != null)
        'borderColor': _ColorJsonCodec.encode(style.borderColor!),
      if (style.pressedBorderColor != null)
        'pressedBorderColor': _ColorJsonCodec.encode(style.pressedBorderColor!),
      'borderWidth': style.borderWidth,
      if (bgPath != null) 'backgroundImage': bgPath,
      if (pressedBgPath != null) 'pressedBackgroundImage': pressedBgPath,
      'opacity': style.opacity,
      'pressedOpacity': style.pressedOpacity,
      if (style.labelStyle != null)
        'labelStyle': _TextStyleJsonCodec.encode(style.labelStyle!),
      if (style.shadows.isNotEmpty)
        'shadows': style.shadows.map(_BoxShadowJsonCodec.encode).toList(),
      if (style.pressedShadows.isNotEmpty)
        'pressedShadows':
            style.pressedShadows.map(_BoxShadowJsonCodec.encode).toList(),
      'imageFit': _BoxFitJsonCodec.encode(style.imageFit),
    };
  }
}

String? _readString(Object? v) {
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s;
}

class _ColorJsonCodec {
  static Color? maybeDecode(Object? v) {
    final value = _decodeToInt(v);
    if (value == null) return null;
    return Color(value);
  }

  static String encode(Color c) {
    // ignore: deprecated_member_use
    return '0x${c.value.toRadixString(16).padLeft(8, '0')}';
  }

  static int? _decodeToInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final normalized = s.startsWith('#') ? s.substring(1) : s;
    return int.tryParse(normalized, radix: 16);
  }
}    final withPrefix =
        normalized.startsWith('0x') || normalized.startsWith('0X')
            ? normalized
            : '0x$normalized';
    return int.tryParse(withPrefix);
  }
}

class _BoxFitJsonCodec {
  static BoxFit decode(Object? v) {
    final s = v?.toString().trim();
    return switch (s) {
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      'fitWidth' => BoxFit.fitWidth,
      'fitHeight' => BoxFit.fitHeight,
      'none' => BoxFit.none,
      'scaleDown' => BoxFit.scaleDown,
      _ => BoxFit.cover,
    };
  }

  static String encode(BoxFit fit) {
    return fit.toString().split('.').last;
  }
}

class _ImageProviderCodec {
  static String? tryEncode(ImageProvider? provider) {
    if (provider == null) return null;
    if (provider is NetworkImage) return provider.url;
    if (provider is AssetImage) return provider.assetName;
    return null;
  }
}

class _TextStyleJsonCodec {
  static TextStyle? maybeDecode(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    final color = _ColorJsonCodec.maybeDecode(json['color']);
    final fontSize = (json['fontSize'] as num?)?.toDouble();
    final height = (json['height'] as num?)?.toDouble();
    final letterSpacing = (json['letterSpacing'] as num?)?.toDouble();
    final fontWeight = _FontWeightJsonCodec.decode(json['fontWeight']);
    return TextStyle(
      color: color,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
    );
  }

  static Map<String, dynamic> encode(TextStyle style) {
    return <String, dynamic>{
      if (style.color != null) 'color': _ColorJsonCodec.encode(style.color!),
      if (style.fontSize != null) 'fontSize': style.fontSize,
      if (style.height != null) 'height': style.height,
      if (style.letterSpacing != null) 'letterSpacing': style.letterSpacing,
      if (style.fontWeight != null)
        'fontWeight': _FontWeightJsonCodec.encode(style.fontWeight!),
    };
  }
}

class _FontWeightJsonCodec {
  static FontWeight? decode(Object? v) {
    if (v == null) return null;
    if (v is int)
      return FontWeight.values[v.clamp(0, FontWeight.values.length - 1)];
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.startsWith('w')) {
      final n = int.tryParse(s.substring(1));
      if (n == null) return null;
      return switch (n) {
        100 => FontWeight.w100,
        200 => FontWeight.w200,
        300 => FontWeight.w300,
        400 => FontWeight.w400,
        500 => FontWeight.w500,
        600 => FontWeight.w600,
        700 => FontWeight.w700,
        800 => FontWeight.w800,
        900 => FontWeight.w900,
        _ => null,
      };
    }
    return null;
  }

  static String encode(FontWeight w) {
    return 'w${w.index * 100 + 100}';
  }
}

class _BoxShadowJsonCodec {
  static BoxShadow decode(Map<String, dynamic> json) {
    final color = _ColorJsonCodec.maybeDecode(json['color']) ?? Colors.black26;
    final blur = (json['blurRadius'] as num? ?? 0.0).toDouble();
    final spread = (json['spreadRadius'] as num? ?? 0.0).toDouble();
    final dx = (json['offsetX'] as num? ?? 0.0).toDouble();
    final dy = (json['offsetY'] as num? ?? 0.0).toDouble();
    return BoxShadow(
      color: color,
      blurRadius: blur,
      spreadRadius: spread,
      offset: Offset(dx, dy),
    );
  }

  static Map<String, dynamic> encode(BoxShadow s) {
    return <String, dynamic>{
      'color': _ColorJsonCodec.encode(s.color),
      'blurRadius': s.blurRadius,
      'spreadRadius': s.spreadRadius,
      'offsetX': s.offset.dx,
      'offsetY': s.offset.dy,
    };
  }
}
