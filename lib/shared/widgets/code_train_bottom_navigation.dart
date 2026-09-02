import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeTrainBottomNavigation extends StatefulWidget {
  const CodeTrainBottomNavigation({
    super.key,
    this.bottomInset = 0,
    this.onTabSelected,
  });

  final double bottomInset;
  final ValueChanged<int>? onTabSelected;

  @override
  State<CodeTrainBottomNavigation> createState() =>
      _CodeTrainBottomNavigationState();
}

class _CodeTrainBottomNavigationState extends State<CodeTrainBottomNavigation>
    with SingleTickerProviderStateMixin {
  static const _tabCenterXPositions = <double>[118, 302, 483, 668, 851];
  static const _tabLabels = <String>[
    'Calendar',
    'Learn',
    'Home',
    'Task',
    'Profile',
  ];
  static const _selectionBurstProgress = 0.70;

  late final AnimationController _animationController;
  late final Animation<double> _animation;
  int _selectedIndex = 2;
  int _previousSelectedIndex = 2;
  bool _hasTriggeredSelectionHaptic = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    _animationController.value = 1;
    _animationController.addListener(_handleAnimationProgress);
  }

  void _handleAnimationProgress() {
    if (_hasTriggeredSelectionHaptic ||
        _animationController.value < _selectionBurstProgress) {
      return;
    }
    _hasTriggeredSelectionHaptic = true;
    unawaited(HapticFeedback.lightImpact().catchError((_) {}));
  }

  void _handleTabTap(Offset localPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    final scale = renderBox.size.width / 973;
    final x = localPosition.dx / scale;
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < _tabCenterXPositions.length; index++) {
      final distance = (x - _tabCenterXPositions[index]).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }

    if (nearestIndex == _selectedIndex) {
      return;
    }

    setState(() {
      _previousSelectedIndex = _selectedIndex;
      _selectedIndex = nearestIndex;
    });
    widget.onTabSelected?.call(nearestIndex);
    _hasTriggeredSelectionHaptic = false;
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTabTap(details.localPosition),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _AnimatedBottomNavigationPainter(
              bottomInset: widget.bottomInset,
              selectedX: _tabCenterXPositions[_selectedIndex],
              selectedIndex: _selectedIndex,
              previousSelectedIndex: _previousSelectedIndex,
              selectedLabel: _tabLabels[_selectedIndex],
              popProgress: _animation.value,
            ),
            child: child,
          );
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.removeListener(_handleAnimationProgress);
    _animationController.dispose();
    super.dispose();
  }
}

class _AnimatedBottomNavigationPainter extends _BottomNavigationPainter {
  const _AnimatedBottomNavigationPainter({
    required super.bottomInset,
    required this.selectedX,
    required this.selectedIndex,
    required this.previousSelectedIndex,
    required this.selectedLabel,
    required this.popProgress,
  });

  final double selectedX;
  final int selectedIndex;
  final int previousSelectedIndex;
  final String selectedLabel;
  final double popProgress;

  static const _black = Color(0xff050505);
  static const _border = Color(0xffb8b8b8);
  static const _selectionPopOvershoot = 1.35;
  static const _selectionJoinAngle = 0.22;
  static const _selectionJoinWidth = 14.0;
  static const _selectionJoinHandle = 14.0;
  static const _tabCenterXPositions = <double>[118, 302, 483, 668, 851];
  static const _selectionPushDistance = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 973;
    final normalizedProgress = popProgress.clamp(0.0, 1.0).toDouble();

    canvas.save();
    canvas.scale(sx, sx);

