import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/models/cloud_models.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
    : _client =
          client ?? (SupabaseConfig.isReady ? SupabaseConfig.client : null);

  final SupabaseClient? _client;

  Future<UserProfile?> fetchProfile(String userId) async {
    if (_client == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> upsertProfile(String userId, UserProfile profile) async {
    if (_client == null) return;

    await _client.from('profiles').upsert({'id': userId, ...profile.toJson()});
  }
}
