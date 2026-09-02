import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({
    super.key,
    required this.repository,
    this.initialDashboard,
  });

  final HomeDashboardRepository repository;
  final HomeDashboard? initialDashboard;

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  late final HomeDashboardRepository _repository;
  late final Future<HomeDashboard> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _dashboardFuture = _repository.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeDashboard>(
      future: _dashboardFuture,
      initialData: widget.initialDashboard,
      builder: (context, snapshot) {
        final dashboard = snapshot.data;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }
        return _HomeDashboardView(dashboard: dashboard);
      },
    );
  }
}

class _HomeDashboardView extends StatefulWidget {
  const _HomeDashboardView({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  State<_HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<_HomeDashboardView> {
  var _selectedTaskIndex = 0;
  var _swipeDirection = 1;

  static const _purple = Color(0xff6263d9);
  static const _orange = Color(0xffff6a2a);
  static const _taskColors = [_purple, Color(0xff3f8f9d), Color(0xff8c5aa8)];

  HomeStudyTask get _selectedTask {
    final tasks = widget.dashboard.studyTasks;
    if (tasks.isEmpty) {
      return const HomeStudyTask(languages: []);
    }
    final safeIndex = _selectedTaskIndex.clamp(0, tasks.length - 1).toInt();
    return tasks[safeIndex];
  }

  Color get _selectedTaskColor =>
      _taskColors[_selectedTaskIndex % _taskColors.length];

  @override
  void didUpdateWidget(covariant _HomeDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final taskCount = widget.dashboard.studyTasks.length;
    if (taskCount == 0) {
      _selectedTaskIndex = 0;
    } else if (_selectedTaskIndex >= taskCount) {
      _selectedTaskIndex = taskCount - 1;
    }
  }

  void _handleTaskSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    final taskCount = widget.dashboard.studyTasks.length;
    if (velocity == null || velocity.abs() < 100 || taskCount < 2) {
      return;
    }

    final direction = velocity < 0 ? 1 : -1;
    HapticFeedback.selectionClick();
    setState(() {
      _swipeDirection = direction;
      _selectedTaskIndex =
          (_selectedTaskIndex + direction + taskCount) % taskCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final tasks = dashboard.studyTasks;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = (constraints.maxWidth * 0.024).clamp(
          7.0,
          16.0,
        );
        final mediaPadding = MediaQuery.paddingOf(context);
        final topNavigationHeight = 64.0 + mediaPadding.top;
        final bottomNavigationScale =
            (constraints.maxWidth / 973).clamp(0.32, 1.0).toDouble();
        final bottomNavigationHeight =
            325 * bottomNavigationScale + mediaPadding.bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topNavigationHeight + 20,
            horizontalPadding,
            bottomNavigationHeight + 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DateAndStreakRow(
                dashboard: dashboard,
                purple: _purple,
                orange: _orange,
              ),
              const SizedBox(height: 21),
              _DayStatusDots(
                statuses: dashboard.dayStatuses,
                highlightedDayIndex: dashboard.highlightedDayIndex,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: _handleTaskSwipe,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offset = Tween<Offset>(
                          begin: Offset(_swipeDirection * 0.08, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
                        );
                      },
                      child: _PlayButton(
                        key: ValueKey('home-play-task-$_selectedTaskIndex'),
                        color: _selectedTaskColor,
                      ),
                    ),
                    if (tasks.length > 1) ...[
                      const SizedBox(height: 7),
                      _TaskIndicator(
                        count: tasks.length,
                        selectedIndex: _selectedTaskIndex,
                        color: _selectedTaskColor,
                      ),
                    ],
                    const SizedBox(height: 17),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.92,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _ProgramRow(
                        key: ValueKey('home-programs-task-$_selectedTaskIndex'),
                        languages: _selectedTask.languages,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 42),
              _RecentXpCard(points: dashboard.recentXp),
            ],
          ),
        );
      },
    );
  }
}

class _RecentXpCard extends StatelessWidget {
  const _RecentXpCard({required this.points});

  final List<HomeXpPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final totalXp = points.fold<int>(
      0,
      (total, point) => total + point.xp,
    );

