class R2Config {
  static const String accountId = 'd61dbacfb3350c63ec66f340783bf9e1';
  // TODO: User to fill these
  static const String accessKeyId = '3ffde29cb9cdcbed9463ed55f65ddbe0';
  static const String secretAccessKey =
      'b325dbf703a7f748484a2fa5d35bf517417ab5b2086aa48f40870f87980df5a8';
  static const String bucketName = 'mmoasis-app-storage';

  // R2 Endpoint - standardized for all R2 users
  static String get endpoint => 'https://$accountId.r2.cloudflarestorage.com';

  // Public URL - usually setup as custom domain or r2.dev subdomain
  // TODO: User to fill this after enabling public access
  static const String publicUrl =
      'https://pub-9a545218955d49059812d1199322a714.r2.dev';
  static const String customDomain = 'app.oasismm.site';
}
