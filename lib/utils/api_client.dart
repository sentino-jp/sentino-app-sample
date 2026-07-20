import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'app_config.dart';
import 'storage.dart';

/// IANA timezone mapping by UTC offset
/// Used when system returns non-ASCII timezone name (e.g. Chinese Windows)
const _offsetToIana = {
  8: 'Asia/Shanghai',
  9: 'Asia/Tokyo',
  -5: 'America/New_York',
  -6: 'America/Chicago',
  -7: 'America/Denver',
  -8: 'America/Los_Angeles',
  0: 'Europe/London',
  1: 'Europe/Paris',
  2: 'Europe/Berlin',
  3: 'Europe/Moscow',
  5: 'Asia/Kolkata',
  7: 'Asia/Bangkok',
  10: 'Australia/Sydney',
  12: 'Pacific/Auckland',
};

/// API base response structure
/// Server returns: {"reqId":"...", "time":..., "code":200, "message":"成功", "data":...}
class ApiResponse<T> {
  final int code;
  final String? message;
  final T? data;
  final String? reqId;

  ApiResponse({required this.code, this.message, this.data, this.reqId});

  bool get isSuccess => code == 200;

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromData) {
    return ApiResponse(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? json['msg'] as String?,
      reqId: json['reqId'] as String?,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'] as T?,
    );
  }
}

/// API exception with business error code and message
class ApiException implements Exception {
  final int? httpStatus;
  final int? bizCode;
  final String message;

  ApiException({this.httpStatus, this.bizCode, required this.message});

  @override
  String toString() => message;
}

/// Dio API client with common request headers
class ApiClient {
  late final Dio _dio;
  final StorageUtil _storage;
  String _language;
  String? _deviceId;

  /// 当检测到需要强制登出的错误码时触发（如 11013、401）
  VoidCallback? onForceLogout;

  ApiClient({
    required String baseUrl,
    required StorageUtil storage,
    String language = 'en_US',
  })  : _storage = storage,
        _language = language {
    // Ensure baseUrl ends with '/' for proper path joining
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    _dio = Dio(BaseOptions(
      baseUrl: normalizedBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Dio get dio => _dio;

  /// Update language parameter
  void setLanguage(String language) {
    _language = language;
  }

  /// Set device unique ID (androidId / identifierForVendor)
  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  /// Device info for UA header
  /// Format: brand|model|os|resolution|deviceName (same as Android SDK)
  String _brand = '';
  String _model = '';
  String _resolution = '';
  String _deviceName = '';

  /// Set device info for UA header
  /// Call this after obtaining device info (e.g. via device_info_plus)
  void setDeviceInfo({
    required String brand,
    required String model,
    required String resolution,
    required String deviceName,
  }) {
    _brand = brand;
    _model = model;
    _resolution = resolution;
    _deviceName = deviceName;
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = options.headers;

    // Authorization
    final token = _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // client_id - base64(clientId:clientSecret)
    _setIfNotEmpty(headers, 'client_id', AppConfig.clientId);

    // app_id
    _setIfNotEmpty(headers, 'app_id', AppConfig.appId);

    // channel_identifier
    _setIfNotEmpty(headers, 'channel_identifier', AppConfig.channelIdentifier);

    // data_center_code
    _setIfNotEmpty(headers, 'data_center_code', AppConfig.dataCenterCode);

    // language (zh_CN | en_US | ja_JP)
    _setIfNotEmpty(headers, 'language', _language);

    // os_name (android | ios)
    headers['os_name'] = AppConfig.osName;

    // version - app version
    headers['version'] = AppConfig.appVersion;

    // devid - device unique identifier
    if (_deviceId != null && _deviceId!.isNotEmpty) {
      headers['devid'] = _deviceId;
    }

    // ua - UserAgent: brand|model|os|resolution|device
    headers['ua'] = _buildUserAgent();

    // package_name
    headers['package_name'] = AppConfig.packageName;

    // request_id - unique request ID
    headers['request_id'] = const Uuid().v4();

    // timezone - system timezone (e.g. "Asia/Shanghai")
    // Use timeZoneOffset to build a standard timezone ID, avoid non-ASCII characters
    headers['timezone'] = _getTimezone();

    // encrypt_type
    headers['encrypt_type'] = AppConfig.encryptType;

    handler.next(options);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint('ApiClient error: ${error.type} ${error.message} ${error.requestOptions.uri}');
    if (error.response?.statusCode == 401) {
      // coucou 模式:flutter 持 dragonflow JWT,cetus(api-iot) 401 属正常(无 cetus token),
      // 绝不能清 dragonflow token/登出——否则登录后被 cetus 401 踢回登录页。
      if (!_storage.isCoucouMode) {
        _storage.removeAccessToken();
        _storage.removeUserId();
        onForceLogout?.call();
      }
    }
    handler.next(error);
  }

  /// Parse HTTP error to user-friendly message
  String _parseHttpError(DioException e) {
    final status = e.response?.statusCode;
    // Try to extract message from response body
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['msg'] ?? 'Request failed ($status)';
      }
    } catch (_) {}

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.connectionError:
        return 'Connection error';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        if (status != null) {
          return 'Request failed ($status)';
        }
        return e.message ?? 'Network request failed';
    }
  }

