class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Social Profile Fields
  final String? bio;
  final String? username; // Unique username for search and tagging
  final String? coverPhotoUrl; // Cover photo for profile
  final bool isPublicProfile; // Whether profile is public
  final List<String> friendIds; // List of friend user IDs
  final List<String> friendRequestsReceived; // Incoming friend requests
  final List<String> friendRequestsSent; // Outgoing friend requests
  final int tripCount; // Number of trips created
  final int followersCount; // Number of followers/friends
  final int followingCount; // Number of users following

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.bio,
    this.username,
    this.coverPhotoUrl,
    this.isPublicProfile = true,
    this.friendIds = const [],
    this.friendRequestsReceived = const [],
    this.friendRequestsSent = const [],
    this.tripCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      bio: json['bio'] as String?,
      username: json['username'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      isPublicProfile: json['isPublicProfile'] as bool? ?? true,
      friendIds: (json['friendIds'] as List<dynamic>?)?.cast<String>() ?? [],
      friendRequestsReceived: (json['friendRequestsReceived'] as List<dynamic>?)?.cast<String>() ?? [],
      friendRequestsSent: (json['friendRequestsSent'] as List<dynamic>?)?.cast<String>() ?? [],
      tripCount: json['tripCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'bio': bio,
      'username': username,
      'coverPhotoUrl': coverPhotoUrl,
      'isPublicProfile': isPublicProfile,
      'friendIds': friendIds,
      'friendRequestsReceived': friendRequestsReceived,
      'friendRequestsSent': friendRequestsSent,
      'tripCount': tripCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  // Copy with method for updating user data
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? bio,
    String? username,
    String? coverPhotoUrl,
    bool? isPublicProfile,
    List<String>? friendIds,
    List<String>? friendRequestsReceived,
    List<String>? friendRequestsSent,
    int? tripCount,
    int? followersCount,
    int? followingCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      bio: bio ?? this.bio,
      username: username ?? this.username,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      isPublicProfile: isPublicProfile ?? this.isPublicProfile,
      friendIds: friendIds ?? this.friendIds,
      friendRequestsReceived: friendRequestsReceived ?? this.friendRequestsReceived,
      friendRequestsSent: friendRequestsSent ?? this.friendRequestsSent,
      tripCount: tripCount ?? this.tripCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }
}
