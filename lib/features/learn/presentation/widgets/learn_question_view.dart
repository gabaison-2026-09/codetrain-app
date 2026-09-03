import 'package:flutter/material.dart';

import '../../domain/learn_content.dart';

class LearnQuestionView extends StatelessWidget {
  const LearnQuestionView({
    super.key,
    required this.question,
    required this.currentQuestionNumber,
    required this.feedbackInterval,
    required this.selectedKey,
    required this.attemptResult,
    required this.isSubmitting,
    required this.errorMessage,
    required this.contentPadding,
    required this.onChoiceSelected,
    required this.onSubmit,
    required this.onNext,
  });

  final LearnQuestion question;
  final int currentQuestionNumber;
  final int feedbackInterval;
  final String? selectedKey;
  final LearnAttemptResult? attemptResult;
  final bool isSubmitting;
  final String? errorMessage;
  final EdgeInsets contentPadding;
  final ValueChanged<String> onChoiceSelected;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionProgressHeader(
                  currentQuestionNumber: currentQuestionNumber,
                  feedbackInterval: feedbackInterval,
                ),
                const SizedBox(height: 28),
                _QuestionHeading(question: question),
                const SizedBox(height: 20),
                _CodePanel(question: question),
                const SizedBox(height: 24),
                const Text(
                  'ANSWER',
                  style: TextStyle(
                    color: Color(0xff8a8a94),
                    fontFamily: 'Russo One',
                    fontSize: 11,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 11),
                for (
                  var index = 0;
                  index < question.choices.length;
                  index++
                ) ...[
                  _ChoiceButton(
                    choice: question.choices[index],
                    index: index,
                    isSelected: selectedKey == question.choices[index].key,
                    attemptResult: attemptResult,
                    onTap: () => onChoiceSelected(question.choices[index].key),
                  ),
                  if (index < question.choices.length - 1)
                    const SizedBox(height: 10),
                ],
                if (attemptResult != null) ...[
                  const SizedBox(height: 18),
                  _AnswerResultPanel(result: attemptResult!),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xffc34949),
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    key: const ValueKey('learn-answer-button'),
                    onPressed: attemptResult != null
                        ? onNext
                        : selectedKey == null || isSubmitting
                        ? null
                        : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff6263d9),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xffc7c7dc),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                attemptResult == null
                                    ? '回答する'
                                    : currentQuestionNumber == feedbackInterval
                                    ? 'フィードバックを見る'
                                    : '次の問題へ',
                                style: const TextStyle(
                                  fontFamily: 'Noto Sans Japanese',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                attemptResult == null
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
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

class _QuestionProgressHeader extends StatelessWidget {
  const _QuestionProgressHeader({
    required this.currentQuestionNumber,
    required this.feedbackInterval,
  });

  final int currentQuestionNumber;
  final int feedbackInterval;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: currentQuestionNumber / feedbackInterval,
              minHeight: 8,
              color: const Color(0xff6263d9),
              backgroundColor: const Color(0xffe5e5ea),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '$currentQuestionNumber / $feedbackInterval',
          style: const TextStyle(
            color: Color(0xff4b4b54),
            fontFamily: 'Russo One',
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _QuestionHeading extends StatelessWidget {
  const _QuestionHeading({required this.question});

  final LearnQuestion question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.title,
          style: const TextStyle(
            color: Color(0xff111116),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 25,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          question.body,
          style: const TextStyle(
            color: Color(0xff5f5f68),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.question});

  final LearnQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff17171d),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            color: const Color(0xff222229),
            child: Row(
              children: [
                const _CodeDot(color: Color(0xff777781)),
                const SizedBox(width: 6),
                const _CodeDot(color: Color(0xff777781)),
                const SizedBox(width: 6),
                const _CodeDot(color: Color(0xff777781)),
                const Spacer(),
                Text(
                  question.codeLanguage,
                  style: const TextStyle(
                    color: Color(0xffa8a8b2),
                    fontFamily: 'Russo One',
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              question.code,
              style: const TextStyle(
                color: Color(0xfff1f1f3),
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeDot extends StatelessWidget {
  const _CodeDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 9),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.index,
    required this.isSelected,
    required this.attemptResult,
    required this.onTap,
  });

  final LearnChoice choice;
  final int index;
  final bool isSelected;
  final LearnAttemptResult? attemptResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = attemptResult?.correctKeys.contains(choice.key) ?? false;
    final isIncorrectSelection =
        attemptResult != null && isSelected && !isCorrect;
    final accent = isCorrect
        ? const Color(0xff278b5b)
        : isIncorrectSelection
        ? const Color(0xffd05252)
        : isSelected
        ? const Color(0xff6263d9)
        : const Color(0xffcfcfd7);
    final fill = isCorrect
        ? const Color(0xffedf8f2)
        : isIncorrectSelection
        ? const Color(0xfffff0f0)
        : isSelected
        ? const Color(0xfff1f1ff)
        : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        key: ValueKey('learn-choice-${choice.key}'),
        borderRadius: BorderRadius.circular(17),
        onTap: attemptResult == null ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: accent,
              width: isSelected || isCorrect ? 2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected || isCorrect ? accent : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.4),
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: isSelected || isCorrect ? Colors.white : accent,
                    fontFamily: 'Russo One',
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  choice.text,
                  style: TextStyle(
                    color: isCorrect || isIncorrectSelection
                        ? accent
                        : const Color(0xff292930),
                    fontFamily: 'Noto Sans Japanese',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
              if (isCorrect || isIncorrectSelection) ...[
                const SizedBox(width: 8),
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: accent,
                  size: 23,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerResultPanel extends StatelessWidget {
  const _AnswerResultPanel({required this.result});

  final LearnAttemptResult result;

  @override
  Widget build(BuildContext context) {
    final accent = result.isCorrect
        ? const Color(0xff278b5b)
        : const Color(0xffd05252);
    return Container(
      key: const ValueKey('learn-answer-result'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isCorrect
                    ? Icons.celebration_rounded
                    : Icons.lightbulb_outline_rounded,
                color: accent,
                size: 24,
              ),
              const SizedBox(width: 9),
              Text(
                result.isCorrect ? '正解！' : 'おしい！',
                style: TextStyle(
                  color: accent,
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (result.xpGained > 0)
                Text(
                  '+${result.xpGained} XP',
                  style: TextStyle(
                    color: accent,
                    fontFamily: 'Russo One',
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.explanation,
            style: const TextStyle(
              color: Color(0xff505059),
              fontFamily: 'Noto Sans Japanese',
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
