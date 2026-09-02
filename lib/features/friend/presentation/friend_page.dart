import 'package:flutter/material.dart';

import '../domain/friend_repository.dart';
import '../domain/friend_user.dart';

class FriendPage extends StatefulWidget {
  const FriendPage({super.key, required this.repository});

  final FriendRepository repository;

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  static const _purple = Color(0xff6263d9);
  static const _orange = Color(0xffff6a2a);
  static const _ink = Color(0xff222229);
  static const _muted = Color(0xff777782);
  static const _line = Color(0xffe3e3e9);

  late Future<List<FriendUser>> _usersFuture;
  FriendFilter _filter = FriendFilter.friends;
  String? _busyUserId;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<FriendUser>> _fetchUsers() {
    return widget.repository.fetchUsers(filter: _filter);
  }

  void _reload() {
    setState(() => _usersFuture = _fetchUsers());
  }

  void _selectFilter(FriendFilter filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _usersFuture = _fetchUsers();
    });
  }

  Future<void> _openUserSearch() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _FriendSearchSheet(repository: widget.repository),
    );
    if (mounted) _reload();
  }

  Future<void> _runAction(
    FriendUser user,
    Future<void> Function(String userId) action,
  ) async {
    setState(() => _busyUserId = user.id);
    try {
      await action(user.id);
      if (!mounted) return;
      setState(() {
        _busyUserId = null;
        _usersFuture = _fetchUsers();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作できませんでした')),
      );
    }
  }

  Future<void> _confirmRemove(FriendUser user) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(user.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('解除'),
          ),
        ],
      ),
    );
    if (shouldRemove == true && mounted) {
      await _runAction(user, widget.repository.removeFriend);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaPadding = MediaQuery.paddingOf(context);
        final bottomScale = (constraints.maxWidth / 973).clamp(0.32, 1.0);
        final bottomHeight = 325 * bottomScale + mediaPadding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            64 + mediaPadding.top + 24,
            22,
            bottomHeight,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'フレンド',
                          style: TextStyle(
                            color: _ink,
                            fontFamily: 'Noto Sans Japanese',
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        key: const ValueKey('friend-open-search'),
                        onPressed: _openUserSearch,
                        style: IconButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.square(48),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FilterBar(selected: _filter, onSelected: _selectFilter),
                  const Divider(height: 1, color: _line),
                  Expanded(
                    child: FutureBuilder<List<FriendUser>>(
                      future: _usersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: _purple),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: IconButton(
                              key: const ValueKey('friend-retry-button'),
                              onPressed: _reload,
                              color: _muted,
                              iconSize: 32,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          );
                        }
                        final users = snapshot.data ?? const <FriendUser>[];
                        if (users.isEmpty) {
                          return const Center(
                            child: Icon(
                              Icons.person_search_outlined,
                              color: _muted,
                              size: 34,
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: users.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: _line),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _FriendRow(
                              user: user,
                              isBusy: _busyUserId == user.id,
                              onSend: () => _runAction(
                                user,
                                widget.repository.sendRequest,
                              ),
                              onCancel: () => _runAction(
                                user,
                                widget.repository.cancelRequest,
                              ),
                              onAccept: () => _runAction(
                                user,
                                widget.repository.acceptRequest,
                              ),
                              onDecline: () => _runAction(
                                user,
                                widget.repository.declineRequest,
                              ),
                              onRemove: () => _confirmRemove(user),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FriendSearchSheet extends StatefulWidget {
  const _FriendSearchSheet({required this.repository});

  final FriendRepository repository;

  @override
  State<_FriendSearchSheet> createState() => _FriendSearchSheetState();
}

class _FriendSearchSheetState extends State<_FriendSearchSheet> {
  final _userCodeController = TextEditingController();
  FriendUser? _result;
  var _hasSearched = false;
  var _isSearching = false;
  var _isSending = false;

  @override
  void dispose() {
    _userCodeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final userCode = _userCodeController.text.trim();
    if (userCode.isEmpty || _isSearching) return;
    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _result = null;
    });
    try {
      final result = await widget.repository.searchUserByCode(userCode);
      if (!mounted) return;
      setState(() {
        _result = result;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('検索できませんでした')),
      );
    }
  }

  Future<void> _sendRequest() async {
    final user = _result;
    if (user == null || _isSending) return;
    setState(() => _isSending = true);
    try {
      await widget.repository.sendRequest(user.id);
      if (!mounted) return;
      setState(() {
        _result = user.copyWith(
          relationship: FriendRelationship.outgoingRequest,
        );
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申請できませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: 390,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _FriendPageState._line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ユーザー検索',
                      style: TextStyle(
                        color: _FriendPageState._ink,
                        fontFamily: 'Noto Sans Japanese',
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('friend-search-field'),
                      controller: _userCodeController,
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'ユーザーID',
                        prefixText: '@',
                        filled: true,
                        fillColor: const Color(0xfff5f5f7),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _FriendPageState._purple,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    key: const ValueKey('friend-search-button'),
                    onPressed: _isSearching ? null : _search,
                    style: IconButton.styleFrom(
                      backgroundColor: _FriendPageState._purple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _FriendPageState._line,
                      minimumSize: const Size.square(48),
                    ),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: _FriendPageState._line),
              Expanded(child: _buildResult()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: _FriendPageState._purple),
      );
    }
    final user = _result;
    if (user == null) {
      if (!_hasSearched) return const SizedBox.shrink();
      return const Center(
        child: Icon(
          Icons.person_search_outlined,
          color: _FriendPageState._muted,
          size: 34,
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        key: ValueKey('friend-search-result-${user.id}'),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xffeeeef2),
              foregroundColor: _FriendPageState._ink,
              child: Text(
                user.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _FriendPageState._ink,
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${user.userCode}',
                    style: const TextStyle(
                      color: _FriendPageState._muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isSending)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _FriendPageState._purple,
                ),
              )
            else
              _SearchRelationshipAction(
                user: user,
                onSend: _sendRequest,
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchRelationshipAction extends StatelessWidget {
  const _SearchRelationshipAction({required this.user, required this.onSend});

  final FriendUser user;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    if (user.relationship == FriendRelationship.none) {
      return TextButton(
        key: ValueKey('friend-send-${user.id}'),
        onPressed: onSend,
        style: TextButton.styleFrom(
          foregroundColor: _FriendPageState._purple,
          minimumSize: const Size(44, 40),
        ),
        child: const Text('申請'),
      );
    }
    final label = switch (user.relationship) {
      FriendRelationship.friend => 'フレンド',
      FriendRelationship.outgoingRequest => '申請中',
      FriendRelationship.incomingRequest => '受信',
      FriendRelationship.none => '',
    };
    return Text(
      label,
      style: const TextStyle(
        color: _FriendPageState._muted,
        fontFamily: 'Noto Sans Japanese',
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final FriendFilter selected;
  final ValueChanged<FriendFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = <(FriendFilter, String)>[
      (FriendFilter.friends, 'フレンド'),
      (FriendFilter.outgoing, '申請中'),
      (FriendFilter.incoming, '受信'),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: InkWell(
              key: ValueKey('friend-filter-${item.$1.name}'),
              onTap: () => onSelected(item.$1),
              child: Container(
                padding: const EdgeInsets.only(bottom: 13),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected == item.$1
                          ? _FriendPageState._purple
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected == item.$1
                        ? _FriendPageState._ink
                        : _FriendPageState._muted,
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.user,
    required this.isBusy,
    required this.onSend,
    required this.onCancel,
    required this.onAccept,
    required this.onDecline,
    required this.onRemove,
  });

  final FriendUser user;
  final bool isBusy;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('friend-user-${user.id}'),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xffeeeef2),
            foregroundColor: _FriendPageState._ink,
            child: Text(
              user.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FriendPageState._ink,
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.userCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FriendPageState._muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (user.relationship == FriendRelationship.friend) ...[
            SizedBox(
              width: 58,
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_outlined,
                    color: _FriendPageState._orange,
                    size: 17,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${user.streakDays}日',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _FriendPageState._ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (isBusy)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _FriendPageState._purple,
              ),
            )
          else
            _RelationshipActions(
              user: user,
              onSend: onSend,
              onCancel: onCancel,
              onAccept: onAccept,
              onDecline: onDecline,
              onRemove: onRemove,
            ),
        ],
      ),
    );
  }
}

class _RelationshipActions extends StatelessWidget {
  const _RelationshipActions({
    required this.user,
    required this.onSend,
    required this.onCancel,
    required this.onAccept,
    required this.onDecline,
    required this.onRemove,
  });

  final FriendUser user;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = TextButton.styleFrom(
      foregroundColor: _FriendPageState._muted,
      minimumSize: const Size(44, 40),
      padding: const EdgeInsets.symmetric(horizontal: 9),
    );
    final primaryStyle = TextButton.styleFrom(
      foregroundColor: _FriendPageState._purple,
      minimumSize: const Size(44, 40),
      padding: const EdgeInsets.symmetric(horizontal: 9),
    );
    return switch (user.relationship) {
      FriendRelationship.none => TextButton(
          key: ValueKey('friend-send-${user.id}'),
          onPressed: onSend,
          style: primaryStyle,
          child: const Text('申請'),
        ),
      FriendRelationship.friend => PopupMenuButton<String>(
          key: ValueKey('friend-menu-${user.id}'),
          onSelected: (_) => onRemove(),
          color: Colors.white,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: _FriendPageState._muted,
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'remove',
              child: Text('フレンド解除'),
            ),
          ],
        ),
      FriendRelationship.outgoingRequest => TextButton(
          key: ValueKey('friend-cancel-${user.id}'),
          onPressed: onCancel,
          style: secondaryStyle,
          child: const Text('取消'),
        ),
      FriendRelationship.incomingRequest => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              key: ValueKey('friend-decline-${user.id}'),
              onPressed: onDecline,
              style: secondaryStyle,
              child: const Text('拒否'),
            ),
            TextButton(
              key: ValueKey('friend-accept-${user.id}'),
              onPressed: onAccept,
              style: primaryStyle,
              child: const Text('承認'),
            ),
          ],
        ),
    };
  }
}
