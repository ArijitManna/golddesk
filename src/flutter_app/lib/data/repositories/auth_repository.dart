import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      final loginResponse = LoginResponse.fromJson(response.data);

      // Store tokens
      await _storage.write(
          key: AppConstants.accessTokenKey, value: loginResponse.accessToken);
      await _storage.write(
          key: AppConstants.refreshTokenKey, value: loginResponse.refreshToken);
      await _storage.write(
          key: AppConstants.userDataKey,
          value: jsonEncode(loginResponse.user.toJson()));

      return loginResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<LoginResponse> refreshToken() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) throw ApiException(message: 'No refresh token');

      final response = await _apiClient.dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final loginResponse = LoginResponse.fromJson(response.data);

      await _storage.write(
          key: AppConstants.accessTokenKey, value: loginResponse.accessToken);
      await _storage.write(
          key: AppConstants.refreshTokenKey, value: loginResponse.refreshToken);
      await _storage.write(
          key: AppConstants.userDataKey,
          value: jsonEncode(loginResponse.user.toJson()));

      return loginResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserInfo?> getCurrentUser() async {
    final userData = await _storage.read(key: AppConstants.userDataKey);
    if (userData == null) return null;
    try {
      return UserInfo.fromJson(jsonDecode(userData));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
  }
}
