import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class WebFileService {
  // Web-compatible file download
  static void downloadFile(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  // Web-compatible file picker simulation
  static Future<Uint8List?> pickFile() async {
    if (kIsWeb) {
      // For web, we'll return null and show a message
      // In a real implementation, you'd use html.FileUploadInputElement
      return null;
    }
    return null;
  }

  // Check if running on web
  static bool get isWeb => kIsWeb;
  
  // Show web-specific message for file operations
  static String get webFileMessage => 
    'File operations are limited on web. Use mobile app for full functionality.';
}
