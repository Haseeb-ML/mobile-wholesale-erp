import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppStorageService {
  static final AppStorageService instance = AppStorageService._internal();
  AppStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<String> get _photosDirectoryPath async {
    if (kIsWeb) return 'photos';
    final appDocDir = await getApplicationDocumentsDirectory();
    final photosDir = io.Directory(p.join(appDocDir.path, 'photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }
    return photosDir.path;
  }

  /// Copies an image from picker into app-owned persistent storage
  /// Returns a relative path e.g. "photos/prod_169999999.jpg"
  Future<String?> pickAndStoreImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      if (kIsWeb) {
        return 'assets/images/products/charger_20w.png';
      }

      final photosDir = await _photosDirectoryPath;
      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path).isNotEmpty ? p.extension(pickedFile.path) : '.jpg'}';
      final targetPath = p.join(photosDir, fileName);

      final bytes = await pickedFile.readAsBytes();
      final targetFile = io.File(targetPath);
      await targetFile.writeAsBytes(bytes);

      return 'photos/$fileName';
    } catch (e) {
      debugPrint('Error picking and storing image: $e');
      return null;
    }
  }

  /// Resolves relative or asset path to a usable File or null
  Future<io.File?> resolveLocalFile(String? relativePath) async {
    if (kIsWeb) return null;
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('assets/')) return null; // Handled by AssetImage

    final appDocDir = await getApplicationDocumentsDirectory();
    final fullPath = p.join(appDocDir.path, relativePath);
    final file = io.File(fullPath);
    if (file.existsSync()) {
      return file;
    }
    return null;
  }

  /// Deletes a user photo file if it exists
  Future<void> deletePhoto(String? relativePath) async {
    if (kIsWeb) return;
    if (relativePath == null || relativePath.isEmpty || relativePath.startsWith('assets/')) return;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fullPath = p.join(appDocDir.path, relativePath);
      final file = io.File(fullPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
    }
  }
}
