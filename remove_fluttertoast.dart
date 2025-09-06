import 'dart:io';

void main() async {
  print('Starting fluttertoast removal script...');
  
  // 1. Update pubspec.yaml to remove fluttertoast dependency
  await removeFluttertoastFromPubspec();
  
  // 2. Find all files that import fluttertoast
  final files = await findFilesWithFluttertoast();
  
  // 3. Update each file to use our custom ToastUtil
  for (final file in files) {
    await updateFile(file);
  }
  
  // 4. Clean build directories to fix Gradle errors
  await cleanBuildDirectories();
  
  print('Fluttertoast removal complete!');
  print('Please run the following commands to complete the process:');
  print('1. flutter clean');
  print('2. flutter pub get');
  print('3. flutter run -d chrome  # To test on web platform');
}

Future<void> removeFluttertoastFromPubspec() async {
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('Error: pubspec.yaml not found!');
    return;
  }
  
  String content = await pubspecFile.readAsString();
  
  // Remove the fluttertoast dependency line
  final regex = RegExp(r'^\s*fluttertoast:.*$', multiLine: true);
  content = content.replaceAll(regex, '');
  
  await pubspecFile.writeAsString(content);
  print('Removed fluttertoast from pubspec.yaml');
}

Future<List<String>> findFilesWithFluttertoast() async {
  final result = <String>[];
  final dir = Directory('lib');
  
  if (!await dir.exists()) {
    print('Error: lib directory not found!');
    return result;
  }
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      if (content.contains("import 'package:fluttertoast/fluttertoast.dart';")) {
        result.add(entity.path);
      }
    }
  }
  
  print('Found ${result.length} files with fluttertoast imports');
  return result;
}

Future<void> updateFile(String filePath) async {
  final file = File(filePath);
  String content = await file.readAsString();
  
  // 1. Replace import statement
  content = content.replaceAll(
    "import 'package:fluttertoast/fluttertoast.dart';",
    "import '../utils/toast_util.dart';"
  );
  
  // Fix relative import path based on file location
  final pathSegments = filePath.split(Platform.pathSeparator);
  final depth = pathSegments.length - 2; // -2 for 'lib' and the file itself
  
  if (depth > 1) {
    final prefix = '../' * (depth - 1);
    content = content.replaceAll(
      "import '../utils/toast_util.dart';",
      "import '$prefix../utils/toast_util.dart';"
    );
  }
  
  // 2. Replace Fluttertoast.showToast with ToastUtil.showToast
  final pattern = RegExp(r'Fluttertoast\.showToast\(\s*msg:\s*([^,]+),(?:[^)]+)\);');
  content = content.replaceAllMapped(pattern, (match) {
    final msg = match.group(1);
    return 'ToastUtil.showToast(\n      context: context,\n      message: $msg,\n    );';
  });
  
  await file.writeAsString(content);
  print('Updated file: $filePath');
}

Future<void> cleanBuildDirectories() async {
  print('\nCleaning build directories to fix Gradle errors...');
  
  // Directories to clean
  final dirsToClean = [
    '.dart_tool',
    'build',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
    'android/.gradle',
    'android/app/build',
  ];
  
  for (final dirPath in dirsToClean) {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
        print('Deleted directory: $dirPath');
      } catch (e) {
        print('Error deleting directory $dirPath: $e');
      }
    }
  }
  
  // Also clean the Gradle cache for fluttertoast
  try {
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (userHome != null) {
      final fluttertoastCachePath = '$userHome/.gradle/caches/modules-2/files-2.1/io.github.ponnamkarthik.toast/fluttertoast';
      final fluttertoastCache = Directory(fluttertoastCachePath);
      if (await fluttertoastCache.exists()) {
        await fluttertoastCache.delete(recursive: true);
        print('Deleted fluttertoast from Gradle cache');
      }
    }
  } catch (e) {
    print('Error cleaning Gradle cache: $e');
  }
  
  print('Build directories cleaned successfully!');
}
