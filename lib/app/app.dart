import 'package:flutter/material.dart';

import '../features/calendar/data/mock_calendar_repository.dart';
import '../features/calendar/domain/calendar_repository.dart';
import '../features/friend/data/mock_friend_repository.dart';
import '../features/friend/domain/friend_repository.dart';
import '../features/home/data/mock_home_dashboard_repository.dart';
import '../features/home/data/mock_top_navigation_repository.dart';
import '../features/home/domain/home_dashboard_repository.dart';
import '../features/home/domain/top_navigation_repository.dart';
import '../features/home/presentation/home_page.dart';
import '../features/learn/data/mock_learn_repository.dart';
import '../features/learn/domain/learn_repository.dart';
import '../features/task/data/mock_task_repository.dart';
import '../features/task/data/mock_task_launcher.dart';
import '../features/task/domain/task_launcher.dart';
import '../features/task/domain/task_repository.dart';

class CodeTrainApp extends StatelessWidget {
  const CodeTrainApp({
    super.key,
    this.topNavigationRepository,
    this.homeRepository,
    this.friendRepository,
    this.taskLauncher,
    this.learnRepository,
    this.taskRepository,
    this.calendarRepository,
  });

  final TopNavigationRepository? topNavigationRepository;
  final HomeDashboardRepository? homeRepository;
  final FriendRepository? friendRepository;
  final TaskLauncher? taskLauncher;
  final LearnRepository? learnRepository;
  final TaskRepository? taskRepository;
  final CalendarRepository? calendarRepository;

  @override
  Widget build(BuildContext context) {
    final usesMockTopNavigation = topNavigationRepository == null;
    final usesMockHome = homeRepository == null;
    final usesMockLearn = learnRepository == null;
    final resolvedTopNavigationRepository =
        topNavigationRepository ?? const MockTopNavigationRepository();
    final resolvedHomeRepository =
        homeRepository ?? const MockHomeDashboardRepository();
    final resolvedFriendRepository = friendRepository ?? MockFriendRepository();
    final resolvedTaskLauncher = taskLauncher ?? const MockTaskLauncher();
    final resolvedLearnRepository =
        learnRepository ?? const MockLearnRepository();
    final resolvedTaskRepository = taskRepository ?? MockTaskRepository();
    final resolvedCalendarRepository =
        calendarRepository ?? const MockCalendarRepository();

    return MaterialApp(
      title: 'CodeTrain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: HomePage(
        topNavigationRepository: resolvedTopNavigationRepository,
        homeRepository: resolvedHomeRepository,
        friendRepository: resolvedFriendRepository,
        taskLauncher: resolvedTaskLauncher,
        learnRepository: resolvedLearnRepository,
        taskRepository: resolvedTaskRepository,
        calendarRepository: resolvedCalendarRepository,
        initialTopNavigationStatus: usesMockTopNavigation
            ? MockTopNavigationRepository.mockStatus
            : null,
        initialHomeDashboard: usesMockHome
            ? MockHomeDashboardRepository.dashboardFor(DateTime.now())
            : null,
        initialLearnCatalog: usesMockLearn
            ? MockLearnRepository.mockCatalog
            : null,
      ),
    );
  }
}
