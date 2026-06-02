import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

class StorageRepository {
  StorageRepository({SupabaseClient? client})
    : _client =
          client ?? (SupabaseConfig.isReady ? SupabaseConfig.client : null);

  final SupabaseClient? _client;

  Future<String?> uploadLogo({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_client == null) return null;

    final ext = fileName.contains('.') ? fileName.split('.').last : 'png';
    final path = '$userId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage
        .from('logos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeForExt(ext)),
        );

    return path;
  }

  Future<String?> uploadGcode({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_client == null) return null;

    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage
        .from('gcodes')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'text/plain'),
        );

    return path;
  }

  Future<Uint8List?> downloadFile(String bucket, String path) async {
    if (_client == null) return null;
    return _client.storage.from(bucket).download(path);
  }

  Future<void> deleteFile(String bucket, String path) async {
    if (_client == null) return;
    await _client.storage.from(bucket).remove([path]);
  }

  String _mimeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }
}
