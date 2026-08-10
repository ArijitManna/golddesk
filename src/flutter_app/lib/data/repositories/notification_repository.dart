import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationItem>> getNotifications({bool? unreadOnly}) async {
    try {
      final response = await _apiClient.dio.get('/notifications', queryParameters: {
        if (unreadOnly != null) 'unreadOnly': unreadOnly,
        'pageSize': 50,
      });
      return (response.data['items'] as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class NotificationItem {
  final String id;
  final String? orderId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationItem({
    required this.id,
    this.orderId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'],
        orderId: json['orderId'],
        type: json['type'],
        title: json['title'],
        message: json['message'],
        isRead: json['isRead'] ?? false,
        createdAt: json['createdAt'],
      );
}
