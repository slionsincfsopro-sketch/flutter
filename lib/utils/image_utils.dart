import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  /// Converts an XFile to a Base64 string.
  static Future<String?> fileToBase64(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting file to base64: $e');
      return null;
    }
  }

  /// Helper to check if a string is a valid Base64 string (rudimentary check).
  static bool isBase64(String str) {
    try {
      base64Decode(str);
      return str.length > 100 && !str.startsWith('http');
    } catch (e) {
      return false;
    }
  }
}
