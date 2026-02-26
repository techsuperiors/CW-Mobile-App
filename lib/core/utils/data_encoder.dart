import 'dart:convert';

/// Encodes a payload to Base64 format with URI encoding
/// 
/// Takes any payload, converts it to JSON string, URI encodes it,
/// then Base64 encodes it and strips padding characters.
/// 
/// Returns an empty string if encoding fails.
String encodeData(dynamic payload) {
  try {
    if (payload == null) {
      throw Exception('No payload provided to encode');
    }
    
    // Convert payload to JSON string
    final dataString = jsonEncode(payload);
    
    // URI encode the JSON string using Uri.encodeFull (similar to JavaScript's encodeURI)
    final uriEncoded = Uri.encodeFull(dataString);
    
    // Base64 encode the URI-encoded string
    var encoded = base64Encode(utf8.encode(uriEncoded));
    
    // Strip padding (trailing '=' characters) - matching TypeScript behavior
    // If your backend requires padding, comment out the next line
    // encoded = encoded.replaceAll(RegExp(r'=+$'), '');
    
    return encoded;
  } catch (error) {
    print('encodeData error: $error');
    return '';
  }
}

/// Decodes a JWT token and extracts the payload
/// 
/// Takes a JWT token in format "header.payload.signature",
/// extracts the payload part, Base64 decodes it, and parses it as JSON.
/// 
/// Returns null if decoding fails.
T? decodeData<T>(String token) {
  try {
    if (token.isEmpty) {
      throw Exception('No token provided');
    }

    // JWT is in format header.payload.signature
    final parts = token.split('.');
    if (parts.length < 2) {
      throw Exception('Invalid JWT format');
    }

    // Get the payload part (second element)
    final payloadBase64 = parts[1];
    
    // Add padding if needed (Base64 strings should be multiples of 4)
    // This handles both cases: if padding already exists (length % 4 == 0), 
    // no padding is added; if padding is missing, it's added automatically
    var paddedBase64 = payloadBase64;
    final remainder = paddedBase64.length % 4;
    if (remainder > 0) {
      paddedBase64 += '=' * (4 - remainder);
    }
    
    // Decode base64 → bytes → string
    final decodedBytes = base64Decode(paddedBase64);
    final decoded = utf8.decode(decodedBytes);
    
    // URI decode using Uri.decodeFull (similar to JavaScript's decodeURI)
    final uriDecoded = Uri.decodeFull(decoded);
    
    // Parse JSON and return as type T
    return jsonDecode(uriDecoded) as T;
  } catch (error) {
    print('decodeData error: $error');
    return null;
  }
}

