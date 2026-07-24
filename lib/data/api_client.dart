import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin Dio wrapper that attaches the bearer token, transparently refreshes
/// on 401 (retry once), and normalizes every error into an [ApiException].
///
/// The mock services don't use this yet — it's the seam the real services
/// plug into once endpoints are provided. Nothing else in the app talks to
/// Dio directly.
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokens;
  bool _refreshing = false;

  ApiClient({Dio? dio, TokenStorage? tokens})
      : _tokens = tokens ?? TokenStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: {'Accept': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['auth'] != false) {
            final token = await _tokens.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final shouldRefresh = error.response?.statusCode == 401 &&
              error.requestOptions.extra['retried'] != true &&
              !_refreshing;
          if (shouldRefresh) {
            final ok = await _tryRefresh();
            if (ok) {
              try {
                final opts = error.requestOptions;
                opts.extra['retried'] = true;
                final token = await _tokens.accessToken;
                opts.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // fall through to the original error
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefresh() async {
    _refreshing = true;
    try {
      final refresh = await _tokens.refreshToken;
      if (refresh == null || refresh.isEmpty) return false;
      final res = await _dio.post(
        ApiConstants.tokenRefresh,
        data: {'refresh': refresh},
        options: Options(extra: {'auth': false}),
      );
      final access = res.data?['access']?.toString();
      if (access != null && access.isNotEmpty) {
        await _tokens.updateAccess(access);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<Response<dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    return _guard(() => _dio.get(path, queryParameters: query));
  }

  Future<Response<dynamic>> post(String path,
      {dynamic data, bool auth = true}) async {
    return _guard(
      () => _dio.post(path, data: data, options: Options(extra: {'auth': auth})),
    );
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) async {
    return _guard(() => _dio.put(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) async {
    return _guard(() => _dio.patch(path, data: data));
  }

  Future<Response<dynamic>> _guard(
      Future<Response<dynamic>> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
