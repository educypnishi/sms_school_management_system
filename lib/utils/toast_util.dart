import 'package:flutter/material.dart';

/// Enum to match Fluttertoast's ToastGravity
enum ToastGravity {
  TOP,
  BOTTOM,
  CENTER,
  TOP_LEFT,
  TOP_RIGHT,
  BOTTOM_LEFT,
  BOTTOM_RIGHT,
  CENTER_LEFT,
  CENTER_RIGHT,
  SNACKBAR
}

/// Enum to match Fluttertoast's Toast length
enum Toast {
  LENGTH_SHORT,
  LENGTH_LONG
}

/// A utility class to show toast messages using SnackBar
/// This replaces the fluttertoast package functionality
class ToastUtil {
  /// Shows a toast message using SnackBar
  /// 
  /// [context] - BuildContext to show the SnackBar
  /// [message] - Message to display (equivalent to msg in Fluttertoast)
  /// [isError] - Whether this is an error message (changes color)
  /// [duration] - How long to show the message
  /// [gravity] - Where to show the toast (only BOTTOM is fully supported)
  /// [backgroundColor] - Background color of the toast
  /// [textColor] - Text color of the toast
  /// [toastLength] - Length of the toast (short or long)
  static void showToast({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration? duration,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color? backgroundColor,
    Color? textColor,
    Toast toastLength = Toast.LENGTH_SHORT,
  }) {
    // Convert toast length to duration
    final Duration toastDuration = duration ?? 
        (toastLength == Toast.LENGTH_LONG 
            ? const Duration(seconds: 5) 
            : const Duration(seconds: 2));
    
    // Set background color
    final Color bgColor = backgroundColor ?? 
        (isError ? Colors.red : Colors.black87);
    
    // Set text color
    final Color txtColor = textColor ?? Colors.white;
    
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: txtColor),
      ),
      backgroundColor: bgColor,
      duration: toastDuration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
