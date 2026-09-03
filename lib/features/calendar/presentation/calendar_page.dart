import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/calendar_activity.dart';
import '../domain/calendar_repository.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.repository, this.initialMonth});

  final CalendarRepository repository;
  final DateTime? initialMonth;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _purple = Color(0xff6263d9);
  static const _muted = Color(0xff91919b);

  late DateTime _visibleMonth;
  late Future<CalendarActivity> _activityFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    _visibleMonth = DateTime(initial.year, initial.month);
    _activityFuture = _fetchMonth();
  }

  Future<CalendarActivity> _fetchMonth() => widget.repository.fetchActivity(
    from: _visibleMonth,
    to: DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0),
  );

  void _moveMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
      _selectedDate = null;
      _activityFuture = _fetchMonth();
    });
  }

  void _showCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
      _activityFuture = _fetchMonth();
    });
  }

  void _selectDate(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = date);
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
            20,
            64 + mediaPadding.top + 20,
            20,
            bottomHeight + 8,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: FutureBuilder<CalendarActivity>(
                future: _activityFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: _purple),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: IconButton(
                        key: const ValueKey('calendar-retry-button'),
                        onPressed: () => setState(
                          () => _activityFuture = _fetchMonth(),
                        ),
                        color: _muted,
                        iconSize: 32,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    );
                  }
                  return _CalendarContent(
                    visibleMonth: _visibleMonth,
                    activity: snapshot.data!,
                    selectedDate: _selectedDate,
                    onPreviousMonth: () => _moveMonth(-1),
                    onNextMonth: () => _moveMonth(1),
                    onToday: _showCurrentMonth,
                    onDateSelected: _selectDate,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarContent extends StatelessWidget {
  const _CalendarContent({
    required this.visibleMonth,
    required this.activity,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final CalendarActivity activity;
  final DateTime? selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onDateSelected;

  static const _ink = Color(0xff222229);
  static const _muted = Color(0xff91919b);
  static const _line = Color(0xffe3e3e9);
  static const _calendarGridHeight = 360.0;

  @override
  Widget build(BuildContext context) {
    final daysByNumber = {
      for (final day in activity.days) day.date.day: day,
    };
    final studiedDayNumbers = {
      for (final day in activity.days)
        if (day.studied) day.date.day,
    };
    final selectedActivity = selectedDate == null
        ? null
        : daysByNumber[selectedDate!.day];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${visibleMonth.year}年${visibleMonth.month}月',
                  key: const ValueKey('calendar-month-label'),
                  style: const TextStyle(
                    color: _ink,
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('calendar-today-button'),
                onPressed: onToday,
                color: _ink,
                tooltip: '今日',
                icon: const Icon(Icons.today_outlined),
              ),
              IconButton(
                key: const ValueKey('calendar-previous-month'),
                onPressed: onPreviousMonth,
                color: _ink,
                tooltip: '前の月',
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                key: const ValueKey('calendar-next-month'),
                onPressed: onNextMonth,
                color: _ink,
                tooltip: '次の月',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (final label in ['日', '月', '火', '水', '木', '金', '土'])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: _muted,
                        fontFamily: 'Noto Sans Japanese',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _calendarGridHeight,
            child: GridView.builder(
              key: const ValueKey('calendar-month-grid'),
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: _calendarGridHeight / 6,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final leadingEmptyDays = visibleMonth.weekday % 7;
                final dayNumber = index - leadingEmptyDays + 1;
                final monthLength = DateTime(
                  visibleMonth.year,
                  visibleMonth.month + 1,
                  0,
                ).day;
                if (dayNumber < 1 || dayNumber > monthLength) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(
                  visibleMonth.year,
                  visibleMonth.month,
                  dayNumber,
                );
                return _CalendarDay(
                  date: date,
                  activity: daysByNumber[dayNumber],
                  selected: _sameDate(date, selectedDate),
                  connectsPrevious:
                      date.weekday != DateTime.sunday &&
                      studiedDayNumbers.contains(dayNumber - 1),
                  connectsNext:
                      date.weekday != DateTime.saturday &&
                      studiedDayNumbers.contains(dayNumber + 1),
                  onPressed: () => onDateSelected(date),
                );
              },
            ),
          ),
          if (selectedDate != null) ...[
            const Divider(height: 1, color: _line),
            _SelectedDayDetails(
              date: selectedDate!,
              activity: selectedActivity,
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedDayDetails extends StatelessWidget {
  const _SelectedDayDetails({required this.date, required this.activity});

  final DateTime date;
  final CalendarDayActivity? activity;

  static const _purple = Color(0xff6263d9);
  static const _ink = Color(0xff222229);
  static const _muted = Color(0xff91919b);
  static const _line = Color(0xffe3e3e9);

  @override
  Widget build(BuildContext context) {
    final tasks = activity?.tasks ?? const <CalendarTaskActivity>[];
    return Column(
      key: const ValueKey('calendar-selected-day-detail'),
      children: [
        SizedBox(
          height: 58,
          child: Row(
            children: [
              Text(
                '${date.month}月${date.day}日',
                style: const TextStyle(
                  color: _ink,
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                activity?.completed == true
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: activity?.studied == true ? _purple : _muted,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                '${activity?.completedSlots ?? 0} / ${activity?.totalSlots ?? 0}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        for (var index = 0; index < tasks.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: _line),
          _CalendarTaskDetails(task: tasks[index]),
        ],
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'この日の学習内容はありません',
              style: TextStyle(
                color: _muted,
                fontFamily: 'Noto Sans Japanese',
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarTaskDetails extends StatelessWidget {
  const _CalendarTaskDetails({required this.task});

  final CalendarTaskActivity task;

  static const _ink = Color(0xff222229);
  static const _purple = Color(0xff6263d9);
  static const _muted = Color(0xff777782);
  static const _line = Color(0xffe3e3e9);

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('calendar-task-${task.id}'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: _purple, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xffeeeefe),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${task.completedQuestions} / ${task.totalQuestions}問',
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (task.contents.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < task.contents.length; index++) ...[
              if (index > 0) const Divider(height: 1, color: _line),
              _CalendarTaskContentDetails(
                key: ValueKey('calendar-task-content-${task.id}-$index'),
                content: task.contents[index],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CalendarTaskContentDetails extends StatelessWidget {
  const _CalendarTaskContentDetails({super.key, required this.content});

  final CalendarTaskContent content;

  static const _purple = Color(0xff6263d9);
  static const _ink = Color(0xff222229);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.code_rounded, color: _purple, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _contentLabel(content),
              softWrap: true,
              style: const TextStyle(
                color: _ink,
                fontFamily: 'Noto Sans Japanese',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _contentLabel(CalendarTaskContent content) {
  final questionType = switch (content.questionType) {
    CalendarQuestionType.codeReading => 'コード読解',
    CalendarQuestionType.outputPrediction => '出力予測',
  };
  final language = switch (content.language) {
    'typescript' => 'TypeScript',
    'javascript' => 'JavaScript',
    'ruby' => 'Ruby',
    'csharp' => 'C#',
    'dart' => 'Dart',
    '' => '指定なし',
    _ => content.language,
  };
  final difficulty = content.difficulty == null
      ? 'おすすめ'
      : 'Lv.${content.difficulty}';
  final count = content.questionCount > 1 ? ' ×${content.questionCount}' : '';
  return '$questionType・$language・$difficulty$count';
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.activity,
    required this.selected,
    required this.connectsPrevious,
    required this.connectsNext,
    required this.onPressed,
  });

  final DateTime date;
  final CalendarDayActivity? activity;
  final bool selected;
  final bool connectsPrevious;
  final bool connectsNext;
  final VoidCallback onPressed;

  static const _purple = Color(0xff6263d9);
  static const _studiedFill = Color(0xffeeeefe);
  static const _muted = Color(0xffa7a7b0);

  @override
  Widget build(BuildContext context) {
    final studied = activity?.studied == true;
    return Semantics(
      label: '${date.month}月${date.day}日${studied ? ' 学習済み' : ''}',
      button: true,
      selected: selected,
      child: InkResponse(
        key: ValueKey('calendar-day-${date.day}'),
        onTap: onPressed,
        radius: 28,
        child: Center(
          child: SizedBox(
            width: double.infinity,
            height: 38,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final halfWidth = constraints.maxWidth / 2;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (studied && connectsPrevious)
                      Positioned(
                        left: 0,
                        top: 0,
                        width: halfWidth,
                        height: 38,
                        child: const ColoredBox(color: _studiedFill),
                      ),
                    if (studied && connectsNext)
                      Positioned(
                        right: 0,
                        top: 0,
                        width: halfWidth,
                        height: 38,
                        child: const ColoredBox(color: _studiedFill),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: studied ? _studiedFill : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _purple, width: 2),
                        ),
                      ),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: studied ? _purple : _muted,
                        fontSize: 14,
                        fontWeight: studied
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameDate(DateTime first, DateTime? second) =>
    second != null &&
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
