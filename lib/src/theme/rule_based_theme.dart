import '../models/virtual_controller_models.dart';
import 'control_matchers.dart';
import 'virtual_control_theme.dart';

class ControlRule {
  const ControlRule({
    required this.when,
    required this.transform,
  });

  final ControlPredicate when;
  final VirtualControl Function(VirtualControl control) transform;
}

class RuleBasedVirtualControlTheme extends VirtualControlTheme {
  const RuleBasedVirtualControlTheme({
    required this.base,
    this.pre = const [],
    this.post = const [],
  });

  final VirtualControlTheme base;
  final List<ControlRule> pre;
  final List<ControlRule> post;

  @override
  VirtualControl decorate(VirtualControl control) {
    var c = control;
    for (final rule in pre) {
      if (!rule.when(c)) continue;
      c = rule.transform(c);
    }
    c = base.decorate(c);
    for (final rule in post) {
      if (!rule.when(c)) continue;
      c = rule.transform(c);
    }
    return c;
  }
}

