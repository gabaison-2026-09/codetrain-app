import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/env/app_config.dart';

void main() {
  // --dart-define で解決された接続先を起動時に確認できるようにする。
  // API連携の配線は Issue 31 以降で行う。
  if (kDebugMode) {
    debugPrint('AppConfig: ${AppConfig.fromEnvironment()}');
  }
  runApp(const CodeTrainApp());
}
