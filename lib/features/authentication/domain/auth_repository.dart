class AuthSession {
  const AuthSession({required this.userId, required this.idToken});

  final String userId;
  final String idToken;
}

abstract interface class AuthRepository {
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithGoogle();
}

class AuthFailure implements Exception {
  const AuthFailure();
}
