import 'package:flutter/material.dart';

import '../domain/task_configuration.dart';
import '../domain/task_repository.dart';
import '../../../shared/widgets/programming_language_selector.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({
    super.key,
    required this.repository,
    this.onTaskCatalogChanged,
  });

  final TaskRepository repository;
  final VoidCallback? onTaskCatalogChanged;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  static const purple = Color(0xff6263d9);
  static const ink = Color(0xff222229);
  static const muted = Color(0xff777782);
  static const line = Color(0xffe3e3e9);

  late final Future<TaskCatalog> _catalogFuture;
  TaskCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    _catalogFuture = widget.repository.fetchCatalog();
  }

  Future<void> _handleSaveTask(LearningTask task) async {
    await widget.repository.saveTask(task);
    if (!mounted) return;
    final updated = await widget.repository.fetchCatalog();
    if (!mounted) return;
    setState(() => _catalog = updated);
    widget.onTaskCatalogChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaskCatalog>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        final catalog = _catalog ?? snapshot.data;
        if (catalog == null) return const SizedBox.shrink();
        _catalog ??= catalog;
        return LayoutBuilder(
          builder: (context, constraints) {
            final mediaPadding = MediaQuery.paddingOf(context);
            final bottomScale = (constraints.maxWidth / 973).clamp(0.32, 1.0);
            final bottomHeight = 325 * bottomScale + mediaPadding.bottom;
            final task = catalog.tasks.isEmpty
                ? LearningTask(
                    id: '',
                    name: '学習タスク',
                    isHomeTask: true,
                    slots: List.generate(
                      5,
                      (index) => TaskSlot(slotNo: index + 1),
                    ),
                  )
                : catalog.tasks.first;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                64 + mediaPadding.top + 24,
                22,
                bottomHeight + 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'タスク',
                        style: TextStyle(
                          color: ink,
                          fontFamily: 'Noto Sans Japanese',
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '5つの学習スロットを設定してください',
                        style: TextStyle(
                          color: muted,
                          fontFamily: 'Noto Sans Japanese',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _TaskEditor(
                        key: ValueKey('task-editor-${task.id}'),
                        initialTask: task,
                        options: catalog.options,
                        onSave: _handleSaveTask,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({
    super.key,
    required this.initialTask,
    required this.options,
    required this.onSave,
  });

  final LearningTask initialTask;
  final List<TaskOption> options;
  final Future<void> Function(LearningTask task) onSave;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late List<TaskSlot> _slots;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _slots = List.generate(5, (index) {
      final slotNo = index + 1;
      for (final slot in widget.initialTask.slots) {
        if (slot.slotNo == slotNo) return slot;
      }
      return TaskSlot(slotNo: slotNo);
    });
  }

  Future<void> _handleEditSlot(TaskSlot slot) async {
    final updated = await showModalBottomSheet<TaskSlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _SlotEditorSheet(
        initialSlot: slot,
        options: widget.options,
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _slots[slot.slotNo - 1] = updated);
  }

  Future<void> _handleSave() async {
    if (_isSaving || _slots.any((slot) => !slot.isConfigured)) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        widget.initialTask.copyWith(
          slots: List.unmodifiable(_slots),
          isHomeTask: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configuredSlotCount =
        _slots.where((slot) => slot.isConfigured).length;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xfffafafd),
        border: Border.symmetric(
          horizontal: BorderSide(color: _TaskPageState.line),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '学習スロット',
                    style: TextStyle(
                      color: _TaskPageState.ink,
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$configuredSlotCount / 5',
                  style: const TextStyle(
                    color: _TaskPageState.purple,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < _slots.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, color: _TaskPageState.line),
              _EditorSlotRow(
                slot: _slots[index],
                onTap: () => _handleEditSlot(_slots[index]),
              ),
            ],
            if (configuredSlotCount < 5) ...[
              const SizedBox(height: 10),
              const Text(
                '保存するには5つすべてのスロットを設定してください。',
                style: TextStyle(
                  color: _TaskPageState.muted,
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('task-save-button'),
              onPressed: configuredSlotCount == 5 && !_isSaving
                  ? _handleSave
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _TaskPageState.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(_isSaving ? '保存中...' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSlotRow extends StatelessWidget {
  const _EditorSlotRow({required this.slot, required this.onTap});

  final TaskSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('task-editor-slot-${slot.slotNo}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 17),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                '${slot.slotNo}'.padLeft(2, '0'),
                style: const TextStyle(
                  color: _TaskPageState.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                slot.isConfigured
                    ? '${slot.questionType!.label}  ·  ${_languageLabel(slot.language)}  ·  ${_difficultyLabel(slot)}'
                    : '未設定',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: slot.isConfigured
                      ? _TaskPageState.ink
                      : _TaskPageState.muted,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _TaskPageState.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotEditorSheet extends StatefulWidget {
  const _SlotEditorSheet({required this.initialSlot, required this.options});

  final TaskSlot initialSlot;
  final List<TaskOption> options;

  @override
  State<_SlotEditorSheet> createState() => _SlotEditorSheetState();
}

class _SlotEditorSheetState extends State<_SlotEditorSheet> {
  late TaskQuestionType _questionType;
  late String _language;
  int? _minimumDifficulty;
  int? _maximumDifficulty;

  @override
  void initState() {
    super.initState();
    _questionType = widget.initialSlot.questionType ??
        widget.options.first.questionType;
    _language = widget.initialSlot.isConfigured
        ? widget.initialSlot.language
        : widget.options
            .firstWhere((option) => option.questionType == _questionType)
            .language;
    _minimumDifficulty = widget.initialSlot.minimumDifficulty;
    _maximumDifficulty = widget.initialSlot.maximumDifficulty;
  }

  List<String> get _languages => widget.options
      .where((option) => option.questionType == _questionType)
      .map((option) => option.language)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'スロット ${widget.initialSlot.slotNo}',
                    style: const TextStyle(
                      color: _TaskPageState.ink,
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.initialSlot.isConfigured)
                  IconButton(
                    onPressed: () => Navigator.pop(
                      context,
                      TaskSlot(slotNo: widget.initialSlot.slotNo),
                    ),
                    color: _TaskPageState.muted,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _EditorDropdown<TaskQuestionType>(
              label: '種類',
              value: _questionType,
              items: TaskQuestionType.values,
              itemLabel: (type) => type.label,
              onChanged: (type) {
                setState(() {
                  _questionType = type;
                  _language = widget.options
                      .firstWhere((option) => option.questionType == type)
                      .language;
                  _minimumDifficulty = null;
                  _maximumDifficulty = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_languages.every((language) => language.isEmpty))
              InputDecorator(
                decoration: _fieldDecoration('言語'),
                child: const Text('指定なし'),
              )
            else
              ProgrammingLanguageSelector(
                languages: _languages,
                selectedLanguage: _language,
                keyPrefix: 'task-language',
                semanticsLabel: 'スロットの言語',
                labelBuilder: _languageLabel,
                onChanged: (language) => setState(() {
                  _language = language;
                  _minimumDifficulty = null;
                  _maximumDifficulty = null;
                }),
              ),
            const SizedBox(height: 12),
            _TaskDifficultySelector(
              minimumDifficulty: _minimumDifficulty,
              maximumDifficulty: _maximumDifficulty,
              onChanged: (values) => setState(() {
                _minimumDifficulty = values.start.round();
                _maximumDifficulty = values.end.round();
              }),
              onRecommended: () => setState(() {
                _minimumDifficulty = null;
                _maximumDifficulty = null;
              }),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                TaskSlot(
                  slotNo: widget.initialSlot.slotNo,
                  questionType: _questionType,
                  language: _language,
                  minimumDifficulty: _minimumDifficulty,
                  maximumDifficulty: _maximumDifficulty,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _TaskPageState.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('決定'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorDropdown<T> extends StatelessWidget {
  const _EditorDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _fieldDecoration(label),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _TaskDifficultySelector extends StatelessWidget {
  const _TaskDifficultySelector({
    required this.minimumDifficulty,
    required this.maximumDifficulty,
    required this.onChanged,
    required this.onRecommended,
  });

  final int? minimumDifficulty;
  final int? maximumDifficulty;
  final ValueChanged<RangeValues> onChanged;
  final VoidCallback onRecommended;

  @override
  Widget build(BuildContext context) {
    const minimumLevel = 1;
    const maximumLevel = 5;
    final safeMinimum = (minimumDifficulty ?? minimumLevel)
        .clamp(minimumLevel, maximumLevel)
        .toInt();
    final safeMaximum = (maximumDifficulty ?? maximumLevel)
        .clamp(safeMinimum, maximumLevel)
        .toInt();
    final isRecommended = minimumDifficulty == null && maximumDifficulty == null;
    final selectedLabel = isRecommended
        ? 'おすすめ'
        : safeMinimum == safeMaximum
            ? 'Lv.$safeMinimum'
            : 'Lv.$safeMinimum 〜 Lv.$safeMaximum';

    return Semantics(
      container: true,
      label: '難易度',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '難易度',
                style: TextStyle(
                  color: _TaskPageState.muted,
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!isRecommended)
                TextButton(
                  onPressed: onRecommended,
                  style: TextButton.styleFrom(
                    foregroundColor: _TaskPageState.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('おすすめ'),
                ),
              Text(
                selectedLabel,
                style: const TextStyle(
                  color: _TaskPageState.purple,
                  fontFamily: 'Russo One',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _TaskPageState.purple,
              inactiveTrackColor: const Color(0xffe4e4eb),
              thumbColor: _TaskPageState.purple,
              overlayColor: const Color(0x1f6263d9),
              rangeValueIndicatorShape:
                  const PaddleRangeSliderValueIndicatorShape(),
              valueIndicatorColor: _TaskPageState.purple,
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
                safeMinimum.toDouble(),
                safeMaximum.toDouble(),
              ),
              min: minimumLevel.toDouble(),
              max: maximumLevel.toDouble(),
              divisions: maximumLevel - minimumLevel,
              labels: RangeLabels(
                'Lv.$safeMinimum',
                'Lv.$safeMaximum',
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: _TaskPageState.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xfff6f6f8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );

String _languageLabel(String language) {
  if (language.isEmpty) return '指定なし';
  const labels = <String, String>{
    'typescript': 'TypeScript',
    'javascript': 'JavaScript',
    'ruby': 'Ruby',
    'csharp': 'C#',
    'dart': 'Dart',
  };
  return labels[language] ?? language;
}

String _difficultyLabel(TaskSlot slot) {
  final minimum = slot.minimumDifficulty;
  final maximum = slot.maximumDifficulty;
  if (minimum == null || maximum == null) return 'おすすめ';
  if (minimum == maximum) return 'Lv.$minimum';
  return 'Lv.$minimum 〜 Lv.$maximum';
}
