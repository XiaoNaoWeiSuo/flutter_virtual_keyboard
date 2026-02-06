import '../models/style/control_style.dart';

ControlStyle controlStyleFromJson(Map<String, dynamic> json) {
  return ControlStyleJsonCodec.fromJson(json);
}

Map<String, dynamic> controlStyleToJson(ControlStyle style) {
  return ControlStyleJsonCodec.toJson(style);
}
