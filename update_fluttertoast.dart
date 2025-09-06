import 'dart:io';

void main() async {
  // Directory to search for Dart files
  final directory = 'lib';
  
  // Get all Dart files in the directory and subdirectories
  final files = await findDartFiles(directory);
  
  int updatedFiles = 0;
  
  // Process each file
  for (final file in files) {
    final updated = await processFile(file);
    if (updated) updatedFiles++;
  }
  
  print('Updated $updatedFiles files');
}

Future<List<String>> findDartFiles(String directory) async {
  final result = <String>[];
  final dir = Directory(directory);
  
  if (!await dir.exists()) {
    print('Directory not found: $directory');
    return result;
  }
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      result.add(entity.path);
    }
  }
  
  return result;
}

Future<bool> processFile(String filePath) async {
  final file = File(filePath);
  final content = await file.readAsString();
  
  // Check if the file imports fluttertoast
  if (!content.contains("import 'package:fluttertoast/fluttertoast.dart';")) {
    return false;
  }
  
  print('Processing file: $filePath');
  
  // Replace the import statement
  var updatedContent = content.replaceAll(
    "import 'package:fluttertoast/fluttertoast.dart';",
    "import '../utils/toast_util.dart';"
  );
  
  // Fix relative import path based on file location
  final pathSegments = filePath.split(Platform.pathSeparator);
  final depth = pathSegments.length - 2; // -2 for 'lib' and the file itself
  
  if (depth > 1) {
    final prefix = '../' * (depth - 1);
    updatedContent = updatedContent.replaceAll(
      "import '../utils/toast_util.dart';",
      "import '$prefix../utils/toast_util.dart';"
    );
  }
  
  // Replace Fluttertoast.showToast with ToastUtil.showToast
  final pattern = RegExp(r'Fluttertoast\.showToast\(\s*msg:\s*([^,]+),(?:[^)]+)\);');
  updatedContent = updatedContent.replaceAllMapped(pattern, (match) {
    final msg = match.group(1);
    return 'ToastUtil.showToast(\n      context: context,\n      message: $msg,\n    );';
  });
  
  // Replace Toast enum references
  updatedContent = updatedContent.replaceAll('Toast.LENGTH_LONG', 'Toast.LENGTH_LONG');
  updatedContent = updatedContent.replaceAll('Toast.LENGTH_SHORT', 'Toast.LENGTH_SHORT');
  
  // Replace ToastGravity enum references
  updatedContent = updatedContent.replaceAll('ToastGravity.BOTTOM', 'ToastGravity.BOTTOM');
  updatedContent = updatedContent.replaceAll('ToastGravity.TOP', 'ToastGravity.TOP');
  updatedContent = updatedContent.replaceAll('ToastGravity.CENTER', 'ToastGravity.CENTER');
  
  // Write the updated content back to the file
  await file.writeAsString(updatedContent);
  
  return true;
}
