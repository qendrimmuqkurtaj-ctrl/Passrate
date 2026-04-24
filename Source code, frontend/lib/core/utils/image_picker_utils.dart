import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../common/widgets/custom_toast.dart';

class ImagePickerUtils {
  static Future<File?> pickImageFile() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final String ext = file.path.split('.').last.toLowerCase();

      if (<String>['jpg', 'jpeg', 'png', 'heic'].contains(ext)) {
        return file;
      } else {
        ToastManager.show(
          message: "❌ Unsupported image format: .$ext",
          backgroundColor: Colors.red.shade700,
          animationDuration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeInSine,
          duration: const Duration(seconds: 1),
        );
        return null;
      }
    }

    return null;
  }
}
