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
  late final ValueNotifier<LearnTaskStartRequest?> _startLearningRequest;
  late final ValueNotifier<bool> _isHomeVisible;

  int _selectedIndex = 2;
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
    _startLearningRequest = ValueNotifier(null);
    _isHomeVisible = ValueNotifier(true);
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
      ),
      HomeTabPage(
        repository: widget.homeRepository,
        taskRepository: widget.taskRepository,
        taskLauncher: widget.taskLauncher,
        taskSelectionVersion: _taskSelectionVersion,
        isVisible: _isHomeVisible,
        initialDashboard: widget.initialHomeDashboard,
        onStartLearning: _handleStartLearningFromHome,
      ),
      TaskPage(
        repository: widget.taskRepository,
        taskLauncher: widget.taskLauncher,
        onTaskCatalogChanged: () => _taskSelectionVersion.value++,
      ),
      FriendPage(repository: widget.friendRepository),
    ];
  }

  @override
  void dispose() {
    _taskSelectionVersion.dispose();
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
