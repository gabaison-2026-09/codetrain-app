import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calendar/domain/calendar_repository.dart';
import '../../friend/domain/friend_repository.dart';
import '../../friend/presentation/friend_page.dart';
import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';
import '../domain/top_navigation_repository.dart';
import '../domain/top_navigation_status.dart';
import '../../../shared/widgets/code_train_bottom_navigation.dart';
import '../../../shared/widgets/code_train_top_navigation.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../learn/presentation/learn_page.dart';
import '../../learn/domain/learn_content.dart';
import '../../learn/domain/learn_repository.dart';
import '../../task/domain/task_configuration.dart';
import '../../task/presentation/task_page.dart';
import '../../task/domain/task_launcher.dart';
import '../../task/domain/task_repository.dart';
import 'home_tab_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.topNavigationRepository,
    required this.homeRepository,
    required this.friendRepository,
    required this.taskLauncher,
    required this.learnRepository,
    required this.taskRepository,
    required this.calendarRepository,
    this.initialTopNavigationStatus,
    this.initialHomeDashboard,
    this.initialLearnCatalog,
  });

  final TopNavigationRepository topNavigationRepository;
  final HomeDashboardRepository homeRepository;
  final FriendRepository friendRepository;
  final TaskLauncher taskLauncher;
  final LearnRepository learnRepository;
  final TaskRepository taskRepository;
  final CalendarRepository calendarRepository;
  final TopNavigationStatus? initialTopNavigationStatus;
  final HomeDashboard? initialHomeDashboard;
  final LearnCatalog? initialLearnCatalog;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<Widget> _pages;
  late final ValueNotifier<int> _taskSelectionVersion;
  late final ValueNotifier<int> _taskCompletionVersion;
  late final ValueNotifier<LearnTaskStartRequest?> _startLearningRequest;
  late final ValueNotifier<bool> _isHomeVisible;

  HomeDashboard? _homeDashboard;
  int _selectedIndex = 2;
  var _taskCompletionOverlayVersion = 0;
  var _taskCompletionOverlayStartProgress = 0.0;
  var _taskCompletionOverlayEndProgress = 0.0;
  var _taskCompletionOverlayStreakDays = 0;
  var _taskCompletionOverlayShouldIncrementStreak = false;
  var _isLearnQuestionViewVisible = false;
  var _isStartingLearningFromHome = false;
  late final TopNavigationRepository _topNavigationRepository;
  late final Future<TopNavigationStatus> _topNavigationStatusFuture;

  @override
  void initState() {
    super.initState();
    _topNavigationRepository = widget.topNavigationRepository;
    _topNavigationStatusFuture = _topNavigationRepository.fetchStatus();
    _taskSelectionVersion = ValueNotifier(0);
    _taskCompletionVersion = ValueNotifier(0);
    _startLearningRequest = ValueNotifier(null);
    _isHomeVisible = ValueNotifier(true);
    _homeDashboard = widget.initialHomeDashboard;
    _pages = [
      CalendarPage(repository: widget.calendarRepository),
      LearnPage(
        repository: widget.learnRepository,
        initialCatalog: widget.initialLearnCatalog,
        startLearningRequest: _startLearningRequest,
        onStartLearningRequestConsumed: () =>
            _startLearningRequest.value = null,
        onQuestionViewChanged: (isVisible) {
          if (_isLearnQuestionViewVisible == isVisible) return;
          setState(() => _isLearnQuestionViewVisible = isVisible);
        },
        onTaskCompleted: _handleTaskCompleted,
      ),
      HomeTabPage(
        repository: widget.homeRepository,
        taskRepository: widget.taskRepository,
        taskLauncher: widget.taskLauncher,
        taskSelectionVersion: _taskSelectionVersion,
        taskCompletionVersion: _taskCompletionVersion,
        onDashboardLoaded: _handleDashboardLoaded,
        isVisible: _isHomeVisible,
        initialDashboard: widget.initialHomeDashboard,
        onStartLearning: _handleStartLearningFromHome,
      ),
      TaskPage(
        repository: widget.taskRepository,
        onTaskCatalogChanged: () => _taskSelectionVersion.value++,
      ),
      FriendPage(repository: widget.friendRepository),
    ];
  }

  @override
  void dispose() {
    _taskSelectionVersion.dispose();
    _taskCompletionVersion.dispose();
    _startLearningRequest.dispose();
    _isHomeVisible.dispose();
    super.dispose();
  }

  void _handleStartLearningFromHome(LearningTask? task) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = 1;
      _isStartingLearningFromHome = true;
    });
    _isHomeVisible.value = false;
    _startLearningRequest.value = LearnTaskStartRequest(
      filters: task == null
          ? const []
          : [
              for (final slot in task.slots)
                if (slot.questionType != null)
                  LearnQuestionFilter(
                    type: switch (slot.questionType!) {
                      TaskQuestionType.codeReading =>
                        LearnQuestionType.codeReading,
                      TaskQuestionType.outputPrediction =>
                        LearnQuestionType.outputPrediction,
                    },
                    language: slot.language,
                    minimumDifficulty: slot.minimumDifficulty,
                    maximumDifficulty: slot.maximumDifficulty,
                  ),
            ],
      isTaskBased: task != null,
    );
  }

  void _handleTaskCompleted() {
    if (!mounted) return;
    final dashboard = _homeDashboard;
    final totalTasks = dashboard?.taskProgress.totalTasks
            .clamp(0, 5)
            .toInt() ??
        5;
    final baseCompletedTasks = dashboard?.taskProgress.completedTasks
            .clamp(0, totalTasks)
            .toInt() ??
        0;
    final currentCompletedTasks = (baseCompletedTasks +
            _taskCompletionVersion.value)
        .clamp(0, totalTasks)
        .toInt();
    final nextCompletedTasks = (currentCompletedTasks + 1)
        .clamp(0, totalTasks)
        .toInt();
    if (totalTasks == 0 || currentCompletedTasks >= totalTasks) {
      return;
    }
    final shouldIncrementStreak = totalTasks > 0 &&
        currentCompletedTasks < totalTasks &&
        nextCompletedTasks == totalTasks;
    _taskCompletionVersion.value++;
    setState(() {
      _taskCompletionOverlayStartProgress = totalTasks == 0
          ? 0.0
          : currentCompletedTasks / totalTasks;
      _taskCompletionOverlayEndProgress = totalTasks == 0
          ? 0.0
          : nextCompletedTasks / totalTasks;
      _taskCompletionOverlayStreakDays = dashboard?.streakDays ?? 0;
      _taskCompletionOverlayShouldIncrementStreak = shouldIncrementStreak;
      _taskCompletionOverlayVersion++;
    });
  }

  void _handleDashboardLoaded(HomeDashboard dashboard) {
    _homeDashboard = dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          for (var index = 0; index < _pages.length; index++)
            _PageLayer(
              key: ValueKey('page-layer-$index'),
              page: _pages[index],
              isVisible: index == _selectedIndex,
              isStartingLearningFromHome: _isStartingLearningFromHome,
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FutureBuilder<TopNavigationStatus>(
              future: _topNavigationStatusFuture,
              initialData: widget.initialTopNavigationStatus,
              builder: (context, snapshot) {
                final status = snapshot.data;
                if (status == null) return const SizedBox.shrink();
                return CodeTrainTopNavigation(
                  level: status.level,
                  progress: status.experienceProgress,
                  filledHeartCount: status.hearts,
                  heartCount: status.maxHearts,
                );
              },
            ),
          ),
          if (!(_selectedIndex == 1 && _isLearnQuestionViewVisible))
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = (constraints.maxWidth / 973).clamp(0.32, 1.0);
                  final systemBottomInset = MediaQuery.of(
                    context,
                  ).padding.bottom;
                  return SizedBox(
                    width: 973 * scale,
                    height: 325 * scale + systemBottomInset,
                    child: CodeTrainBottomNavigation(
                      initialSelectedIndex: _selectedIndex,
                      bottomInset: systemBottomInset / scale,
                      onTabSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                          _isStartingLearningFromHome = false;
                        });
                        _isHomeVisible.value = index == 2;
                      },
                    ),
                  );
                },
              ),
            ),
          if (_taskCompletionOverlayVersion > 0)
            Positioned.fill(
              child: _TaskCompletionOverlay(
                key: ValueKey(
                  'task-completion-overlay-$_taskCompletionOverlayVersion',
                ),
                startProgress: _taskCompletionOverlayStartProgress,
                endProgress: _taskCompletionOverlayEndProgress,
                streakDays: _taskCompletionOverlayStreakDays,
                shouldIncrementStreak:
                    _taskCompletionOverlayShouldIncrementStreak,
                onCompleted: () {
                  if (!mounted) return;
                  setState(() => _taskCompletionOverlayVersion = 0);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PageLayer extends StatelessWidget {
  const _PageLayer({
    super.key,
    required this.page,
    required this.isVisible,
    required this.isStartingLearningFromHome,
  });

  final Widget page;
  final bool isVisible;
  final bool isStartingLearningFromHome;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(
      milliseconds: isStartingLearningFromHome ? 480 : 260,
    );
    final hiddenOffset = isStartingLearningFromHome
        ? const Offset(0, 0.075)
        : const Offset(0.018, 0);
    final hiddenScale = isStartingLearningFromHome ? 0.96 : 1.0;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isVisible,
        child: AnimatedOpacity(
          opacity: isVisible ? 1 : 0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: isVisible ? Offset.zero : hiddenOffset,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: isVisible ? 1 : hiddenScale,
              duration: duration,
              curve: Curves.easeOutBack,
              child: page,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCompletionOverlay extends StatefulWidget {
  const _TaskCompletionOverlay({
    super.key,
    required this.startProgress,
    required this.endProgress,
    required this.streakDays,
    required this.shouldIncrementStreak,
    required this.onCompleted,
  });

  final double startProgress;
  final double endProgress;
  final int streakDays;
  final bool shouldIncrementStreak;
  final VoidCallback onCompleted;

  @override
  State<_TaskCompletionOverlay> createState() => _TaskCompletionOverlayState();
}

class _TaskCompletionOverlayState extends State<_TaskCompletionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentScale;
  late final Animation<double> _gaugeProgress;
  late final Animation<double> _oldStreakDayScale;
  late final Animation<double> _oldStreakDayOpacity;
  late final Animation<double> _newStreakDayScale;
  late final Animation<double> _newStreakDayOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.shouldIncrementStreak ? 5000 : 3000,
      ),
    )..addStatusListener(_handleAnimationStatus);
    _contentOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 1),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: widget.shouldIncrementStreak ? 88 : 78,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1, end: 0),
        weight: widget.shouldIncrementStreak ? 2 : 12,
      ),
    ]).animate(_controller);
    _contentScale = Tween<double>(begin: 0.56, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.2, curve: Curves.easeOutBack),
      ),
    );
    _gaugeProgress = Tween<double>(
      begin: widget.startProgress,
      end: widget.endProgress,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.6, curve: Curves.easeInOutCubic),
      ),
    );
    _oldStreakDayScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 0.0),
        weight: 58,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.shouldIncrementStreak ? 0.63 : 1.0,
          widget.shouldIncrementStreak ? 0.71 : 1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _oldStreakDayOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 44,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1, end: 0),
        weight: 56,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.shouldIncrementStreak ? 0.63 : 1.0,
          widget.shouldIncrementStreak ? 0.71 : 1.0,
          curve: Curves.linear,
        ),
      ),
    );
    _newStreakDayScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.62, end: 1.08),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0),
        weight: 42,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.shouldIncrementStreak ? 0.72 : 1.0,
          widget.shouldIncrementStreak ? 0.78 : 1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _newStreakDayOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.shouldIncrementStreak ? 0.72 : 1.0,
          widget.shouldIncrementStreak ? 0.76 : 1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final screenSize = MediaQuery.sizeOf(context);
          final gaugeSize = math.min(
            math.min(screenSize.width, screenSize.height) * 0.74,
            460.0,
          ).clamp(260.0, 460.0).toDouble();
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.white.withAlpha(236)),
              Center(
                child: FadeTransition(
                  opacity: _contentOpacity,
                  child: ScaleTransition(
                    scale: _contentScale,
                    child: SizedBox.square(
                      dimension: gaugeSize,
                      child: CustomPaint(
                        painter: _FullScreenStreakGaugePainter(
                          progress: _gaugeProgress.value,
                          color: const Color(0xffff6a2a),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_outlined,
                                color: Color(0xffff6a2a),
                                size: 90,
                              ),
                              _StreakDayLabel(
                                currentStreakDays: widget.streakDays,
                                shouldIncrementStreak:
                                    widget.shouldIncrementStreak,
                                oldScale: _oldStreakDayScale.value,
                                oldOpacity: _oldStreakDayOpacity.value,
                                newScale: _newStreakDayScale.value,
                                newOpacity: _newStreakDayOpacity.value,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '連続日数',
                                style: TextStyle(
                                  color: Color(0xff707078),
                                  fontFamily: 'Noto Sans Japanese',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakDayLabel extends StatelessWidget {
  const _StreakDayLabel({
    required this.currentStreakDays,
    required this.shouldIncrementStreak,
    required this.oldScale,
    required this.oldOpacity,
    required this.newScale,
    required this.newOpacity,
  });

  final int currentStreakDays;
  final bool shouldIncrementStreak;
  final double oldScale;
  final double oldOpacity;
  final double newScale;
  final double newOpacity;

  static const _textStyle = TextStyle(
    color: Colors.black,
    fontFamily: 'Jua',
    fontSize: 68,
    fontWeight: FontWeight.w400,
    height: 0.9,
  );

  @override
  Widget build(BuildContext context) {
    if (!shouldIncrementStreak) {
      return Text('$currentStreakDays', style: _textStyle);
    }

    return SizedBox(
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: oldOpacity,
            child: Transform.scale(
              scale: oldScale,
              child: Text('$currentStreakDays', style: _textStyle),
            ),
          ),
          Opacity(
            opacity: newOpacity,
            child: Transform.scale(
              scale: newScale,
              child: Text('${currentStreakDays + 1}', style: _textStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenStreakGaugePainter extends CustomPainter {
  const _FullScreenStreakGaugePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = 140 * math.pi / 180;
    const sweepAngle = 260 * math.pi / 180;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 18;
    final trackPaint = Paint()
      ..color = const Color(0xffe6e6eb)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
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
  bool shouldRepaint(covariant _FullScreenStreakGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
