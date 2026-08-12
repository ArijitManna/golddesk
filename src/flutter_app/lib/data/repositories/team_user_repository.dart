import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class TeamUserRepository {
  final ApiClient _apiClient;

  TeamUserRepository(this._apiClient);

  Future<List<TeamUserData>> getTeamUsers() async {
    try {
      final response = await _apiClient.dio.get('/team-users');
      return (response.data as List)
          .map((e) => TeamUserData.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TeamUserData> createTeamUser({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post('/team-users', data: {
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'password': password,
      });
      return TeamUserData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deactivateTeamUser(String userId) async {
    try {
      await _apiClient.dio.post('/team-users/$userId/deactivate');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class TeamUserData {
  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final String role;
  final String status;
  final bool isCurrentUser;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  TeamUserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.role,
    required this.status,
    required this.isCurrentUser,
    this.lastLoginAt,
    required this.createdAt,
  });

  bool get isActive => status == 'Active';

  factory TeamUserData.fromJson(Map<String, dynamic> json) => TeamUserData(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        mobile: json['mobile'] ?? '',
        role: json['role'] ?? '',
        status: json['status'] ?? '',
        isCurrentUser: json['isCurrentUser'] ?? false,
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
