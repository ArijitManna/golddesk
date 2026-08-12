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

  Future<PlatformShopsReport> getShopsReport() async {
    try {
      final response = await _apiClient.dio.get('/admin/reports/shops');
      return PlatformShopsReport.fromJson(response.data);
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

class PlatformShopsReport {
  final int totalShops;
  final int activeShops;
  final int pendingShops;
  final int totalKarigars;
  final List<PlatformShopSummary> shops;

  PlatformShopsReport({
    required this.totalShops,
    required this.activeShops,
    required this.pendingShops,
    required this.totalKarigars,
    required this.shops,
  });

  factory PlatformShopsReport.fromJson(Map<String, dynamic> json) => PlatformShopsReport(
        totalShops: json['totalShops'] ?? 0,
        activeShops: json['activeShops'] ?? 0,
        pendingShops: json['pendingShops'] ?? 0,
        totalKarigars: json['totalKarigars'] ?? 0,
        shops: (json['shops'] as List? ?? [])
            .map((e) => PlatformShopSummary.fromJson(e))
            .toList(),
      );
}

class PlatformShopSummary {
  final String tenantId;
  final String shopName;
  final String ownerName;
  final String mobile;
  final String email;
  final String status;
  final int karigarCount;
  final int activeKarigarCount;
  final String registeredAt;

  PlatformShopSummary({
    required this.tenantId,
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.status,
    required this.karigarCount,
    required this.activeKarigarCount,
    required this.registeredAt,
  });

  factory PlatformShopSummary.fromJson(Map<String, dynamic> json) => PlatformShopSummary(
        tenantId: json['tenantId'],
        shopName: json['shopName'],
        ownerName: json['ownerName'],
        mobile: json['mobile'] ?? '',
        email: json['email'] ?? '',
        status: json['status'] ?? '',
        karigarCount: json['karigarCount'] ?? 0,
        activeKarigarCount: json['activeKarigarCount'] ?? 0,
        registeredAt: json['registeredAt']?.toString() ?? '',
      );
}
