class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'GoldDesk';
  static const String appTagline = 'Digital Partner for Gold Shop';
  static const String appVersion = '1.0.0';

  // API
  // Use 'http://localhost:5282' for Android emulator
  // Use 'http://localhost:5282' for iOS simulator or web
  // Use 'http://192.168.x.x:5282' for physical device
  // Production: 'http://162.35.185.106:8082'
  static const String serverUrl = 'http://162.35.185.106:8082';
  static const String baseUrl = '$serverUrl/api';

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
