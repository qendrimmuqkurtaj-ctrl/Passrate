import 'dart:io';
 import 'package:file_picker/file_picker.dart';

import 'logger_utils.dart';

class FilePickerUtils {
  static Future<File?> pickFile() async {
   try {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    } else {
      return null; 
    }
  } catch (e) {
    LoggerUtils.error('Error picking PDF file: $e');
    return null;
  }
  }
  
}