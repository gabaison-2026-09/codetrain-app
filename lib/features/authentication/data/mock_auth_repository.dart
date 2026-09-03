import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthFailure();
    }
    return const AuthSession(
      userId: 'mock-email-user',
      idToken: 'mock-firebase-id-token',
    );
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    return const AuthSession(
      userId: 'mock-google-user',
      idToken: 'mock-firebase-id-token',
    );
  }

  @override
  Future<AuthSession> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthFailure();
    }
    return const AuthSession(
      userId: 'mock-created-user',
      idToken: 'mock-firebase-id-token',
    );
  }
}
