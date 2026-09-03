import 'package:flutter/material.dart';

import '../../domain/learn_content.dart';

class LearnFeedbackView extends StatelessWidget {
  const LearnFeedbackView({
    super.key,
    required this.correctAnswerCount,
    required this.questionCount,
    required this.message,
    required this.reviews,
    required this.contentPadding,
    required this.onBackToList,
    required this.onContinue,
  });

  final int correctAnswerCount;
  final int questionCount;
  final String message;
  final List<LearnQuestionReview> reviews;
  final EdgeInsets contentPadding;
  final VoidCallback onBackToList;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
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
                Text(
                  key: const ValueKey('learn-feedback-message'),
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff111116),
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 26),
                _FeedbackValue(
                  label: '正解数',
                  value: '$correctAnswerCount / $questionCount',
                ),
                const SizedBox(height: 34),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          key: const ValueKey('learn-feedback-list'),
                          onPressed: onBackToList,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff111116),
                            side: const BorderSide(
                              color: Color(0xffcfcfd7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '一覧へ',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Japanese',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 54,
                        child: FilledButton(
                          key: const ValueKey('learn-feedback-continue'),
                          onPressed: onContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff6263d9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '学習を続ける',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Japanese',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const Text(
                  '今回の回答',
                  style: TextStyle(
                    color: Color(0xff111116),
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < reviews.length; index++) ...[
                  _QuestionReviewCard(
                    review: reviews[index],
                    questionNumber: index + 1,
                  ),
                  if (index < reviews.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.review,
    required this.questionNumber,
  });

  final LearnQuestionReview review;
  final int questionNumber;

  @override
  Widget build(BuildContext context) {
    final accent = review.result.isCorrect
        ? const Color(0xff278b5b)
        : const Color(0xffd05252);
    final selectedAnswer = review.question.choices
        .where((choice) => choice.key == review.selectedKey)
        .map((choice) => choice.text)
        .firstOrNull;
    final correctAnswers = review.question.choices
        .where((choice) => review.result.correctKeys.contains(choice.key))
        .map((choice) => choice.text)
        .join(' / ');

    return Container(
      key: ValueKey('learn-review-${review.question.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe1e1e7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Q$questionNumber',
                style: const TextStyle(
                  color: Color(0xff6263d9),
                  fontFamily: 'Russo One',
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Icon(
                review.result.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                review.result.isCorrect ? '正解' : '不正解',
                style: TextStyle(
                  color: accent,
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            review.question.title,
            style: const TextStyle(
              color: Color(0xff292930),
              fontFamily: 'Noto Sans Japanese',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 11),
          _ReviewAnswerRow(
            label: 'あなたの回答',
            value: selectedAnswer ?? review.selectedKey,
          ),
          const SizedBox(height: 5),
          _ReviewAnswerRow(label: '正解', value: correctAnswers),
          const SizedBox(height: 10),
          Text(
            review.result.explanation,
            style: const TextStyle(
              color: Color(0xff60606a),
              fontFamily: 'Noto Sans Japanese',
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewAnswerRow extends StatelessWidget {
  const _ReviewAnswerRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xff8a8a94),
              fontFamily: 'Noto Sans Japanese',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xff3f3f48),
              fontFamily: 'Noto Sans Japanese',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
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
