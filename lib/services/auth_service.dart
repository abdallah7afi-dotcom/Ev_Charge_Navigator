import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  String _userName = '';
  String _userRole = 'client'; // 'client' or 'admin'

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin' || (_user?.email?.contains('admin') ?? false);

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserData();
      } else {
        _userName = '';
        _userRole = 'client';
      }
      notifyListeners();
    });
  }

  /// Admin Auto-Seeding: Checks if default admin exists in Auth.
  /// If no admin exists, creates default admin@evcharge.com / password123.
  Future<void> seedAdminAccountIfEmpty() async {
    const adminEmail = 'admin@evcharge.com';
    const adminPassword = 'password123';
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': 'System Administrator',
        'email': adminEmail,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Sign out after seeding so app lands cleanly on login screen
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Admin already seeded
        return;
      }
    } catch (e) {
      debugPrint('Admin seeding note: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await _db.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data();
        _userName = data?['name'] ?? '';
        _userRole = data?['role'] ?? 'customer';
        if (_user?.email != null && _user!.email!.toLowerCase().contains('admin') && _userRole != 'admin') {
          _userRole = 'admin';
          await _db.collection('users').doc(_user!.uid).update({'role': 'admin'});
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          if (email.trim().toLowerCase() == 'admin@evcharge.com') {
            return await register(email, password, 'System Administrator', role: 'admin');
          }
        }
        rethrow;
      }

      await _fetchUserData();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, {String role = 'client'}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final assignedRole = (email.trim().toLowerCase().contains('admin')) ? 'admin' : role;

      // Create user document in Firestore with role
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': assignedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _userName = name.trim();
      _userRole = assignedRole;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Password reset feature using user's registered email via Firebase Auth
  Future<bool> sendPasswordReset(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email.trim());

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to send password reset email. Please check address.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userName = '';
      _userRole = 'client';
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error signing out. Please try again.';
      notifyListeners();
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _user!.verifyBeforeUpdateEmail(newEmail.trim());
      await _db.collection('users').doc(_user!.uid).update({
        'email': newEmail.trim(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error updating email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _user!.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error updating password. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPassword(String password) async {
    if (_user == null || _user!.email == null) return false;
    try {
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      await _user!.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to update credentials.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Authentication error: $code';
    }
  }
}
