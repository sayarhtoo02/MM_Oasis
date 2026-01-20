import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/dua_model.dart';
import 'package:munajat_e_maqbool_app/providers/dua_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/dua_detail_screen.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class DuaListScreen extends StatelessWidget {
  final int? manzilNumber;

  const DuaListScreen({super.key, this.manzilNumber});

  @override
  Widget build(BuildContext context) {
    final int effectiveManzilNumber =
        manzilNumber ?? (ModalRoute.of(context)!.settings.arguments as int);
    final duaProvider = Provider.of<DuaProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);

    final List<Dua> manzilDuas = duaProvider.allDuas
        .where((dua) => dua.manzilNumber == effectiveManzilNumber)
        .toList();

    return GlassScaffold(
      title: 'Manzil $effectiveManzilNumber Duas',
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: manzilDuas.length,
        itemBuilder: (context, index) {
          final Dua dua = manzilDuas[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              isDark: isDark,
              borderRadius: 20,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DuaDetailScreen(
                      initialDua: dua,
                      manzilDuas: manzilDuas,
                    ),
                  ),
                );
              },
              child: Text(
                dua.arabicText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Indopak',
                  letterSpacing: 0,
                  fontSize:
                      38 *
                      settingsProvider
                          .appSettings
                          .displaySettings
                          .arabicFontSizeMultiplier,
                  height: 2.2,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
