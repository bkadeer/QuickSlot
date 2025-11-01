import '../entities/user.dart';

abstract class AuthRepository {
  /// Login with email and password
  /// Throws exceptions on failure
  Future<User> login({
    required String email,
    required String password,
  });

  /// Register a new user
  /// Throws exceptions on failure
  Future<User> register({
    required String email,
    required String password,
    String? name,
    String? phoneNumber,
  });

  /// Logout the current user
  /// Throws exceptions on failure
  Future<void> logout();

  /// Get current user
  /// Throws exceptions on failure
  Future<User> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Request password reset
  /// Throws exceptions on failure
  Future<void> requestPasswordReset(String email);

  /// Login with biometrics
  /// Throws exceptions on failure
  Future<User> loginWithBiometrics();

  /// Enable biometric authentication
  /// Throws exceptions on failure
  Future<void> enableBiometricAuth();

  /// Disable biometric authentication
  /// Throws exceptions on failure
  Future<void> disableBiometricAuth();

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled();
}