    final fill = Paint()..color = Colors.white;
    final border = Paint()
      ..color = _border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final isAttached = normalizedProgress < 0.70;
    final selectionProgressInput = (normalizedProgress / 0.70)
        .clamp(0.0, 1.0)
        .toDouble();
    final easedSelectionProgress = Curves.easeOutBack.transform(
      selectionProgressInput,
    );
    final selectionPopProgress =
        selectionProgressInput +
        (easedSelectionProgress - selectionProgressInput) *
            _selectionPopOvershoot;
    final separationProgress = Curves.easeInOutCubic.transform(
      ((normalizedProgress - 0.70) / 0.30).clamp(0.0, 1.0),
    );
    const selectionBubbleColor = Colors.white;
    const selectionBubbleBorderColor = _border;
    // Keep the circle, nodes, labels, and connection line on the same layout
    // progress so they contract together before the bubble separates.
    final layoutProgress = selectionPopProgress.clamp(0.0, 1.0).toDouble();
    final previousTabCenters = _restingTabCenters(previousSelectedIndex);
    final selectedTabCenters = _restingTabCenters(selectedIndex);
    final tabCenters = <double>[
      for (var index = 0; index < _tabCenterXPositions.length; index++)
        _lerp(
          previousTabCenters[index],
          selectedTabCenters[index],
          layoutProgress,
        ),
    ];
    final selectionCenterX = tabCenters[selectedIndex];
    final notchStart = math.max(0.0, selectionCenterX - 153).toDouble();
    final notchEnd = math.min(973.0, selectionCenterX + 154).toDouble();
    final notchStartPoint = Offset(
      selectionCenterX + 101 * 0.5 * -1.93,
      102 + 101 * 0.29,
    );
    final notchEndPoint = Offset(
      selectionCenterX + 101 * 0.96,
      102 + 101 * 0.29,
    );

    // The tray bulge and every selected element share this progress so the
    // icon stays inside its surrounding circle throughout the animation.
    // Before the pop, the tray and the bulge are a single smooth path.
    final tray = Path()..moveTo(0, 92);
    if (isAttached) {
      final bulgeRadius = 86 * selectionPopProgress;
      final bulgeCenterY = 92 + 10 * selectionPopProgress;
      final bulgeHalfWidth =
          math.sqrt(86 * 86 - 10 * 10) * selectionPopProgress;
      if (bulgeRadius > 0) {
        final arcSweep =
            math.pi - 2 * math.atan2(10, math.sqrt(86 * 86 - 10 * 10));
        final startAngle =
            math.atan2(-10 * selectionPopProgress, -bulgeHalfWidth) +
            _selectionJoinAngle;
        final endAngle = startAngle + arcSweep - 2 * _selectionJoinAngle;
        final circle = Rect.fromCircle(
          center: Offset(selectionCenterX, bulgeCenterY),
          radius: bulgeRadius,
        );
        final arcStart = Offset(
          selectionCenterX + bulgeRadius * math.cos(startAngle),
          bulgeCenterY + bulgeRadius * math.sin(startAngle),
        );
        final arcEnd = Offset(
          selectionCenterX + bulgeRadius * math.cos(endAngle),
          bulgeCenterY + bulgeRadius * math.sin(endAngle),
        );
        final joinWidth = math.min(_selectionJoinWidth, bulgeRadius * 0.18);
        final handle = math.min(_selectionJoinHandle, bulgeRadius * 0.25);
        final leftJoin = selectionCenterX - bulgeHalfWidth - joinWidth;
        final rightJoin = selectionCenterX + bulgeHalfWidth + joinWidth;
        tray
          ..lineTo(leftJoin, 92)
          ..cubicTo(
            leftJoin + joinWidth,
            92,
            arcStart.dx - handle * -math.sin(startAngle),
            arcStart.dy - handle * math.cos(startAngle),
            arcStart.dx,
            arcStart.dy,
          )
          ..arcTo(circle, startAngle, endAngle - startAngle, false)
          ..cubicTo(
            arcEnd.dx + handle * -math.sin(endAngle),
            arcEnd.dy + handle * math.cos(endAngle),
            rightJoin - joinWidth,
            92,
            rightJoin,
            92,
          )
          ..lineTo(939, 92);
      } else {
        tray.lineTo(973, 92);
      }
    } else {
      tray
        ..lineTo(notchStart, 92)
        ..cubicTo(
          notchStart + (notchStartPoint.dx - notchStart) * 0.5,
          92,
          notchStartPoint.dx - 13,
          105,
          notchStartPoint.dx,
          notchEndPoint.dy,
        )
        // A circular cut-out around the selected tab, with tangent joins.
        ..arcTo(
          Rect.fromCircle(center: Offset(selectionCenterX, 102), radius: 101),
          2.85,
          -2.56,
          false,
        )
        ..cubicTo(
          notchEndPoint.dx + 8,
          105,
          notchEnd - (notchEnd - notchEndPoint.dx) * 0.45,
          92,
          notchEnd,
          92,
        )
        ..lineTo(notchEnd, 92);
    }
    tray
      ..lineTo(973, 92)
      ..lineTo(973, 324 + bottomInset)
      ..lineTo(0, 324 + bottomInset)
      ..close();
    canvas.drawPath(tray, fill);
    canvas.drawPath(tray, border);

