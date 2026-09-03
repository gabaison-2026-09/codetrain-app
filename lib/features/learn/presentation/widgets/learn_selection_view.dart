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
  late String _selectedLanguageKey;
  var _minimumDifficulty = 1;
  var _maximumDifficulty = 5;

  @override
  void initState() {
    super.initState();
    final selectedSkill = _skillForNode(widget.selectedNodeId);
    _selectedLanguageKey = selectedSkill == null
        ? ''
        : _LearnLanguageOption.fromSkill(selectedSkill).key;
    if (_selectedLanguageKey.isEmpty && widget.catalog.skills.isNotEmpty) {
      _selectedLanguageKey =
          _LearnLanguageOption.fromSkill(widget.catalog.skills.first).key;
    }
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

  List<_LearnLanguageOption> get _languageOptions {
    final options = <String, _LearnLanguageOption>{};
    for (final skill in widget.catalog.skills) {
      final option = _LearnLanguageOption.fromSkill(skill);
      options.update(
        option.key,
        (current) => current.addSkill(skill),
        ifAbsent: () => option,
      );
    }
    return options.values.toList(growable: false);
  }

  LearnSkill? _skillForNode(String? nodeId) {
    if (nodeId == null) return null;
    for (final skill in widget.catalog.skills) {
      if (skill.nodes.any((node) => node.id == nodeId)) return skill;
    }
    return null;
  }

  List<_LearnNodeEntry> get _filteredEntries {
    final query = _searchController.text.trim().toLowerCase();
    return _allEntries.where((entry) {
      final matchesQuery = query.isEmpty ||
          entry.node.name.toLowerCase().contains(query) ||
          entry.skill.name.toLowerCase().contains(query);
      final matchesLanguage = _selectedLanguageKey.isEmpty ||
          _LearnLanguageOption.fromSkill(entry.skill).key ==
              _selectedLanguageKey;
      final matchesDifficulty = entry.node.difficulty >= _minimumDifficulty &&
          entry.node.difficulty <= _maximumDifficulty;
      return matchesQuery && matchesLanguage && matchesDifficulty;
    }).toList(growable: false);
  }

  void _handleSearchChanged(String value) {
    setState(() {});
  }

  void _handleLanguageChanged(_LearnLanguageOption option) {
    final firstNode = option.skills
        .expand((skill) => skill.nodes)
        .firstOrNull;
    setState(() => _selectedLanguageKey = option.key);
    if (firstNode != null && firstNode.id != widget.selectedNodeId) {
      widget.onNodeSelected(firstNode.id);
    }
  }

  void _handleDifficultyChanged(RangeValues values) {
    setState(() {
      _minimumDifficulty = values.start.round();
      _maximumDifficulty = values.end.round();
    });
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
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SelectionTitle(),
                const SizedBox(height: 20),
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
                    fillColor: const Color(0xfff5f5f7),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xff6263d9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _LanguageSelector(
                  options: _languageOptions,
                  selectedKey: _selectedLanguageKey,
                  onChanged: _handleLanguageChanged,
                ),
                const SizedBox(height: 18),
                _DifficultySelector(
                  key: const ValueKey('learn-difficulty-filter'),
                  minimum: _minimumDifficulty,
                  maximum: _maximumDifficulty,
                  onChanged: _handleDifficultyChanged,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xffe3e3e9)),
                const SizedBox(height: 2),
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
                      backgroundColor: const Color(0xff6263d9),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xffe3e3e9),
                      disabledForegroundColor: const Color(0xff91919b),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

