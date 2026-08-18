class ShopDashboardData {
  final int totalOrders;
  final int fromShowrooms;
  final int directOrders;
  final int pending;
  final int assigned;
  final int inProgress;
  final int dueToday;
  final int dueNext3Days;
  final int overdue;
  final int ready;
  final int unassigned;
  final int activeKarigars;
  final String businessType;
  final List<BusinessOrderCount> connectedShops;
  final List<BusinessOrderCount> connectedShowrooms;
  final List<BusinessOrderCount> externalCustomers;
  final List<OrderSummary> recentOrders;
  final List<OrderSummary> overdueOrders;

  ShopDashboardData({
    required this.totalOrders,
    required this.fromShowrooms,
    required this.directOrders,
    required this.pending,
    required this.assigned,
    required this.inProgress,
    required this.dueToday,
    required this.dueNext3Days,
    required this.overdue,
    required this.ready,
    required this.unassigned,
    required this.activeKarigars,
    required this.businessType,
    required this.connectedShops,
    required this.connectedShowrooms,
    required this.externalCustomers,
    required this.recentOrders,
    required this.overdueOrders,
  });

  factory ShopDashboardData.fromJson(Map<String, dynamic> json) {
    return ShopDashboardData(
      totalOrders: json['totalOrders'] ?? 0,
      fromShowrooms: json['fromShowrooms'] ?? 0,
      directOrders: json['directOrders'] ?? 0,
      pending: json['pending'] ?? 0,
      assigned: json['assigned'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
      dueToday: json['dueToday'] ?? 0,
      dueNext3Days: json['dueNext3Days'] ?? 0,
      overdue: json['overdue'] ?? 0,
      ready: json['ready'] ?? 0,
      unassigned: json['unassigned'] ?? 0,
      activeKarigars: json['activeKarigars'] ?? 0,
      businessType: json['businessType'] ?? 'Shop',
      connectedShops:
          (json['connectedShops'] as List?)
              ?.map((e) => BusinessOrderCount.fromJson(e))
              .toList() ??
          [],
      connectedShowrooms:
          (json['connectedShowrooms'] as List?)
              ?.map((e) => BusinessOrderCount.fromJson(e))
              .toList() ??
          [],
      externalCustomers:
          (json['externalCustomers'] as List?)
              ?.map((e) => BusinessOrderCount.fromJson(e))
              .toList() ??
          [],
      recentOrders:
          (json['recentOrders'] as List?)
              ?.map((e) => OrderSummary.fromJson(e))
              .toList() ??
          [],
      overdueOrders:
          (json['overdueOrders'] as List?)
              ?.map((e) => OrderSummary.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BusinessOrderCount {
  final String businessId;
  final String businessName;
  final String? code;
  final int orderCount;

  const BusinessOrderCount({
    required this.businessId,
    required this.businessName,
    this.code,
    required this.orderCount,
  });

  factory BusinessOrderCount.fromJson(Map<String, dynamic> json) =>
      BusinessOrderCount(
        businessId: json['businessId'],
        businessName: json['businessName'],
        code: json['code'],
        orderCount: json['orderCount'] ?? 0,
      );
}

class OrderSummary {
  final String id;
  final String orderNo;
  final String orderDate;
  final String? deliveryDate;
  final String status;
  final double totalWeight;
  final double makingCharges;
  final double advancePaid;
  final double estimatedAmount;
  final String? notes;
  final String? karigarName;
  final String? assignmentStatus;
  final String? dueDate;
  final String? firstItemImage;
  final String source;
  final String acceptanceStatus;
  final String orderFromBusinessName;
  final String createdByBusinessName;
  final String createdForBusinessName;

  OrderSummary({
    required this.id,
    required this.orderNo,
    required this.orderDate,
    this.deliveryDate,
    required this.status,
    required this.totalWeight,
    required this.makingCharges,
    required this.advancePaid,
    required this.estimatedAmount,
    this.notes,
    this.karigarName,
    this.assignmentStatus,
    this.dueDate,
    this.firstItemImage,
    this.source = 'Direct',
    this.acceptanceStatus = 'Accepted',
    this.orderFromBusinessName = '',
    this.createdByBusinessName = '',
    this.createdForBusinessName = '',
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'],
      orderNo: json['orderNo'],
      orderDate: json['orderDate'],
      deliveryDate: json['deliveryDate'],
      status: json['status'],
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      makingCharges: (json['makingCharges'] ?? 0).toDouble(),
      advancePaid: (json['advancePaid'] ?? 0).toDouble(),
      estimatedAmount: (json['estimatedAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      karigarName: json['karigarName'],
      assignmentStatus: json['assignmentStatus'],
      dueDate: json['dueDate'],
      firstItemImage: json['firstItemImage'],
      source: json['source'] ?? 'Direct',
      acceptanceStatus: json['acceptanceStatus'] ?? 'Accepted',
      orderFromBusinessName: json['orderFromBusinessName'] ?? '',
      createdByBusinessName: json['createdByBusinessName'] ?? '',
      createdForBusinessName: json['createdForBusinessName'] ?? '',
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
