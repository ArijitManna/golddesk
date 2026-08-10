import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<List<PendingShop>> getPendingRegistrations() async {
    try {
      final response = await _apiClient.dio.get('/admin/registrations/pending');
      return (response.data as List)
          .map((e) => PendingShop.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> approveShop(String tenantId, {String? note}) async {
    try {
      await _apiClient.dio.post(
        '/admin/registrations/$tenantId/approve',
        data: {'adminNote': note},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> rejectShop(String tenantId, String reason) async {
    try {
      await _apiClient.dio.post(
        '/admin/registrations/$tenantId/reject',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class PendingShop {
  final String tenantId;
  final String shopName;
  final String ownerName;
  final String mobile;
  final String email;
  final String? address;
  final String registeredAt;

  PendingShop({
    required this.tenantId,
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    this.address,
    required this.registeredAt,
  });

  factory PendingShop.fromJson(Map<String, dynamic> json) => PendingShop(
        tenantId: json['tenantId'],
        shopName: json['shopName'],
        ownerName: json['ownerName'],
        mobile: json['mobile'],
        email: json['email'],
        address: json['address'],
        registeredAt: json['registeredAt'],
      );
}
