class CreateOrderRequest {
  final String? orderFromBusinessId;
  final String? orderFromExternalBusinessId;
  final String? orderToBusinessId;
  final String? orderDate;
  final String? deliveryDate;
  final String? notes;
  final double advancePaid;
  final List<OrderItemRequest> items;

  CreateOrderRequest({
    this.orderFromBusinessId,
    this.orderFromExternalBusinessId,
    this.orderToBusinessId,
    this.orderDate,
    this.deliveryDate,
    this.notes,
    this.advancePaid = 0,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    if (orderFromBusinessId != null) 'orderFromBusinessId': orderFromBusinessId,
    if (orderFromExternalBusinessId != null)
      'orderFromExternalBusinessId': orderFromExternalBusinessId,
    if (orderToBusinessId != null) 'orderToBusinessId': orderToBusinessId,
    if (orderDate != null) 'orderDate': orderDate,
    if (deliveryDate != null) 'deliveryDate': deliveryDate,
    if (notes != null) 'notes': notes,
    'advancePaid': advancePaid,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class OrderItemRequest {
  final String? id;
  final String? itemMasterId;
  final String itemName;
  final double weight;
  final int quantity;
  final String? purity;
  final double rate;
  final double makingCharge;
  final double amount;
  final String? size;

  OrderItemRequest({
    this.id,
    this.itemMasterId,
    required this.itemName,
    this.weight = 0,
    this.quantity = 1,
    this.purity,
    this.rate = 0,
    this.makingCharge = 0,
    this.amount = 0,
    this.size,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (itemMasterId != null) 'itemMasterId': itemMasterId,
    'itemName': itemName,
    'weight': weight,
    'quantity': quantity,
    if (purity != null) 'purity': purity,
    'rate': rate,
    'makingCharge': makingCharge,
    'amount': amount,
    if (size != null) 'size': size,
  };
}

class AssignKarigarRequest {
  final String karigarId;
  final String givenDate;
  final String dueDate;
  final String? notes;

  AssignKarigarRequest({
    required this.karigarId,
    required this.givenDate,
    required this.dueDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'karigarId': karigarId,
    'givenDate': givenDate,
    'dueDate': dueDate,
    if (notes != null) 'notes': notes,
  };
}

class OrderDetail {
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
  final String source;
  final String acceptanceStatus;
  final String orderFromBusinessName;
  final String createdByBusinessName;
  final String createdForBusinessName;
  final List<OrderItemDetail> items;
  final List<AssignmentDetail> assignments;

  OrderDetail({
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
    this.source = 'Direct',
    this.acceptanceStatus = 'Accepted',
    this.orderFromBusinessName = '',
    this.createdByBusinessName = '',
    this.createdForBusinessName = '',
    required this.items,
    required this.assignments,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
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
      source: json['source'] ?? 'Direct',
      acceptanceStatus: json['acceptanceStatus'] ?? 'Accepted',
      orderFromBusinessName: json['orderFromBusinessName'] ?? '',
      createdByBusinessName: json['createdByBusinessName'] ?? '',
      createdForBusinessName: json['createdForBusinessName'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((e) => OrderItemDetail.fromJson(e))
              .toList() ??
          [],
      assignments:
          (json['assignments'] as List?)
              ?.map((e) => AssignmentDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class OrderItemDetail {
  final String id;
  final String? itemMasterId;
  final String itemName;
  final double weight;
  final int quantity;
  final String? purity;
  final double rate;
  final double makingCharge;
  final double amount;
  final String? size;
  final String? imagePath;

  OrderItemDetail({
    required this.id,
    this.itemMasterId,
    required this.itemName,
    required this.weight,
    required this.quantity,
    this.purity,
    required this.rate,
    required this.makingCharge,
    required this.amount,
    this.size,
    this.imagePath,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      id: json['id'],
      itemMasterId: json['itemMasterId'],
      itemName: json['itemName'],
      weight: (json['weight'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      purity: json['purity'],
      rate: (json['rate'] ?? 0).toDouble(),
      makingCharge: (json['makingCharge'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      size: json['size'],
      imagePath: json['imagePath'],
    );
  }
}

class AssignmentDetail {
  final String id;
  final String karigarName;
  final String karigarId;
  final String givenDate;
  final String dueDate;
  final String status;
  final String? notes;
  final bool isActive;

  AssignmentDetail({
    required this.id,
    required this.karigarName,
    required this.karigarId,
    required this.givenDate,
    required this.dueDate,
    required this.status,
    this.notes,
    required this.isActive,
  });

  factory AssignmentDetail.fromJson(Map<String, dynamic> json) {
    return AssignmentDetail(
      id: json['id'],
      karigarName: json['karigarName'],
      karigarId: json['karigarId'],
      givenDate: json['givenDate'],
      dueDate: json['dueDate'],
      status: json['status'],
      notes: json['notes'],
      isActive: json['isActive'] ?? false,
    );
  }
}

class OrderCommentData {
  final String id;
  final String authorBusinessName;
  final String channel;
  final String message;
  final DateTime createdAt;

  const OrderCommentData({
    required this.id,
    required this.authorBusinessName,
    required this.channel,
    required this.message,
    required this.createdAt,
  });

  factory OrderCommentData.fromJson(Map<String, dynamic> json) =>
      OrderCommentData(
        id: json['id'],
        authorBusinessName: json['authorBusinessName'],
        channel: json['channel'],
        message: json['message'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class OrderEventData {
  final String eventType;
  final String description;
  final String businessName;
  final DateTime occurredAt;

  const OrderEventData({
    required this.eventType,
    required this.description,
    required this.businessName,
    required this.occurredAt,
  });

  factory OrderEventData.fromJson(Map<String, dynamic> json) => OrderEventData(
    eventType: json['eventType'],
    description: json['description'],
    businessName: json['businessName'],
    occurredAt: DateTime.parse(json['occurredAt']),
  );
}

class KarigarItem {
  final String id;
  final String name;
  final String? specialization;

  KarigarItem({required this.id, required this.name, this.specialization});

  factory KarigarItem.fromJson(Map<String, dynamic> json) => KarigarItem(
    id: json['id'],
    name: json['name'],
    specialization: json['specialization'],
  );
}
