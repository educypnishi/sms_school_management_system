import 'dart:io';

void main() {
  // List of files to update
  final filesToUpdate = [
    'lib/screens/admin_applications_screen.dart',
    'lib/screens/application_form_screen.dart',
    'lib/screens/chat_screen.dart',
    'lib/screens/conversations_screen.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/notifications_screen.dart',
    'lib/screens/partner_applications_screen.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/program_detail_screen.dart',
    'lib/screens/program_list_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/signup_screen.dart',
  ];

  for (final filePath in filesToUpdate) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('File not found: $filePath');
        continue;
      }

      String content = file.readAsStringSync();
      
      // Replace import statement
      content = content.replaceAll(
        "import 'package:fluttertoast/fluttertoast.dart';",
        "import '../utils/toast_util.dart';"
      );
      
      // Replace Fluttertoast.showToast with ToastUtil.showToast
      final regex = RegExp(r'Fluttertoast\.showToast\(\s*msg:\s*([^,]+),(?:[^)]+)\);');
      content = content.replaceAllMapped(regex, (match) {
        final msg = match.group(1);
        return 'ToastUtil.showToast(\n      context: context,\n      message: $msg,\n    );';
      });
      
      file.writeAsStringSync(content);
      print('Updated: $filePath');
    } catch (e) {
      print('Error updating $filePath: $e');
    }
  }
  
  print('Toast utility update completed!');
}
