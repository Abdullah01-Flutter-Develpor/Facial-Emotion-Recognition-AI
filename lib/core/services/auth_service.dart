import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a moment.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageFor(e);
    }
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageFor(e);
    }
  }

  bool _googleReady = false;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return null;
      }

      await _ensureGoogleReady();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return 'Google sign-in failed. Try again.';

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageFor(e);
    } catch (e) {
      if (e.toString().toLowerCase().contains('cancel')) {
        return 'Google sign-in was cancelled.';
      }
      return 'Google sign-in failed. Try again.';
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageFor(e);
    }
  }

  Future<String?> confirmPasswordReset(
    String oobCode,
    String newPassword,
  ) async {
    try {
      await _auth.verifyPasswordResetCode(oobCode);
      await _auth.confirmPasswordReset(code: oobCode, newPassword: newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageFor(e);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