  /// POST request with full error handling
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromData,
  }) async {
    final normalizedPath = _normalizePath(path);
    try {
      final response = await _dio.post(
        normalizedPath,
        data: data,
        queryParameters: queryParameters,
      );

      // HTTP 200 — parse business response
      final apiResp = ApiResponse.fromJson(
          response.data as Map<String, dynamic>, fromData);

      // Business code check
      if (!apiResp.isSuccess) {
        // 11013: token 失效，强制登出(coucou 模式除外——dragonflow token 不受 cetus session 影响)
        if (apiResp.code == 11013 && !_storage.isCoucouMode) {
          _storage.removeAccessToken();
          _storage.removeUserId();
          onForceLogout?.call();
        }
        throw ApiException(
          httpStatus: response.statusCode,
          bizCode: apiResp.code,
          message: apiResp.message ?? 'Request failed',
        );
      }
      return apiResp;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        httpStatus: e.response?.statusCode,
        message: _parseHttpError(e),
      );
    } catch (e) {
      debugPrint('ApiClient.post error: $e');
      throw ApiException(message: e.toString());
    }
  }

  /// POST form-urlencoded request (for OAuth login)
  Future<ApiResponse<T>> postForm<T>(
    String path, {
    required Map<String, dynamic> data,
    T Function(dynamic)? fromData,
  }) async {
    final normalizedPath = _normalizePath(path);
    try {
      final formBody = data.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key.toString())}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');

      final response = await _dio.post(
        normalizedPath,
        data: formBody,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'scope': AppConfig.scope,
            'Authorization': 'Basic ${AppConfig.clientId}',
          },
        ),
      );

      final apiResp = ApiResponse.fromJson(
          response.data as Map<String, dynamic>, fromData);

      if (!apiResp.isSuccess) {
        throw ApiException(
          httpStatus: response.statusCode,
          bizCode: apiResp.code,
          message: apiResp.message ?? 'Request failed',
        );
      }
      return apiResp;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        httpStatus: e.response?.statusCode,
        message: _parseHttpError(e),
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Normalize API path: strip leading '/' to avoid double slash with baseUrl
  /// e.g. "business-app/v1/xxx" → "business-app/v1/xxx"
  ///      "/business-app/v1/xxx" → "business-app/v1/xxx"
  String _normalizePath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// Get IANA timezone name (e.g. "Asia/Shanghai")
  /// Falls back to offset-based IANA lookup if system returns non-ASCII name
  String _getTimezone() {
    final name = DateTime.now().timeZoneName;
    // If name is ASCII-safe and looks like IANA (contains '/'), use directly
    if (name.contains('/') &&
        name.codeUnits.every((c) => c >= 0x20 && c <= 0x7E)) {
      return name;
    }
    // Map UTC offset to IANA timezone name
    final hours = DateTime.now().timeZoneOffset.inHours;
    return _offsetToIana[hours] ?? 'Asia/Shanghai';
  }

  /// Build UserAgent string
  /// Format: brand|model|os|resolution|deviceName, then Base64 encoded
  /// Same rule as Android SDK RequestHeaderUtils.getUaHeader()
  String _buildUserAgent() {
    final brand = _brand.isNotEmpty ? _brand : 'Flutter';
    final model = _model.isNotEmpty ? _model : AppConfig.osName;
    final os = AppConfig.osName;
    final resolution = _resolution.isNotEmpty ? _resolution : '0x0';
    final deviceName = _deviceName.isNotEmpty ? _deviceName : 'unknown';
    final raw = '$brand|$model|$os|$resolution|$deviceName';
    return base64Encode(utf8.encode(raw));
  }

  /// Set header only if value is not empty
  void _setIfNotEmpty(
      Map<String, dynamic> headers, String key, String value) {
    if (value.isNotEmpty) {
      headers[key] = value;
    }
  }
}
