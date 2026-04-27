import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _currentUserKey = 'current_user';
  static const String _usersKey = 'all_users';
  static const String _isLoggedInKey = 'is_logged_in';

  final Uuid _uuid = const Uuid();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Hash password for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Initialize default admin user for testing
  Future<void> initializeDefaultAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      final Map<String, dynamic> allUsers = usersJson != null
          ? jsonDecode(usersJson) as Map<String, dynamic>
          : {};

      // Check if admin user exists
      const adminEmail = 'admin@travel.com';
      const adminPassword = 'admin123';

      if (!allUsers.containsKey(adminEmail)) {
        // Create admin user
        final adminUser = UserModel(
          id: _uuid.v4(),
          email: adminEmail,
          displayName: 'Admin',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        allUsers[adminEmail] = {
          'user': adminUser.toJson(),
          'passwordHash': _hashPassword(adminPassword),
        };

        await prefs.setString(_usersKey, jsonEncode(allUsers));
        print('Default admin user created: $adminEmail / $adminPassword');
      }
    } catch (e) {
      print('Error initializing default admin: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);

      if (userJson == null) return null;

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Sign up new user
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        return AuthResult(
          success: false,
          message: 'Please enter a valid email address',
        );
      }

      // Validate password strength
      if (password.length < 6) {
        return AuthResult(
          success: false,
          message: 'Password must be at least 6 characters long',
        );
      }

      final prefs = await SharedPreferences.getInstance();

      // Get all users
      final usersJson = prefs.getString(_usersKey);
      final Map<String, dynamic> allUsers = usersJson != null
          ? jsonDecode(usersJson) as Map<String, dynamic>
          : {};

      // Check if user already exists
      if (allUsers.containsKey(email)) {
        return AuthResult(
          success: false,
          message: 'An account with this email already exists',
        );
      }

      // Create new user
      final userId = _uuid.v4();
      final now = DateTime.now();

      final newUser = UserModel(
        id: userId,
        email: email,
        displayName: displayName ?? email.split('@')[0],
        createdAt: now,
        lastLoginAt: now,
      );

      // Store user credentials
      allUsers[email] = {
        'user': newUser.toJson(),
        'passwordHash': _hashPassword(password),
      };

      // Save all users
      await prefs.setString(_usersKey, jsonEncode(allUsers));

      // Set current user
      await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      return AuthResult(
        success: true,
        message: 'Account created successfully',
        user: newUser,
      );
    } catch (e) {
      print('Error signing up: $e');
      return AuthResult(
        success: false,
        message: 'Failed to create account. Please try again.',
      );
    }
  }

  // Sign in existing user
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all users
      final usersJson = prefs.getString(_usersKey);
      if (usersJson == null) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      final Map<String, dynamic> allUsers =
          jsonDecode(usersJson) as Map<String, dynamic>;

      // Check if user exists
      if (!allUsers.containsKey(email)) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      // Verify password
      final userData = allUsers[email] as Map<String, dynamic>;
      final storedPasswordHash = userData['passwordHash'] as String;
      final inputPasswordHash = _hashPassword(password);

      if (storedPasswordHash != inputPasswordHash) {
        return AuthResult(
          success: false,
          message: 'Incorrect password',
        );
      }

      // Update last login time
      final userJson = userData['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());

      // Update user in storage
      allUsers[email] = {
        'user': updatedUser.toJson(),
        'passwordHash': storedPasswordHash,
      };
      await prefs.setString(_usersKey, jsonEncode(allUsers));

      // Set current user
      await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      return AuthResult(
        success: true,
        message: 'Welcome back!',
        user: updatedUser,
      );
    } catch (e) {
      print('Error signing in: $e');
      return AuthResult(
        success: false,
        message: 'Failed to sign in. Please try again.',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoUrl,
    String? coverPhotoUrl,
    String? bio,
    String? username,
  }) async {
    print('[AUTH_SERVICE] 1. updateProfile called with coverPhotoUrl: $coverPhotoUrl, photoUrl: $photoUrl');

    try {
      print('[AUTH_SERVICE] 2. Getting current user');
      final currentUser = await getCurrentUser();

      if (currentUser == null) {
        print('[AUTH_SERVICE] 3. Current user is null');
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      print('[AUTH_SERVICE] 4. Current user: ${currentUser.email}, id: ${currentUser.id}');

      final updatedUser = currentUser.copyWith(
        displayName: displayName ?? currentUser.displayName,
        photoUrl: photoUrl ?? currentUser.photoUrl,
        coverPhotoUrl: coverPhotoUrl ?? currentUser.coverPhotoUrl,
        bio: bio ?? currentUser.bio,
        username: username ?? currentUser.username,
      );

      print('[AUTH_SERVICE] 5. Created updated user with coverPhotoUrl: ${updatedUser.coverPhotoUrl}');

      final prefs = await SharedPreferences.getInstance();

      print('[AUTH_SERVICE] 6. Converting user to JSON');
      final userJson = updatedUser.toJson();
      print('[AUTH_SERVICE] 7. User JSON: $userJson');

      print('[AUTH_SERVICE] 8. Saving to _currentUserKey');
      // Update current user
      await prefs.setString(_currentUserKey, jsonEncode(userJson));

      print('[AUTH_SERVICE] 9. Getting all users');
      // Update in all users
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        print('[AUTH_SERVICE] 10. Decoding all users JSON');
        final Map<String, dynamic> allUsers =
            jsonDecode(usersJson) as Map<String, dynamic>;

        if (allUsers.containsKey(currentUser.email)) {
          print('[AUTH_SERVICE] 11. Updating user in allUsers for email: ${currentUser.email}');
          final userData = allUsers[currentUser.email] as Map<String, dynamic>;
          allUsers[currentUser.email] = {
            'user': updatedUser.toJson(),
            'passwordHash': userData['passwordHash'],
          };

          print('[AUTH_SERVICE] 12. Saving updated allUsers to SharedPreferences');
          await prefs.setString(_usersKey, jsonEncode(allUsers));
        } else {
          print('[AUTH_SERVICE] WARNING: Current user email not found in allUsers');
        }
      } else {
        print('[AUTH_SERVICE] WARNING: usersJson is null');
      }

      print('[AUTH_SERVICE] 13. Profile update completed successfully');
      return AuthResult(
        success: true,
        message: 'Profile updated successfully',
        user: updatedUser,
      );
    } catch (e, stackTrace) {
      print('[AUTH_SERVICE] ERROR: Exception in updateProfile: $e');
      print('[AUTH_SERVICE] ERROR: Stack trace: $stackTrace');
      return AuthResult(
        success: false,
        message: 'Failed to update profile',
      );
    }
  }

  // Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      final prefs = await SharedPreferences.getInstance();

      // Remove from all users
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        final Map<String, dynamic> allUsers =
            jsonDecode(usersJson) as Map<String, dynamic>;
        allUsers.remove(currentUser.email);
        await prefs.setString(_usersKey, jsonEncode(allUsers));
      }

      // Sign out
      await signOut();

      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } catch (e) {
      print('Error deleting account: $e');
      return AuthResult(
        success: false,
        message: 'Failed to delete account',
      );
    }
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}
