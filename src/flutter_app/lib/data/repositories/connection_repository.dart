import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/connection_models.dart';

class ConnectionRepository {
  final ApiClient _apiClient;

  ConnectionRepository(this._apiClient);

  Future<List<BusinessConnection>> getConnections({
    String? status,
    String? connectionType,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/connections',
        queryParameters: {'status': ?status, 'connectionType': ?connectionType},
      );
      return (response.data as List)
          .map((item) => BusinessConnection.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BusinessSummary> searchBusiness(String goldDeskId) async {
    try {
      final response = await _apiClient.dio.get(
        '/connections/search',
        queryParameters: {'goldDeskId': goldDeskId},
      );
      return BusinessSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BusinessConnection> requestConnection(
    String targetGoldDeskId, {
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/connections/request',
        data: {
          'targetGoldDeskId': targetGoldDeskId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return BusinessConnection.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BusinessConnection> respondToRequest(
    String connectionId, {
    required bool accept,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/connections/$connectionId/respond',
        data: {'accept': accept},
      );
      return BusinessConnection.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelConnectionRequest(String connectionId) async {
    try {
      await _apiClient.dio.delete('/connections/$connectionId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> blockConnection(String connectionId) async {
    try {
      await _apiClient.dio.post('/connections/$connectionId/block');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
