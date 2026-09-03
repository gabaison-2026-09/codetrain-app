import 'package:flutter/material.dart';

import '../features/authentication/data/mock_auth_repository.dart';
import '../features/authentication/domain/auth_repository.dart';
import '../features/authentication/presentation/login_page.dart';
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

class CodeTrainApp extends StatefulWidget {
  const CodeTrainApp({
    super.key,
    this.authRepository,
    this.initiallyAuthenticated = false,
    this.topNavigationRepository,
    this.homeRepository,
    this.friendRepository,
    this.taskLauncher,
    this.learnRepository,
    this.taskRepository,
    this.calendarRepository,
  });

  final AuthRepository? authRepository;
  final bool initiallyAuthenticated;
  final TopNavigationRepository? topNavigationRepository;
  final HomeDashboardRepository? homeRepository;
  final FriendRepository? friendRepository;
  final TaskLauncher? taskLauncher;
  final LearnRepository? learnRepository;
  final TaskRepository? taskRepository;
  final CalendarRepository? calendarRepository;

  @override
  State<CodeTrainApp> createState() => _CodeTrainAppState();
}

class _CodeTrainAppState extends State<CodeTrainApp> {
  late final AuthRepository _authRepository;
  late bool _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? const MockAuthRepository();
    _isAuthenticated = widget.initiallyAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    final usesMockTopNavigation = widget.topNavigationRepository == null;
    final usesMockHome = widget.homeRepository == null;
    final usesMockLearn = widget.learnRepository == null;
    final resolvedTopNavigationRepository =
        widget.topNavigationRepository ?? const MockTopNavigationRepository();
    final resolvedHomeRepository =
        widget.homeRepository ?? const MockHomeDashboardRepository();
    final resolvedFriendRepository =
        widget.friendRepository ?? MockFriendRepository();
    final resolvedTaskLauncher =
        widget.taskLauncher ?? const MockTaskLauncher();
    final resolvedLearnRepository =
        widget.learnRepository ?? const MockLearnRepository();
    final resolvedTaskRepository =
        widget.taskRepository ?? MockTaskRepository();
    final resolvedCalendarRepository =
        widget.calendarRepository ?? const MockCalendarRepository();

    return MaterialApp(
      title: 'CodeTrain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: _isAuthenticated
          ? HomePage(
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
            )
          : LoginPage(
              repository: _authRepository,
              onSignedIn: (_) => setState(() => _isAuthenticated = true),
            ),
    );
  }
}
