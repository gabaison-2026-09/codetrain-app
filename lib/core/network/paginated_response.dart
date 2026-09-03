/// カーソルページング（`docs/API_DESIGN.md` §1 ページング規約）のレスポンスラッパ。
///
/// 一覧系レスポンス `{"<資源名>": [...], "next_cursor": ...}` を汎用的に表す。
class PaginatedResponse<T> {
  const PaginatedResponse({required this.items, required this.nextCursor});

  final List<T> items;

  /// 次ページのカーソル。次ページが無ければ `null`。
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
