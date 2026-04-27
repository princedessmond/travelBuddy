import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trip_provider.dart';
import 'providers/auth_provider.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/country_selector_screen.dart';
import 'screens/currency_picker_screen.dart';
import 'screens/budget_setup_screen.dart';
import 'screens/main_dashboard_screen.dart';
import 'screens/trip_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/offline_map_screen.dart';
import 'screens/user_search_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/friends_list_screen.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService().init();

  // Initialize default admin user for testing
  await AuthService().initializeDefaultAdmin();

  runApp(const TravelCompanionApp());
}

class TravelCompanionApp extends StatefulWidget {
  const TravelCompanionApp({super.key});

  @override
  State<TravelCompanionApp> createState() => _TravelCompanionAppState();
}

class _TravelCompanionAppState extends State<TravelCompanionApp> with WidgetsBindingObserver {
  late AuthProvider _authProvider;
  late TripProvider _tripProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider = AuthProvider()..init();
    _tripProvider = TripProvider()..init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.dispose();
    _tripProvider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background (e.g., after image picker/cropper), reinitialize auth
    if (state == AppLifecycleState.resumed) {
      debugPrint('[LIFECYCLE] App resumed, re-initializing auth state');
      // Force reload auth state from storage
      _authProvider.init().then((_) {
        debugPrint('[LIFECYCLE] Auth state reloaded. isAuthenticated: ${_authProvider.isAuthenticated}');
      });
    } else if (state == AppLifecycleState.paused) {
      debugPrint('[LIFECYCLE] App paused');
    } else if (state == AppLifecycleState.inactive) {
      debugPrint('[LIFECYCLE] App inactive');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: _authProvider,
        ),
        ChangeNotifierProvider.value(
          value: _tripProvider,
        ),
      ],
      child: MaterialApp(
        title: 'Travel Companion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primaryPink,
          scaffoldBackgroundColor: AppColors.backgroundPink,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryPink,
            primary: AppColors.primaryPink,
            secondary: AppColors.primaryPurple,
          ),
          fontFamily: 'Poppins',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppColors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: AppColors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightPink),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightPink),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryPink, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/setup': (context) => const CountrySelectorScreen(),
          '/country-selector': (context) => const CountrySelectorScreen(),
          '/currency-picker': (context) => const CurrencyPickerScreen(),
          '/budget-setup': (context) => const BudgetSetupScreen(),
          '/dashboard': (context) => const MainDashboardScreen(),
          '/trip-history': (context) => const TripHistoryScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/ai-assistant': (context) => const AIAssistantScreen(),
          '/offline-map': (context) => const OfflineMapScreen(),
          '/user-search': (context) => const UserSearchScreen(),
          '/friend-requests': (context) => const FriendRequestsScreen(),
          '/friends-list': (context) => const FriendsListScreen(),
        },
      ),
    );
  }
}
