import 'package:flutter/material.dart';

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
  final TopNavigationStatus? initialTopNavigationStatus;
  final HomeDashboard? initialHomeDashboard;
  final LearnCatalog? initialLearnCatalog;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<Widget> _pages;
  late final ValueNotifier<int> _taskSelectionVersion;

  int _selectedIndex = 2;
  var _isLearnQuestionViewVisible = false;
  late final TopNavigationRepository _topNavigationRepository;
  late final Future<TopNavigationStatus> _topNavigationStatusFuture;

  @override
  void initState() {
    super.initState();
    _topNavigationRepository = widget.topNavigationRepository;
    _topNavigationStatusFuture = _topNavigationRepository.fetchStatus();
    _taskSelectionVersion = ValueNotifier(0);
    _pages = [
      const CalendarPage(),
      LearnPage(
        repository: widget.learnRepository,
        initialCatalog: widget.initialLearnCatalog,
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
        initialDashboard: widget.initialHomeDashboard,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            reverseDuration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  ...(currentChild == null
                      ? const <Widget>[]
                      : <Widget>[currentChild]),
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0.018, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slideAnimation, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: _pages[_selectedIndex],
            ),
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
                        });
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