class _SelectionTitle extends StatelessWidget {
  const _SelectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '学習',
      style: TextStyle(
        color: Color(0xff222229),
        fontFamily: 'Noto Sans Japanese',
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.options,
    required this.selectedKey,
    required this.onChanged,
  });

  final List<_LearnLanguageOption> options;
  final String selectedKey;
  final ValueChanged<_LearnLanguageOption> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: '学習言語',
      child: SizedBox(
        height: 82,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final option in options) ...[
                _LanguageButton(
                  option: option,
                  isSelected: option.key == selectedKey,
                  onTap: () => onChanged(option),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _LearnLanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: option.name,
      child: InkWell(
        key: ValueKey('learn-language-${option.key}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xff6263d9)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _LanguageGlyph(
                  option: option,
                  isSelected: isSelected,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xff6263d9)
                      : const Color(0xff55555e),
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageGlyph extends StatelessWidget {
  const _LanguageGlyph({required this.option, required this.isSelected});

  final _LearnLanguageOption option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: option.backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: option.borderColor),
      ),
      child: Center(
        child: Text(
          option.glyph,
          style: TextStyle(
            color: isSelected ? const Color(0xff393941) : option.textColor,
            fontFamily: 'Russo One',
            fontSize: option.glyph.length > 2 ? 10 : 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _LearnLanguageOption {
  const _LearnLanguageOption({
    required this.key,
    required this.name,
    required this.glyph,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.skills,
  });

  factory _LearnLanguageOption.fromSkill(LearnSkill skill) {
    final name = skill.language;
    final key = name.toLowerCase();
    final metadata = switch (key) {
      'c#' => (
        glyph: 'C#',
        backgroundColor: const Color(0xffded7e9),
        borderColor: const Color(0xffa99bb9),
        textColor: const Color(0xff4c4055),
      ),
      'typescript' => (
        glyph: 'TS',
        backgroundColor: const Color(0xffd3e2ec),
        borderColor: const Color(0xff8eafc5),
        textColor: const Color(0xff345268),
      ),
      'javascript' => (
        glyph: 'JS',
        backgroundColor: const Color(0xffe8e1b7),
        borderColor: const Color(0xffbbb176),
        textColor: const Color(0xff5d572d),
      ),
      'ruby' => (
        glyph: 'Rb',
        backgroundColor: const Color(0xffecd1d1),
        borderColor: const Color(0xffb98585),
        textColor: const Color(0xff773838),
      ),
      'python' => (
        glyph: 'Py',
        backgroundColor: const Color(0xffd7e3ef),
        borderColor: const Color(0xff8da9c6),
        textColor: const Color(0xff365675),
      ),
      'dart' => (
        glyph: 'D',
        backgroundColor: const Color(0xffd2e7f2),
        borderColor: const Color(0xff82b4ce),
        textColor: const Color(0xff2d617c),
      ),
      _ => (
        glyph: name.length > 3 ? name.substring(0, 2) : name,
        backgroundColor: const Color(0xffe3e3e9),
        borderColor: const Color(0xffb7b7c2),
        textColor: const Color(0xff4c4c55),
      ),
    };
    return _LearnLanguageOption(
      key: key,
      name: name,
      glyph: metadata.glyph,
      backgroundColor: metadata.backgroundColor,
      borderColor: metadata.borderColor,
      textColor: metadata.textColor,
      skills: [skill],
    );
  }

  final String key;
  final String name;
  final String glyph;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final List<LearnSkill> skills;

  _LearnLanguageOption addSkill(LearnSkill skill) {
    return _LearnLanguageOption(
      key: key,
      name: name,
      glyph: glyph,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      textColor: textColor,
      skills: [...skills, skill],
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    super.key,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final int minimum;
  final int maximum;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final isAllSelected = minimum == 1 && maximum == 5;
    return Semantics(
      container: true,
      label: '難易度の範囲',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '難易度',
                style: TextStyle(
                  color: Color(0xff55555e),
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                isAllSelected ? 'すべて' : 'Lv.$minimum 〜 Lv.$maximum',
                style: const TextStyle(
                  color: Color(0xff6263d9),
                  fontFamily: 'Russo One',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xff6263d9),
              inactiveTrackColor: const Color(0xffe4e4eb),
              thumbColor: const Color(0xff6263d9),
              overlayColor: const Color(0x1f6263d9),
              rangeValueIndicatorShape:
                  const PaddleRangeSliderValueIndicatorShape(),
              valueIndicatorColor: const Color(0xff6263d9),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontFamily: 'Russo One',
                fontSize: 11,
              ),
              trackHeight: 4,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 9,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 17),
            ),
            child: RangeSlider(
              values: RangeValues(
                minimum.toDouble(),
                maximum.toDouble(),
              ),
              min: 1,
              max: 5,
              divisions: 4,
              labels: RangeLabels('Lv.$minimum', 'Lv.$maximum'),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
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
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xff6263d9)
                        : const Color(0xff3f3f47),
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}
