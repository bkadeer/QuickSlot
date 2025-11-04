import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final SecureStorageService _storage;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._storage,
  );

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save tokens
      await _storage.saveAccessToken(result.accessToken);
      await _storage.saveRefreshToken(result.refreshToken);
      await _storage.saveUserId(result.user.id);
      await _storage.saveUserEmail(result.user.email);

      return result.user.toEntity();
    } on ServerException catch (e) {
      throw AuthenticationException(e.message);
    } on NetworkException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final result = await _remoteDataSource.register(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );

      // Save tokens
      await _storage.saveAccessToken(result.accessToken);
      await _storage.saveRefreshToken(result.refreshToken);
      await _storage.saveUserId(result.user.id);
      await _storage.saveUserEmail(result.user.email);

      return result.user.toEntity();
    } on ServerException catch (e) {
      throw AuthenticationException(e.message);
    } on NetworkException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Try to logout on server
      await _remoteDataSource.logout();
    } catch (e) {
      // Continue with local logout even if server logout fails
    } finally {
      // Clear all local data
      await _storage.clearAll();
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      return userModel.toEntity();
    } on ServerException catch (e) {
      throw AuthenticationException(e.message);
    } on NetworkException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _remoteDataSource.requestPasswordReset(email);
    } on ServerException catch (e) {
      throw AuthenticationException(e.message);
    } on NetworkException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Failed to request password reset: ${e.toString()}');
    }
  }

  @override
  Future<User> loginWithBiometrics() async {
    try {
      // Check if biometric is available
      final isAvailable = await _localDataSource.checkBiometricAvailability();
      if (!isAvailable) {
        // Gracefully fail - biometric not available (e.g., iOS Simulator)
        throw AuthenticationException('Biometric not available. Please enable Face ID/Touch ID in device settings.');
      }

      // Get saved email
      final email = await _localDataSource.getBiometricCredentials();
      if (email == null) {
        throw AuthenticationException('No biometric credentials found');
      }

      // Authenticate with biometrics (returns false if fails, doesn't throw)
      final authenticated = await _localDataSource.authenticateWithBiometrics();
      if (!authenticated) {
        // User cancelled or biometric failed - gracefully fallback
        throw AuthenticationException('Biometric authentication cancelled or failed');
      }

      // Check if still logged in (has valid token)
      final isLoggedIn = await this.isLoggedIn();
      if (isLoggedIn) {
        // Try to get current user with existing token
        try {
          return await getCurrentUser();
        } catch (e) {
          // Token might be expired, need to login again
          throw AuthenticationException('Session expired. Please login again with password');
        }
      } else {
        throw AuthenticationException('Please login again with password');
      }
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException('Biometric login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> enableBiometricAuth() async {
    try {
      final email = await _storage.getUserEmail();
      if (email == null) {
        throw AuthenticationException('No user logged in');
      }

      await _localDataSource.saveBiometricCredentials(email);
    } catch (e) {
      throw AuthenticationException('Failed to enable biometric auth: ${e.toString()}');
    }
  }

  @override
  Future<void> disableBiometricAuth() async {
    try {
      await _localDataSource.clearBiometricCredentials();
    } catch (e) {
      throw AuthenticationException('Failed to disable biometric auth: ${e.toString()}');
    }
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return await _storage.isBiometricEnabled();
  }
}
