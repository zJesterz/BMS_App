import 'package:firebase_auth/firebase_auth.dart';

enum AuthResult {
  success,
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
}

abstract class AuthService {
  Future<AuthResult> login(String username, String password);
  Future<AuthResult> register(String username, String password);
  Future<void> logout();
  String? get currentUserEmail;
}

/// Real Firebase Email/Password authentication.
class FirebaseAuthService implements AuthService {
  final _auth = FirebaseAuth.instance;

  @override
  String? get currentUserEmail => _auth.currentUser?.email;
  Future<AuthResult> login(String username, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: username.trim(),
        password: password,
      );
      return AuthResult.success;
    } on FirebaseAuthException {
      return AuthResult.invalidCredentials;
    }
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: username.trim(),
        password: password,
      );
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return AuthResult.emailAlreadyInUse;
        case 'weak-password':
          return AuthResult.weakPassword;
        default:
          return AuthResult.invalidCredentials;
      }
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }
}

/// Mock authentication — kept for testing without Firebase.
class MockAuthService implements AuthService {
  static const String _mockUsername = 'admin';
  static const String _mockPassword = 'admin';

  @override
  String? get currentUserEmail => 'admin';
  Future<AuthResult> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (username == _mockUsername && password == _mockPassword) {
      return AuthResult.success;
    }
    return AuthResult.invalidCredentials;
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return AuthResult.success;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}