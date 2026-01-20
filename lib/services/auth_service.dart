import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('SignIn Error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String username,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // metadata in auth.users
      );

      if (response.user != null) {
        // Create profile in our custom schema
        await _supabase.schema('munajat_app').from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'role': 'user',
        });
      }
      return response;
    } catch (e) {
      debugPrint('SignUp Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .schema('munajat_app')
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('GetProfile Error: $e');
      return null;
    }
  }
}
