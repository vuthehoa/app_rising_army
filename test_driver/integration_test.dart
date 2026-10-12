import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Ghi ảnh chụp từ integration test ra thư mục chỉ định bởi biến môi trường SHOT_DIR.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final dir = Directory(Platform.environment['SHOT_DIR'] ?? 'build/shots')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes);
    return true;
  },
);
