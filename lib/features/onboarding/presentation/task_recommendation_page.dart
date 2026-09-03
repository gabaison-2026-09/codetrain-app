import 'package:flutter/material.dart';

import '../../../shared/widgets/programming_language_icon.dart';
import '../../task/domain/task_configuration.dart';
import '../../task/domain/task_repository.dart';
import '../domain/task_recommendation.dart';

class TaskRecommendationPage extends StatefulWidget {
  const TaskRecommendationPage({
    super.key,
    required this.recommendationRepository,
    required this.taskRepository,
    required this.onCompleted,
  });

  final TaskRecommendationRepository recommendationRepository;
  final TaskRepository taskRepository;
  final VoidCallback onCompleted;

  @override
  State<TaskRecommendationPage> createState() =>
      _TaskRecommendationPageState();
}

class _TaskRecommendationPageState extends State<TaskRecommendationPage> {
  static const _purple = Color(0xff6263d9);
  static const _questionCount = 4;

  var _questionIndex = 0;
  CreationGoal? _goal;
  LearningLanguage? _language;
  LearningPurpose? _purpose;
  var _experience = ProgrammingExperience.none;
  LearningTask? _recommendation;
  var _isLoading = false;
  var _isSaving = false;
  String? _errorMessage;

  bool get _canContinue => switch (_questionIndex) {
    0 => _goal != null,
    1 => _language != null,
    2 => _purpose != null,
    3 => true,
    _ => false,
  };

