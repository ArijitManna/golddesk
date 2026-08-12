import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/dashboard_models.dart';
import '../models/order_models.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<PagedResponse<OrderSummary>> getOrders({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get('/orders', queryParameters: {
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        'page': page,
        'pageSize': pageSize,
      });
      final data = response.data;
      return PagedResponse<OrderSummary>(
        items: (data['items'] as List)
            .map((e) => OrderSummary.fromJson(e))
            .toList(),
        totalCount: data['totalCount'],
        page: data['page'],
        pageSize: data['pageSize'],
        totalPages: data['totalPages'],
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<OrderDetail> getOrderById(String id) async {
    try {
      final response = await _apiClient.dio.get('/orders/$id');
      return OrderDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<OrderSummary> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _apiClient.dio.post('/orders', data: request.toJson());
      return OrderSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> assignKarigar(String orderId, AssignKarigarRequest request) async {
    try {
      await _apiClient.dio.post('/orders/$orderId/assign', data: request.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _apiClient.dio.post('/orders/$orderId/cancel', data: {
        if (reason != null) 'reason': reason,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> uploadOrderItemImage(String orderItemId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });
      final response = await _apiClient.dio.post(
        '/files/upload/order-item/$orderItemId',
        data: formData,
      );
      return response.data['imagePath'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CustomerItem>> getCustomers({String? search}) async {
    try {
      final response = await _apiClient.dio.get('/customers', queryParameters: {
        if (search != null) 'search': search,
        'pageSize': 50,
      });
      return (response.data['items'] as List)
          .map((e) => CustomerItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<KarigarItem>> getKarigars() async {
    try {
      final response = await _apiClient.dio.get('/karigars', queryParameters: {
        'activeOnly': true,
        'pageSize': 50,
      });
      return (response.data['items'] as List)
          .map((e) => KarigarItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final response = await _apiClient.dio.get('/items', queryParameters: {
        'pageSize': 100,
      });
      return List<Map<String, dynamic>>.from(response.data['items']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
