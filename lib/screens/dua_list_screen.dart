import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';

class DuaListScreen extends StatelessWidget {
  const DuaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int manzilNumber = ModalRoute.of(context)!.settings.arguments as int;
    final duaProvider = Provider.of<DuaProvider>(context);

    final List<Dua> manzilDuas = duaProvider.allDuas
        .where((dua) => dua.manzilNumber == manzilNumber)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manzil $manzilNumber Duas'),
      ),
      body: ListView.builder(
        itemCount: manzilDuas.length,
        itemBuilder: (context, index) {
          final Dua dua = manzilDuas[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/dua_detail', // This route will be defined later
                arguments: {
                  'selectedDua': dua,
                  'manzilDuas': manzilDuas,
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // Use card color for consistency
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Subtle shadow from primary color
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(16.0), // Slightly larger rounded corners
              ),
              child: Text(
                dua.arabicText,
                textAlign: TextAlign.justify, // Keep right alignment
                textDirection: TextDirection.rtl, // Ensure right-to-left text direction
                style: TextStyle(
                  fontFamily: 'Arabic', // Apply the Arabic font
                  fontSize: 38 * Provider.of<SettingsProvider>(context).appSettings.displaySettings.arabicFontSizeMultiplier, // Slightly larger font for Arabic
                  letterSpacing: 0,
                  height: 2.0, // Adjust line spacing for better calligraphy appearance
                  color: Theme.of(context).colorScheme.onSurface, // Use onSurface for Arabic text
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
