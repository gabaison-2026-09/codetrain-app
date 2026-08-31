import 'package:flutter/material.dart';

import '../../../shared/widgets/code_train_bottom_navigation.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6f7),
      body: Stack(
        children: [
          const SizedBox.expand(),
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
