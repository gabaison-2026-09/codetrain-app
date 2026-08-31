import 'package:flutter/material.dart';

import '../../../shared/widgets/code_train_bottom_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _pages = <Widget>[
    _NavigationPlaceholderPage(label: 'Calendar'),
    _NavigationPlaceholderPage(label: 'Learn'),
    _NavigationPlaceholderPage(label: 'Home'),
    _NavigationPlaceholderPage(label: 'Task'),
    _NavigationPlaceholderPage(label: 'Profile'),
  ];

  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6f7),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
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

class _NavigationPlaceholderPage extends StatelessWidget {
  const _NavigationPlaceholderPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$label screen',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
