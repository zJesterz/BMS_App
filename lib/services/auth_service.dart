/// Result of an authentication attempt.
enum AuthResult {
  success,
  invalidCredentials,
}

/// Abstract contract for user authentication.
///
/// Replace [MockAuthService] with a REST or token-based implementation
/// when connecting to a real backend.
abstract class AuthService {
  /// Validates credentials and returns the outcome.
  Future<AuthResult> login(String username, String password);

  /// Clears the current session (no-op for mock; useful for real backends).
  Future<void> logout();
}

/// Mock authentication using fixed admin credentials.
class MockAuthService implements AuthService {
  MockAuthService();

  static const String _mockUsername = 'admin';
  static const String _mockPassword = 'admin';

  @override
  Future<AuthResult> login(String username, String password) async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (username == _mockUsername && password == _mockPassword) {
      return AuthResult.success;
    }
    return AuthResult.invalidCredentials;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
