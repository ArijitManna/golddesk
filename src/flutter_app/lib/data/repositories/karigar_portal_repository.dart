import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class KarigarPortalRepository {
  final ApiClient _apiClient;

  KarigarPortalRepository(this._apiClient);

  Future<KarigarDashboardData> getDashboard() async {
    try {
      final response = await _apiClient.dio.get('/karigar/dashboard');
      return KarigarDashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<KarigarOrderItem>> getMyOrders({
    String? status,
    String? assignmentStatus,
    String? due,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/karigar/orders',
        queryParameters: {
          if (status != null) 'status': status,
          if (assignmentStatus != null) 'assignmentStatus': assignmentStatus,
          if (due != null) 'due': due,
          'pageSize': 50,
        },
      );
      return (response.data['items'] as List)
          .map((e) => KarigarOrderItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateStatus(
    String orderId,
    String status, {
    String? notes,
  }) async {
    try {
      await _apiClient.dio.post(
        '/orders/$orderId/karigar-update',
        data: {'status': status, if (notes != null) 'progressNotes': notes},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> acceptWork(String orderId) async {
    try {
      await _apiClient.dio.post('/orders/$orderId/assignment/accept');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class KarigarDashboardData {
  final int totalAssigned;
  final int newWork;
  final int workAccepted;
  final int inProgress;
  final int dueToday;
  final int dueSoon;
  final int overdue;
  final int ready;
  final List<KarigarOrderItem> dueSoonOrders;
  final List<KarigarOrderItem> recentOrders;

  KarigarDashboardData({
    required this.totalAssigned,
    required this.newWork,
    required this.workAccepted,
    required this.inProgress,
    required this.dueToday,
    required this.dueSoon,
    required this.overdue,
    required this.ready,
    required this.dueSoonOrders,
    required this.recentOrders,
  });

  factory KarigarDashboardData.fromJson(Map<String, dynamic> json) =>
      KarigarDashboardData(
        totalAssigned: json['totalAssigned'] ?? 0,
        newWork: json['newWork'] ?? 0,
        workAccepted: json['workAccepted'] ?? 0,
        inProgress: json['inProgress'] ?? 0,
        dueToday: json['dueToday'] ?? 0,
        dueSoon: json['dueSoon'] ?? 0,
        overdue: json['overdue'] ?? 0,
        ready: json['ready'] ?? 0,
        dueSoonOrders:
            (json['dueSoonOrders'] as List?)
                ?.map((e) => KarigarOrderItem.fromJson(e))
                .toList() ??
            [],
        recentOrders:
            (json['recentOrders'] as List?)
                ?.map((e) => KarigarOrderItem.fromJson(e))
                .toList() ??
            [],
      );
}

class KarigarOrderItem {
  final String orderId;
  final String orderNo;
  final String orderFromBusinessName;
  final String sourceShopName;
  final String status;
  final String assignmentStatus;
  final String dueDate;
  final int daysLeft;
  final String? notes;
  final double totalWeight;

  KarigarOrderItem({
    required this.orderId,
    required this.orderNo,
    required this.orderFromBusinessName,
    required this.sourceShopName,
    required this.status,
    required this.assignmentStatus,
    required this.dueDate,
    required this.daysLeft,
    this.notes,
    required this.totalWeight,
  });

  factory KarigarOrderItem.fromJson(Map<String, dynamic> json) =>
      KarigarOrderItem(
        orderId: json['orderId'],
        orderNo: json['orderNo'],
        orderFromBusinessName: json['orderFromBusinessName'],
        sourceShopName: json['sourceShopName'] ?? '',
        status: json['status'],
        assignmentStatus: json['assignmentStatus'] ?? 'Active',
        dueDate: json['dueDate'],
        daysLeft: json['daysLeft'] ?? 0,
        notes: json['notes'],
        totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      );
}