    return Card(
      key: const ValueKey('recent-xp-card'),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffe8e8ed)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: _RecentXpChartPainter(points: points),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'total',
                  style: TextStyle(
                    color: Color(0xff9b9ba4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalXp',
                  style: const TextStyle(
                    fontFamily: 'Russo One',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentXpChartPainter extends CustomPainter {
  const _RecentXpChartPainter({required this.points});

  final List<HomeXpPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    final maxXp = points.fold<int>(
      1,
      (maximum, point) => point.xp > maximum ? point.xp : maximum,
    );
    final gap = points.length > 14 ? 3.5 : (points.length > 1 ? 7.0 : 0.0);
    final barWidth = ((size.width - gap * (points.length - 1)) / points.length)
        .clamp(3.0, 9.0)
        .toDouble();
    final chartHeight = size.height - 3;
    final barPaint = Paint()..style = PaintingStyle.fill;

    for (var index = 0; index < points.length; index++) {
      final value = points[index].xp.clamp(0, maxXp);
      final barHeight = value == 0
          ? 4.0
          : (chartHeight * value / maxXp).clamp(6.0, chartHeight).toDouble();
      final left = index * (barWidth + gap);
      final top = chartHeight - barHeight;
      barPaint.color = const Color(0xff6263d9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          Radius.circular(barWidth / 2),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RecentXpChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _DateAndStreakRow extends StatelessWidget {
  const _DateAndStreakRow({
    required this.dashboard,
    required this.purple,
    required this.orange,
  });

  final HomeDashboard dashboard;
  final Color purple;
  final Color orange;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-4, 0),
          child: Icon(Icons.calendar_today_outlined, color: purple, size: 52),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Transform.translate(
                  offset: const Offset(-3, 13),
                  child: Text(
                    '${dashboard.activityDate.month}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Jua',
                      fontSize: 100,
                      fontWeight: FontWeight.w400,
                      height: 0.8,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Transform.translate(
                  offset: const Offset(0, 7),
                  child: const Text(
                    '/',
                    style: TextStyle(
                      color: Color(0xffd2d2d2),
                      fontSize: 88,
                      fontWeight: FontWeight.w300,
                      height: 0.88,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Transform.translate(
                  offset: const Offset(0, 10),
                  child: Text(
                    '${dashboard.activityDate.day}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Jua',
                      fontSize: 64,
                      fontWeight: FontWeight.w400,
                      height: 0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: orange,
                size: 38,
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${dashboard.streakDays}',
                      style: const TextStyle(
                        fontFamily: 'Jua',
                        fontSize: 34,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const TextSpan(
                      text: ' days',
                      style: TextStyle(
                        fontFamily: 'Russo One',
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(color: Colors.black, height: 1),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayStatusDots extends StatelessWidget {
  const _DayStatusDots({
    required this.statuses,
    required this.highlightedDayIndex,
  });

  final List<HomeDayStatus> statuses;
  final int highlightedDayIndex;

  Color _colorFor(HomeDayStatus status) {
    switch (status) {
      case HomeDayStatus.completed:
        return const Color.fromARGB(255, 145, 201, 131);
      case HomeDayStatus.missed:
        return const Color(0xffe49a9a);
      case HomeDayStatus.active:
        return const Color(0xff6263d9);
      case HomeDayStatus.upcoming:
        return const Color(0xffd8d8d8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();

    var dotsWidth = 0.0;
    for (var index = 0; index < statuses.length; index++) {
      if (index > 0) dotsWidth += 11;
      dotsWidth += index == highlightedDayIndex ? 22 : 14;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: SizedBox(
        width: dotsWidth,
        height: 34,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 6,
              child: Row(
                children: [
                  for (var index = 0; index < statuses.length; index++) ...[
                    if (index > 0) const SizedBox(width: 11),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _colorFor(statuses[index]),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: index == highlightedDayIndex ? 22 : 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({super.key, required this.color});

  final Color color;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _TaskIndicator extends StatelessWidget {
  const _TaskIndicator({
    required this.count,
    required this.selectedIndex,
    required this.color,
  });

  final int count;
  final int selectedIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _TaskIndicatorLine(),
        const SizedBox(width: 12),
        for (var index = 0; index < count; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            width: index == selectedIndex ? 7 : 4,
            height: index == selectedIndex ? 7 : 4,
            decoration: BoxDecoration(
              color: index == selectedIndex
                  ? color
                  : color.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
          ),
        ],
        const SizedBox(width: 12),
        const _TaskIndicatorLine(),
      ],
    );
  }
}

class _TaskIndicatorLine extends StatelessWidget {
  const _TaskIndicatorLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 96,
      height: 1,
      child: ColoredBox(color: Color(0xffe1e1e1)),
    );
  }
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Center(
      child: SizedBox.square(
        dimension: 278,
        child: AnimatedBuilder(
          animation: _rotationController,
          child: Center(
            child: SizedBox.square(
              dimension: 254,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: color, width: 9),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: color,
                    size: 210,
                  ),
                ),
              ),
            ),
          ),
          builder: (context, child) {
            return CustomPaint(
              painter: _PlayButtonDecorationPainter(
                rotation: _rotationController.value * math.pi * 2,
                color: color,
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _PlayButtonDecorationPainter extends CustomPainter {
  const _PlayButtonDecorationPainter({
    required this.rotation,
    required this.color,
  });

  final double rotation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final purple = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.75,
      0.95,
      false,
      purple,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.25,
      1.15,
      false,
      purple,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlayButtonDecorationPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({super.key, required this.languages});

  final List<HomeLanguage> languages;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 23,
      runSpacing: 12,
      children: [
        for (final language in languages) ...[_ProgramIcon(language: language)],
        const _AddProgramButton(),
      ],
    );
  }
}

class _ProgramIcon extends StatelessWidget {
  const _ProgramIcon({required this.language});

  final HomeLanguage language;

  @override
  Widget build(BuildContext context) {
    switch (language) {
      case HomeLanguage.csharp:
        return const _CSharpIcon();
      case HomeLanguage.typescript:
        return const _TypeScriptIcon();
      case HomeLanguage.ruby:
        return const _RubyIcon();
    }
  }
}

class _CSharpIcon extends StatelessWidget {
  const _CSharpIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _CSharpIconPainter()),
    );
  }
}

class _CSharpIconPainter extends CustomPainter {
  const _CSharpIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width - 2.4, 8.4)
      ..lineTo(size.width - 2.4, 27.6)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(2.4, 27.6)
      ..lineTo(2.4, 8.4)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xff0566a8));
    final painter = TextPainter(
      text: const TextSpan(
        text: 'C#',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((size.width - painter.width) / 2, 8.5));
  }

  @override
  bool shouldRepaint(covariant _CSharpIconPainter oldDelegate) => false;
}

class _TypeScriptIcon extends StatelessWidget {
  const _TypeScriptIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Color(0xff367bbb)),
        child: Center(
          child: Text(
            'TS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RubyIcon extends StatelessWidget {
  const _RubyIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _RubyIconPainter()),
    );
  }
}

class _RubyIconPainter extends CustomPainter {
  const _RubyIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 30, size.height / 30);
    final paint = Paint()..color = const Color(0xffd52d36);
    final left = Path()
      ..moveTo(2, 8)
      ..lineTo(11, 2)
      ..lineTo(17, 10)
      ..lineTo(9, 28)
      ..close();
    final right = Path()
      ..moveTo(17, 10)
      ..lineTo(28, 5)
      ..lineTo(26, 22)
      ..lineTo(9, 28)
      ..close();
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
    canvas.drawCircle(const Offset(18, 10), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RubyIconPainter oldDelegate) => false;
}

class _AddProgramButton extends StatelessWidget {
  const _AddProgramButton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _AddProgramButtonPainter()),
    );
  }
}

class _AddProgramButtonPainter extends CustomPainter {
  const _AddProgramButtonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 30, size.height / 30);
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    const center = Offset(15, 15);
    const radius = 12.0;
    for (var index = 0; index < 16; index++) {
      final start = (index * 3.14159265359 / 8) + 0.05;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        0.14,
        false,
        stroke,
      );
    }
    canvas.drawLine(const Offset(10, 15), const Offset(20, 15), stroke);
    canvas.drawLine(const Offset(15, 10), const Offset(15, 20), stroke);
  }

  @override
  bool shouldRepaint(covariant _AddProgramButtonPainter oldDelegate) => false;
}
