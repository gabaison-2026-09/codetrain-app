import 'package:flutter/material.dart';

import '../features/home/data/mock_home_dashboard_repository.dart';
import '../features/home/data/mock_top_navigation_repository.dart';
import '../features/home/domain/home_dashboard_repository.dart';
import '../features/home/domain/top_navigation_repository.dart';
import '../features/home/presentation/home_page.dart';
import '../features/learn/data/mock_learn_repository.dart';
import '../features/learn/domain/learn_repository.dart';

class CodeTrainApp extends StatelessWidget {
  const CodeTrainApp({
    super.key,
    this.topNavigationRepository,
    this.homeRepository,
    this.learnRepository,
  });

  final TopNavigationRepository? topNavigationRepository;
  final HomeDashboardRepository? homeRepository;
  final LearnRepository? learnRepository;

  @override
  Widget build(BuildContext context) {
    final usesMockTopNavigation = topNavigationRepository == null;
    final usesMockHome = homeRepository == null;
    final usesMockLearn = learnRepository == null;
    final resolvedTopNavigationRepository =
        topNavigationRepository ?? const MockTopNavigationRepository();
    final resolvedHomeRepository =
        homeRepository ?? const MockHomeDashboardRepository();
    final resolvedLearnRepository =
        learnRepository ?? const MockLearnRepository();

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
        learnRepository: resolvedLearnRepository,
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
