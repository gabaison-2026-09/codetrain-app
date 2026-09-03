import 'package:codetrain_app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException.fromResponse', () {
    test('エラーエンベロープから code / message を採用する', () {
      final exception = ApiException.fromResponse(404, {
        'error': {'code': 'QUESTION_NOT_FOUND', 'message': '問題が見つかりません'},
      });

      expect(exception.code, 'QUESTION_NOT_FOUND');
      expect(exception.message, '問題が見つかりません');
      expect(exception.statusCode, 404);
    });

    test('非標準ボディはHTTPステータスから汎用コードにフォールバックする', () {
      final exception = ApiException.fromResponse(500, {'unexpected': true});

      expect(exception.code, ApiException.codeInternalError);
      expect(exception.statusCode, 500);
    });

    test('ボディが null（パース不能）でもステータスからコードを決める', () {
      final exception = ApiException.fromResponse(401, null);

      expect(exception.code, ApiException.codeUnauthorized);
      expect(exception.isUnauthorized, isTrue);
    });

    test('ネットワークエラーは NETWORK_ERROR / statusCode 0', () {
      final exception = ApiException.network('SocketException');

      expect(exception.code, ApiException.codeNetworkError);
      expect(exception.statusCode, 0);
      expect(exception.isNetworkError, isTrue);
    });
  });
}
