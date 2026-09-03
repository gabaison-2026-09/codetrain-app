import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.repository,
    required this.onSignedIn,
  });

  final AuthRepository repository;
  final ValueChanged<AuthSession> onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _purple = Color(0xff6263d9);
  static const _fieldBorder = Color(0xffd7d7df);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isPasswordVisible = false;
  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _signIn(
      () => widget.repository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    await _signIn(widget.repository.signInWithGoogle);
  }

  Future<void> _signIn(Future<AuthSession> Function() request) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final session = await request();
      if (!mounted) return;
      widget.onSignedIn(session);
    } on AuthFailure {
      if (!mounted) return;
      setState(() => _errorMessage = 'ログインできませんでした');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'ログインできませんでした');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(28, 24, 28, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: SizedBox(
                    width: 380,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CodeTrainMark(color: _purple),
                          const SizedBox(height: 52),
                          TextFormField(
                            key: const ValueKey('login-email-field'),
                            controller: _emailController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: _inputDecoration(
                              label: 'メールアドレス',
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty ||
                                  !email.contains('@') ||
                                  !email.contains('.')) {
                                return 'メールアドレスを確認してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            key: const ValueKey('login-password-field'),
                            controller: _passwordController,
                            enabled: !_isSubmitting,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _handleEmailSignIn(),
                            decoration: _inputDecoration(
                              label: 'パスワード',
                              suffixIcon: IconButton(
                                key: const ValueKey(
                                  'login-password-visibility',
                                ),
                                onPressed: () => setState(
                                  () => _isPasswordVisible =
                                      !_isPasswordVisible,
                                ),
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xff777780),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').length < 6) {
                                return '6文字以上で入力してください';
                              }
                              return null;
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xffb3261e),
                                fontFamily: 'Noto Sans Japanese',
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              key: const ValueKey('login-submit-button'),
                              onPressed:
                                  _isSubmitting ? null : _handleEmailSignIn,
                              style: FilledButton.styleFrom(
                                backgroundColor: _purple,
                                disabledBackgroundColor: const Color(
                                  0xffc7c7dc,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'ログイン',
                                      style: TextStyle(
                                        fontFamily: 'Noto Sans Japanese',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              key: const ValueKey('login-google-button'),
                              onPressed:
                                  _isSubmitting ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xff26262d),
                                side: const BorderSide(color: _fieldBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const _GoogleMark(),
                              label: const Text(
                                'Googleでログイン',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Japanese',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xff707078),
        fontFamily: 'Noto Sans Japanese',
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xfffafafd),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _purple, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffb3261e)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffb3261e), width: 1.6),
      ),
    );
  }
}

class _CodeTrainMark extends StatelessWidget {
  const _CodeTrainMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox.square(
          dimension: 72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(Icons.play_arrow_rounded, color: color, size: 54),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'CodeTrain',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xff222229),
            fontFamily: 'Russo One',
            fontSize: 32,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 24,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xff6263d9),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
