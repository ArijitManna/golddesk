import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/dashboard_models.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<ShopDashboardData> getShopDashboard() async {
    try {
      final response = await _apiClient.dio.get('/dashboard');
      return ShopDashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<GoldRateData> getGoldRate({String? city}) async {
    try {
      final response = await _apiClient.dio.get(
        '/dashboard/gold-rate',
        queryParameters: {
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        },
      );
      return GoldRateData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
