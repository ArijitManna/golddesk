import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class TenantRepository {
  final ApiClient _apiClient;

  TenantRepository(this._apiClient);

  Future<TenantProfile> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/tenant/profile');
      return TenantProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TenantProfile> updateProfile({
    required String shopName,
    required String ownerName,
    required String mobile,
    String? address,
    String? gstNumber,
  }) async {
    try {
      final response = await _apiClient.dio.put('/tenant/profile', data: {
        'shopName': shopName,
        'ownerName': ownerName,
        'mobile': mobile,
        if (address != null) 'address': address,
        if (gstNumber != null) 'gstNumber': gstNumber,
      });
      return TenantProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TenantProfile> updateNotificationPrefs({
    required bool notifyDueSoon3Days,
    required bool notifyDueSoon2Days,
    required bool notifyDueSoon1Day,
    required bool notifyDueToday,
    required bool notifyOverdue,
  }) async {
    try {
      final response = await _apiClient.dio.put('/tenant/notification-prefs', data: {
        'notifyDueSoon3Days': notifyDueSoon3Days,
        'notifyDueSoon2Days': notifyDueSoon2Days,
        'notifyDueSoon1Day': notifyDueSoon1Day,
        'notifyDueToday': notifyDueToday,
        'notifyOverdue': notifyOverdue,
      });
      return TenantProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> uploadLogo(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filePath.split(Platform.pathSeparator).last),
      });
      final response = await _apiClient.dio.post('/files/upload/tenant-logo', data: formData);
      return response.data['logoPath'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class TenantProfile {
  final String id;
  final String shopName;
  final String ownerName;
  final String mobile;
  final String email;
  final String? address;
  final String? gstNumber;
  final String? logoPath;
  final bool notifyDueSoon3Days;
  final bool notifyDueSoon2Days;
  final bool notifyDueSoon1Day;
  final bool notifyDueToday;
  final bool notifyOverdue;

  TenantProfile({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    this.address,
    this.gstNumber,
    this.logoPath,
    required this.notifyDueSoon3Days,
    required this.notifyDueSoon2Days,
    required this.notifyDueSoon1Day,
    required this.notifyDueToday,
    required this.notifyOverdue,
  });

  factory TenantProfile.fromJson(Map<String, dynamic> json) => TenantProfile(
        id: json['id'],
        shopName: json['shopName'],
        ownerName: json['ownerName'],
        mobile: json['mobile'],
        email: json['email'],
        address: json['address'],
        gstNumber: json['gstNumber'],
        logoPath: json['logoPath'],
        notifyDueSoon3Days: json['notifyDueSoon3Days'] ?? true,
        notifyDueSoon2Days: json['notifyDueSoon2Days'] ?? true,
        notifyDueSoon1Day: json['notifyDueSoon1Day'] ?? true,
        notifyDueToday: json['notifyDueToday'] ?? true,
        notifyOverdue: json['notifyOverdue'] ?? true,
      );
}
