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
              const SizedBox(height: 40),
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
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.center,
                child: _MonthlyStudyProgress(
                  progress: dashboard.monthlyProgress,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
        _StreakProgressArc(
          completedTasks: dashboard.taskProgress.completedTasks,
          totalTasks: dashboard.taskProgress.totalTasks,
          streakDays: dashboard.streakDays,
          color: orange,
        ),
      ],
    );
  }
}

class _StreakProgressArc extends StatelessWidget {
  const _StreakProgressArc({
    required this.completedTasks,
    required this.totalTasks,
    required this.streakDays,
    required this.color,
  });

  final int completedTasks;
  final int totalTasks;
  final int streakDays;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalTasks.clamp(0, 5).toInt();
    final safeCompleted = completedTasks.clamp(0, safeTotal).toInt();
    final progress = safeTotal == 0 ? 0.0 : safeCompleted / safeTotal;

    return SizedBox(
      width: 124,
      height: 116,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StreakProgressArcPainter(
                progress: progress,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Icon(
                        Icons.local_fire_department_outlined,
                        color: color,
                        size: 35,
                      ),
                    ),
                    Text(
                      '$streakDays',
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'Jua',
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Text(
              '連続日数',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff707078),
                fontFamily: 'Noto Sans Japanese',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakProgressArcPainter extends CustomPainter {
  const _StreakProgressArcPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = 140 * math.pi / 180;
    const sweepAngle = 260 * math.pi / 180;
    final center = Offset(size.width / 2, size.height / 2 - 1);
    final radius = math.min(size.width, size.height).toDouble() / 2 - 8;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = const Color(0xffe6e6eb)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0).toDouble(),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StreakProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}

class _MonthlyStudyProgress extends StatelessWidget {
  const _MonthlyStudyProgress({required this.progress});

  final HomeMonthlyProgress progress;

  @override
  Widget build(BuildContext context) {
    final maxDays = progress.maxDays.clamp(1, 30).toInt();
    final studiedDays = progress.studiedDays.clamp(0, maxDays).toInt();

    return SizedBox(
      width: 278,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '今月の勉強量',
                style: TextStyle(
                  color: Color(0xff9b9ba4),
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$studiedDays日',
                style: const TextStyle(
                  color: Color(0xff60606a),
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 278,
            height: 28,
            child: CustomPaint(
              painter: _MonthlyStudyProgressPainter(
                studiedDays: studiedDays,
                maxDays: maxDays,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyStudyProgressPainter extends CustomPainter {
  const _MonthlyStudyProgressPainter({
    required this.studiedDays,
    required this.maxDays,
  });

  final int studiedDays;
  final int maxDays;

  @override
  void paint(Canvas canvas, Size size) {
    final trackHeight = 7.0;
    final trackTop = 1.0;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackTop, size.width, trackHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      trackRect,
      Paint()..color = const Color(0xffe8e8f0),
    );

    final progressWidth =
        size.width * studiedDays / maxDays.clamp(1, 30).toDouble();
    if (progressWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, trackTop, progressWidth, trackHeight),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xff6263d9),
      );
    }

    final tickPaint = Paint()
      ..color = const Color(0xffb9b9c6)
      ..strokeWidth = 1;
    final milestones = <int>[];
    for (var milestone = 10; milestone < maxDays; milestone += 10) {
      milestones.add(milestone);
    }
    milestones.add(maxDays);

    for (final milestone in milestones) {
      final x = size.width * milestone / maxDays;
      canvas.drawLine(Offset(x, 0), Offset(x, 10), tickPaint);

      final label = TextPainter(
        text: TextSpan(
          text: '$milestone',
          style: const TextStyle(
            color: Color(0xffa2a2ad),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelLeft =
          (x - label.width / 2).clamp(0.0, size.width - label.width).toDouble();
      label.paint(canvas, Offset(labelLeft, 14));
    }

  }

  @override
  bool shouldRepaint(covariant _MonthlyStudyProgressPainter oldDelegate) =>
      oldDelegate.studiedDays != studiedDays ||
      oldDelegate.maxDays != maxDays;
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
