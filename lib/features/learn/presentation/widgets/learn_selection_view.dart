import 'package:flutter/material.dart';

import '../../domain/learn_content.dart';

class LearnSelectionView extends StatefulWidget {
  const LearnSelectionView({
    super.key,
    required this.catalog,
    required this.selectedNodeId,
    required this.isLoading,
    required this.errorMessage,
    required this.contentPadding,
    required this.onNodeSelected,
    required this.onStart,
  });

  final LearnCatalog catalog;
  final String? selectedNodeId;
  final bool isLoading;
  final String? errorMessage;
  final EdgeInsets contentPadding;
  final ValueChanged<String> onNodeSelected;
  final VoidCallback onStart;

  @override
  State<LearnSelectionView> createState() => _LearnSelectionViewState();
}

class _LearnSelectionViewState extends State<LearnSelectionView> {
  final _searchController = TextEditingController();
  late String _selectedSkillId;
  String _selectedDifficulty = '';

  @override
  void initState() {
    super.initState();
    _selectedSkillId =
        widget.catalog.skills.isEmpty ? '' : widget.catalog.skills.first.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_LearnNodeEntry> get _allEntries => [
        for (final skill in widget.catalog.skills)
          for (final node in skill.nodes)
            _LearnNodeEntry(skill: skill, node: node),
      ];

  List<_LearnNodeEntry> get _filteredEntries {
    final query = _searchController.text.trim().toLowerCase();
    return _allEntries.where((entry) {
      final matchesQuery = query.isEmpty ||
          entry.node.name.toLowerCase().contains(query) ||
          entry.skill.name.toLowerCase().contains(query);
      final matchesSkill =
          _selectedSkillId.isEmpty || entry.skill.id == _selectedSkillId;
      final matchesDifficulty = _selectedDifficulty.isEmpty ||
          entry.node.difficulty.toString() == _selectedDifficulty;
      return matchesQuery && matchesSkill && matchesDifficulty;
    }).toList(growable: false);
  }

  void _handleSearchChanged(String value) {
    setState(() {});
  }

  void _handleSkillChanged(String? skillId) {
    setState(() => _selectedSkillId = skillId ?? '');
  }

  void _handleDifficultyChanged(String? difficulty) {
    setState(() => _selectedDifficulty = difficulty ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _filteredEntries;
    final selectedNodeIsVisible =
        filteredEntries.any((entry) => entry.node.id == widget.selectedNodeId);

    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: widget.contentPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SelectionHeader(),
                const SizedBox(height: 24),
                TextField(
                  key: const ValueKey('learn-search-field'),
                  controller: _searchController,
                  onChanged: _handleSearchChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    color: Color(0xff111116),
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: '学習内容を検索',
                    hintStyle: const TextStyle(
                      color: Color(0xff9b9ba4),
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xff777781),
                      size: 21,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '検索をクリア',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xff777781),
                              size: 19,
                            ),
                          ),
                    filled: true,
                    fillColor: const Color(0xfffafafd),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: Color(0xffd9d9df)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: Color(0xffd9d9df)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(
                        color: Color(0xff6263d9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SelectionDropdown(
                        key: const ValueKey('learn-skill-filter'),
                        value: _selectedSkillId,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('すべてのスキル'),
                          ),
                          for (final skill in widget.catalog.skills)
                            DropdownMenuItem(
                              value: skill.id,
                              child: Text(skill.name),
                            ),
                        ],
                        onChanged: _handleSkillChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SelectionDropdown(
                        key: const ValueKey('learn-difficulty-filter'),
                        value: _selectedDifficulty,
                        items: const [
                          DropdownMenuItem(
                            value: '',
                            child: Text('すべての難易度'),
                          ),
                          DropdownMenuItem(value: '1', child: Text('Lv.1')),
                          DropdownMenuItem(value: '2', child: Text('Lv.2')),
                          DropdownMenuItem(value: '3', child: Text('Lv.3')),
                          DropdownMenuItem(value: '4', child: Text('Lv.4')),
                          DropdownMenuItem(value: '5', child: Text('Lv.5')),
                        ],
                        onChanged: _handleDifficultyChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (filteredEntries.isEmpty)
                  const _EmptySelectionView()
                else
                  for (final entry in filteredEntries)
                    _NodeButton(
                      node: entry.node,
                      isSelected: entry.node.id == widget.selectedNodeId,
                      onTap: () => widget.onNodeSelected(entry.node.id),
                    ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xffc34949),
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    key: const ValueKey('learn-start-button'),
                    onPressed: !selectedNodeIsVisible || widget.isLoading
                        ? null
                        : widget.onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff111116),
                      disabledBackgroundColor: const Color(0xffd8d8df),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'この内容で始める',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Japanese',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '何を学習する？',
      style: TextStyle(
        color: Color(0xff111116),
        fontFamily: 'Noto Sans Japanese',
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SelectionDropdown extends StatelessWidget {
  const _SelectionDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.unfold_more_rounded, size: 19),
      style: const TextStyle(
        color: Color(0xff3f3f47),
        fontFamily: 'Noto Sans Japanese',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xfffafafd),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xffd9d9df)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xffd9d9df)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(
            color: Color(0xff6263d9),
            width: 1.5,
          ),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _EmptySelectionView extends StatelessWidget {
  const _EmptySelectionView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 38),
      child: Text(
        '該当する学習内容がありません',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xff777781),
          fontFamily: 'Noto Sans Japanese',
          fontSize: 13,
        ),
      ),
    );
  }
}

class _LearnNodeEntry {
  const _LearnNodeEntry({required this.skill, required this.node});

  final LearnSkill skill;
  final LearnSkillNode node;
}

class _NodeButton extends StatelessWidget {
  const _NodeButton({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  final LearnSkillNode node;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        key: ValueKey('learn-node-${node.id}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected
                    ? const Color(0xff6263d9)
                    : Colors.transparent,
                width: 3,
              ),
              bottom: const BorderSide(color: Color(0xffededf0)),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xff6263d9)
                        : const Color(0xff3f3f47),
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  ),
                ),
              Text(
                'Lv.${node.difficulty}',
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xff6263d9)
                      : const Color(0xff777781),
                  fontFamily: 'Russo One',
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
