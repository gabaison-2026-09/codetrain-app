import 'dart:math';

import 'package:flutter/foundation.dart';
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
    this.startLearningRequest,
    this.onStartLearningRequestConsumed,
    this.onQuestionViewChanged,
    this.onTaskCompleted,
  });

  final LearnRepository repository;
  final LearnCatalog? initialCatalog;
  final ValueListenable<LearnTaskStartRequest?>? startLearningRequest;
  final VoidCallback? onStartLearningRequestConsumed;
  final ValueChanged<bool>? onQuestionViewChanged;
  final VoidCallback? onTaskCompleted;

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  static const _feedbackMessages = <String>[
    'おつかれさま！',
    'いい感じです',
    'ナイスチャレンジ！',
    'この調子でいこう！',
    'しっかり身についています',
  ];
  static const _feedbackInterval = 5;

  final _random = Random();
  late final Future<LearnCatalog> _catalogFuture;
  String? _selectedNodeId;
  List<LearnQuestion>? _questions;
  var _questionIndex = 0;
  String? _selectedKey;
  LearnAttemptResult? _attemptResult;
  var _questionReviews = <LearnQuestionReview>[];
  var _answeredQuestionCount = 0;
  var _correctAnswerCount = 0;
  var _feedbackMessage = _feedbackMessages.first;
  var _isShowingFeedback = false;
  DateTime? _questionStartedAt;
  var _isLoadingQuestions = false;
  var _isSubmitting = false;
  var _isTaskBasedSession = false;
  var _hasReportedTaskCompletion = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _catalogFuture = widget.repository.fetchCatalog();
    _selectedNodeId =
        widget.initialCatalog?.skills.firstOrNull?.nodes.firstOrNull?.id;
    final startLearningRequest = widget.startLearningRequest;
    if (startLearningRequest != null) {
      startLearningRequest.addListener(_handleStartLearningRequest);
      if (startLearningRequest.value != null) {
        _startLearningAfterCatalogReady(startLearningRequest.value!);
      }
    }
  }

  @override
  void dispose() {
    widget.startLearningRequest?.removeListener(_handleStartLearningRequest);
    super.dispose();
  }

  void _handleStartLearningRequest() {
    if (!mounted) return;
    final startLearningRequest = widget.startLearningRequest?.value;
    if (startLearningRequest == null) {
      return;
    }
    _startLearningAfterCatalogReady(startLearningRequest);
  }

  Future<void> _startLearningAfterCatalogReady(
    LearnTaskStartRequest request,
  ) async {
    widget.onStartLearningRequestConsumed?.call();
    try {
      final catalog = await _catalogFuture;
      if (!mounted) return;
      _selectedNodeId ??= catalog.skills.firstOrNull?.nodes.firstOrNull?.id;
      await _handleStart(request: request);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '学習内容を読み込めませんでした。もう一度お試しください。';
      });
    }
  }

  Future<void> _handleStart({LearnTaskStartRequest? request}) async {
    final selectedNodeId = _selectedNodeId;
    if (selectedNodeId == null || _isLoadingQuestions) return;

    setState(() {
      _isLoadingQuestions = true;
      _errorMessage = null;
    });
    try {
      final questions = request?.isTaskBased == true
          ? await widget.repository.fetchQuestionsForTask(
              filters: request!.filters,
            )
          : await widget.repository.fetchQuestionsForSkillNode(selectedNodeId);
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
        _questionReviews = [];
        _answeredQuestionCount = 0;
        _correctAnswerCount = 0;
        _feedbackMessage = _feedbackMessages.first;
        _isShowingFeedback = false;
        _questionStartedAt = DateTime.now();
        _isLoadingQuestions = false;
        _isTaskBasedSession = request?.isTaskBased == true;
        _hasReportedTaskCompletion = false;
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
        final updatedReviews = [
          ..._questionReviews,
          LearnQuestionReview(
            question: questions[_questionIndex],
            selectedKey: selectedKey,
            result: result,
          ),
        ];
        _questionReviews = updatedReviews.length > _feedbackInterval
            ? updatedReviews.sublist(
                updatedReviews.length - _feedbackInterval,
              )
            : updatedReviews;
        _answeredQuestionCount += 1;
        if (result.isCorrect) {
          _correctAnswerCount += 1;
        }
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
      if (_isTaskBasedSession && !_hasReportedTaskCompletion) {
        _hasReportedTaskCompletion = true;
        widget.onTaskCompleted?.call();
      }
      HapticFeedback.selectionClick();
      setState(() {
        _feedbackMessage =
            _feedbackMessages[_random.nextInt(_feedbackMessages.length)];
        _isShowingFeedback = true;
      });
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

  Future<void> _handleExitLearning() async {
    if (_isSubmitting) return;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xffe1e1e7)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: const Text('学習をやめますか？'),
        titleTextStyle: const TextStyle(
          color: Color(0xff111116),
          fontFamily: 'Noto Sans Japanese',
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        content: const Text(
          '今回の学習状況は破棄されます。',
          style: TextStyle(
            color: Color(0xff60606a),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    key: const ValueKey('learn-exit-confirm'),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff6263d9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'やめる',
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
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    key: const ValueKey('learn-exit-cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff111116),
                      side: const BorderSide(color: Color(0xffcfcfd7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '続ける',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Japanese',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (!mounted || shouldExit != true) return;
    _handleBackToList();
  }

  void _handleContinueAfterFeedback() {
    final questions = _questions;
    if (questions == null) return;
    setState(() {
      _questionIndex = (_questionIndex + 1) % questions.length;
      _selectedKey = null;
      _attemptResult = null;
      _questionReviews = [];
      _answeredQuestionCount = 0;
      _correctAnswerCount = 0;
      _isShowingFeedback = false;
      _questionStartedAt = DateTime.now();
      _errorMessage = null;
      _isTaskBasedSession = false;
      _hasReportedTaskCompletion = false;
    });
    widget.onQuestionViewChanged?.call(true);
  }

  void _handleBackToList() {
    setState(() {
      _questions = null;
      _questionIndex = 0;
      _selectedKey = null;
      _attemptResult = null;
      _questionReviews = [];
      _answeredQuestionCount = 0;
      _correctAnswerCount = 0;
      _isShowingFeedback = false;
      _questionStartedAt = null;
      _errorMessage = null;
    });
    widget.onQuestionViewChanged?.call(false);
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
          22,
          64 + mediaPadding.top + 24,
          22,
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
              message: _feedbackMessage,
              reviews: _questionReviews,
              contentPadding: contentPadding,
              onBackToList: _handleBackToList,
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
            onExit: _handleExitLearning,
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
