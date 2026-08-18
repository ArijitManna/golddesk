class BusinessSummary {
  final String id;
  final String name;
  final String goldDeskId;
  final String businessType;
  final String? mobile;
  final String? address;

  const BusinessSummary({
    required this.id,
    required this.name,
    required this.goldDeskId,
    required this.businessType,
    this.mobile,
    this.address,
  });

  factory BusinessSummary.fromJson(Map<String, dynamic> json) =>
      BusinessSummary(
        id: json['id'],
        name: json['name'],
        goldDeskId: json['goldDeskId'],
        businessType: json['businessType'],
        mobile: json['mobile'],
        address: json['address'],
      );
}

class BusinessConnection {
  final String id;
  final String counterpartyBusinessId;
  final String counterpartyName;
  final String counterpartyGoldDeskId;
  final String counterpartyBusinessType;
  final String connectionType;
  final String status;
  final bool isIncoming;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const BusinessConnection({
    required this.id,
    required this.counterpartyBusinessId,
    required this.counterpartyName,
    required this.counterpartyGoldDeskId,
    required this.counterpartyBusinessType,
    required this.connectionType,
    required this.status,
    required this.isIncoming,
    required this.createdAt,
    this.acceptedAt,
  });

  factory BusinessConnection.fromJson(Map<String, dynamic> json) =>
      BusinessConnection(
        id: json['id'],
        counterpartyBusinessId: json['counterpartyBusinessId'],
        counterpartyName: json['counterpartyName'],
        counterpartyGoldDeskId: json['counterpartyGoldDeskId'],
        counterpartyBusinessType: json['counterpartyBusinessType'],
        connectionType: json['connectionType'],
        status: json['status'],
        isIncoming: json['isIncoming'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        acceptedAt: json['acceptedAt'] == null
            ? null
            : DateTime.parse(json['acceptedAt']),
      );
}

class ExternalBusiness {
  final String id;
  final String customerCode;
  final String name;
  final String businessType;
  final String? contactPerson;
  final String? mobile;
  final String? email;
  final String? linkedBusinessId;

  const ExternalBusiness({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.businessType,
    this.contactPerson,
    this.mobile,
    this.email,
    this.linkedBusinessId,
  });

  factory ExternalBusiness.fromJson(Map<String, dynamic> json) =>
      ExternalBusiness(
        id: json['id'],
        customerCode: json['customerCode'] ?? '',
        name: json['name'],
        businessType: json['businessType'],
        contactPerson: json['contactPerson'],
        mobile: json['mobile'],
        email: json['email'],
        linkedBusinessId: json['linkedBusinessId'],
      );
}
