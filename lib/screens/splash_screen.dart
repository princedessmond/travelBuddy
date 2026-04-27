import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  int _currentScene = 0;
  final StorageService _storage = StorageService();

  final List<Map<String, String>> _scenes = [
    {
      'title': 'Plan your outfits. Pack your bags.',
      'subtitle': 'Every detail, beautifully organized',
      'emoji': '👗',
      'mascot': '🧳',
      'animation': 'packing',
    },
    {
      'title': 'Budget made easy.',
      'subtitle': 'Track expenses in any currency',
      'emoji': '💰',
      'mascot': '🌍',
      'animation': 'budget',
    },
    {
      'title': 'Share your adventure.',
      'subtitle': 'One link. Complete trip plan.',
      'emoji': '✈️',
      'mascot': '🗺️',
      'animation': 'share',
    },
  ];

  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late AnimationController _planeController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _planeController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _planeController, curve: Curves.linear),
    );

    _startIntroSequence();
  }

  void _startIntroSequence() async {
    // Start the animation first
    _controller.forward();

    // IMPORTANT: Wait for auth provider to initialize before checking auth status
    // This ensures user data is loaded from storage (fixes logout after image picker)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth initialization if it's still loading
    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final isAuthenticated = authProvider.isAuthenticated;

    if (!isAuthenticated && mounted) {
      // User not logged in, just show splash - they control when to proceed
      return;
    }

    // User is authenticated, check if they have seen intro
    final hasSeenIntro = await _storage.hasSeenIntro();

    if (hasSeenIntro && mounted) {
      // Skip intro, check if user has a trip after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateBasedOnTripStatus();
      return;
    }

    // Show intro - user controls progression with skip button
  }

  void _navigateBasedOnTripStatus() {
    if (!mounted) return;

    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    if (tripProvider.hasTrip) {
      // User has a trip, go to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      // No trip, go to setup
      Navigator.of(context).pushReplacementNamed('/setup');
    }
  }

  void _skipIntro() async {
    if (_currentScene < _scenes.length - 1) {
      // Move to next scene
      setState(() => _currentScene++);
      _controller.reset();
      _controller.forward();
    } else {
      // Last scene, mark as seen and navigate to login
      await _storage.setHasSeenIntro(true);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _planeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_currentScene];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Main content with fade-in
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Travel Mascot Scene
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background circle
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),
                              // Orbiting plane animation
                              AnimatedBuilder(
                                animation: _rotationAnimation,
                                builder: (context, child) {
                                  final angle = _rotationAnimation.value;
                                  final radius = 90.0;
                                  final x = radius * cos(angle);
                                  final y = radius * sin(angle);

                                  return Transform.translate(
                                    offset: Offset(x, y),
                                    child: Transform.rotate(
                                      angle: angle + 3.14159, // 180 degrees - point inward toward center
                                      child: const Text(
                                        '✈️',
                                        style: TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Animated logo with bounce
                              AnimatedBuilder(
                                animation: _bounceAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -_bounceAnimation.value),
                                    child: SvgPicture.asset(
                                      'assets/images/logo_icon.svg',
                                      width: 120,
                                      height: 120,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        scene['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        scene['subtitle']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentScene == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentScene == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Next/Get Started button
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _skipIntro,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  _currentScene < _scenes.length - 1 ? 'Next' : 'Get Started',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // App title at bottom
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '✈️ ',
                          style: TextStyle(fontSize: 24),
                        ),
                        Text(
                          'Travel Companion',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Budget • Pack • Plan • Share',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
