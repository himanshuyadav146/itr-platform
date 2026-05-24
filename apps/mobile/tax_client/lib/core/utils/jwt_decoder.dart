import 'dart:convert';

class JwtDecoder {
  /// Decode JWT token and extract payload
  /// Returns null if token is invalid or cannot be decoded
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      // JWT tokens have format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed for base64 decoding
      String normalizedPayload = payload;
      final padding = 4 - (payload.length % 4);
      if (padding != 4) {
        normalizedPayload += '=' * padding;
      }

      // Decode base64
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      
      // Parse JSON
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      // If decoding fails, return null
      return null;
    }
  }

  /// Extract UserId from JWT token payload
  /// Returns null if UserId is not found
  static String? getUserIdFromToken(String token) {
    final payload = decodePayload(token);
    if (payload == null) {
      return null;
    }

    // Try different possible keys for userId
    final userIdValue = payload['UserId'] ?? 
                       payload['userId'] ?? 
                       payload['user_id'] ?? 
                       payload['sub'];
    
    if (userIdValue != null) {
      return userIdValue.toString();
    }
    
    return null;
  }
}

