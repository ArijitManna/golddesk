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
    String? address,
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
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );
      return ExternalBusiness.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ExternalBusiness> updateExternalBusiness({
    required String id,
    required String customerCode,
    required String name,
    String? contactPerson,
    String? mobile,
    String? email,
    String? address,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/external-businesses/$id',
        data: {
          'customerCode': customerCode,
          'name': name,
          if (contactPerson != null && contactPerson.isNotEmpty)
            'contactPerson': contactPerson,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
          if (email != null && email.isNotEmpty) 'email': email,
          if (address != null && address.isNotEmpty) 'address': address,
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
}
