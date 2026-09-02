import 'package:flutter/material.dart';

import '../data/mock_home_dashboard_repository.dart';
import '../domain/home_dashboard.dart';
import '../domain/home_dashboard_repository.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key, this.repository});

  final HomeDashboardRepository? repository;

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  late final HomeDashboardRepository _repository;
  late final HomeDashboard _initialDashboard;
  late final Future<HomeDashboard> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? const MockHomeDashboardRepository();
    _initialDashboard = MockHomeDashboardRepository.dashboardFor(
      DateTime.now(),
    );
    _dashboardFuture = _repository.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeDashboard>(
      future: _dashboardFuture,
      initialData: _initialDashboard,
      builder: (context, snapshot) {
        final dashboard = snapshot.data;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }
        return _HomeDashboardView(dashboard: dashboard);
      },
    );
  }
}

class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView({required this.dashboard});

  final HomeDashboard dashboard;

  static const _purple = Color(0xff6263d9);
  static const _orange = Color(0xffff6a2a);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = (constraints.maxWidth * 0.024).clamp(
          7.0,
          16.0,
        );
        final topNavigationHeight = 64.0 + MediaQuery.paddingOf(context).top;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topNavigationHeight + 20,
            horizontalPadding,
            330,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DateAndStreakRow(
                dashboard: dashboard,
                purple: _purple,
                orange: _orange,
              ),
              const SizedBox(height: 21),
              _DayStatusDots(
                statuses: dashboard.dayStatuses,
                highlightedDayIndex: dashboard.highlightedDayIndex,
              ),
              const SizedBox(height: 45),
              const _SectionHeading(label: 'READY TO TRAIN'),
              const SizedBox(height: 12),
              const _PlayButton(),
              const SizedBox(height: 17),
              _ProgramRow(programs: dashboard.programs),
              const SizedBox(height: 22),
              const _ReviewProgramSection(),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});

  final String label;

  static const _purple = Color(0xff6263d9);
  static const _line = Color(0xffe9e9f0);
  static const _labelColor = Color(0xff777785);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: _purple,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            height: 1,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(
            color: _line,
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _DateAndStreakRow extends StatelessWidget {
  const _DateAndStreakRow({
    required this.dashboard,
    required this.purple,
    required this.orange,
  });

  final HomeDashboard dashboard;
  final Color purple;
  final Color orange;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-4, 0),
          child: Icon(Icons.calendar_today_outlined, color: purple, size: 52),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Transform.translate(
                  offset: const Offset(-3, 13),
                  child: Text(
                    '${dashboard.activityDate.day}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Jua',
                      fontSize: 100,
                      fontWeight: FontWeight.w400,
                      height: 0.8,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Transform.translate(
                  offset: const Offset(0, 7),
                  child: const Text(
                    '/',
                    style: TextStyle(
                      color: Color(0xffd2d2d2),
                      fontSize: 88,
                      fontWeight: FontWeight.w300,
                      height: 0.88,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Transform.translate(
                  offset: const Offset(0, 10),
                  child: Text(
                    '${dashboard.activityDate.month}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Jua',
                      fontSize: 64,
                      fontWeight: FontWeight.w400,
                      height: 0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: orange,
                size: 38,
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${dashboard.streakDays}',
                      style: const TextStyle(
                        fontFamily: 'Jua',
                        fontSize: 34,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const TextSpan(
                      text: ' days',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(color: Colors.black, height: 1),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayStatusDots extends StatelessWidget {
  const _DayStatusDots({
    required this.statuses,
    required this.highlightedDayIndex,
  });

  final List<HomeDayStatus> statuses;
  final int highlightedDayIndex;

  Color _colorFor(HomeDayStatus status) {
    switch (status) {
      case HomeDayStatus.completed:
        return const Color(0xff91c783);
      case HomeDayStatus.active:
        return const Color(0xff6263d9);
      case HomeDayStatus.upcoming:
        return const Color(0xffd8d8d8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();

    var dotsWidth = 0.0;
    for (var index = 0; index < statuses.length; index++) {
      if (index > 0) dotsWidth += 11;
      dotsWidth += index == highlightedDayIndex ? 22 : 14;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: SizedBox(
        width: dotsWidth,
        height: 34,
        child: Stack(
          children: [
            const Positioned(
              left: 7,
              right: 7,
              top: 17,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xffe9e9f0)),
                child: SizedBox(height: 1),
              ),
            ),
            Positioned(
              left: 0,
              top: 6,
              child: Row(
                children: [
                  for (var index = 0; index < statuses.length; index++) ...[
                    if (index > 0) const SizedBox(width: 11),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _colorFor(statuses[index]),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: index == highlightedDayIndex ? 22 : 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  static const _purple = Color(0xff6263d9);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 278,
        child: CustomPaint(
          painter: const _PlayButtonDecorationPainter(),
          child: const Center(
            child: SizedBox.square(
              dimension: 254,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: _purple, width: 9),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: _purple,
                    size: 210,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButtonDecorationPainter extends CustomPainter {
  const _PlayButtonDecorationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final purple = Paint()
      ..color = const Color(0xff6263d9).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.75,
      0.95,
      false,
      purple,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.25,
      1.15,
      false,
      purple,
    );
  }

  @override
  bool shouldRepaint(covariant _PlayButtonDecorationPainter oldDelegate) =>
      false;
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({required this.programs});

  final List<HomeProgram> programs;

  String _labelFor(HomeProgram program) {
    switch (program) {
      case HomeProgram.csharp:
        return 'C#';
      case HomeProgram.typescript:
        return 'TypeScript';
      case HomeProgram.ruby:
        return 'Ruby';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 23,
      runSpacing: 14,
      children: [
        for (final program in programs)
          _ProgramItem(
            icon: _ProgramIcon(program: program),
            label: _labelFor(program),
          ),
        const _ProgramItem(icon: _AddProgramButton(), label: 'ADD'),
        const _ProgramItem(icon: _AddProgramButton(), label: 'ADD'),
      ],
    );
  }
}

class _ProgramItem extends StatelessWidget {
  const _ProgramItem({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 5),
          SizedBox(
            height: 10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff777785),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewProgramSection extends StatelessWidget {
  const _ReviewProgramSection();

  static const _purple = Color(0xff6263d9);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionHeading(label: 'REVIEW PROGRAM'),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.replay_rounded, size: 20),
          label: const Text('復習する'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _purple,
            side: const BorderSide(color: _purple, width: 1.5),
            minimumSize: const Size(152, 48),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgramIcon extends StatelessWidget {
  const _ProgramIcon({required this.program});

  final HomeProgram program;

  @override
  Widget build(BuildContext context) {
    switch (program) {
      case HomeProgram.csharp:
        return const _CSharpIcon();
      case HomeProgram.typescript:
        return const _TypeScriptIcon();
      case HomeProgram.ruby:
        return const _RubyIcon();
    }
  }
}

class _CSharpIcon extends StatelessWidget {
  const _CSharpIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _CSharpIconPainter()),
    );
  }
}

class _CSharpIconPainter extends CustomPainter {
  const _CSharpIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width - 2.4, 8.4)
      ..lineTo(size.width - 2.4, 27.6)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(2.4, 27.6)
      ..lineTo(2.4, 8.4)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xff0566a8));
    final painter = TextPainter(
      text: const TextSpan(
        text: 'C#',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((size.width - painter.width) / 2, 8.5));
  }

  @override
  bool shouldRepaint(covariant _CSharpIconPainter oldDelegate) => false;
}

class _TypeScriptIcon extends StatelessWidget {
  const _TypeScriptIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Color(0xff367bbb)),
        child: Center(
          child: Text(
            'TS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RubyIcon extends StatelessWidget {
  const _RubyIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _RubyIconPainter()),
    );
  }
}

class _RubyIconPainter extends CustomPainter {
  const _RubyIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 30, size.height / 30);
    final paint = Paint()..color = const Color(0xffd52d36);
    final left = Path()
      ..moveTo(2, 8)
      ..lineTo(11, 2)
      ..lineTo(17, 10)
      ..lineTo(9, 28)
      ..close();
    final right = Path()
      ..moveTo(17, 10)
      ..lineTo(28, 5)
      ..lineTo(26, 22)
      ..lineTo(9, 28)
      ..close();
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
    canvas.drawCircle(const Offset(18, 10), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RubyIconPainter oldDelegate) => false;
}

class _AddProgramButton extends StatelessWidget {
  const _AddProgramButton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _AddProgramButtonPainter()),
    );
  }
}

class _AddProgramButtonPainter extends CustomPainter {
  const _AddProgramButtonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 30, size.height / 30);
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    const center = Offset(15, 15);
    const radius = 12.0;
    for (var index = 0; index < 16; index++) {
      final start = (index * 3.14159265359 / 8) + 0.05;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        0.14,
        false,
        stroke,
      );
    }
    canvas.drawLine(const Offset(10, 15), const Offset(20, 15), stroke);
    canvas.drawLine(const Offset(15, 10), const Offset(15, 20), stroke);
  }

  @override
  bool shouldRepaint(covariant _AddProgramButtonPainter oldDelegate) => false;
}
