import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> pickProfileImageAsBase64({ImageSource source = ImageSource.gallery}) async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64Data';
  } catch (e) {
    debugPrint('Error picking profile image: $e');
    return null;
  }
}
