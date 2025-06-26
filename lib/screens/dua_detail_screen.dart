import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
import '../models/dua_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/dua_detail_components/dua_content_display.dart';
import '../widgets/dua_detail_components/audio_player_controls.dart';
import '../widgets/dua_detail_components/dua_detail_app_bar_actions.dart';
import '../widgets/dua_detail_components/dua_audio_player_manager.dart';

class DuaDetailScreen extends StatefulWidget {
  final Dua initialDua;
  final List<Dua> manzilDuas;

  const DuaDetailScreen({
    super.key,
    required this.initialDua,
    required this.manzilDuas,
  });

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  late PageController _pageController;
  late int _currentPageIndex;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Find the index of the initialDua by comparing their unique IDs
    int initialIndex = widget.manzilDuas.indexWhere((dua) => dua.id == widget.initialDua.id);
    _currentPageIndex = initialIndex != -1 ? initialIndex : 0;
    _pageController = PageController(initialPage: _currentPageIndex);

    // Initialize notes controller with current dua's note
    _notesController = TextEditingController();
    _loadDuaNote(widget.manzilDuas[_currentPageIndex].id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadDuaNote(String duaId) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final note = settingsProvider.getDuaNote(duaId);
    _notesController.text = note ?? '';
  }

  void _saveDuaNote(String duaId, String note) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.setDuaNote(duaId, note);
  }

  void _copyDuaText(Dua dua, String selectedLanguage) {
    final String translationText = dua.translations.getTranslationText(selectedLanguage);
    final String textToCopy =
        'Arabic: ${dua.arabicText}\n\nTranslation: $translationText\n\nSource: ${dua.source}';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dua text copied to clipboard!')),
    );
  }

  void _shareDuaText(Dua dua, String selectedLanguage) {
    final String translationText = dua.translations.getTranslationText(selectedLanguage);
    final String textToShare =
        'Munajat-e-Maqbool\n\nArabic: ${dua.arabicText}\n\nTranslation: $translationText\n\nSource: ${dua.source}\n\n#MunajatEMaqboolApp';
    Share.share(textToShare);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final selectedLanguage = settingsProvider.appSettings.languageSettings.selectedLanguage;
    final currentDua = widget.manzilDuas[_currentPageIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentDua.day),
        centerTitle: true,
        actions: [
          DuaDetailAppBarActions(
            currentDua: currentDua,
            selectedLanguage: selectedLanguage,
            onCopyDuaText: _copyDuaText,
            onShareDuaText: _shareDuaText,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest, // Use a subtle gradient
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal, // Changed to horizontal
          itemCount: widget.manzilDuas.length,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
            final currentDua = widget.manzilDuas[index];
            settingsProvider.setLastReadDua(currentDua);
            settingsProvider.setManzilProgress(currentDua.manzilNumber, currentDua.id);
            _loadDuaNote(currentDua.id); // Load note for the new Dua
          },
          itemBuilder: (context, index) {
            final dua = widget.manzilDuas[index];
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Always allow inner scroll
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch to fill width
                children: [
                  DuaContentDisplay(
                    dua: dua,
                    selectedLanguage: selectedLanguage,
                  ),
                  const SizedBox(height: 25),
                  DuaAudioPlayerManager(
                    currentDua: dua,
                    builder: (playerState, duration, position, onPlayPausePressed, onSliderChanged, isLooping, onToggleLoop, playbackSpeed, onSpeedChanged) {
                      return AudioPlayerControls(
                        playerState: playerState,
                        duration: duration,
                        position: position,
                        onPlayPausePressed: onPlayPausePressed,
                        onSliderChanged: onSliderChanged,
                        isLooping: isLooping,
                        onToggleLoop: onToggleLoop,
                        playbackSpeed: playbackSpeed,
                        onSpeedChanged: onSpeedChanged,
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: null, // Allows for multiline input
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Add your personal notes here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.all(16.0),
                    ),
                    onChanged: (text) {
                      _saveDuaNote(dua.id, text);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
