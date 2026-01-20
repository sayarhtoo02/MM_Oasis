import 'package:flutter/material.dart';
import 'lib/screens/tafseer_screen.dart';
import 'lib/widgets/tafseer_widget.dart';

// Example 1: Using TafseerScreen as a full screen
class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quran')),
      body: ListView(
        children: [
          // Your existing Quran content...
          
          // Add a button to open tafseer
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TafseerScreen(
                    ayahKey: '103:1', // Example: Surah Al-Asr, Ayah 1
                    surahName: 'Al-Asr',
                    ayahNumber: 1,
                  ),
                ),
              );
            },
            child: Text('View Tafseer'),
          ),
        ],
      ),
    );
  }
}

// Example 2: Using TafseerWidget inline
class AyahDetailPage extends StatelessWidget {
  final String ayahKey;
  
  const AyahDetailPage({super.key, required this.ayahKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ayah Details')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your ayah content (Arabic text, translation, etc.)
            
            // Add tafseer widget directly
            TafseerWidget(
              ayahKey: ayahKey,
              language: 'my', // Start with Myanmar
            ),
          ],
        ),
      ),
    );
  }
}

// Example 3: Using in a bottom sheet
class QuranWithTafseer extends StatelessWidget {
  const QuranWithTafseer({super.key});

  void _showTafseer(BuildContext context, String ayahKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: TafseerWidget(
              ayahKey: ayahKey,
              language: 'my',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quran with Tafseer')),
      body: ListView.builder(
        itemCount: 10, // Example
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Ayah ${index + 1}'),
            subtitle: Text('Arabic text here...'),
            trailing: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showTafseer(context, '103:${index + 1}'),
            ),
          );
        },
      ),
    );
  }
}