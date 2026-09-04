import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';
import '../../legal/presentation/open_source_licenses_page.dart';
import '../../task/domain/task_configuration.dart';
import '../../task/domain/task_launcher.dart';
import '../../task/domain/task_repository.dart';
import '../../../shared/widgets/programming_language_icon.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({
    super.key,
    required this.repository,
    required this.taskRepository,
    required this.taskLauncher,
    this.taskSelectionVersion,
    this.taskCompletionVersion,
    this.onDashboardLoaded,
    this.isVisible,
    this.initialDashboard,
    this.onStartLearning,
  });

  final HomeDashboardRepository repository;
  final TaskRepository taskRepository;
  final TaskLauncher taskLauncher;
  final ValueListenable<int>? taskSelectionVersion;
  final ValueListenable<int>? taskCompletionVersion;
  final ValueChanged<HomeDashboard>? onDashboardLoaded;
  final ValueListenable<bool>? isVisible;
  final HomeDashboard? initialDashboard;
  final ValueChanged<LearningTask?>? onStartLearning;

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  late final HomeDashboardRepository _repository;
  late final Future<HomeDashboard> _dashboardFuture;
  late Future<TaskCatalog> _taskCatalogFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _dashboardFuture = _repository.fetchDashboard();
    _taskCatalogFuture = widget.taskRepository.fetchCatalog();
    widget.taskSelectionVersion?.addListener(_handleTaskSelectionChanged);
  }

  @override
  void dispose() {
    widget.taskSelectionVersion?.removeListener(_handleTaskSelectionChanged);
    super.dispose();
  }

  void _handleTaskSelectionChanged() {
    if (!mounted) return;
    setState(() {
      _taskCatalogFuture = widget.taskRepository.fetchCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeDashboard>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final dashboard = snapshot.data ??
            (snapshot.hasError ? widget.initialDashboard : null);
        if (dashboard == null) {
          return const _HomeLoadingView();
        }
        return FutureBuilder<TaskCatalog>(
          future: _taskCatalogFuture,
          builder: (context, taskSnapshot) {
            if (taskSnapshot.connectionState != ConnectionState.done) {
              return const _HomeLoadingView();
            }
            final catalogTasks = taskSnapshot.data?.tasks;
            final learningTask = catalogTasks == null || catalogTasks.isEmpty
                ? null
                : catalogTasks.first;
            final configuredSlots = learningTask?.slots
                .where((slot) => slot.isConfigured)
                .take(5)
                .toList();
            configuredSlots?.sort(
              (left, right) => left.slotNo.compareTo(right.slotNo),
            );
            final selectedTasks = configuredSlots == null
                ? dashboard.studyTasks
                : [
                    for (final slot in configuredSlots)
                      _toHomeStudyTask(learningTask!, slot),
                  ];
            final slotConfigurations = configuredSlots == null
                ? null
                : [
                    for (final slot in configuredSlots)
                      learningTask!.copyWith(slots: [slot]),
                  ];
            return _HomeDashboardView(
              dashboard: dashboard,
              taskLauncher: widget.taskLauncher,
              studyTasks: selectedTasks,
              taskConfigurations: slotConfigurations,
              taskCompletionVersion: widget.taskCompletionVersion,
              onDashboardLoaded: widget.onDashboardLoaded,
              isVisible: widget.isVisible,
              onStartLearning: widget.onStartLearning,
              onOpenLicenses: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const OpenSourceLicensesPage(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xff6263d9),
        ),
      ),
    );
  }
}

HomeStudyTask _toHomeStudyTask(LearningTask task, TaskSlot slot) {
  return HomeStudyTask(
    id: task.id,
    name: slot.questionType!.label,
    taskNo: slot.slotNo,
    languages: slot.language.isEmpty ? const [] : [slot.language],
  );
}

class _HomeDashboardView extends StatefulWidget {
  const _HomeDashboardView({
    required this.dashboard,
    required this.taskLauncher,
    required this.studyTasks,
    this.taskConfigurations,
    this.taskCompletionVersion,
    this.onDashboardLoaded,
    this.isVisible,
    this.onStartLearning,
    required this.onOpenLicenses,
  });

  final HomeDashboard dashboard;
  final TaskLauncher taskLauncher;
  final List<HomeStudyTask> studyTasks;
  final List<LearningTask>? taskConfigurations;
  final ValueListenable<int>? taskCompletionVersion;
  final ValueChanged<HomeDashboard>? onDashboardLoaded;
  final ValueListenable<bool>? isVisible;
  final ValueChanged<LearningTask?>? onStartLearning;
  final VoidCallback onOpenLicenses;

  @override
  State<_HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<_HomeDashboardView> {
  var _selectedTaskIndex = 0;
  var _swipeDirection = 1;
  var _isStartingTask = false;
  HomeStudyTask? _startingTask;
  late int _displayedCompletedTasks;
  late int _displayedStreakDays;
  var _lastTaskCompletionVersion = 0;
  var _streakProgressAnimationToken = 0;
  var _streakProgressAnimationStartTasks = 0;
  var _hasPendingStreakProgressAnimation = false;

  @override
  void initState() {
    super.initState();
    widget.onDashboardLoaded?.call(widget.dashboard);
    final completionVersion = widget.taskCompletionVersion?.value ?? 0;
    _lastTaskCompletionVersion = completionVersion;
    final initialCompletedTasks = _clampCompletedTasks(
      widget.dashboard.taskProgress.completedTasks,
      widget.dashboard.taskProgress.totalTasks,
    );
    _displayedCompletedTasks = _clampCompletedTasks(
      initialCompletedTasks + completionVersion,
      widget.dashboard.taskProgress.totalTasks,
    );
    final shouldIncrementInitialStreak =
        widget.dashboard.taskProgress.totalTasks > 0 &&
        initialCompletedTasks < widget.dashboard.taskProgress.totalTasks &&
        _displayedCompletedTasks >= widget.dashboard.taskProgress.totalTasks;
    _displayedStreakDays =
        widget.dashboard.streakDays + (shouldIncrementInitialStreak ? 1 : 0);
    _streakProgressAnimationStartTasks = initialCompletedTasks;
    if (_displayedCompletedTasks > initialCompletedTasks) {
      if (widget.isVisible?.value != false) {
        _streakProgressAnimationToken = 1;
      } else {
        _hasPendingStreakProgressAnimation = true;
      }
    }
    widget.taskCompletionVersion?.addListener(_handleTaskCompletionChanged);
    widget.isVisible?.addListener(_handleVisibilityChanged);
  }

  @override
  void didUpdateWidget(covariant _HomeDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      oldWidget.isVisible?.removeListener(_handleVisibilityChanged);
      widget.isVisible?.addListener(_handleVisibilityChanged);
    }
    if (oldWidget.taskCompletionVersion != widget.taskCompletionVersion) {
      oldWidget.taskCompletionVersion?.removeListener(
        _handleTaskCompletionChanged,
      );
      _lastTaskCompletionVersion =
          widget.taskCompletionVersion?.value ?? _lastTaskCompletionVersion;
      widget.taskCompletionVersion?.addListener(_handleTaskCompletionChanged);
    }

    final taskCount = widget.studyTasks.length;
    if (taskCount == 0) {
      _selectedTaskIndex = 0;
    } else if (_selectedTaskIndex >= taskCount) {
      _selectedTaskIndex = taskCount - 1;
    }
  }

  @override
  void dispose() {
    widget.taskCompletionVersion?.removeListener(_handleTaskCompletionChanged);
    widget.isVisible?.removeListener(_handleVisibilityChanged);
    super.dispose();
  }

  void _handleVisibilityChanged() {
    if (!mounted || widget.isVisible?.value != true) {
      return;
    }
    if (!_isStartingTask && !_hasPendingStreakProgressAnimation) return;
    setState(() {
      if (_isStartingTask) {
        _isStartingTask = false;
        _startingTask = null;
      }
      if (_hasPendingStreakProgressAnimation) {
        _hasPendingStreakProgressAnimation = false;
        _streakProgressAnimationToken++;
      }
    });
  }

  void _handleTaskCompletionChanged() {
    final completionVersion = widget.taskCompletionVersion?.value;
    if (!mounted || completionVersion == null) return;
    final completionCount =
        completionVersion - _lastTaskCompletionVersion;
    if (completionCount <= 0) return;
    _lastTaskCompletionVersion = completionVersion;

    final previousCompletedTasks = _displayedCompletedTasks;
    final nextCompletedTasks = _clampCompletedTasks(
      previousCompletedTasks + completionCount,
      widget.dashboard.taskProgress.totalTasks,
    );
    if (nextCompletedTasks == previousCompletedTasks) return;

    final isVisible = widget.isVisible?.value != false;
    final shouldIncrementStreak =
        widget.dashboard.taskProgress.totalTasks > 0 &&
        previousCompletedTasks < widget.dashboard.taskProgress.totalTasks &&
        nextCompletedTasks >= widget.dashboard.taskProgress.totalTasks;
    setState(() {
      _displayedCompletedTasks = nextCompletedTasks;
      if (shouldIncrementStreak) {
        _displayedStreakDays++;
      }
      if (isVisible) {
        _streakProgressAnimationStartTasks = previousCompletedTasks;
        _streakProgressAnimationToken++;
      } else if (!_hasPendingStreakProgressAnimation) {
        _streakProgressAnimationStartTasks = previousCompletedTasks;
        _hasPendingStreakProgressAnimation = true;
      }
    });
  }

  static int _clampCompletedTasks(int completedTasks, int totalTasks) {
    final safeTotal = totalTasks.clamp(0, 5).toInt();
    return completedTasks.clamp(0, safeTotal).toInt();
  }

  static const _purple = Color(0xff6263d9);
  static const _orange = Color(0xffff6a2a);
  static const _taskColors = [_purple, Color(0xff3f8f9d), Color(0xff8c5aa8)];

  HomeStudyTask get _selectedTask {
    final startingTask = _startingTask;
    if (startingTask != null) {
      return startingTask;
    }
    final tasks = widget.studyTasks;
    if (tasks.isEmpty) {
      return const HomeStudyTask(languages: []);
    }
    final safeIndex = _selectedTaskIndex.clamp(0, tasks.length - 1).toInt();
    return tasks[safeIndex];
  }

  LearningTask? get _selectedTaskConfiguration {
    final taskConfigurations = widget.taskConfigurations;
    if (taskConfigurations == null || taskConfigurations.isEmpty) {
      return null;
    }
    final safeIndex = _selectedTaskIndex
        .clamp(0, taskConfigurations.length - 1)
        .toInt();
    return taskConfigurations[safeIndex];
  }

  Color get _selectedTaskColor =>
      _taskColors[_selectedTaskIndex % _taskColors.length];

  void _handleTaskSwipe(DragEndDetails details) {
    if (_isStartingTask) return;
    final velocity = details.primaryVelocity;
    final taskCount = widget.studyTasks.length;
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

  Future<void> _handleStartSelectedTask() async {
    if (_isStartingTask) return;
    final task = _selectedTask;
    final taskConfiguration = _selectedTaskConfiguration;
    if (task.id.isEmpty && task.taskNo == null) return;
    setState(() {
      _isStartingTask = true;
      _startingTask = task;
    });
    try {
      await widget.taskLauncher.start(
        TaskLaunchTarget(
          name: task.name,
          taskId: task.id,
          taskNo: task.taskNo,
        ),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      widget.onStartLearning?.call(taskConfiguration);
      if (widget.onStartLearning == null) {
        setState(() {
          _isStartingTask = false;
          _startingTask = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isStartingTask = false;
        _startingTask = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タスクを開始できませんでした。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final tasks = widget.studyTasks;
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
                completedTasks: _displayedCompletedTasks,
                streakProgressAnimationToken: _streakProgressAnimationToken,
                streakProgressAnimationStartTasks:
                    _streakProgressAnimationStartTasks,
                streakDays: _displayedStreakDays,
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
                        key: ValueKey('home-play-slot-$_selectedTaskIndex'),
                        color: _selectedTaskColor,
                        onPressed: _isStartingTask
                            ? null
                            : _handleStartSelectedTask,
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
                        key: ValueKey('home-programs-slot-$_selectedTaskIndex'),
                        taskName: _selectedTask.name,
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
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerRight,
                child: _OpenSourceLicensesLink(
                  onPressed: widget.onOpenLicenses,
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
    required this.completedTasks,
    required this.streakProgressAnimationToken,
    required this.streakProgressAnimationStartTasks,
    required this.streakDays,
    required this.purple,
    required this.orange,
  });

  final HomeDashboard dashboard;
  final int completedTasks;
  final int streakProgressAnimationToken;
  final int streakProgressAnimationStartTasks;
  final int streakDays;
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
          completedTasks: completedTasks,
          totalTasks: dashboard.taskProgress.totalTasks,
          streakDays: streakDays,
          color: orange,
          animationToken: streakProgressAnimationToken,
          animationStartCompletedTasks: streakProgressAnimationStartTasks,
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
    required this.animationToken,
    required this.animationStartCompletedTasks,
  });

  final int completedTasks;
  final int totalTasks;
  final int streakDays;
  final Color color;
  final int animationToken;
  final int animationStartCompletedTasks;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalTasks.clamp(0, 5).toInt();
    final safeCompleted = completedTasks.clamp(0, safeTotal).toInt();
    final progress = safeTotal == 0 ? 0.0 : safeCompleted / safeTotal;
    final safeAnimationStart = animationStartCompletedTasks
        .clamp(0, safeCompleted)
        .toInt();
    final animationStartProgress = safeTotal == 0
        ? 0.0
        : safeAnimationStart / safeTotal;
    final shouldAnimate = animationToken > 0 &&
        animationStartProgress < progress;

    return SizedBox(
      width: 124,
      height: 116,
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(
                'streak-progress-$animationToken-$safeCompleted',
              ),
              tween: Tween<double>(
                begin: shouldAnimate ? animationStartProgress : progress,
                end: progress,
              ),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return CustomPaint(
                  painter: _StreakProgressArcPainter(
                    progress: animatedProgress,
                    color: color,
                  ),
                  child: child,
                );
              },
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
  const _PlayButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback? onPressed;

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
            key: ValueKey('home-slot-indicator-$index'),
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
    return GestureDetector(
      onTap: widget.onPressed,
      child: Center(
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
  const _ProgramRow({
    super.key,
    required this.taskName,
    required this.languages,
  });

  final String taskName;
  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (taskName.isNotEmpty) ...[
          Text(
            taskName,
            style: const TextStyle(
              color: Color(0xff222229),
              fontFamily: 'Noto Sans Japanese',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (languages.isNotEmpty)
          _ProgramIcon(language: languages.first)
        else
          const Icon(
            Icons.code_rounded,
            key: ValueKey('home-generic-task-icon'),
            color: Color(0xff6263d9),
            size: 36,
          ),
      ],
    );
  }
}

class _ProgramIcon extends StatelessWidget {
  const _ProgramIcon({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    return ProgrammingLanguageIcon(language: language, size: 36);
  }
}

class _OpenSourceLicensesLink extends StatelessWidget {
  const _OpenSourceLicensesLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const ValueKey('home-open-source-licenses-link'),
      onPressed: onPressed,
      label: const Text('オープンソースライセンス'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xff9b9ba4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: const TextStyle(
          fontFamily: 'Noto Sans Japanese',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
