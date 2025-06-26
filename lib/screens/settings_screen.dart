import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:munajat_e_maqbool_app/screens/custom_collections_screen.dart'; // Import CustomCollectionsScreen
import 'package:munajat_e_maqbool_app/screens/display_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/language_settings_screen.dart';
import 'package:munajat_e_maqbool_app/screens/dua_preferences_screen.dart';
import 'package:munajat_e_maqbool_app/screens/notification_settings_screen.dart'; // Import NotificationSettingsScreen
import '../screens/settings_screen_components/settings_card.dart'; // Import the buildSettingsCard function

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: ListView(
        children: [
          SettingsCard(
            title: 'Display Settings',
            icon: Icons.display_settings,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DisplaySettingsScreen()));
            },
          ),
          SettingsCard(
            title: 'Language Settings',
            icon: Icons.language,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()));
            },
          ),
          SettingsCard(
            title: 'Dua Preferences',
            icon: Icons.favorite,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DuaPreferencesScreen()));
            },
          ),
          SettingsCard(
            title: 'Reminder Settings',
            icon: Icons.notifications,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
            },
          ),
          SettingsCard(
            title: 'Custom Collections',
            icon: Icons.collections_bookmark,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomCollectionsScreen()));
            },
          ),
          // ... other categories
        ],
      ),
    );
  }
}
