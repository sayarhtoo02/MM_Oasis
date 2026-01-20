import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Supabase Client
/// Uses the service role key to bypass RLS for admin operations.
/// ⚠️ WARNING: This client bypasses all Row Level Security!
/// Only use for admin-authenticated operations.
class AdminSupabaseClient {
  static SupabaseClient? _instance;

  static const String _supabaseUrl = 'https://lgmbvrtkulhwylmwhoou.supabase.co';
  static const String _serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbWJ2cnRrdWxod3lsbXdob291Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzcwNzk1MiwiZXhwIjoyMDgzMjgzOTUyfQ.poR2qA_WW2Yna_qnvQ5zV0il_GMlGpA4dEt-xgakHuo';

  /// Get the admin Supabase client (bypasses RLS)
  static SupabaseClient get client {
    _instance ??= SupabaseClient(_supabaseUrl, _serviceRoleKey);
    return _instance!;
  }
}
