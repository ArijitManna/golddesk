class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'GoldDesk';
  static const String appTagline = 'Digital Partner for Gold Shop';
  static const String appVersion = '1.0.0';

  // API
  // Use 'http://10.0.2.2:5282/api' for Android emulator
  // Use 'http://localhost:5282/api' for iOS simulator or web
  // Use your machine's IP (e.g., 'http://192.168.x.x:5282/api') for physical device
  static const String baseUrl = 'http://10.0.2.2:5282/api';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String tenantDataKey = 'tenant_data';

  // Pagination
  static const int defaultPageSize = 20;

  // Date Formats
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String apiDateFormat = 'yyyy-MM-dd';

  // Order Number Prefix
  static const String orderPrefix = 'ORD-';
}
