import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/video_background.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/auth_text_field.dart';
import '../providers/auth_providers.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authNotifier = ref.read(authStateProvider.notifier);
    final isEnabled = await authNotifier.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _showBiometricButton = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: VideoBackground(
        videoPath: 'assets/videos/background.mp4',
        overlayOpacity: 0.6,
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    children: [
                      // Spacer to push content to lower portion
                      const Spacer(flex: 2),
                      
                      // Logo and Title
                      _buildHeader(theme)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 90),
                  const SizedBox(height: 100),
                  
                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                        
                        const SizedBox(height: 16),
                        
                        // Password Field
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                        
                        const SizedBox(height: 13),
                        
                        // Sign In Button
                        // Sign In Button
SizedBox(
  height: 50,
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _isLoading ? null : _handleLogin,
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: const Color(0xFF0E1F40), // dark navy theme
      disabledBackgroundColor: Colors.grey.shade500,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
    child: AnimatedSwitcher(
      duration: 300.ms,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _isLoading
          ? const SizedBox(
              key: ValueKey("loading"),
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              key: ValueKey("text"),
              'SIGN IN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: Colors.white,
              ),
            ),
    ),
  ),
).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: .2, end: 0),

                        
                        const SizedBox(height: 16),
                        
                        // Biometric Login Button (if enabled)
                        if (_showBiometricButton)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _loginWithBiometrics,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  side: const BorderSide(
                                    color: Color(0xFF00FFF0),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.fingerprint,
                                  color: Color(0xFF00FFF0),
                                  size: 24,
                                ),
                                label: const Text(
                                  'Login with Biometrics',
                                  style: TextStyle(
                                    color: Color(0xFF00FFF0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                              const SizedBox(height: 16),
                            ],
                          ),
                        
                        // Forgot Password & Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF40FFB0),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SignupPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF00FFF0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                  
                  // Spacer at bottom
                  const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/quickslot_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.white54,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome Back',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Please sign in to QuickSpot',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        // Login with backend
        await ref.read(authStateProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          // Check if biometric auth should be enabled after successful login
          await _promptBiometricSetup();
          
          // Navigate to home page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _promptBiometricSetup() async {
    final localAuth = LocalAuthentication();
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    if (canCheckBiometrics && isDeviceSupported) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable Biometric Login?'),
            content: const Text(
              'Would you like to enable biometric authentication for faster login next time?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );

        if (result == true) {
          try {
            await ref.read(authStateProvider.notifier).enableBiometricAuth();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometric authentication enabled'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            // Silently fail if biometric setup fails
          }
        }
      }
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).loginWithBiometrics();

      if (mounted) {
        // Navigate to home page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
