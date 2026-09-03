import 'api_exception.dart';

/// 2xx レスポンスのJSON形状を検証する。
///
/// HTTPエラーだけでなく、バックエンドとの契約差異もRepository利用側へ
/// [ApiException] として一貫して通知するための変換境界。
Map<String, dynamic> expectJsonObject(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const ApiException(
    code: ApiException.codeInvalidResponse,
    message: 'APIレスポンスの形式が不正です',
    statusCode: 200,
  );
}

List<Map<String, dynamic>> expectJsonObjectList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value is! List) {
    throw const ApiException(
      code: ApiException.codeInvalidResponse,
      message: 'APIレスポンスの一覧形式が不正です',
      statusCode: 200,
    );
  }
  try {
    return value.cast<Map<String, dynamic>>();
  } on TypeError {
    throw const ApiException(
      code: ApiException.codeInvalidResponse,
      message: 'APIレスポンスの一覧要素が不正です',
      statusCode: 200,
    );
  }
}

T parseApiResponse<T>(T Function() parse) {
  try {
    return parse();
  } on TypeError catch (_) {
    throw const ApiException(
      code: ApiException.codeInvalidResponse,
      message: 'APIレスポンスのフィールド形式が不正です',
      statusCode: 200,
    );
  } on FormatException catch (_) {
    throw const ApiException(
      code: ApiException.codeInvalidResponse,
      message: 'APIレスポンスの値が不正です',
      statusCode: 200,
    );
  }
}