    // Cover the tray's connection line inside the growing circle, then draw
    // only the visible upper arc while the circle is still attached.
    final selectionBubbleProgress = selectionPopProgress
        .clamp(0.0, double.infinity)
        .toDouble();
    final selectionBubbleCenter = Offset(
      selectionCenterX,
      isAttached ? 92 + 10 * selectionBubbleProgress : 102,
    );
    final selectionBubbleRadius = isAttached
        ? 86 * selectionBubbleProgress
        : 86 + 4 * math.sin(math.pi * separationProgress);
    if (selectionBubbleRadius > 0) {
      _drawSelectionBubble(
        canvas,
        selectionBubbleCenter,
        selectionBubbleRadius,
        attached: isAttached,
        fillColor: selectionBubbleColor,
        borderColor: selectionBubbleBorderColor,
      );
    }

    final line = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(tabCenters.first, 236),
      Offset(tabCenters.last, 236),
      line,
    );

    if (selectedIndex != 0) {
      _drawCalendar(canvas, Offset(tabCenters[0], 169));
    }
    if (selectedIndex != 1) {
      _drawLearn(canvas, Offset(tabCenters[1], 169));
    }
    if (selectedIndex != 3) {
      _drawTask(canvas, Offset(tabCenters[3], 169));
    }
    if (selectedIndex != 4) {
      _drawProfile(canvas, Offset(tabCenters[4], 169));
    }
    if (selectedIndex != 2) {
      _drawHouseMark(canvas, Offset(tabCenters[2], 169), 0.55);
    }

    _drawSelectedIcon(
      canvas,
      selectionPopProgress,
      selectedCenterX: selectionCenterX,
    );

    for (var index = 0; index < 5; index++) {
      _drawNode(
        canvas,
        Offset(tabCenters[index], 236),
        index == selectedIndex ? 15 + 8 * selectionPopProgress : 15,
      );
    }

    const labels = <String>['Calendar', 'Learn', 'Home', 'Task', 'Profile'];
    for (var index = 0; index < labels.length; index++) {
      if (index != selectedIndex) {
        _drawLabel(canvas, labels[index], Offset(tabCenters[index], 270), 26);
      }
    }
    _drawLabel(
      canvas,
      selectedLabel,
      Offset(tabCenters[selectedIndex], 270 - 6 * selectionPopProgress),
      26 + 17 * selectionPopProgress,
    );

    canvas.restore();
  }

  List<double> _restingTabCenters(int selectedIndex) {
    return <double>[
      for (var index = 0; index < _tabCenterXPositions.length; index++)
        index == selectedIndex
            ? _tabCenterXPositions[index]
            : _tabCenterXPositions[index] +
                  (index < selectedIndex
                      ? -_selectionPushDistance
                      : _selectionPushDistance),
    ];
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  void _drawSelectionBubble(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool attached,
    required Color fillColor,
    required Color borderColor,
  }) {
    if (radius <= 0) {
      return;
    }
    final outer = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = attached ? 2.2 : 5;
    canvas.drawCircle(center, radius, outer);
    if (attached) {
      const trayTop = 92.0;
      final verticalDistance = trayTop - center.dy;
      if (verticalDistance.abs() < radius) {
        final horizontalDistance = math.sqrt(
          radius * radius - verticalDistance * verticalDistance,
        );
        final startAngle =
            math.atan2(verticalDistance, -horizontalDistance) +
            _selectionJoinAngle;
        final arcSweep =
            math.pi -
            2 * math.atan2(verticalDistance.abs(), horizontalDistance);
        final endAngle = startAngle + arcSweep - 2 * _selectionJoinAngle;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          endAngle - startAngle,
          false,
          outline,
        );
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          math.pi,
          math.pi,
          false,
          outline,
        );
      }
    } else {
      canvas.drawCircle(center, radius, outline);
    }
  }

  void _drawSelectedIcon(
    Canvas canvas,
    double selectionPopProgress, {
    required double selectedCenterX,
  }) {
    const baseCenters = <Offset>[
      Offset(118, 169),
      Offset(302, 169),
      Offset(483, 169),
      Offset(668, 169),
      Offset(851, 169),
    ];
    final baseCenter = baseCenters[selectedIndex];
    final selectedCenter = Offset(
      selectedCenterX,
      169 - 67 * selectionPopProgress,
    );
    const iconWidthScale = <double>[1.44, 1.17, 1.0, 1.28, 1.28];
    final iconScale =
        iconWidthScale[selectedIndex] *
        (0.58 + 0.40 * selectionPopProgress) *
        (1 + 0.16 * math.sin(math.pi * selectionPopProgress));
    canvas.save();
    canvas.translate(
      selectedCenter.dx - baseCenter.dx,
      selectedCenter.dy - baseCenter.dy,
    );
    canvas.translate(baseCenter.dx, baseCenter.dy);
    canvas.scale(iconScale, iconScale);
    canvas.translate(-baseCenter.dx, -baseCenter.dy);
    switch (selectedIndex) {
      case 0:
        _drawCalendar(canvas, baseCenter);
      case 1:
        _drawLearn(canvas, baseCenter);
      case 2:
        _drawHouseMark(canvas, baseCenter, 0.55 + 0.45 * selectionPopProgress);
      case 3:
        _drawTask(canvas, baseCenter);
      case 4:
        _drawProfile(canvas, baseCenter);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedBottomNavigationPainter oldDelegate) {
    return oldDelegate.bottomInset != bottomInset ||
        oldDelegate.selectedX != selectedX ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.previousSelectedIndex != previousSelectedIndex ||
        oldDelegate.popProgress != popProgress;
  }
}

