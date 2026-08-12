import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class MasterRepository {
  final ApiClient _apiClient;

  MasterRepository(this._apiClient);

  // Customers
  Future<List<CustomerData>> getCustomers({String? search}) async {
    try {
      final response = await _apiClient.dio.get('/customers', queryParameters: {
        if (search != null) 'search': search,
        'pageSize': 50,
      });
      return (response.data['items'] as List)
          .map((e) => CustomerData.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerData> createCustomer({
    required String name,
    String? mobile,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post('/customers', data: {
        'name': name,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      });
      return CustomerData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Karigars
  Future<List<KarigarData>> getKarigars() async {
    try {
      final response = await _apiClient.dio.get('/karigars', queryParameters: {
        'activeOnly': true,
        'pageSize': 50,
      });
      return (response.data['items'] as List)
          .map((e) => KarigarData.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<KarigarData> createKarigar({
    required String name,
    required String mobile,
    String? email,
    String? specialization,
    bool createLogin = false,
    String? password,
  }) async {
    try {
      final response = await _apiClient.dio.post('/karigars', data: {
        'name': name,
        'mobile': mobile,
        if (email != null) 'email': email,
        if (specialization != null) 'specialization': specialization,
        'createLogin': createLogin,
        if (password != null) 'password': password,
      });
      return KarigarData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class CustomerData {
  final String id;
  final String name;
  final String? mobile;
  final String? email;
  final String? address;

  CustomerData({required this.id, required this.name, this.mobile, this.email, this.address});

  factory CustomerData.fromJson(Map<String, dynamic> json) => CustomerData(
        id: json['id'],
        name: json['name'],
        mobile: json['mobile'],
        email: json['email'],
        address: json['address'],
      );
}

class KarigarData {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? specialization;
  final String status;
  final bool hasLoginAccess;

  KarigarData({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.specialization,
    required this.status,
    required this.hasLoginAccess,
  });

  factory KarigarData.fromJson(Map<String, dynamic> json) => KarigarData(
        id: json['id'],
        name: json['name'],
        mobile: json['mobile'],
        email: json['email'],
        specialization: json['specialization'],
        status: json['status'],
        hasLoginAccess: json['hasLoginAccess'] ?? false,
      );
}
