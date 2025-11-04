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
      final authNotifier = ref.read(authStateProvider.notifier);
      
      // Check if biometric is enabled
      final biometricEnabled = await authNotifier.isBiometricEnabled();
      
      if (biometricEnabled) {
        await Future.delayed(const Duration(milliseconds: 450));

        // Biometric is enabled - trigger biometric prompt
        try {
          // This will:
          // 1. Show biometric prompt
          // 2. If successful, validate stored token with /auth/me
          // 3. If token valid, return user and auto-login
          // 4. If token expired, throw error and fallback to login
          await authNotifier.loginWithBiometrics();
          
          if (mounted) {
            setState(() {
              _isAuthenticated = true;
              _isCheckingAuth = false;
            });
          }
        } catch (e) {
          // Biometric failed or token expired - show login page
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
              _isCheckingAuth = false;
            });
          }
        }
      } else {
        // Biometric not enabled - AuthNotifier already checked token via /auth/me
        // Just wait a moment for AuthNotifier to finish, then read the state
        await Future.delayed(const Duration(milliseconds: 100));
        final authState = ref.read(authStateProvider);
        
        if (mounted) {
          setState(() {
            _isAuthenticated = authState.isAuthenticated;
            _isCheckingAuth = false;
          });
        }
      }
    } catch (e) {
      // Any error - show login page
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
