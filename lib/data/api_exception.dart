import 'package:dio/dio.dart';

/// A single normalized error shape for the whole app.
///
/// The backend is inconsistent: `LoginView` returns `{"error": "..."}` while
/// serializer validation returns per-field arrays `{"field": ["msg", ...]}`.
/// This class flattens both into one [message] plus optional [fieldErrors]
/// so forms can highlight individual inputs.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;

  /// Build from a raw DRF error body (either shape).
  factory ApiException.fromResponse(
    dynamic data,
    int? status,
  ) {
    if (data is Map) {
      // {"error": "..."} or {"detail": "..."}
      final single = data['error'] ?? data['detail'] ?? data['message'];
      if (single != null && data.length == 1) {
        return ApiException(single.toString(), statusCode: status);
      }

      // Per-field arrays: {"username": ["already taken"], ...}
      final fieldErrors = <String, String>{};
      final messages = <String>[];
      data.forEach((key, value) {
        final text = value is List
            ? value.map((e) => e.toString()).join(' ')
            : value.toString();
        if (key == 'error' || key == 'detail' || key == 'message') {
          messages.add(text);
        } else {
          fieldErrors[key.toString()] = text;
          messages.add(text);
        }
      });
      return ApiException(
        messages.isEmpty ? 'Something went wrong.' : messages.join('\n'),
        statusCode: status,
        fieldErrors: fieldErrors,
      );
    }
    return ApiException(
      data?.toString() ?? 'Something went wrong.',
      statusCode: status,
    );
  }

  /// Translate a Dio error into an [ApiException].
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException('The connection timed out. Try again.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'No connection. Check your internet and try again.',
        );
      default:
        final res = e.response;
        if (res != null) {
          return ApiException.fromResponse(res.data, res.statusCode);
        }
        return const ApiException('Something went wrong. Please try again.');
    }
  }
}