class _BottomNavigationPainter extends CustomPainter {
  const _BottomNavigationPainter({required this.bottomInset});

  final double bottomInset;

  static const _black = Color(0xff050505);
  static const _border = Color(0xffb8b8b8);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 973;

    canvas.save();
    canvas.scale(sx, sx);

    final fill = Paint()..color = Colors.white;
    final border = Paint()
      ..color = _border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // The navigation tray has a raised, rounded section around Home.
    final tray = Path()
      ..moveTo(0, 119)
      ..cubicTo(0, 104, 15, 92, 34, 92)
      ..lineTo(330, 92)
      ..cubicTo(360, 92, 378, 105, 386, 131)
      // A circular cut-out around Home, with tangent joins on both sides.
      ..arcTo(
        Rect.fromCircle(center: const Offset(483, 102), radius: 101),
        2.85,
        -2.56,
        false,
      )
      ..cubicTo(588, 105, 612, 92, 637, 92)
      ..lineTo(939, 92)
      ..cubicTo(958, 92, 973, 104, 973, 119)
      ..lineTo(973, 324 + bottomInset)
      ..lineTo(0, 324 + bottomInset)
      ..close();
    canvas.drawPath(tray, fill);
    canvas.drawPath(tray, border);

    final line = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(118, 236), const Offset(851, 236), line);

    _drawCalendar(canvas, const Offset(118, 169));
    _drawLearn(canvas, const Offset(302, 169));
    _drawTask(canvas, const Offset(668, 169));
    _drawProfile(canvas, const Offset(851, 169));
    _drawHome(canvas, const Offset(483, 102));

    _drawNode(canvas, const Offset(118, 236), 15);
    _drawNode(canvas, const Offset(302, 236), 15);
    _drawNode(canvas, const Offset(483, 236), 23);
    _drawNode(canvas, const Offset(668, 236), 15);
    _drawNode(canvas, const Offset(851, 236), 15);

    _drawLabel(canvas, 'Calendar', const Offset(118, 270), 26);
    _drawLabel(canvas, 'Learn', const Offset(302, 270), 26);
    _drawLabel(canvas, 'Home', const Offset(483, 264), 43);
    _drawLabel(canvas, 'Task', const Offset(668, 270), 26);
    _drawLabel(canvas, 'Profile', const Offset(851, 270), 26);

    canvas.restore();
  }

  void _drawNode(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, outline);
  }

  void _drawCalendar(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx - 118, center.dy - 169);
    final paint = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(118, 177), width: 57, height: 58),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawLine(const Offset(102, 136), const Offset(102, 145), paint);
    canvas.drawLine(const Offset(135, 136), const Offset(135, 145), paint);
    canvas.drawLine(const Offset(91, 159), const Offset(146, 159), paint);

    final dots = <Offset>[
      const Offset(104, 173),
      const Offset(119, 173),
      const Offset(133, 173),
      const Offset(104, 188),
      const Offset(119, 188),
      const Offset(133, 188),
    ];
    final dotPaint = Paint()..color = _black;
    for (final dot in dots) {
      canvas.drawCircle(dot, 3.2, dotPaint);
    }
    canvas.restore();
  }

  void _drawLearn(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx - 302, center.dy - 169);
    final paint = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.square;
    final left = Path()
      ..moveTo(280, 154)
      ..lineTo(267, 168)
      ..lineTo(280, 182);
    final right = Path()
      ..moveTo(324, 154)
      ..lineTo(337, 168)
      ..lineTo(324, 182);
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
    canvas.drawLine(const Offset(310, 143), const Offset(295, 194), paint);
    canvas.restore();
  }

  void _drawTask(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx - 668, center.dy - 169);
    final outline = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(const Offset(668, 169), 32, outline);
    final check = Path()
      ..moveTo(652, 170)
      ..lineTo(663, 181)
      ..lineTo(685, 157);
    canvas.drawPath(
      check,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter,
    );
    canvas.restore();
  }

  void _drawProfile(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx - 851, center.dy - 169);
    final outline = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(const Offset(851, 169), 32, outline);
    canvas.drawCircle(const Offset(851, 160), 10, outline);
    final shoulders = Path()
      ..moveTo(827, 191)
      ..cubicTo(834, 181, 843, 178, 851, 178)
      ..cubicTo(860, 178, 869, 181, 876, 191);
    canvas.drawPath(shoulders, outline);
    canvas.restore();
  }

  void _drawHouseMark(Canvas canvas, Offset center, double scale) {
    final house = Path()
      ..moveTo(-41, 43)
      ..lineTo(-41, -21)
      ..lineTo(0, -52)
      ..lineTo(41, -21)
      ..lineTo(41, 43)
      ..lineTo(11, 43)
      ..lineTo(11, 5)
      ..lineTo(-11, 5)
      ..lineTo(-11, 43)
      ..close();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.drawPath(
      house,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.miter,
    );
    canvas.restore();
  }

  void _drawHome(Canvas canvas, Offset center) {
    final outer = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = _black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, 86, outer);
    canvas.drawCircle(center, 86, outline);

    final house = Path()
      ..moveTo(442, 145)
      ..lineTo(442, 81)
      ..lineTo(483, 50)
      ..lineTo(524, 81)
      ..lineTo(524, 145)
      ..lineTo(494, 145)
      ..lineTo(494, 107)
      ..lineTo(472, 107)
      ..lineTo(472, 145)
      ..close();
    canvas.drawPath(
      house,
      Paint()
        ..color = _black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  void _drawLabel(Canvas canvas, String label, Offset center, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _black,
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _BottomNavigationPainter oldDelegate) =>
      oldDelegate.bottomInset != bottomInset;
}
