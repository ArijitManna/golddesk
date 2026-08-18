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
    String? due,
    String? search,
    String? source,
    String? shopId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/orders',
        queryParameters: {
          if (status != null) 'status': status,
          if (due != null) 'due': due,
          if (search != null) 'search': search,
          if (source != null) 'source': source,
          if (shopId != null) 'shopId': shopId,
          'page': page,
          'pageSize': pageSize,
        },
      );
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
      final response = await _apiClient.dio.post(
        '/orders',
        data: request.toJson(),
      );
      return OrderSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<OrderSummary> updateOrder(
    String orderId,
    CreateOrderRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '/orders/$orderId',
        data: request.toJson(),
      );
      return OrderSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> assignKarigar(
    String orderId,
    AssignKarigarRequest request,
  ) async {
    try {
      await _apiClient.dio.post(
        '/orders/$orderId/assign',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _apiClient.dio.post(
        '/orders/$orderId/cancel',
        data: {if (reason != null) 'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> respondToOrder(
    String orderId, {
    required bool accept,
    String? note,
  }) async {
    try {
      await _apiClient.dio.post(
        '/orders/$orderId/respond',
        data: {
          'accept': accept,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateOrderStatus(
    String orderId, {
    required String status,
    String? remarks,
  }) async {
    try {
      await _apiClient.dio.post(
        '/orders/$orderId/status',
        data: {
          'status': status,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<OrderCommentData>> getComments(
    String orderId,
    String channel,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/orders/$orderId/comments/$channel',
      );
      return (response.data as List)
          .map((item) => OrderCommentData.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> addComment(
    String orderId, {
    required String channel,
    required String message,
  }) async {
    try {
      await _apiClient.dio.post(
        '/orders/$orderId/comments',
        data: {'channel': channel, 'message': message},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<OrderEventData>> getEvents(String orderId) async {
    try {
      final response = await _apiClient.dio.get('/orders/$orderId/events');
      return (response.data as List)
          .map((item) => OrderEventData.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> uploadOrderItemImage(
    String orderItemId,
    String filePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
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

  Future<List<KarigarItem>> getKarigars() async {
    try {
      final response = await _apiClient.dio.get(
        '/karigars',
        queryParameters: {'activeOnly': true, 'pageSize': 50},
      );
      return (response.data['items'] as List)
          .map((e) => KarigarItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final response = await _apiClient.dio.get(
        '/items',
        queryParameters: {'pageSize': 100},
      );
      return List<Map<String, dynamic>>.from(response.data['items']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
