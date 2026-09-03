import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({
    super.key,
    required this.repository,
    required this.onCreated,
  });

  final AuthRepository repository;
  final ValueChanged<AuthSession> onCreated;

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  static const _purple = Color(0xff6263d9);
  static const _fieldBorder = Color(0xffd7d7df);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  var _isPasswordVisible = false;
  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final session = await widget.repository.createAccountWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      widget.onCreated(session);
    } on AuthFailure {
      if (!mounted) return;
      setState(() => _errorMessage = 'アカウントを作成できませんでした');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'アカウントを作成できませんでした');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff222229),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'アカウント作成',
          style: TextStyle(
            fontFamily: 'Noto Sans Japanese',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 44
                      ? constraints.maxHeight - 44
                      : 0,
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
                          const Text(
                            'CodeTrainをはじめよう',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xff222229),
                              fontFamily: 'Russo One',
                              fontSize: 26,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'メールアドレスとパスワードを入力してください',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xff707078),
                              fontFamily: 'Noto Sans Japanese',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 36),
                          TextFormField(
                            key: const ValueKey('create-account-email-field'),
                            controller: _emailController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newUsername],
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
                            key: const ValueKey(
                              'create-account-password-field',
                            ),
                            controller: _passwordController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: !_isPasswordVisible,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'パスワード',
                              suffixIcon: IconButton(
                                key: const ValueKey(
                                  'create-account-password-visibility',
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
                          const SizedBox(height: 18),
                          TextFormField(
                            key: const ValueKey(
                              'create-account-password-confirmation-field',
                            ),
                            controller: _passwordConfirmationController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: !_isPasswordVisible,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleCreateAccount(),
                            decoration: _inputDecoration(
                              label: 'パスワード（確認）',
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'パスワードが一致しません';
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
                              key: const ValueKey(
                                'create-account-submit-button',
                              ),
                              onPressed:
                                  _isSubmitting ? null : _handleCreateAccount,
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
                                      'アカウントを作成',
                                      style: TextStyle(
                                        fontFamily: 'Noto Sans Japanese',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            key: const ValueKey(
                              'create-account-back-to-login-button',
                            ),
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              foregroundColor: _purple,
                            ),
                            child: const Text(
                              'ログイン画面に戻る',
                              style: TextStyle(
                                fontFamily: 'Noto Sans Japanese',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
