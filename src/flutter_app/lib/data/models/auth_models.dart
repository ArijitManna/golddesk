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

  RegisterRequest({
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.password,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'ownerName': ownerName,
        'mobile': mobile,
        'email': email,
        'password': password,
        if (address != null) 'address': address,
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

  UserInfo({
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.shopName,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        userId: json['userId'],
        tenantId: json['tenantId'],
        email: json['email'],
        fullName: json['fullName'],
        role: json['role'],
        shopName: json['shopName'],
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'tenantId': tenantId,
        'email': email,
        'fullName': fullName,
        'role': role,
        'shopName': shopName,
      };

  UserInfo copyWith({
    String? userId,
    String? tenantId,
    String? email,
    String? fullName,
    String? role,
    String? shopName,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
    );
  }
}

class RegisterResponse {
  final String tenantId;
  final String userId;
  final String message;

  RegisterResponse({
    required this.tenantId,
    required this.userId,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        tenantId: json['tenantId'],
        userId: json['userId'],
        message: json['message'],
      );
}
