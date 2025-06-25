import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dua_model.dart';
import '../../providers/settings_provider.dart';

class DuaDetailAppBarActions extends StatelessWidget {
  final Dua currentDua;
  final String selectedLanguage;
  final Function(Dua, String) onCopyDuaText;
  final Function(Dua, String) onShareDuaText;

  const DuaDetailAppBarActions({
    super.key,
    required this.currentDua,
    required this.selectedLanguage,
    required this.onCopyDuaText,
    required this.onShareDuaText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy Dua Text',
          onPressed: () => onCopyDuaText(currentDua, selectedLanguage),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share Dua',
          onPressed: () => onShareDuaText(currentDua, selectedLanguage),
        ),
        Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final isFavorite = settingsProvider.isDuaFavorite(currentDua);
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                settingsProvider.toggleFavoriteDua(currentDua);
              },
            );
          },
        ),
      ],
    );
  }
}
