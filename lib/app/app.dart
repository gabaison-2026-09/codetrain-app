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
import '../features/onboarding/data/mock_task_recommendation_repository.dart';
import '../features/onboarding/domain/task_recommendation.dart';
import '../features/onboarding/presentation/task_recommendation_page.dart';
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
    this.taskRecommendationRepository,
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
  final TaskRecommendationRepository? taskRecommendationRepository;
  final CalendarRepository? calendarRepository;

  @override
  State<CodeTrainApp> createState() => _CodeTrainAppState();
}

class _CodeTrainAppState extends State<CodeTrainApp> {
  late final AuthRepository _authRepository;
  late TaskRepository _taskRepository;
  late final TaskRecommendationRepository _taskRecommendationRepository;
  late _AppDestination _destination;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? const MockAuthRepository();
    _taskRepository = widget.taskRepository ?? MockTaskRepository();
    _taskRecommendationRepository =
        widget.taskRecommendationRepository ??
        const MockTaskRecommendationRepository();
    _destination = widget.initiallyAuthenticated
        ? _AppDestination.home
        : _AppDestination.authentication;
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
      home: switch (_destination) {
        _AppDestination.home => HomePage(
              topNavigationRepository: resolvedTopNavigationRepository,
              homeRepository: resolvedHomeRepository,
              friendRepository: resolvedFriendRepository,
              taskLauncher: resolvedTaskLauncher,
              learnRepository: resolvedLearnRepository,
              taskRepository: _taskRepository,
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
        _AppDestination.onboarding => TaskRecommendationPage(
              recommendationRepository: _taskRecommendationRepository,
              taskRepository: _taskRepository,
              onCompleted: () =>
                  setState(() => _destination = _AppDestination.home),
            ),
        _AppDestination.authentication => LoginPage(
              repository: _authRepository,
              onSignedIn: (_) =>
                  setState(() => _destination = _AppDestination.home),
              onAccountCreated: _handleAccountCreated,
            ),
      },
    );
  }

  void _handleAccountCreated(AuthSession _) {
    if (widget.taskRepository == null) {
      _taskRepository = MockTaskRepository(hasInitialTasks: false);
    }
    setState(() => _destination = _AppDestination.onboarding);
  }
}

enum _AppDestination { authentication, onboarding, home }
