import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import 'package:uuid/uuid.dart';

class FriendService {
  final Uuid _uuid = const Uuid();

  // SharedPreferences keys
  static const String _friendRequestsKey = 'friend_requests';
  static const String _usersKey = 'users';

  // =====================
  // Friend Request Operations
  // =====================

  /// Send a friend request from one user to another
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all users
      final users = await _getAllUsers();
      final fromUser = users.firstWhere(
        (u) => u.id == fromUserId,
        orElse: () => throw Exception('From user not found'),
      );
      final toUser = users.firstWhere(
        (u) => u.id == toUserId,
        orElse: () => throw Exception('To user not found'),
      );

      // Check if they're already friends
      if (fromUser.friendIds.contains(toUserId)) {
        throw Exception('Users are already friends');
      }

      // Check if a pending request already exists
      final allRequests = await _getAllFriendRequests();
      final existingRequest = allRequests.any((r) =>
          r.status == FriendRequestStatus.pending &&
          ((r.fromUserId == fromUserId && r.toUserId == toUserId) ||
              (r.fromUserId == toUserId && r.toUserId == fromUserId)));

      if (existingRequest) {
        throw Exception('A friend request already exists between these users');
      }

      // Create the friend request
      final requestId = _uuid.v4();
      final friendRequest = FriendRequestModel(
        id: requestId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      // Save friend request
      allRequests.add(friendRequest);
      await _saveFriendRequests(allRequests);

      // Update users
      final updatedFromRequestsSent = List<String>.from(fromUser.friendRequestsSent)..add(requestId);
      final updatedToRequestsReceived = List<String>.from(toUser.friendRequestsReceived)..add(requestId);

      final updatedFromUser = fromUser.copyWith(friendRequestsSent: updatedFromRequestsSent);
      final updatedToUser = toUser.copyWith(friendRequestsReceived: updatedToRequestsReceived);

      await _updateUser(updatedFromUser);
      await _updateUser(updatedToUser);

      print('Friend request sent successfully');
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    try {
      final allRequests = await _getAllFriendRequests();
      final requestIndex = allRequests.indexWhere((r) => r.id == requestId);

      if (requestIndex == -1) {
        throw Exception('Friend request not found');
      }

      final request = allRequests[requestIndex];

      // Verify the current user is the recipient
      if (request.toUserId != currentUserId) {
        throw Exception('Not authorized to accept this request');
      }

      // Verify request is still pending
      if (request.status != FriendRequestStatus.pending) {
        throw Exception('Request is no longer pending');
      }

      // Update the friend request status
      allRequests[requestIndex] = FriendRequestModel(
        id: request.id,
        fromUserId: request.fromUserId,
        toUserId: request.toUserId,
        status: FriendRequestStatus.accepted,
        createdAt: request.createdAt,
        respondedAt: DateTime.now(),
      );
      await _saveFriendRequests(allRequests);

      // Update users - add each to other's friend list
      final users = await _getAllUsers();
      final fromUser = users.firstWhere((u) => u.id == request.fromUserId);
      final toUser = users.firstWhere((u) => u.id == request.toUserId);

      final updatedFromFriendIds = List<String>.from(fromUser.friendIds)..add(request.toUserId);
      final updatedFromRequestsSent = List<String>.from(fromUser.friendRequestsSent)..remove(requestId);

      final updatedToFriendIds = List<String>.from(toUser.friendIds)..add(request.fromUserId);
      final updatedToRequestsReceived = List<String>.from(toUser.friendRequestsReceived)..remove(requestId);

      final updatedFromUser = fromUser.copyWith(
        friendIds: updatedFromFriendIds,
        friendRequestsSent: updatedFromRequestsSent,
        followersCount: fromUser.followersCount + 1,
      );

      final updatedToUser = toUser.copyWith(
        friendIds: updatedToFriendIds,
        friendRequestsReceived: updatedToRequestsReceived,
        followingCount: toUser.followingCount + 1,
      );

      await _updateUser(updatedFromUser);
      await _updateUser(updatedToUser);

      print('Friend request accepted successfully');
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Reject a friend request
  Future<void> rejectFriendRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    try {
      final allRequests = await _getAllFriendRequests();
      final requestIndex = allRequests.indexWhere((r) => r.id == requestId);

      if (requestIndex == -1) {
        throw Exception('Friend request not found');
      }

      final request = allRequests[requestIndex];

      // Verify the current user is the recipient
      if (request.toUserId != currentUserId) {
        throw Exception('Not authorized to reject this request');
      }

      // Verify request is still pending
      if (request.status != FriendRequestStatus.pending) {
        throw Exception('Request is no longer pending');
      }

      // Update the friend request status
      allRequests[requestIndex] = FriendRequestModel(
        id: request.id,
        fromUserId: request.fromUserId,
        toUserId: request.toUserId,
        status: FriendRequestStatus.rejected,
        createdAt: request.createdAt,
        respondedAt: DateTime.now(),
      );
      await _saveFriendRequests(allRequests);

      // Remove request from both users' lists
      final users = await _getAllUsers();
      final fromUser = users.firstWhere((u) => u.id == request.fromUserId);
      final toUser = users.firstWhere((u) => u.id == request.toUserId);

      final updatedFromRequestsSent = List<String>.from(fromUser.friendRequestsSent)..remove(requestId);
      final updatedToRequestsReceived = List<String>.from(toUser.friendRequestsReceived)..remove(requestId);

      final updatedFromUser = fromUser.copyWith(friendRequestsSent: updatedFromRequestsSent);
      final updatedToUser = toUser.copyWith(friendRequestsReceived: updatedToRequestsReceived);

      await _updateUser(updatedFromUser);
      await _updateUser(updatedToUser);

      print('Friend request rejected successfully');
    } catch (e) {
      print('Error rejecting friend request: $e');
      rethrow;
    }
  }

  /// Cancel a sent friend request
  Future<void> cancelFriendRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    try {
      final allRequests = await _getAllFriendRequests();
      final request = allRequests.firstWhere(
        (r) => r.id == requestId,
        orElse: () => throw Exception('Friend request not found'),
      );

      // Verify the current user is the sender
      if (request.fromUserId != currentUserId) {
        throw Exception('Not authorized to cancel this request');
      }

      // Verify request is still pending
      if (request.status != FriendRequestStatus.pending) {
        throw Exception('Request is no longer pending');
      }

      // Remove the friend request
      allRequests.removeWhere((r) => r.id == requestId);
      await _saveFriendRequests(allRequests);

      // Remove request from both users' lists
      final users = await _getAllUsers();
      final fromUser = users.firstWhere((u) => u.id == request.fromUserId);
      final toUser = users.firstWhere((u) => u.id == request.toUserId);

      final updatedFromRequestsSent = List<String>.from(fromUser.friendRequestsSent)..remove(requestId);
      final updatedToRequestsReceived = List<String>.from(toUser.friendRequestsReceived)..remove(requestId);

      final updatedFromUser = fromUser.copyWith(friendRequestsSent: updatedFromRequestsSent);
      final updatedToUser = toUser.copyWith(friendRequestsReceived: updatedToRequestsReceived);

      await _updateUser(updatedFromUser);
      await _updateUser(updatedToUser);

      print('Friend request cancelled successfully');
    } catch (e) {
      print('Error cancelling friend request: $e');
      rethrow;
    }
  }

