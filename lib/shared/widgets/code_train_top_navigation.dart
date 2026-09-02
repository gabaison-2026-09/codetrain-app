import 'package:flutter/material.dart';

class CodeTrainTopNavigation extends StatelessWidget {
  const CodeTrainTopNavigation({
    super.key,
    required this.level,
    required this.progress,
    required this.filledHeartCount,
    required this.heartCount,
  });

  final int level;
  final double progress;
  final int filledHeartCount;
  final int heartCount;

  static const _borderColor = Color(0xffbdbdbd);
  static const _progressTrackColor = Color(0xffdddddd);
  static const _progressColor = Color(0xff91c783);
  static const _filledHeartColor = Color(0xfff2b2b2);
  static const _emptyHeartColor = Color(0xffd9d9d9);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final clampedFilledHeartCount = filledHeartCount.clamp(0, heartCount);
    final firstFilledHeartIndex = heartCount - clampedFilledHeartCount;

    return Container(
      height: 64 + topInset,
      padding: EdgeInsets.fromLTRB(10, topInset, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          const _ProfileAvatar(),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.$level',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 9,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: _progressTrackColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const SizedBox.expand(),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: _progressColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: SizedBox(
                              width: constraints.maxWidth * clampedProgress,
                              height: 9,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < heartCount; index++) ...[
                      if (index > 0) const SizedBox(width: 4),
                      Icon(
                        Icons.favorite,
                        size: 28,
                        color: index >= firstFilledHeartIndex
                            ? _filledHeartColor
                            : _emptyHeartColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(painter: _ProfileAvatarPainter()),
    );
  }
}

class _ProfileAvatarPainter extends CustomPainter {
  const _ProfileAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, 20.5, outline);
    canvas.drawCircle(Offset(center.dx, center.dy - 6.5), 6.5, outline);

    final shoulders = Path()
      ..moveTo(center.dx - 13.5, center.dy + 13.5)
      ..cubicTo(
        center.dx - 10.5,
        center.dy + 5.5,
        center.dx - 5.5,
        center.dy + 3.5,
        center.dx,
        center.dy + 3.5,
      )
      ..cubicTo(
        center.dx + 5.5,
        center.dy + 3.5,
        center.dx + 10.5,
        center.dy + 5.5,
        center.dx + 13.5,
        center.dy + 13.5,
      );
    canvas.drawPath(shoulders, outline);
  }

  @override
  bool shouldRepaint(covariant _ProfileAvatarPainter oldDelegate) => false;
}
