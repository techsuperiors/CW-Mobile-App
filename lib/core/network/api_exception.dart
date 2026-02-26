import '../error/exceptions.dart';

/// API Exception - extends AppException for consistency
class ApiException extends AppException {
  final int statusCode;

  ApiException(this.statusCode, String message) : super(message);

  @override
  String toString() => message;
}

/// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final ApiException? error;

  ApiResponse({this.data, this.error});

  bool get isSuccess => data != null && error == null;
}

