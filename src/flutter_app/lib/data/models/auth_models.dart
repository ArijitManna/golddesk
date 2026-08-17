class LoginRequest {
  final String email;
  final String password;
  final String? fcmToken;

  LoginRequest({required this.email, required this.password, this.fcmToken});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };
}

class RegisterRequest {
  final String shopName;
  final String ownerName;
  final String mobile;
  final String email;
  final String password;
  final String? address;
  final String businessType;

  RegisterRequest({
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.password,
    this.address,
    required this.businessType,
  });

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'ownerName': ownerName,
        'mobile': mobile,
        'email': email,
        'password': password,
        if (address != null) 'address': address,
        'businessType': businessType,
      };
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final UserInfo user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        expiresAt: DateTime.parse(json['expiresAt']),
        user: UserInfo.fromJson(json['user']),
      );
}

class UserInfo {
  final String userId;
  final String tenantId;
  final String email;
  final String fullName;
  final String role;
  final String shopName;
  final String businessType;
  final String goldDeskId;

  UserInfo({
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.shopName,
    required this.businessType,
    required this.goldDeskId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        userId: json['userId'],
        tenantId: json['tenantId'],
        email: json['email'],
        fullName: json['fullName'],
        role: json['role'],
        shopName: json['shopName'],
        businessType: json['businessType'] ?? 'Shop',
        goldDeskId: json['goldDeskId'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'tenantId': tenantId,
        'email': email,
        'fullName': fullName,
        'role': role,
        'shopName': shopName,
        'businessType': businessType,
        'goldDeskId': goldDeskId,
      };

  UserInfo copyWith({
    String? userId,
    String? tenantId,
    String? email,
    String? fullName,
    String? role,
    String? shopName,
    String? businessType,
    String? goldDeskId,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
      businessType: businessType ?? this.businessType,
      goldDeskId: goldDeskId ?? this.goldDeskId,
    );
  }
}

class RegisterResponse {
  final String tenantId;
  final String userId;
  final String goldDeskId;
  final String message;

  RegisterResponse({
    required this.tenantId,
    required this.userId,
    required this.goldDeskId,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        tenantId: json['tenantId'],
        userId: json['userId'],
        goldDeskId: json['goldDeskId'] ?? '',
        message: json['message'],
      );
}
