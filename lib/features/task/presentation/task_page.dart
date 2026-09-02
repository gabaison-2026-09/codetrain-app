import 'package:flutter/material.dart';

import '../domain/task_configuration.dart';
import '../domain/task_launcher.dart';
import '../domain/task_repository.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({
    super.key,
    required this.repository,
    required this.taskLauncher,
    this.onTaskCatalogChanged,
  });

  final TaskRepository repository;
  final TaskLauncher taskLauncher;
  final VoidCallback? onTaskCatalogChanged;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  static const purple = Color(0xff6263d9);
  static const ink = Color(0xff222229);
  static const muted = Color(0xff777782);
  static const line = Color(0xffe3e3e9);
  static const maxHomeTasks = 3;

  late final Future<TaskCatalog> _catalogFuture;
  TaskCatalog? _catalog;
  String? _expandedTaskId;

  @override
  void initState() {
    super.initState();
    _catalogFuture = widget.repository.fetchCatalog();
  }

  Future<void> _handleCreateTask() async {
    final catalog = _catalog;
    if (catalog == null) return;
    final result = await showModalBottomSheet<_TaskEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _TaskEditor(
        options: catalog.options,
      ),
    );
    if (result == null || !mounted) return;
    await widget.repository.saveTask(result.task);
    if (!mounted) return;
    final updated = await widget.repository.fetchCatalog();
    if (!mounted) return;
    setState(() => _catalog = updated);
    widget.onTaskCatalogChanged?.call();
  }

  void _handleTaskTap(LearningTask task) {
    setState(() {
      _expandedTaskId = _expandedTaskId == task.id ? null : task.id;
    });
  }

  Future<void> _handleSaveTask(LearningTask task) async {
    await widget.repository.saveTask(task);
    if (!mounted) return;
    final updated = await widget.repository.fetchCatalog();
    if (!mounted) return;
    setState(() {
      _catalog = updated;
      _expandedTaskId = null;
    });
    widget.onTaskCatalogChanged?.call();
  }

  Future<void> _handleDeleteTask(String taskId) async {
    await widget.repository.deleteTask(taskId);
    if (!mounted) return;
    final updated = await widget.repository.fetchCatalog();
    if (!mounted) return;
    setState(() {
      _catalog = updated;
      _expandedTaskId = null;
    });
    widget.onTaskCatalogChanged?.call();
  }

  Future<void> _handleToggleHomeTask(LearningTask task) async {
    final catalog = _catalog;
    if (catalog == null) return;
    final homeTaskCount =
        catalog.tasks.where((task) => task.isHomeTask).length;
    if (!task.isHomeTask && homeTaskCount >= maxHomeTasks) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ホームで開始できるタスクは3つまでです。')),
      );
      return;
    }

    await widget.repository.saveTask(
      task.copyWith(isHomeTask: !task.isHomeTask),
    );
    if (!mounted) return;
    final updated = await widget.repository.fetchCatalog();
    if (!mounted) return;
    setState(() => _catalog = updated);
    widget.onTaskCatalogChanged?.call();
  }

  Future<void> _handleStartTask(LearningTask task) async {
    try {
      await widget.taskLauncher.start(
        TaskLaunchTarget(name: task.name, taskId: task.id),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.name} を開始します。')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タスクを開始できませんでした。')),
      );
    }
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
            final tasks = catalog.tasks;
            final homeTaskCount =
                tasks.where((task) => task.isHomeTask).length;
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'タスク',
                              style: TextStyle(
                                color: ink,
                                fontFamily: 'Noto Sans Japanese',
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton.filled(
                            key: const ValueKey('task-add-button'),
                            onPressed: _handleCreateTask,
                            style: IconButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.square(48),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ホームで開始するタスク  $homeTaskCount / $maxHomeTasks',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: line),
                      for (final task in tasks) ...[
                        _TaskRow(
                          task: task,
                          isExpanded: _expandedTaskId == task.id,
                          onTap: () => _handleTaskTap(task),
                          onStartTask: () => _handleStartTask(task),
                          onHomeTaskToggle: () => _handleToggleHomeTask(task),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: _expandedTaskId == task.id
                              ? _TaskEditor(
                                  key: ValueKey('task-editor-${task.id}'),
                                  initialTask: task,
                                  options: catalog.options,
                                  inline: true,
                                  onSave: _handleSaveTask,
                                  onDelete: () => _handleDeleteTask(task.id),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                      if (tasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 54),
                          child: Center(
                            child: Icon(
                              Icons.inbox_outlined,
                              color: muted,
                              size: 30,
                            ),
                          ),
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isExpanded,
    required this.onTap,
    required this.onStartTask,
    required this.onHomeTaskToggle,
  });

  final LearningTask task;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onStartTask;
  final VoidCallback onHomeTaskToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _TaskPageState.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('task-${task.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            color: _TaskPageState.ink,
                            fontFamily: 'Noto Sans Japanese',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SlotIndicator(slots: task.slots),
                      ],
                    ),
                  ),
                  Text(
                    '${task.configuredSlotCount} / 5',
                    style: const TextStyle(
                      color: _TaskPageState.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: _TaskPageState.muted,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: ValueKey('task-start-button-${task.id}'),
                  onPressed: onStartTask,
                  style: TextButton.styleFrom(
                    foregroundColor: _TaskPageState.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  label: const Text('開始'),
                ),
                TextButton.icon(
                  key: ValueKey('task-home-toggle-${task.id}'),
                  onPressed: onHomeTaskToggle,
                  style: TextButton.styleFrom(
                    foregroundColor: task.isHomeTask
                        ? _TaskPageState.purple
                        : _TaskPageState.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 40),
                  ),
                  icon: Icon(
                    task.isHomeTask
                        ? Icons.check_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                  ),
                  label: Text(task.isHomeTask ? '登録済み' : 'ホームに登録'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotIndicator extends StatelessWidget {
  const _SlotIndicator({required this.slots});

  final List<TaskSlot> slots;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final isConfigured = slots.any(
          (slot) => slot.slotNo == index + 1 && slot.isConfigured,
        );
        return Container(
          width: 22,
          height: 3,
          margin: EdgeInsets.only(right: index == 4 ? 0 : 5),
          decoration: BoxDecoration(
            color: isConfigured ? _TaskPageState.purple : _TaskPageState.line,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _TaskEditorResult {
  const _TaskEditorResult(this.task);

  final LearningTask task;
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({
    super.key,
    this.initialTask,
    required this.options,
    this.inline = false,
    this.onSave,
    this.onDelete,
  });

  final LearningTask? initialTask;
  final List<TaskOption> options;
  final bool inline;
  final Future<void> Function(LearningTask task)? onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final TextEditingController _nameController;
  late List<TaskSlot> _slots;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialTask?.name);
    _slots = List.generate(5, (index) {
      final slotNo = index + 1;
      for (final slot in widget.initialTask?.slots ?? const <TaskSlot>[]) {
        if (slot.slotNo == slotNo) return slot;
      }
      return TaskSlot(slotNo: slotNo);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
    final name = _nameController.text.trim();
    if (name.isEmpty || !_slots.any((slot) => slot.isConfigured)) return;
    final task = LearningTask(
      id: widget.initialTask?.id ?? '',
      name: name,
      slots: List.unmodifiable(_slots),
    );
    if (widget.onSave != null) {
      await widget.onSave!(task);
    } else if (mounted) {
      Navigator.pop(context, _TaskEditorResult(task));
    }
  }

  Future<void> _handleDelete() async {
    if (widget.onDelete != null) {
      await widget.onDelete!();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.inline) ...[
            const _SheetHandle(),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.initialTask == null ? 'タスクを作成' : 'タスクを編集',
                  style: const TextStyle(
                    color: _TaskPageState.ink,
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.initialTask != null)
                IconButton(
                  key: const ValueKey('task-delete-button'),
                  onPressed: _handleDelete,
                  color: _TaskPageState.muted,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('task-name-field'),
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: _fieldDecoration('名前'),
          ),
          const SizedBox(height: 18),
          if (widget.inline)
            Column(
              children: [
                for (var index = 0; index < _slots.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: _TaskPageState.line),
                  _EditorSlotRow(
                    slot: _slots[index],
                    onTap: () => _handleEditSlot(_slots[index]),
                  ),
                ],
              ],
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: _TaskPageState.line,
                ),
                itemBuilder: (context, index) {
                  final slot = _slots[index];
                  return _EditorSlotRow(
                    slot: slot,
                    onTap: () => _handleEditSlot(slot),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          FilledButton(
            key: const ValueKey('task-save-button'),
            onPressed: _nameController.text.trim().isNotEmpty &&
                    _slots.any((slot) => slot.isConfigured)
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
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (widget.inline) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xfffafafd),
          border: Border(
            bottom: BorderSide(color: _TaskPageState.line),
          ),
        ),
        child: content,
      );
    }
    return FractionallySizedBox(heightFactor: 0.9, child: content);
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
                    ? '${slot.questionType!.label}  ·  ${_languageLabel(slot.language)}  ·  ${slot.difficulty == null ? 'おすすめ' : 'Lv.${slot.difficulty}'}'
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
  int? _difficulty;

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
    _difficulty = widget.initialSlot.difficulty;
  }

  List<String> get _languages => widget.options
      .where((option) => option.questionType == _questionType)
      .map((option) => option.language)
      .toSet()
      .toList();

  List<int> get _difficulties => widget.options
      .where(
        (option) =>
            option.questionType == _questionType &&
            option.language == _language,
      )
      .map((option) => option.difficulty)
      .toSet()
      .toList()
    ..sort();

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
                  _difficulty = null;
                });
              },
            ),
            const SizedBox(height: 12),
            _EditorDropdown<String>(
              label: '言語',
              value: _language,
              items: _languages,
              itemLabel: _languageLabel,
              onChanged: (language) => setState(() {
                _language = language;
                _difficulty = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _difficulty,
              isExpanded: true,
              decoration: _fieldDecoration('難易度'),
              items: <int?>[null, ..._difficulties]
                  .map(
                    (difficulty) => DropdownMenuItem<int?>(
                      value: difficulty,
                      child: Text(
                        difficulty == null ? 'おすすめ' : 'Lv.$difficulty',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (difficulty) =>
                  setState(() => _difficulty = difficulty),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                TaskSlot(
                  slotNo: widget.initialSlot.slotNo,
                  questionType: _questionType,
                  language: _language,
                  difficulty: _difficulty,
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