  /// Remove a friend connection
  Future<void> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
    try {
      final users = await _getAllUsers();
      final currentUser = users.firstWhere((u) => u.id == currentUserId);
      final friendUser = users.firstWhere((u) => u.id == friendUserId);

      // Remove each user from the other's friend list
      final updatedCurrentFriendIds = List<String>.from(currentUser.friendIds)..remove(friendUserId);
      final updatedFriendFriendIds = List<String>.from(friendUser.friendIds)..remove(currentUserId);

      final updatedCurrentUser = currentUser.copyWith(
        friendIds: updatedCurrentFriendIds,
        followingCount: (currentUser.followingCount - 1).clamp(0, double.infinity).toInt(),
      );

      final updatedFriendUser = friendUser.copyWith(
        friendIds: updatedFriendFriendIds,
        followersCount: (friendUser.followersCount - 1).clamp(0, double.infinity).toInt(),
      );

      await _updateUser(updatedCurrentUser);
      await _updateUser(updatedFriendUser);

      print('Friend removed successfully');
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  // =====================
  // Query Operations
  // =====================

  /// Get pending friend requests received by a user
  Stream<List<FriendRequestModel>> getPendingReceivedRequests(String userId) {
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      final allRequests = await _getAllFriendRequests();
      return allRequests
          .where((r) =>
              r.toUserId == userId && r.status == FriendRequestStatus.pending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }).asyncMap((event) => event);
  }

