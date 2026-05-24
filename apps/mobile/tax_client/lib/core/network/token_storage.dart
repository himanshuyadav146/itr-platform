import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/utils/jwt_decoder.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _panNumberKey = 'pan_number';
  static const String _fcmTokenKey = 'fcm_token';

  /// Save authentication token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Delete authentication token
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_panNumberKey);
  }

  /// Clear all local preferences storage
  Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Check if token exists
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  /// Save user data as JSON
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Save full authentication response (includes token, user, status, message)
  Future<void> saveAuthResponse(Map<String, dynamic> authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store the full response
    await prefs.setString('auth_response', jsonEncode(authResponse));
    
    // Also store token separately for easy access
    if (authResponse['token'] != null) {
      await prefs.setString(_tokenKey, authResponse['token']);
    }
    
    // Store user data separately for easy access
    if (authResponse['user'] != null) {
      await prefs.setString(_userDataKey, jsonEncode(authResponse['user']));
    }
  }

  /// Get stored authentication response
  Future<Map<String, dynamic>?> getAuthResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final authResponseString = prefs.getString('auth_response');
    if (authResponseString != null) {
      return jsonDecode(authResponseString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Save FCM token locally (before user logs in)
  Future<void> saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  /// Get locally stored FCM token
  Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  /// Clear locally stored FCM token
  Future<void> clearFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }

  /// Save PAN number
  Future<void> savePanNumber(String panNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_panNumberKey, panNumber);
  }

  /// Get stored PAN number
  Future<String?> getPanNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_panNumberKey);
  }

  /// Get user ID from token, auth response, or user data
  Future<String?> getUserId() async {
    // First try to get from JWT token payload
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      final userIdFromToken = JwtDecoder.getUserIdFromToken(token);
      if (userIdFromToken != null && userIdFromToken.isNotEmpty) {
        return userIdFromToken;
      }
    }
    
    // If not found in token, try to get from auth response
    final authResponse = await getAuthResponse();
    if (authResponse != null) {
      final userIdValue = authResponse['userId'];
      if (userIdValue != null) {
        return userIdValue.toString();
      }
    }
    
    // If not found, try to get from user data
    final userData = await getUserData();
    if (userData != null && userData['id'] != null) {
      return userData['id'].toString();
    }
    
    return null;
  }
}
