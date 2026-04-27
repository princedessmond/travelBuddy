import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // Initialize and check if user is logged in
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await _authService.isLoggedIn();
      if (_isAuthenticated) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _error = 'Failed to initialize auth: $e';
      print(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.success) {
        _currentUser = result.user;
        _isAuthenticated = true;
        _error = null;
      } else {
        _error = result.message;
      }

      _isLoading = false;
      notifyListeners();

      return result.success;
    } catch (e) {
      _error = 'An error occurred during sign up';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.success) {
        _currentUser = result.user;
        _isAuthenticated = true;
        _error = null;
      } else {
        _error = result.message;
      }

      _isLoading = false;
      notifyListeners();

      return result.success;
    } catch (e) {
      _error = 'An error occurred during sign in';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      _error = 'Failed to sign out';
      print(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? coverPhotoUrl,
    String? bio,
    String? username,
  }) async {
    print('[AUTH_PROVIDER] 1. updateProfile called with coverPhotoUrl: $coverPhotoUrl, photoUrl: $photoUrl');

    _isLoading = true;
    _error = null;

    print('[AUTH_PROVIDER] 2. Set isLoading=true, calling notifyListeners');
    notifyListeners();

    try {
      print('[AUTH_PROVIDER] 3. Calling authService.updateProfile');

      final result = await _authService.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
        coverPhotoUrl: coverPhotoUrl,
        bio: bio,
        username: username,
      );

      print('[AUTH_PROVIDER] 4. authService.updateProfile returned: ${result.success}');

      if (result.success) {
        print('[AUTH_PROVIDER] 5. Success! Setting _currentUser');
        _currentUser = result.user;
        _error = null;
        print('[AUTH_PROVIDER] 6. _currentUser updated, coverPhotoUrl: ${_currentUser?.coverPhotoUrl}');
      } else {
        print('[AUTH_PROVIDER] 7. Failed! Error message: ${result.message}');
        _error = result.message;
      }

      _isLoading = false;
      print('[AUTH_PROVIDER] 8. Set isLoading=false, calling notifyListeners');
      notifyListeners();

      print('[AUTH_PROVIDER] 9. Returning ${result.success}');
      return result.success;
    } catch (e, stackTrace) {
      print('[AUTH_PROVIDER] ERROR: Exception in updateProfile: $e');
      print('[AUTH_PROVIDER] ERROR: Stack trace: $stackTrace');

      _error = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.deleteAccount();

      if (result.success) {
        _currentUser = null;
        _isAuthenticated = false;
        _error = null;
      } else {
        _error = result.message;
      }

      _isLoading = false;
      notifyListeners();

      return result.success;
    } catch (e) {
      _error = 'Failed to delete account';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
