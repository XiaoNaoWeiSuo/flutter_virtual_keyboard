import 'web_interop_test_stub.dart'
    if (dart.library.js_interop) 'web_interop_test_web.dart' as impl;

void main() {
  impl.runWebInteropTests();
}