  /// Get pending friend requests sent by a user
  Stream<List<FriendRequestModel>> getPendingSentRequests(String userId) {
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      final allRequests = await _getAllFriendRequests();
      return allRequests
          .where((r) =>
              r.fromUserId == userId && r.status == FriendRequestStatus.pending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }).asyncMap((event) => event);
  }

  /// Get a specific friend request by ID
  Future<FriendRequestModel?> getFriendRequest(String requestId) async {
    try {
      final allRequests = await _getAllFriendRequests();
      return allRequests.firstWhere(
        (r) => r.id == requestId,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      print('Error getting friend request: $e');
      return null;
    }
  }

  /// Get list of user's friends with their full user data
  Future<List<UserModel>> getFriends(String userId) async {
    try {
      final users = await _getAllUsers();
      final user = users.firstWhere(
        (u) => u.id == userId,
        orElse: () => throw Exception('User not found'),
      );

      if (user.friendIds.isEmpty) {
        return [];
      }

      return users.where((u) => user.friendIds.contains(u.id)).toList();
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  /// Search for users by username or display name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final queryLower = query.toLowerCase();
      final users = await _getAllUsers();

      return users.where((user) {
        final username = (user.username ?? '').toLowerCase();
        final displayName = (user.displayName ?? '').toLowerCase();
        return username.contains(queryLower) || displayName.contains(queryLower);
      }).take(20).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Get a user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final users = await _getAllUsers();
      return users.firstWhere(
        (u) => u.id == userId,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final users = await _getAllUsers();
      final user1 = users.firstWhere(
        (u) => u.id == userId1,
        orElse: () => throw Exception('User not found'),
      );
      return user1.friendIds.contains(userId2);
    } catch (e) {
      print('Error checking friendship: $e');
      return false;
    }
  }

  /// Check friend request status between two users
  /// Returns: null (no request), 'pending_sent', 'pending_received', or 'friends'
  Future<String?> getFriendshipStatus(String currentUserId, String otherUserId) async {
    try {
      // Check if already friends
      final isFriend = await areFriends(currentUserId, otherUserId);
      if (isFriend) {
        return 'friends';
      }

      // Check for pending requests
      final allRequests = await _getAllFriendRequests();

      // Check for sent request
      final sentRequest = allRequests.any((r) =>
          r.fromUserId == currentUserId &&
          r.toUserId == otherUserId &&
          r.status == FriendRequestStatus.pending);

      if (sentRequest) {
        return 'pending_sent';
      }

      // Check for received request
      final receivedRequest = allRequests.any((r) =>
          r.fromUserId == otherUserId &&
          r.toUserId == currentUserId &&
          r.status == FriendRequestStatus.pending);

      if (receivedRequest) {
        return 'pending_received';
      }

      return null; // No connection
    } catch (e) {
      print('Error getting friendship status: $e');
      return null;
    }
  }

  /// Get count of pending friend requests for a user
  Future<int> getPendingRequestCount(String userId) async {
    try {
      final allRequests = await _getAllFriendRequests();
      return allRequests
          .where((r) =>
              r.toUserId == userId && r.status == FriendRequestStatus.pending)
          .length;
    } catch (e) {
      print('Error getting pending request count: $e');
      return 0;
    }
  }

  // =====================
  // Helper Methods
  // =====================

  Future<List<FriendRequestModel>> _getAllFriendRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_friendRequestsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => FriendRequestModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading friend requests: $e');
      return [];
    }
  }

  Future<void> _saveFriendRequests(List<FriendRequestModel> requests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = requests.map((r) => r.toJson()).toList();
      await prefs.setString(_friendRequestsKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving friend requests: $e');
    }
  }

  Future<List<UserModel>> _getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_usersKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading users: $e');
      return [];
    }
  }

  Future<void> _updateUser(UserModel user) async {
    try {
      final users = await _getAllUsers();
      final index = users.indexWhere((u) => u.id == user.id);

      if (index != -1) {
        users[index] = user;
      } else {
        users.add(user);
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonList = users.map((u) => u.toJson()).toList();
      await prefs.setString(_usersKey, json.encode(jsonList));
    } catch (e) {
      print('Error updating user: $e');
    }
  }
}
