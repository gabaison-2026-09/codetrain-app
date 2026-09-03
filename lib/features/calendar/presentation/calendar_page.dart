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
          child: Center(
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

  static const _purple = Color(0xff6263d9);
  static const _ink = Color(0xff222229);
  static const _muted = Color(0xff91919b);
  static const _line = Color(0xffe3e3e9);

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
    return Column(
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
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellHeight = (constraints.maxHeight / 6).clamp(42.0, 72.0);
              return GridView.builder(
                key: const ValueKey('calendar-month-grid'),
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: cellHeight,
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
              );
            },
          ),
        ),
        const Divider(height: 1, color: _line),
        SizedBox(
          height: 58,
          child: selectedDate == null
              ? const SizedBox.shrink()
              : Row(
                  key: const ValueKey('calendar-selected-day-detail'),
                  children: [
                    Text(
                      '${selectedDate!.month}月${selectedDate!.day}日',
                      style: const TextStyle(
                        color: _ink,
                        fontFamily: 'Noto Sans Japanese',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      selectedActivity?.completed == true
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selectedActivity?.studied == true
                          ? _purple
                          : _muted,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedActivity?.completedSlots ?? 0} / ${selectedActivity?.totalSlots ?? 0}',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
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
