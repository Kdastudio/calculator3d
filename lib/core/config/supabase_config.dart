import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;

  static bool get isReady => _initialized;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (_initialized || !Env.hasSupabase) return;

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }
}
