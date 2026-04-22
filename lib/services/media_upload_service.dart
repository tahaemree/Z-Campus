import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MediaEntityType { event, venue }

class MediaUploadService {
  MediaUploadService({SupabaseClient? supabase, ImagePicker? picker})
      : _supabase = supabase ?? Supabase.instance.client,
        _picker = picker ?? ImagePicker();

  static const String bucketName = 'app-media';
  static const int maxUploadBytes = 8 * 1024 * 1024;
  static const Set<String> _supportedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  final SupabaseClient _supabase;
  final ImagePicker _picker;

  Future<String?> pickAndUploadImage({
    required MediaEntityType entityType,
    required ImageSource source,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Görsel yüklemek için giriş yapmalısınız.');
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
      requestFullMetadata: false,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Seçilen görsel okunamadı.');
    }

    if (bytes.lengthInBytes > maxUploadBytes) {
      throw Exception('Görsel boyutu en fazla 8 MB olabilir.');
    }

    final extension = _resolveExtension(picked.name);
    if (!_supportedExtensions.contains(extension)) {
      throw Exception(
        'Desteklenmeyen görsel formatı. Lütfen JPG, PNG, WEBP veya HEIC seçin.',
      );
    }

    final contentType = _contentTypeForExtension(extension);
    final rootFolder =
        entityType == MediaEntityType.event ? 'events' : 'venues';

    final objectPath =
        '$rootFolder/$userId/${DateTime.now().millisecondsSinceEpoch}_${_randomToken()}.$extension';

    await _supabase.storage.from(bucketName).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            cacheControl: '3600',
            contentType: contentType,
          ),
        );

    return _supabase.storage.from(bucketName).getPublicUrl(objectPath);
  }

  String _resolveExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == filename.length - 1) {
      return 'jpg';
    }

    return filename.substring(dotIndex + 1).toLowerCase();
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
    }

    throw StateError('Unsupported extension: $extension');
  }

  String _randomToken() {
    final random = Random();
    return (random.nextInt(900000) + 100000).toString();
  }
}
