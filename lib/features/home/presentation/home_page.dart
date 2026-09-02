import 'package:flutter/material.dart';

import '../data/mock_top_navigation_repository.dart';
import '../domain/top_navigation_repository.dart';
import '../domain/top_navigation_status.dart';
import '../../../shared/widgets/code_train_bottom_navigation.dart';
import '../../../shared/widgets/code_train_top_navigation.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../learn/presentation/learn_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../task/presentation/task_page.dart';
import 'home_tab_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.topNavigationRepository});

  final TopNavigationRepository? topNavigationRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _pages = <Widget>[
    CalendarPage(),
    LearnPage(),
    HomeTabPage(),
    TaskPage(),
    ProfilePage(),
  ];

  int _selectedIndex = 2;
  late final TopNavigationRepository _topNavigationRepository;
  late final Future<TopNavigationStatus> _topNavigationStatusFuture;

  @override
  void initState() {
    super.initState();
    _topNavigationRepository =
        widget.topNavigationRepository ?? const MockTopNavigationRepository();
    _topNavigationStatusFuture = _topNavigationRepository.fetchStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6f7),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FutureBuilder<TopNavigationStatus>(
              future: _topNavigationStatusFuture,
              initialData: MockTopNavigationRepository.mockStatus,
              builder: (context, snapshot) {
                final status = snapshot.data!;
                return CodeTrainTopNavigation(
                  level: status.level,
                  progress: status.experienceProgress,
                  filledHeartCount: status.hearts,
                  heartCount: status.maxHearts,
                );
              },
            ),
          ),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = (constraints.maxWidth / 973).clamp(0.32, 1.0);
                final systemBottomInset = MediaQuery.of(context).padding.bottom;
                return SizedBox(
                  width: 973 * scale,
                  height: 325 * scale + systemBottomInset,
                  child: CodeTrainBottomNavigation(
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
