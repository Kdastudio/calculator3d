import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? (SupabaseConfig.isReady ? SupabaseConfig.client : null);

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    if (_client == null) return const Stream.empty();
    return _client.auth.onAuthStateChange;
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _requireClient();
    await _client!.auth.signUp(email: email, password: password);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _requireClient();
    await _client!.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    _requireClient();
    await _client!.auth.signOut();
  }

  void _requireClient() {
    if (_client == null) {
      throw StateError('Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY.');
    }
  }
}
