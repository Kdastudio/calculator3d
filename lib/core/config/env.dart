import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static bool _loaded = false;

  static const String _supabaseUrlDefine = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _supabaseAnonKeyDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static Future<void> load() async {
    if (_loaded) return;

    if (_supabaseUrlDefine.isEmpty || _supabaseAnonKeyDefine.isEmpty) {
      await _loadDotEnvFromLocalFile();
      if (_dotenvValue('SUPABASE_URL').isEmpty) {
        try {
          await dotenv.load(fileName: '.env');
        } catch (_) {
          // Asset .env ausente ou vazio (comum no web com .gitignore).
        }
      }
    }

    _loaded = true;
  }

  static Future<void> _loadDotEnvFromLocalFile() async {
    if (kIsWeb) return;

    try {
      final file = File('.env');
      if (!await file.exists()) return;

      final content = await file.readAsString();
      if (content.trim().isEmpty) return;

      dotenv.testLoad(fileInput: content);
    } catch (_) {
      // Ignora leitura local em ambientes restritos.
    }
  }

  static String _dotenvValue(String key) => _normalize(dotenv.maybeGet(key));

  static String _normalize(String? value) {
    if (value == null) return '';
    var v = value.trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")))) {
      v = v.substring(1, v.length - 1);
    }
    return v.trim();
  }

  static String get supabaseUrl {
    final fromDefine = _normalize(_supabaseUrlDefine);
    if (fromDefine.isNotEmpty) return fromDefine;
    return _dotenvValue('SUPABASE_URL');
  }

  static String get supabaseAnonKey {
    final fromDefine = _normalize(_supabaseAnonKeyDefine);
    if (fromDefine.isNotEmpty) return fromDefine;
    return _dotenvValue('SUPABASE_ANON_KEY');
  }

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
