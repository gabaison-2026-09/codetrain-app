import 'package:codetrain_app/core/env/app_config.dart';
import 'package:codetrain_app/core/env/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.resolve', () {
    test('ベースURL未指定・AUTH_MODE既定で local 環境になりフォールバックURLを使う', () {
      final config = AppConfig.resolve(
        apiBaseUrl: '',
        authMode: 'dev',
        devUser: AppConfig.defaultDevUser,
      );

      expect(config.apiBaseUrl.toString(), AppConfig.fallbackLocalBaseUrl);
      expect(config.environment, AppEnvironment.local);
      expect(config.devUser, AppConfig.defaultDevUser);
    });

    test('ベースURLを明示指定すると dev 環境になる', () {
      final config = AppConfig.resolve(
        apiBaseUrl: 'https://staging.example.com',
        authMode: 'dev',
        devUser: 'tester',
      );

      expect(config.apiBaseUrl, Uri.parse('https://staging.example.com'));
      expect(config.environment, AppEnvironment.dev);
      expect(config.devUser, 'tester');
    });

    test('AUTH_MODE=prod で prod 環境になり devUser は null', () {
      final config = AppConfig.resolve(
        apiBaseUrl: 'https://api.example.com',
        authMode: 'prod',
        devUser: 'ignored',
      );

      expect(config.environment, AppEnvironment.prod);
      expect(config.devUser, isNull);
      expect(config.environment.isProduction, isTrue);
    });

    test('AUTH_MODE の大文字・前後空白を許容する', () {
      final config = AppConfig.resolve(
        apiBaseUrl: '',
        authMode: '  PROD  ',
        devUser: AppConfig.defaultDevUser,
      );

      expect(config.environment, AppEnvironment.prod);
    });
  });
}
