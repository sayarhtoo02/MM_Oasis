import 'dart:io';

// -----------------------------------------------------------------------------
// CONFIGURATION
// -----------------------------------------------------------------------------
// PASTE YOUR GITHUB RELEASE DIRECT LINK HERE
// Example: https://github.com/username/repo/releases/download/v2.0.0/app-release.apk
const String kDownloadUrl =
    'https://github.com/Sayarhtoo1/munajat_e_maqbool_app/releases/download/Islamic/app-release.apk';

const String kReleaseNotes = '''
- Added OTA Updates
- Added Halal Shop Registration
- New Glassmorphism UI
''';

const bool kForceUpdate = false;
// -----------------------------------------------------------------------------

void main() {
  print('🚀 Generating Update SQL...');

  // 1. Find pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found in current directory.');
    print('   Please run this script from the project root.');
    return;
  }

  // 2. Read content and parse version
  final content = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(
    r'version:\s+(\d+\.\d+\.\d+)(?:\+(\d+))?',
  ).firstMatch(content);

  if (versionMatch == null) {
    print('❌ Error: Could not find "version: x.y.z[+n]" in pubspec.yaml');
    return;
  }

  final versionName = versionMatch.group(1)!;
  final versionCode = versionMatch.group(2) != null
      ? int.parse(versionMatch.group(2)!)
      : 1;

  print('✅ Detected Version: $versionName (Build: $versionCode)');

  // 3. Generate SQL
  print('\n----------------------------------------------------------------');
  print('-- COPY AND PASTE THE FOLLOWING INTO SUPABASE SQL EDITOR --');
  print('----------------------------------------------------------------');

  final sql =
      '''
INSERT INTO munajat_app.app_versions (
  version_code, 
  version_name, 
  download_url, 
  force_update, 
  release_notes
) VALUES (
  $versionCode,
  '$versionName',
  '$kDownloadUrl',
  ${kForceUpdate ? 'TRUE' : 'FALSE'},
  '${kReleaseNotes.replaceAll("'", "''")}'
);
''';

  print(sql);
  print('----------------------------------------------------------------');
}
