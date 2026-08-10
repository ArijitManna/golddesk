import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your internet.',
          statusCode: null,
        );
      case DioExceptionType.badResponse:
        return _handleResponse(error.response);
      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return ApiException(message: 'No internet connection');
      default:
        return ApiException(message: 'Something went wrong. Please try again.');
    }
  }

  static ApiException _handleResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      message = data['error'];
    } else if (data is Map<String, dynamic> && data.containsKey('message')) {
      message = data['message'];
    } else {
      switch (statusCode) {
        case 400:
          message = 'Invalid request';
          break;
        case 401:
          message = 'Invalid email or password';
          break;
        case 403:
          message = 'You do not have permission to perform this action';
          break;
        case 404:
          message = 'Resource not found';
          break;
        case 409:
          message = 'This already exists';
          break;
        case 422:
          message = 'Validation failed';
          break;
        case 500:
          message = 'Server error. Please try again later.';
          break;
        default:
          message = 'Something went wrong';
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  @override
  String toString() => message;
}
