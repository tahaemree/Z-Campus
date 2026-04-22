import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  User? get currentUser => _supabase.auth.currentUser;

  Future<String?> fetchDisplayName() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('users')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();

    final dbDisplayName = (data?['display_name'] as String?)?.trim();
    if (dbDisplayName != null && dbDisplayName.isNotEmpty) {
      return dbDisplayName;
    }

    final metaDisplayName =
        (user.userMetadata?['display_name'] as String?)?.trim();
    if (metaDisplayName != null && metaDisplayName.isNotEmpty) {
      return metaDisplayName;
    }

    return null;
  }

  Future<void> updateDisplayName(String name) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Oturum bulunamadı.');
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Isim bos olamaz.');
    }

    await _supabase.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': cleanName,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _supabase.auth.updateUser(
      UserAttributes(data: {'display_name': cleanName}),
    );
  }

  Future<void> deleteCurrentUser() async {
    if (currentUser == null) {
      throw Exception('Oturum bulunamadı.');
    }

    await _supabase.rpc('delete_user');
    await _supabase.auth.signOut();
  }
}
