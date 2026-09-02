import 'package:flutter/material.dart';

class LearnFeedbackView extends StatelessWidget {
  const LearnFeedbackView({
    super.key,
    required this.correctAnswerCount,
    required this.questionCount,
    required this.gainedXp,
    required this.contentPadding,
    required this.onContinue,
  });

  final int correctAnswerCount;
  final int questionCount;
  final int gainedXp;
  final EdgeInsets contentPadding;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: contentPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              key: const ValueKey('learn-feedback'),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xff6263d9),
                  size: 42,
                ),
                const SizedBox(height: 18),
                const Text(
                  '5問のフィードバック',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff111116),
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FeedbackValue(
                      label: '正解数',
                      value: '$correctAnswerCount / $questionCount',
                    ),
                    const SizedBox(width: 48),
                    _FeedbackValue(label: '獲得XP', value: '+$gainedXp XP'),
                  ],
                ),
                const SizedBox(height: 34),
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    key: const ValueKey('learn-feedback-continue'),
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff111116),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '学習を続ける',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Japanese',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 9),
                        Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackValue extends StatelessWidget {
  const _FeedbackValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xff6263d9),
            fontFamily: 'Russo One',
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff777781),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
