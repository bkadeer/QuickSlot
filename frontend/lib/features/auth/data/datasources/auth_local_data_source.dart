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
      final isAvailable = await checkBiometricAvailability();
      if (!isAvailable) {
        throw AuthenticationException('Biometric authentication not available');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in to QuickSlot',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } catch (e) {
      throw AuthenticationException('Biometric authentication failed: ${e.toString()}');
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
