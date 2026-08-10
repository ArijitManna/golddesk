class ShopDashboardData {
  final int totalOrders;
  final int pending;
  final int assigned;
  final int inProgress;
  final int dueToday;
  final int dueNext3Days;
  final int overdue;
  final int ready;
  final int unassigned;
  final int activeKarigars;
  final List<OrderSummary> recentOrders;
  final List<OrderSummary> overdueOrders;

  ShopDashboardData({
    required this.totalOrders,
    required this.pending,
    required this.assigned,
    required this.inProgress,
    required this.dueToday,
    required this.dueNext3Days,
    required this.overdue,
    required this.ready,
    required this.unassigned,
    required this.activeKarigars,
    required this.recentOrders,
    required this.overdueOrders,
  });

  factory ShopDashboardData.fromJson(Map<String, dynamic> json) {
    return ShopDashboardData(
      totalOrders: json['totalOrders'] ?? 0,
      pending: json['pending'] ?? 0,
      assigned: json['assigned'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
      dueToday: json['dueToday'] ?? 0,
      dueNext3Days: json['dueNext3Days'] ?? 0,
      overdue: json['overdue'] ?? 0,
      ready: json['ready'] ?? 0,
      unassigned: json['unassigned'] ?? 0,
      activeKarigars: json['activeKarigars'] ?? 0,
      recentOrders: (json['recentOrders'] as List?)
              ?.map((e) => OrderSummary.fromJson(e))
              .toList() ??
          [],
      overdueOrders: (json['overdueOrders'] as List?)
              ?.map((e) => OrderSummary.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class OrderSummary {
  final String id;
  final String orderNo;
  final String customerName;
  final String customerId;
  final String orderDate;
  final String? deliveryDate;
  final String status;
  final double totalWeight;
  final double makingCharges;
  final double advancePaid;
  final double estimatedAmount;
  final String? notes;
  final String? karigarName;
  final String? dueDate;
  final String? firstItemImage;

  OrderSummary({
    required this.id,
    required this.orderNo,
    required this.customerName,
    required this.customerId,
    required this.orderDate,
    this.deliveryDate,
    required this.status,
    required this.totalWeight,
    required this.makingCharges,
    required this.advancePaid,
    required this.estimatedAmount,
    this.notes,
    this.karigarName,
    this.dueDate,
    this.firstItemImage,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'],
      orderNo: json['orderNo'],
      customerName: json['customerName'],
      customerId: json['customerId'],
      orderDate: json['orderDate'],
      deliveryDate: json['deliveryDate'],
      status: json['status'],
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      makingCharges: (json['makingCharges'] ?? 0).toDouble(),
      advancePaid: (json['advancePaid'] ?? 0).toDouble(),
      estimatedAmount: (json['estimatedAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      karigarName: json['karigarName'],
      dueDate: json['dueDate'],
      firstItemImage: json['firstItemImage'],
    );
  }
}

class PagedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}
