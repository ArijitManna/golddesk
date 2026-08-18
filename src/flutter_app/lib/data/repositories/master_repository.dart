import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/connection_models.dart';

class MasterRepository {
  final ApiClient _apiClient;

  MasterRepository(this._apiClient);

  Future<List<ExternalBusiness>> getExternalBusinesses() async {
    try {
      final response = await _apiClient.dio.get('/external-businesses');
      return (response.data as List)
          .map((item) => ExternalBusiness.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ExternalBusiness> createExternalBusiness({
    required String customerCode,
    required String name,
    required String businessType,
    String? contactPerson,
    String? mobile,
    String? email,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/external-businesses',
        data: {
          'customerCode': customerCode,
          'name': name,
          'businessType': businessType,
          if (contactPerson != null && contactPerson.isNotEmpty)
            'contactPerson': contactPerson,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      return ExternalBusiness.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> linkExternalBusiness({
    required String externalBusinessId,
    required String goldDeskId,
  }) async {
    try {
      await _apiClient.dio.post(
        '/external-businesses/$externalBusinessId/link',
        data: {'goldDeskId': goldDeskId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Karigars
  Future<List<KarigarData>> getKarigars() async {
    try {
      final response = await _apiClient.dio.get(
        '/karigars',
        queryParameters: {'activeOnly': true, 'pageSize': 50},
      );
      return (response.data['items'] as List)
          .map((e) => KarigarData.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<KarigarData> createKarigar({
    required String name,
    required String mobile,
    String? email,
    String? specialization,
    bool createLogin = false,
    String? password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/karigars',
        data: {
          'name': name,
          'mobile': mobile,
          if (email != null) 'email': email,
          if (specialization != null) 'specialization': specialization,
          'createLogin': createLogin,
          if (password != null) 'password': password,
        },
      );
      return KarigarData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class KarigarData {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? specialization;
  final String status;
  final bool hasLoginAccess;

  KarigarData({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.specialization,
    required this.status,
    required this.hasLoginAccess,
  });

  factory KarigarData.fromJson(Map<String, dynamic> json) => KarigarData(
    id: json['id'],
    name: json['name'],
    mobile: json['mobile'],
    email: json['email'],
    specialization: json['specialization'],
    status: json['status'],
    hasLoginAccess: json['hasLoginAccess'] ?? false,
  );
}
