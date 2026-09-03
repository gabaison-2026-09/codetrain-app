/// APIエラーを表す例外。
///
/// `docs/API_DESIGN.md` §1.1 / §4 の共通エラーエンベロープ
/// `{"error": {"code": "...", "message": "..."}}` を変換して生成する。
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  /// HTTPレスポンスから例外を組み立てる。
  ///
  /// [decodedBody] は `jsonDecode` 済みのボディ（失敗時は `null`）。
  /// エラーエンベロープ形式なら `code` / `message` を採用し、そうでなければ
  /// HTTPステータスから汎用コードにフォールバックする。
  factory ApiException.fromResponse(int statusCode, Object? decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      final error = decodedBody['error'];
      if (error is Map<String, dynamic>) {
        final code = error['code'];
        final message = error['message'];
        if (code is String && code.isNotEmpty) {
          return ApiException(
            code: code,
            message: message is String && message.isNotEmpty
                ? message
                : _defaultMessageFor(statusCode),
            statusCode: statusCode,
          );
        }
      }
    }
    return ApiException(
      code: _fallbackCodeFor(statusCode),
      message: _defaultMessageFor(statusCode),
      statusCode: statusCode,
    );
  }

  /// ネットワーク到達不能（接続失敗・タイムアウト等）。
  factory ApiException.network([Object? cause]) {
    return ApiException(
      code: codeNetworkError,
      message: cause == null
          ? 'ネットワークに接続できませんでした'
          : 'ネットワークに接続できませんでした: $cause',
      statusCode: 0,
    );
  }

  final String code;
  final String message;

  /// HTTPステータスコード。ネットワークエラー時は `0`。
  final int statusCode;

  // docs/API_DESIGN.md §4 共通コード
  static const String codeValidationError = 'VALIDATION_ERROR';
  static const String codeUnauthorized = 'UNAUTHORIZED';
  static const String codeForbidden = 'FORBIDDEN';
  static const String codeNotFound = 'NOT_FOUND';
  static const String codeConflict = 'CONFLICT';
  static const String codeInternalError = 'INTERNAL_ERROR';

  /// クライアント都合の通信エラー（API設計外の独自コード）。
  static const String codeNetworkError = 'NETWORK_ERROR';

  bool get isNetworkError => code == codeNetworkError;
  bool get isUnauthorized => statusCode == 401;

  static String _fallbackCodeFor(int statusCode) {
    switch (statusCode) {
      case 400:
        return codeValidationError;
      case 401:
        return codeUnauthorized;
      case 403:
        return codeForbidden;
      case 404:
        return codeNotFound;
      case 409:
        return codeConflict;
      default:
        return codeInternalError;
    }
  }

  static String _defaultMessageFor(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'リクエストの内容が正しくありません';
      case 401:
        return '認証が必要です';
      case 403:
        return 'この操作を行う権限がありません';
      case 404:
        return 'リソースが見つかりません';
      case 409:
        return '状態が競合しています';
      default:
        return 'サーバーエラーが発生しました';
    }
  }

  @override
  String toString() => 'ApiException($code, status: $statusCode): $message';
}
