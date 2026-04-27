import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../services/friend_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user's profile

  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FriendService _friendService = FriendService();
  String? _friendshipStatus;
  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _loadFriendshipStatus();
    }
  }

  Future<void> _loadFriendshipStatus() async {
    setState(() => _isLoadingStatus = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    if (currentUserId != null && widget.userId != null) {
      final status = await _friendService.getFriendshipStatus(
        currentUserId,
        widget.userId!,
      );
      setState(() {
        _friendshipStatus = status;
        _isLoadingStatus = false;
      });
    } else {
      setState(() => _isLoadingStatus = false);
    }
  }

  bool get _isOwnProfile => widget.userId == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final currentUser = authProvider.currentUser;

          if (currentUser == null) {
            return const Center(child: Text('Not logged in'));
          }

          // For viewing others' profiles, fetch their data
          // For now, showing current user profile
          final displayUser = currentUser; // TODO: fetch other user data if userId provided

          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.lightGradient,
            ),
            child: CustomScrollView(
              slivers: [
                // App Bar with Cover Photo
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover Photo
                        displayUser.coverPhotoUrl != null
                            ? _buildImageWidget(
                                displayUser.coverPhotoUrl!,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                              ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        // Edit cover photo button (only for own profile)
                        if (_isOwnProfile)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: IconButton(
                              onPressed: () => _editCoverPhoto(context),
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Profile Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPink.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryPink.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: displayUser.photoUrl != null
                                          ? _buildImageWidget(
                                              displayUser.photoUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: _buildAvatarPlaceholder(displayUser),
                                            )
                                          : _buildAvatarPlaceholder(displayUser),
                                    ),
                                  ),
                                  // Edit photo button (only for own profile)
                                  if (_isOwnProfile)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _editProfilePhoto(context),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryPink,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Name & Username
                              Text(
                                displayUser.displayName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (displayUser.username != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '@${displayUser.username}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryPink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),

                              // Bio
                              if (displayUser.bio != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    displayUser.bio!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Stats Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatItem(
                                    count: displayUser.tripCount,
                                    label: 'Trips',
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppColors.textSecondary.withOpacity(0.2),
                                  ),
                                  _StatItem(
                                    count: displayUser.friendIds.length,
                                    label: 'Friends',
                                    onTap: () => _navigateToFriends(context),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppColors.textSecondary.withOpacity(0.2),
                                  ),
                                  _StatItem(
                                    count: displayUser.followersCount,
                                    label: 'Followers',
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Action Buttons
                              if (_isOwnProfile) ...[
                                // Edit Profile Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _editProfile(context, displayUser),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit Profile'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryPink,
                                      side: const BorderSide(
                                        color: AppColors.primaryPink,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Friend Requests Button
                                SizedBox(
                                  width: double.infinity,
                                  child: StreamBuilder<int>(
                                    stream: _friendService
                                        .getPendingReceivedRequests(displayUser.id)
                                        .map((requests) => requests.length),
                                    builder: (context, snapshot) {
                                      final pendingCount = snapshot.data ?? 0;
                                      return OutlinedButton.icon(
                                        onPressed: () =>
                                            Navigator.pushNamed(context, '/friend-requests'),
                                        icon: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            const Icon(Icons.person_add),
                                            if (pendingCount > 0)
                                              Positioned(
                                                right: -8,
                                                top: -8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.error,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    pendingCount > 9
                                                        ? '9+'
                                                        : '$pendingCount',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        label: const Text('Friend Requests'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primaryPurple,
                                          side: const BorderSide(
                                            color: AppColors.primaryPurple,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ] else ...[
                                // Friend Action Button (for other users' profiles)
                                _buildFriendActionButton(),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Settings Section (only for own profile)
                        if (_isOwnProfile) ...[
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Consumer<TripProvider>(
                            builder: (context, tripProvider, child) {
                              return _SettingsCard(
                                icon: Icons.history,
                                title: 'Trip History',
                                subtitle: '${tripProvider.tripHistory.length} previous trips',
                                onTap: () {
                                  Navigator.pushNamed(context, '/trip-history');
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          _SettingsCard(
                            icon: Icons.search,
                            title: 'Find Friends',
                            subtitle: 'Search for other travelers',
                            onTap: () {
                              Navigator.pushNamed(context, '/user-search');
                            },
                          ),
                          const SizedBox(height: 12),

                          _SettingsCard(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'Version 1.0.0',
                            onTap: () => _showAboutDialog(context),
                          ),
                          const SizedBox(height: 20),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _handleLogout(context),
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarPlaceholder(displayUser) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          displayUser.displayName?.substring(0, 1).toUpperCase() ??
              displayUser.email.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendActionButton() {
    if (_isLoadingStatus) {
      return const Center(child: CircularProgressIndicator());
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    if (currentUserId == null || widget.userId == null) {
      return const SizedBox.shrink();
    }

    switch (_friendshipStatus) {
      case 'friends':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _removeFriend(currentUserId, widget.userId!),
            icon: const Icon(Icons.person_remove),
            label: const Text('Remove Friend'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case 'pending_sent':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement cancel request
            },
            icon: const Icon(Icons.hourglass_empty),
            label: const Text('Request Pending'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.textSecondary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case 'pending_received':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Accept request
            },
            icon: const Icon(Icons.check),
            label: const Text('Accept Friend Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _sendFriendRequest(currentUserId, widget.userId!),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friend'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
    }
  }

  Future<void> _sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      await _friendService.sendFriendRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadFriendshipStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeFriend(String currentUserId, String friendUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _friendService.removeFriend(
          currentUserId: currentUserId,
          friendUserId: friendUserId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend removed'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadFriendshipStatus();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToFriends(BuildContext context) {
    Navigator.pushNamed(context, '/friends-list');
  }

  void _editProfile(BuildContext context, user) {
    final displayNameController = TextEditingController(text: user.displayName);
    final usernameController = TextEditingController(text: user.username ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Enter your display name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 3,
                      maxLength: 150,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    displayNameController.dispose();
                    usernameController.dispose();
                    bioController.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newDisplayName = displayNameController.text.trim();
                    final newUsername = usernameController.text.trim();
                    final newBio = bioController.text.trim();

                    if (newDisplayName.isEmpty) {
                      ScaffoldMessenger.of(stateContext).showSnackBar(
                        const SnackBar(
                          content: Text('Display name cannot be empty'),
                          backgroundColor: AppColors.error,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    // Close dialog first
                    Navigator.of(dialogContext).pop();

                    // Now update profile
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );

                    final success = await authProvider.updateProfile(
                      displayName: newDisplayName,
                      username: newUsername.isEmpty ? null : newUsername,
                      bio: newBio.isEmpty ? null : newBio,
                    );

                    // Dispose controllers after everything is done
                    displayNameController.dispose();
                    usernameController.dispose();
                    bioController.dispose();

                    // Show result message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Profile updated successfully!'
                                : 'Failed to update profile',
                          ),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editProfilePhoto(BuildContext context) async {
    // Get the messenger and auth provider before any async operations
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;
    if (!mounted) return;

    try {
      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: AppColors.primaryPink,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) return;
      if (!mounted) return;

      // Show loading
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Uploading profile photo...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Save to local app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');
      await savedImage.writeAsBytes(await File(croppedFile.path).readAsBytes());

      if (!mounted) return;

      // Update user profile with local file path
      final result = await authProvider.updateProfile(
        photoUrl: savedImage.path,
      );

      if (!mounted) return;

      // Show result
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result ? 'Profile photo updated successfully!' : 'Failed to update profile photo',
          ),
          backgroundColor: result ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      print('Error updating profile photo: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _editCoverPhoto(BuildContext context) async {
    print('[COVER_PHOTO] 1. Starting cover photo edit');

    // Get the messenger and auth provider before any async operations
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('[COVER_PHOTO] 2. Got messenger and auth provider');

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    print('[COVER_PHOTO] 3. Image picked: ${image?.path ?? "null"}');

    if (image == null) {
      print('[COVER_PHOTO] 4. Image is null, returning');
      return;
    }

    if (!mounted) {
      print('[COVER_PHOTO] 5. Widget not mounted after picking image, returning');
      return;
    }

    try {
      print('[COVER_PHOTO] 6. Starting image crop');

      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Cover Photo',
            toolbarColor: AppColors.primaryPink,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Cover Photo',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      print('[COVER_PHOTO] 7. Image cropped: ${croppedFile?.path ?? "null"}');

      if (croppedFile == null) {
        print('[COVER_PHOTO] 8. Cropped file is null, returning');
        return;
      }

      if (!mounted) {
        print('[COVER_PHOTO] 9. Widget not mounted after cropping, returning');
        return;
      }

      print('[COVER_PHOTO] 10. Showing loading snackbar');

      // Show loading
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Uploading cover photo...'),
          duration: Duration(seconds: 1),
        ),
      );

      print('[COVER_PHOTO] 11. Getting app directory for saving');

      // Save to local app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');

      print('[COVER_PHOTO] 12. Saving image to: ${savedImage.path}');

      await savedImage.writeAsBytes(await File(croppedFile.path).readAsBytes());

      print('[COVER_PHOTO] 13. Image saved successfully');

      if (!mounted) {
        print('[COVER_PHOTO] 14. Widget not mounted after saving, returning');
        return;
      }

      print('[COVER_PHOTO] 15. Calling authProvider.updateProfile with coverPhotoUrl: ${savedImage.path}');

      // Update user profile with local file path
      final result = await authProvider.updateProfile(
        coverPhotoUrl: savedImage.path,
      );

      print('[COVER_PHOTO] 16. updateProfile returned: $result');

      if (!mounted) {
        print('[COVER_PHOTO] 17. Widget not mounted after update, returning');
        return;
      }

      print('[COVER_PHOTO] 18. Showing result snackbar');

      // Show result
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result ? 'Cover photo updated successfully!' : 'Failed to update cover photo',
          ),
          backgroundColor: result ? AppColors.success : AppColors.error,
        ),
      );

      print('[COVER_PHOTO] 19. Cover photo edit completed successfully');
    } catch (e, stackTrace) {
      print('[COVER_PHOTO] ERROR: Exception caught: $e');
      print('[COVER_PHOTO] ERROR: Stack trace: $stackTrace');

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Helper method to display images (handles both local files and network URLs)
  Widget _buildImageWidget(
    String imagePath, {
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    // Check if it's a local file path (starts with /)
    if (imagePath.startsWith('/')) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
        );
      } else {
        return placeholder ?? Container(color: Colors.grey);
      }
    } else {
      // It's a network URL
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit,
        placeholder: (context, url) => placeholder ?? Container(color: Colors.grey),
        errorWidget: (context, url, error) => placeholder ?? Container(color: Colors.grey),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Travel Companion'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel Companion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Your all-in-one travel planning app with budget tracking, packing lists, daily planner, and trip sharing.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );

              await authProvider.signOut();

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }

    return widget;
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.lightPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryPink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
