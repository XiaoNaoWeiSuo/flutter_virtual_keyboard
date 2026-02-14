import '../models/virtual_controller_models.dart';

abstract class VirtualControlTheme {
  const VirtualControlTheme();

  VirtualControl decorate(VirtualControl control);
}

class DefaultVirtualControlTheme extends VirtualControlTheme {
  const DefaultVirtualControlTheme();

  @override
  VirtualControl decorate(VirtualControl control) => control;
}

