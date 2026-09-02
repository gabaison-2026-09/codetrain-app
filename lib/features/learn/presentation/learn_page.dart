import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/learn_content.dart';
import '../domain/learn_repository.dart';
import 'widgets/learn_feedback_view.dart';
import 'widgets/learn_question_view.dart';
import 'widgets/learn_selection_view.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({
    super.key,
    required this.repository,
    this.initialCatalog,
    this.onQuestionViewChanged,
  });

  final LearnRepository repository;
  final LearnCatalog? initialCatalog;
  final ValueChanged<bool>? onQuestionViewChanged;

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  static const _feedbackInterval = 5;

  late final Future<LearnCatalog> _catalogFuture;
  String? _selectedNodeId;
  List<LearnQuestion>? _questions;
  var _questionIndex = 0;
  String? _selectedKey;
  LearnAttemptResult? _attemptResult;
  var _answeredQuestionCount = 0;
  var _correctAnswerCount = 0;
  var _gainedXp = 0;
  var _isShowingFeedback = false;
  DateTime? _questionStartedAt;
  var _isLoadingQuestions = false;
  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _catalogFuture = widget.repository.fetchCatalog();
    _selectedNodeId =
        widget.initialCatalog?.skills.firstOrNull?.nodes.firstOrNull?.id;
  }

  Future<void> _handleStart() async {
    final selectedNodeId = _selectedNodeId;
    if (selectedNodeId == null || _isLoadingQuestions) return;

    setState(() {
      _isLoadingQuestions = true;
      _errorMessage = null;
    });
    try {
      final questions = await widget.repository.fetchQuestionsForSkillNode(
        selectedNodeId,
      );
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() {
          _errorMessage = 'この学習内容には、現在挑戦できる問題がありません。';
          _isLoadingQuestions = false;
        });
        return;
      }
      HapticFeedback.selectionClick();
      setState(() {
        _questions = questions;
        _questionIndex = 0;
        _selectedKey = null;
        _attemptResult = null;
        _answeredQuestionCount = 0;
        _correctAnswerCount = 0;
        _gainedXp = 0;
        _isShowingFeedback = false;
        _questionStartedAt = DateTime.now();
        _isLoadingQuestions = false;
      });
      widget.onQuestionViewChanged?.call(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '問題を読み込めませんでした。もう一度お試しください。';
        _isLoadingQuestions = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final questions = _questions;
    final selectedKey = _selectedKey;
    if (questions == null ||
        selectedKey == null ||
        _isSubmitting ||
        _attemptResult != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final startedAt = _questionStartedAt ?? DateTime.now();
    try {
      final result = await widget.repository.submitAttempt(
        questionId: questions[_questionIndex].id,
        selectedKeys: [selectedKey],
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
      if (!mounted) return;
      if (result.isCorrect) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      setState(() {
        _attemptResult = result;
        _answeredQuestionCount += 1;
        if (result.isCorrect) {
          _correctAnswerCount += 1;
        }
        _gainedXp += result.xpGained;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '回答を送信できませんでした。もう一度お試しください。';
        _isSubmitting = false;
      });
    }
  }

  void _handleNext() {
    final questions = _questions;
    if (questions == null) return;
    if (_answeredQuestionCount == _feedbackInterval) {
      HapticFeedback.selectionClick();
      setState(() => _isShowingFeedback = true);
      widget.onQuestionViewChanged?.call(false);
      return;
    }

    setState(() {
      _questionIndex = (_questionIndex + 1) % questions.length;
      _selectedKey = null;
      _attemptResult = null;
      _questionStartedAt = DateTime.now();
    });
  }

  void _handleContinueAfterFeedback() {
    final questions = _questions;
    if (questions == null) return;
    setState(() {
      _questionIndex = (_questionIndex + 1) % questions.length;
      _selectedKey = null;
      _attemptResult = null;
      _answeredQuestionCount = 0;
      _correctAnswerCount = 0;
      _gainedXp = 0;
      _isShowingFeedback = false;
      _questionStartedAt = DateTime.now();
      _errorMessage = null;
    });
    widget.onQuestionViewChanged?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaPadding = MediaQuery.paddingOf(context);
        final bottomNavigationScale = (constraints.maxWidth / 973).clamp(
          0.32,
          1.0,
        );
        final showsQuestion = _questions != null && !_isShowingFeedback;
        final contentPadding = EdgeInsets.fromLTRB(
          20,
          64 + mediaPadding.top + 22,
          20,
          showsQuestion
              ? mediaPadding.bottom + 18
              : 325 * bottomNavigationScale + mediaPadding.bottom + 18,
        );
        final questions = _questions;
        if (questions != null) {
          if (_isShowingFeedback) {
            return LearnFeedbackView(
              correctAnswerCount: _correctAnswerCount,
              questionCount: _feedbackInterval,
              gainedXp: _gainedXp,
              contentPadding: contentPadding,
              onContinue: _handleContinueAfterFeedback,
            );
          }
          return LearnQuestionView(
            key: ValueKey(questions[_questionIndex].id),
            question: questions[_questionIndex],
            currentQuestionNumber:
                _answeredQuestionCount + (_attemptResult == null ? 1 : 0),
            feedbackInterval: _feedbackInterval,
            selectedKey: _selectedKey,
            attemptResult: _attemptResult,
            isSubmitting: _isSubmitting,
            errorMessage: _errorMessage,
            contentPadding: contentPadding,
            onChoiceSelected: (key) {
              setState(() {
                _selectedKey = key;
                _errorMessage = null;
              });
            },
            onSubmit: _handleSubmit,
            onNext: _handleNext,
          );
        }

        return FutureBuilder<LearnCatalog>(
          future: _catalogFuture,
          initialData: widget.initialCatalog,
          builder: (context, snapshot) {
            final catalog = snapshot.data;
            if (catalog == null) {
              if (snapshot.hasError) {
                return _LearnMessageView(
                  contentPadding: contentPadding,
                  icon: Icons.cloud_off_outlined,
                  message: '学習内容を読み込めませんでした。',
                );
              }
              return _LearnLoadingView(contentPadding: contentPadding);
            }
            _selectedNodeId ??=
                catalog.skills.firstOrNull?.nodes.firstOrNull?.id;
            return LearnSelectionView(
              catalog: catalog,
              selectedNodeId: _selectedNodeId,
              isLoading: _isLoadingQuestions,
              errorMessage: _errorMessage,
              contentPadding: contentPadding,
              onNodeSelected: (nodeId) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedNodeId = nodeId;
                  _errorMessage = null;
                });
              },
              onStart: _handleStart,
            );
          },
        );
      },
    );
  }
}

class _LearnLoadingView extends StatelessWidget {
  const _LearnLoadingView({required this.contentPadding});

  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: contentPadding,
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xff6263d9)),
      ),
    );
  }
}

class _LearnMessageView extends StatelessWidget {
  const _LearnMessageView({
    required this.contentPadding,
    required this.icon,
    required this.message,
  });

  final EdgeInsets contentPadding;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: contentPadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xff8d8d98)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Noto Sans Japanese',
                fontSize: 15,
                color: Color(0xff60606a),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
