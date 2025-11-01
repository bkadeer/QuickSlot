import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<({UserModel user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  });

  Future<({UserModel user, String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    String? name,
    String? phoneNumber,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout();

  Future<void> requestPasswordReset(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<({UserModel user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return (
          user: UserModel.fromJson(data['user']),
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      } else if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Login failed',
          statusCode: e.response?.statusCode,
        );
      } else {
        throw ServerException(message: 'Unknown error occurred');
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<({UserModel user, String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        return (
          user: UserModel.fromJson(data['user']),
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      } else if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Registration failed',
          statusCode: e.response?.statusCode,
        );
      } else {
        throw ServerException(message: 'Unknown error occurred');
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to get user data',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      } else if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Failed to get user data',
          statusCode: e.response?.statusCode,
        );
      } else {
        throw ServerException(message: 'Unknown error occurred');
      }
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } on DioException catch (e) {
      // Even if logout fails on server, we'll clear local data
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      }
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-reset/request',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to request password reset',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException();
      } else if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Failed to request password reset',
          statusCode: e.response?.statusCode,
        );
      } else {
        throw ServerException(message: 'Unknown error occurred');
      }
    }
  }
}
