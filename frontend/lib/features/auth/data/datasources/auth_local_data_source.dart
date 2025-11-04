import 'package:local_auth/local_auth.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<bool> checkBiometricAvailability();
  Future<bool> authenticateWithBiometrics();
  Future<void> saveBiometricCredentials(String email);
  Future<String?> getBiometricCredentials();
  Future<void> clearBiometricCredentials();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalAuthentication _localAuth;
  final SecureStorageService _storage;

  AuthLocalDataSourceImpl(this._localAuth, this._storage);

  @override
  Future<bool> checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      // Check if biometric is available first
      final isAvailable = await checkBiometricAvailability();
      if (!isAvailable) {
        // Gracefully fail - don't crash, just return false
        // This handles iOS Simulator without enrolled biometrics
        return false;
      }

      // Attempt biometric authentication
      // Use biometricOnly: true to prioritize Face ID/Touch ID
      // Only fallback to passcode if biometric fails or is cancelled
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in to QuickSlot',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Use Face ID/Touch ID only, no automatic passcode fallback
          useErrorDialogs: true, // Show error dialogs if biometric fails
          sensitiveTransaction: false, // Don't require additional confirmation
        ),
      );

      return authenticated;
    } catch (e) {
      // Gracefully handle any biometric errors
      // Don't throw - just return false and fallback to normal login
      return false;
    }
  }

  @override
  Future<void> saveBiometricCredentials(String email) async {
    try {
      await _storage.saveUserEmail(email);
      await _storage.setBiometricEnabled(true);
    } catch (e) {
      throw CacheException('Failed to save biometric credentials');
    }
  }

  @override
  Future<String?> getBiometricCredentials() async {
    try {
      final isEnabled = await _storage.isBiometricEnabled();
      if (!isEnabled) return null;
      
      return await _storage.getUserEmail();
    } catch (e) {
      throw CacheException('Failed to get biometric credentials');
    }
  }

  @override
  Future<void> clearBiometricCredentials() async {
    try {
      await _storage.setBiometricEnabled(false);
    } catch (e) {
      throw CacheException('Failed to clear biometric credentials');
    }
  }
}
