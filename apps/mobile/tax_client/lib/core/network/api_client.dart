import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/exceptions.dart';
import 'package:tax_client/core/network/base_response.dart';
import 'package:tax_client/core/network/no_internet_notifier.dart';
import 'package:tax_client/core/network/logout_notifier.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/features/auth/data/models/refresh_token_data.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

class ApiClient {
  final Ref ref;
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  bool _tokenLoaded = false;
  Future<String?>? _refreshTokenFuture;

  ApiClient(this.ref, {this.baseUrl = ApiConstants.baseUrl})
    : defaultHeaders = {'Content-Type': 'application/json'};

  /// Set authorization token for authenticated requests
  void setAuthToken(String token) {
    defaultHeaders['Authorization'] = 'Bearer $token';
    _tokenLoaded = true;
  }

  /// Clear authorization token
  void clearAuthToken() {
    defaultHeaders.remove('Authorization');
    _tokenLoaded = false;
  }

  /// Load token from storage if not already loaded
  Future<void> _ensureTokenLoaded() async {
    if (!_tokenLoaded) {
      final tokenStorage = ref.read(tokenStorageProvider);
      final token = await tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        setAuthToken(token);
      }
    }
  }

  /// Log API request details
  void _logRequest(String method, String url, Map<String, String> headers, {String? body}) {
    if (kDebugMode) {
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ 🌐 API REQUEST');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Method: $method');
      print('║ URL: $url');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Headers:');
      headers.forEach((key, value) {
        // Mask the token for security
        if (key.toLowerCase() == 'authorization' && value.startsWith('Bearer ')) {
          final token = value.substring(7);
          final maskedToken = token.length > 20 
              ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
              : '***';
          print('║   $key: Bearer $maskedToken');
        } else {
          print('║   $key: $value');
        }
      });
      if (body != null && body.isNotEmpty) {
        print('╠════════════════════════════════════════════════════════════════');
        print('║ Body:');
        try {
          // Pretty print JSON
          final decoded = jsonDecode(body);
          final prettyJson = JsonEncoder.withIndent('  ').convert(decoded);
          prettyJson.split('\n').forEach((line) {
            print('║   $line');
          });
        } catch (e) {
          print('║   $body');
        }
      }
      print('╚════════════════════════════════════════════════════════════════\n');
    }
  }

  /// Log API response details
  void _logResponse(String method, String url, int statusCode, String body, {bool isRetry = false}) {
    if (kDebugMode) {
      final statusEmoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      final retryText = isRetry ? ' (RETRY)' : '';
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ $statusEmoji API RESPONSE$retryText');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Method: $method');
      print('║ URL: $url');
      print('║ Status: $statusCode');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Response Body:');
      if (body.isNotEmpty) {
        try {
          // Pretty print JSON
          final decoded = jsonDecode(body);
          final prettyJson = JsonEncoder.withIndent('  ').convert(decoded);
          prettyJson.split('\n').forEach((line) {
            print('║   $line');
          });
        } catch (e) {
          // If not JSON, print as is
          body.split('\n').forEach((line) {
            print('║   $line');
          });
        }
      } else {
        print('║   (empty)');
      }
      print('╚════════════════════════════════════════════════════════════════\n');
    }
  }

  Future<BaseResponse<T>> get<T>(
    String path,
    T Function(Map<String, dynamic>) parser, {
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    await _ensureInternet();
    await _ensureTokenLoaded();
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = {...defaultHeaders, ...?headers};
    
    // Log request
    _logRequest('GET', uri.toString(), requestHeaders);
    
    var res = await http.get(uri, headers: requestHeaders);
    
    // Log response
    _logResponse('GET', uri.toString(), res.statusCode, res.body);
    
    // Handle 401 and retry with refreshed token
    if (res.statusCode == 401 && retryOn401 && path != ApiConstants.authRefreshToken) {
      final newToken = await _refreshTokenIfNeeded();
      if (newToken != null) {
        // Update headers with new token and retry
        requestHeaders['Authorization'] = 'Bearer $newToken';
        
        // Log retry request
        _logRequest('GET', uri.toString(), requestHeaders);
        
        res = await http.get(uri, headers: requestHeaders);
        
        // Log retry response
        _logResponse('GET', uri.toString(), res.statusCode, res.body, isRetry: true);
      }
    }
    
    return _mapResponse(res, parser);
  }

  Future<BaseResponse<T>> post<T>(
    String path,
    Object body,
    T Function(Map<String, dynamic>) parser, {
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    await _ensureInternet();
    await _ensureTokenLoaded();
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = {...defaultHeaders, ...?headers};
    final encodedBody = jsonEncode(body);
    
    // Log request
    _logRequest('POST', uri.toString(), requestHeaders, body: encodedBody);
    
    var res = await http.post(
      uri,
      headers: requestHeaders,
      body: encodedBody,
    );
    
    // Log response
    _logResponse('POST', uri.toString(), res.statusCode, res.body);
    
    // Handle 401 and retry with refreshed token
    if (res.statusCode == 401 && retryOn401 && path != ApiConstants.authRefreshToken) {
      final newToken = await _refreshTokenIfNeeded();
      if (newToken != null) {
        // Update headers with new token and retry
        requestHeaders['Authorization'] = 'Bearer $newToken';
        
        // Log retry request
        _logRequest('POST', uri.toString(), requestHeaders, body: encodedBody);
        
        res = await http.post(
          uri,
          headers: requestHeaders,
          body: encodedBody,
        );
        
        // Log retry response
        _logResponse('POST', uri.toString(), res.statusCode, res.body, isRetry: true);
      }
    }
    
    return _mapResponse(res, parser);
  }

  /// Post multipart/form-data request for file uploads
  Future<BaseResponse<T>> postMultipart<T>(
    String path,
    T Function(Map<String, dynamic>) parser, {
    Map<String, String>? fields,
    Map<String, File>? files,
    bool retryOn401 = true,
  }) async {
    await _ensureInternet();
    await _ensureTokenLoaded();
    
    final uri = Uri.parse('$baseUrl$path');
    
    // Helper function to create and send multipart request
    Future<http.Response> sendMultipartRequest(String? authToken) async {
      final request = http.MultipartRequest('POST', uri);
      
      // Add authorization header
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      } else if (defaultHeaders.containsKey('Authorization')) {
        request.headers['Authorization'] = defaultHeaders['Authorization']!;
      }
      
      // Add form fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Add files
      if (files != null) {
        for (var entry in files.entries) {
          final file = entry.value;
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              file.path,
            ),
          );
        }
      }
      
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }
    
    var response = await sendMultipartRequest(null);
    
    // Handle 401 and retry with refreshed token
    if (response.statusCode == 401 && retryOn401 && path != ApiConstants.authRefreshToken) {
      final newToken = await _refreshTokenIfNeeded();
      if (newToken != null) {
        // Retry with new token
        response = await sendMultipartRequest(newToken);
      }
    }
    
    return _mapResponse(response, parser);
  }

  BaseResponse<T> _mapResponse<T>(
    http.Response res,
    T Function(Map<String, dynamic>) parser,
  ) {
    final status = res.statusCode;
    dynamic decoded;
    try {
      decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    } catch (e) {
      decoded = {};
    }

    if (status >= 200 && status < 300) {
      if (decoded is Map<String, dynamic>) {
        return BaseResponse<T>.fromJson(decoded, parser);
      }
      throw ApiException(
        AppStrings.invalidResponseFormat,
        statusCode: status,
      );
    }
    
    String message = 'Request failed';
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('message') && decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded.containsKey('error') && decoded['error'] != null) {
        message = decoded['error'].toString();
      } else if (decoded.containsKey('data') && 
                 decoded['data'] is Map<String, dynamic> && 
                 decoded['data']['message'] != null) {
        message = decoded['data']['message'].toString();
      }
    }
    
    throw ApiException(message, statusCode: status);
  }

  /// Refresh token if needed (handles concurrent requests)
  Future<String?> _refreshTokenIfNeeded() async {
    // If refresh is already in progress, wait for it
    if (_refreshTokenFuture != null) {
      return await _refreshTokenFuture;
    }

    // Start refresh token process
    _refreshTokenFuture = _performRefreshToken();
    try {
      final newToken = await _refreshTokenFuture;
      return newToken;
    } finally {
      _refreshTokenFuture = null;
    }
  }

  /// Perform the actual refresh token API call
  Future<String?> _performRefreshToken() async {
    try {
      final tokenStorage = ref.read(tokenStorageProvider);
      final oldToken = await tokenStorage.getToken();
      
      if (oldToken == null || oldToken.isEmpty) {
        return null;
      }

      // Call refresh token endpoint (without retryOn401 to avoid infinite loop)
      final uri = Uri.parse('$baseUrl${ApiConstants.authRefreshToken}');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $oldToken',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Handle BaseResponse format: { statusCode, status, data: { token, ... } }
        if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
          final refreshTokenData = RefreshTokenData.fromJson(
            decoded['data'] as Map<String, dynamic>,
          );
          
          if (refreshTokenData.token.isNotEmpty) {
            // Save new token
            await tokenStorage.saveToken(refreshTokenData.token);
            setAuthToken(refreshTokenData.token);
            return refreshTokenData.token;
          }
        }
      }
      
      // If refresh token API returns 401, perform full logout
      if (response.statusCode == 401) {
        await _performLogout();
      } else {
        // For other errors, just clear token
        await tokenStorage.deleteToken();
        clearAuthToken();
      }
      return null;
    } catch (e) {
      // If refresh fails, clear token and logout
      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.deleteToken();
      clearAuthToken();
      return null;
    }
  }

  /// Perform full logout: clear all preferences and trigger logout notifier
  Future<void> _performLogout() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    
    // Clear all local preferences storage
    await tokenStorage.clearAllPreferences();
    
    // Clear token from API client
    clearAuthToken();
    
    // Trigger logout notifier to navigate to login
    ref.read(logoutNotifierProvider.notifier).trigger();
  }

  Future<void> _ensureInternet() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) {
      ref.read(noInternetNotifierProvider.notifier).trigger();
      throw NoInternetException();
    }
  }
}
