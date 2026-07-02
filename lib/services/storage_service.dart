import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  // Secilen gorselleri Firebase Storage'a yukler ve acik URL listesini dondurur.
  Future<List<String>> uploadListingImages({
    required String sellerId,
    required List<XFile> files,
  }) async {
    final uploadedUrls = <String>[];

    for (final file in files) {
      uploadedUrls.add(
        await uploadListingImage(sellerId: sellerId, file: file),
      );
    }

    return uploadedUrls;
  }

  Future<String> uploadListingImage({
    required String sellerId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = _normalizeExtension(file.name);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeName(file.name)}$extension';

    final reference = _storage
        .ref()
        .child(AppConstants.listingImagesFolder)
        .child(sellerId)
        .child(fileName);

    final metadata = SettableMetadata(
      contentType: _contentTypeFor(extension),
      customMetadata: {'originalName': file.name, 'sellerId': sellerId},
    );

    final snapshot = await reference.putData(bytes, metadata);
    return snapshot.ref.getDownloadURL();
  }

  String _normalizeExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }

    final extension = fileName.substring(dotIndex).toLowerCase();
    if (extension == '.png' ||
        extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.webp') {
      return extension;
    }

    return '.jpg';
  }

  String _sanitizeName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex == -1
        ? fileName
        : fileName.substring(0, dotIndex);

    final cleaned = baseName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    if (cleaned.isEmpty) {
      return 'listing_image';
    }

    return cleaned;
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}
