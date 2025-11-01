import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_text_field.dart';
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
  final LocalAuthentication _localAuth = LocalAuthentication();

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
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
                  
                  const SizedBox(height: 16),
                  
                  // Service indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFF0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00FFF0).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Discover • Book • Enjoy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF40FFB0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  
                  const SizedBox(height: 40),
                  
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
                        
                        const SizedBox(height: 24),
                        
                        // Sign In Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C4FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                        
                        const SizedBox(height: 16),
                        
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
          'Sign in to continue to QuickSlot',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Credentials collected. Please authenticate with Face ID/Biometrics.'),
          backgroundColor: AppTheme.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      // Trigger biometric authentication
      await _authenticateWithBiometrics();
    }
  }
  
  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biometric authentication not available on this device'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to complete sign in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      
      if (mounted) {
        if (didAuthenticate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Authentication successful! Logging in...'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // TODO: Complete login flow with collected credentials
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Authentication failed. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
