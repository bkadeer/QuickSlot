import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: QuickSlotApp(),
    ),
  );
}

class QuickSlotApp extends ConsumerStatefulWidget {
  const QuickSlotApp({super.key});

  @override
  ConsumerState<QuickSlotApp> createState() => _QuickSlotAppState();
}

class _QuickSlotAppState extends ConsumerState<QuickSlotApp> {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check if biometric is enabled and try auto-login
      final authNotifier = ref.read(authStateProvider.notifier);
      final biometricEnabled = await authNotifier.isBiometricEnabled();
      
      if (biometricEnabled) {
        // Try biometric login
        await authNotifier.loginWithBiometrics();
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isCheckingAuth = false;
          });
        }
      } else {
        // Check if there's a valid session
        final currentUser = ref.read(currentUserProvider);
        if (mounted) {
          setState(() {
            _isAuthenticated = currentUser != null;
            _isCheckingAuth = false;
          });
        }
      }
    } catch (e) {
      // If auto-login fails, show login page
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickSlot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: _isCheckingAuth
          ? const Scaffold(
              backgroundColor: Color(0xFF0A1128),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00FFF0),
                ),
              ),
            )
          : _isAuthenticated
              ? const HomePage()
              : const LoginPage(),
    );
  }
}
