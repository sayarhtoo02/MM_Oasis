import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/dua_provider.dart'; // Import DuaProvider
import '../screens/dua_detail_screen.dart';
import '../services/dua_repository.dart';
import '../models/dua_model.dart'; // Import Dua model
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

        return Consumer2<SettingsProvider, DuaProvider>(
          builder: (context, settingsProvider, duaProvider, child) {
            final String? lastReadDuaId = settingsProvider.appSettings.duaPreferences.manzilProgress[manzilNumber];
            final Dua? lastReadDua = lastReadDuaId != null
                ? duaProvider.allDuas.firstWhere((d) => d.id == lastReadDuaId, orElse: () => duaProvider.allDuas.firstWhere((d) => d.manzilNumber == manzilNumber))
                : null;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              elevation: 3, // Revert elevation
              color: Theme.of(context).cardColor, // Revert color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide.none, // Remove border
              ),
              child: InkWell(
                onTap: () async {
                  final duaRepository = DuaRepository();
                  final List<Dua> manzilDuas = await duaRepository.getDuasByManzil(manzilNumber);
                  if (!context.mounted) return;

                  if (lastReadDua != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DuaDetailScreen(
                          initialDua: lastReadDua,
                          manzilDuas: manzilDuas,
                        ),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/dua_list',
                      arguments: manzilNumber,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary), // Revert icon color
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  manzils[index],
                                  style: TextStyle(
                                    fontSize: 19 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface, // Revert text color
                                  ),
                                ),
                                if (isTodayManzil)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'TODAY',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (lastReadDua != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Last Read: Dua ${lastReadDua.id}',
                                  style: TextStyle(
                                    fontSize: 14 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Revert text color
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Start Reading',
                                  style: TextStyle(
                                    fontSize: 14 * settingsProvider.appSettings.displaySettings.translationFontSizeMultiplier,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Revert text color
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // Revert icon color
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
