import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/dua_detail_screen.dart';
import '../services/dua_repository.dart';
// Import DuaListScreen
// Import for DateFormat

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Munajat-e-Maqbool'),
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              if (settingsProvider.appSettings.duaPreferences.lastReadDua != null) {
                return IconButton(
                  icon: const Icon(Icons.bookmark),
                  tooltip: 'Last Read Dua',
                  onPressed: () async {
                    final duaRepository = DuaRepository();
                    final manzilDuas = await duaRepository.getDuasByManzil(
                        settingsProvider.appSettings.duaPreferences.lastReadDua!.manzilNumber);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DuaDetailScreen(
                          initialDua: settingsProvider.appSettings.duaPreferences.lastReadDua!,
                          manzilDuas: manzilDuas,
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search), // Search icon
            onPressed: () {
              // Navigate to SearchScreen
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: const _ManzilListScreen(),
    );
  }
}

class _ManzilListScreen extends StatelessWidget {
  const _ManzilListScreen();

  @override
  Widget build(BuildContext context) {
    final List<String> manzils = [
      "Manzil 1 - Saturday",
      "Manzil 2 - Sunday",
      "Manzil 3 - Monday",
      "Manzil 4 - Tuesday",
      "Manzil 5 - Wednesday",
      "Manzil 6 - Thursday",
      "Manzil 7 - Friday",
    ];

    // Get the current day of the week (1 for Monday, 7 for Sunday)
    final int currentDay = DateTime.now().weekday;
    // Adjust to match Manzil's Saturday-Friday order (Saturday is 1, Friday is 7)
    // Dart's weekday: Monday=1, ..., Sunday=7
    // Manzil's day: Saturday=1, Sunday=2, ..., Friday=7
    int highlightedManzilIndex;
    if (currentDay == DateTime.saturday) {
      highlightedManzilIndex = 0; // Saturday is Manzil 1 (index 0)
    } else if (currentDay == DateTime.sunday) {
      highlightedManzilIndex = 1; // Sunday is Manzil 2 (index 1)
    } else {
      highlightedManzilIndex = currentDay + 1; // Monday (1) -> Manzil 3 (index 2), ..., Friday (5) -> Manzil 7 (index 6)
    }


    return ListView.builder(
      itemCount: manzils.length,
      itemBuilder: (context, index) {
        final int manzilNumber = index + 1;
        final bool isTodayManzil = index == highlightedManzilIndex;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical:10.0),
          elevation: 3, // Even higher elevation for today
          color: isTodayManzil ? Theme.of(context).colorScheme.tertiaryContainer.withAlpha(200) : Theme.of(context).cardColor, // Use tertiaryContainer for highlight
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Slightly larger rounded corners
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/dua_list',
                arguments: manzilNumber,
              );
            },
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      manzils[index],
                      style: TextStyle(
                        fontSize: 19 * Provider.of<SettingsProvider>(context).appSettings.displaySettings.translationFontSizeMultiplier,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