  Future<void> _handleContinue() async {
    if (!_canContinue || _isLoading) return;
    if (_questionIndex < _questionCount - 1) {
      setState(() => _questionIndex++);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recommendation = await widget.recommendationRepository.recommend(
        TaskRecommendationAnswers(
          goal: _goal!,
          language: _language!,
          purpose: _purpose!,
          experience: _experience,
        ),
      );
      if (!mounted) return;
      setState(() => _recommendation = recommendation);
    } on TaskRecommendationFailure {
      if (!mounted) return;
      setState(() => _errorMessage = 'タスクを提案できませんでした');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'タスクを提案できませんでした');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStart() async {
    final recommendation = _recommendation;
    if (recommendation == null || _isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.taskRepository.saveTask(recommendation);
      if (!mounted) return;
      widget.onCompleted();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'タスクを保存できませんでした');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: recommendation == null
            ? _buildQuestions()
            : _buildRecommendation(recommendation),
      ),
    );
  }

  Widget _buildQuestions() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 24, 8),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: _questionIndex == 0
                    ? null
                    : IconButton(
                        key: const ValueKey('recommendation-back-button'),
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _questionIndex--),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    key: const ValueKey('recommendation-progress'),
                    value: (_questionIndex + 1) / _questionCount,
                    minHeight: 8,
                    color: _purple,
                    backgroundColor: const Color(0xffe8e8ef),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: SingleChildScrollView(
              key: ValueKey('recommendation-question-$_questionIndex'),
              padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildCurrentQuestion(),
                ),
              ),
            ),
          ),
        ),
        _BottomAction(
          errorMessage: _errorMessage,
          isLoading: _isLoading,
          isEnabled: _canContinue,
          label: _questionIndex == _questionCount - 1 ? '提案を見る' : '次へ',
          onPressed: _handleContinue,
        ),
      ],
    );
  }

  Widget _buildCurrentQuestion() {
    return switch (_questionIndex) {
      0 => _Question(
          title: '何を作りたい？',
          children: [
            for (final option in CreationGoal.values)
              _ChoiceTile(
                key: ValueKey('recommendation-goal-${option.apiValue}'),
                label: option.label,
                icon: _goalIcon(option),
                isSelected: _goal == option,
                onTap: () => setState(() => _goal = option),
              ),
          ],
        ),
      1 => _Question(
          title: 'どの言語をやりたい？',
          children: [
            for (final option in LearningLanguage.values)
              _ChoiceTile(
                key: ValueKey('recommendation-language-${option.apiValue}'),
                label: option.label,
                leading: ProgrammingLanguageIcon(
                  language: option.apiValue,
                  size: 30,
                ),
                isSelected: _language == option,
                onTap: () => setState(() => _language = option),
              ),
          ],
        ),
      2 => _Question(
          title: '何のために学ぶ？',
          children: [
            for (final option in LearningPurpose.values)
              _ChoiceTile(
                key: ValueKey('recommendation-purpose-${option.apiValue}'),
                label: option.label,
                icon: _purposeIcon(option),
                isSelected: _purpose == option,
                onTap: () => setState(() => _purpose = option),
              ),
          ],
        ),
      _ => _ExperienceQuestion(
          experience: _experience,
          onChanged: (experience) =>
              setState(() => _experience = experience),
        ),
    };
  }

  Widget _buildRecommendation(LearningTask task) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 44, 28, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: _purple,
                      size: 44,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'このタスクから始めよう',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xff222229),
                        fontFamily: 'Noto Sans Japanese',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xfffafafd),
                        border: Border.all(color: const Color(0xffdedee6)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            task.name,
                            style: const TextStyle(
                              color: Color(0xff222229),
                              fontFamily: 'Noto Sans Japanese',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final slot in task.slots) ...[
                            _RecommendationSlot(slot: slot),
                            if (slot.slotNo != task.slots.last.slotNo)
                              const Divider(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _BottomAction(
          errorMessage: _errorMessage,
          isLoading: _isSaving,
          isEnabled: true,
          label: 'はじめる',
          buttonKey: const ValueKey('recommendation-start-button'),
          onPressed: _handleStart,
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff222229),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        for (final child in children) ...[
          child,
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.leading,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Material(
        color: isSelected ? const Color(0xfff1f1ff) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? const Color(0xff6263d9)
                : const Color(0xffd9d9e1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                leading ??
                    Icon(
                      icon,
                      size: 26,
                      color: isSelected
                          ? const Color(0xff6263d9)
                          : const Color(0xff666670),
                    ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xff2a2a31),
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xff6263d9),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceQuestion extends StatelessWidget {
  const _ExperienceQuestion({
    required this.experience,
    required this.onChanged,
  });

  final ProgrammingExperience experience;
  final ValueChanged<ProgrammingExperience> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = ProgrammingExperience.values.indexOf(experience).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'プログラミング歴は？',
          style: TextStyle(
            color: Color(0xff222229),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 64),
        Text(
          experience.label,
          key: const ValueKey('recommendation-experience-label'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff6263d9),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 32),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xff6263d9),
            inactiveTrackColor: const Color(0xffe4e4eb),
            thumbColor: const Color(0xff6263d9),
            overlayColor: const Color(0x1f6263d9),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          ),
          child: Slider(
            key: const ValueKey('recommendation-experience-slider'),
            value: value,
            min: 0,
            max: (ProgrammingExperience.values.length - 1).toDouble(),
            divisions: ProgrammingExperience.values.length - 1,
            onChanged: (value) => onChanged(
              ProgrammingExperience.values[value.round()],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('未経験', style: _scaleLabelStyle),
              Text('3年以上', style: _scaleLabelStyle),
            ],
          ),
        ),
      ],
    );
  }

  static const _scaleLabelStyle = TextStyle(
    color: Color(0xff777780),
    fontFamily: 'Noto Sans Japanese',
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class _RecommendationSlot extends StatelessWidget {
  const _RecommendationSlot({required this.slot});

  final TaskSlot slot;

  @override
  Widget build(BuildContext context) {
    final level = slot.minimumDifficulty == slot.maximumDifficulty
        ? 'Lv.${slot.minimumDifficulty}'
        : 'Lv.${slot.minimumDifficulty}〜${slot.maximumDifficulty}';
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xffededff),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${slot.slotNo}',
            style: const TextStyle(
              color: Color(0xff6263d9),
              fontFamily: 'Russo One',
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${slot.questionType!.label}  $level',
            style: const TextStyle(
              color: Color(0xff4f4f58),
              fontFamily: 'Noto Sans Japanese',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.errorMessage,
    required this.isLoading,
    required this.isEnabled,
    required this.label,
    required this.onPressed,
    this.buttonKey = const ValueKey('recommendation-continue-button'),
  });

  final String? errorMessage;
  final bool isLoading;
  final bool isEnabled;
  final String label;
  final VoidCallback onPressed;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffe5e5eb))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xffb3261e),
                        fontFamily: 'Noto Sans Japanese',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      key: buttonKey,
                      onPressed: isEnabled && !isLoading ? onPressed : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff6263d9),
                        disabledBackgroundColor: const Color(0xffc7c7dc),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'Noto Sans Japanese',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _goalIcon(CreationGoal goal) => switch (goal) {
  CreationGoal.webService => Icons.language_rounded,
  CreationGoal.mobileApp => Icons.phone_iphone_rounded,
  CreationGoal.game => Icons.sports_esports_rounded,
  CreationGoal.automation => Icons.settings_suggest_rounded,
  CreationGoal.dataAnalysis => Icons.query_stats_rounded,
};

IconData _purposeIcon(LearningPurpose purpose) => switch (purpose) {
  LearningPurpose.firstDevelopment => Icons.flag_outlined,
  LearningPurpose.work => Icons.work_outline_rounded,
  LearningPurpose.career => Icons.trending_up_rounded,
  LearningPurpose.personalProject => Icons.rocket_launch_outlined,
  LearningPurpose.review => Icons.refresh_rounded,
};
