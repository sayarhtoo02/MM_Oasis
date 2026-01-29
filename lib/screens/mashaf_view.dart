import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quran_provider.dart';
import '../../services/database/oasismm_database.dart';
import 'mashaf/mashaf_page.dart';

class MashafView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function(int surah, int ayah)? onAyahTap;
  final Map<String, dynamic>? selectedAyah;

  const MashafView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    this.onAyahTap,
    this.selectedAyah,
  });

  @override
  State<MashafView> createState() => _MashafViewState();
}

class _MashafViewState extends State<MashafView> {
  List<Map<String, dynamic>> _surahs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuranProvider>(context, listen: false).loadMashafInfo();
      _loadMetadata();
    });
  }

  Future<void> _loadMetadata() async {
    try {
      final surahs = await OasisMMDatabase.getSurahs();
      setState(() {
        _surahs = surahs;
      });
    } catch (e) {
      debugPrint('Error loading metadata: $e');
    }
  }

  Map<String, dynamic>? _getSurahInfo(int surahNumber) {
    if (_surahs.isEmpty) return null;
    try {
      return _surahs.firstWhere((s) => s['id'] == surahNumber);
    } catch (_) {
      return null;
    }
  }

  int _getJuzForPage(int pageNumber) {
    return ((pageNumber - 1) ~/ 20) + 1;
  }

  String _getHizbForPage(int pageNumber) {
    final hizb = ((pageNumber - 1) ~/ 10) + 1;
    final quarter = ((pageNumber - 1) % 10) ~/ 2.5;
    if (quarter == 0) return 'Hizb $hizb';
    return '¼ Hizb $hizb';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        if (provider.mashafError != null) {
          return Center(child: Text('Error: ${provider.mashafError}'));
        }

        if (provider.mashafInfo == null) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D3B2E)),
          );
        }

        return OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: PageView.builder(
                controller: widget.pageController,
                reverse: true, // Quran is RTL
                itemCount: provider.mashafInfo!.numberOfPages,
                onPageChanged: widget.onPageChanged,
                itemBuilder: (context, index) {
                  final pageNumber = index + 1;
                  return MashafPage(
                    pageNumber: pageNumber,
                    isLandscape: isLandscape,
                    surahInfo: _getSurahInfo(1),
                    juzNumber: _getJuzForPage(pageNumber),
                    hizbInfo: _getHizbForPage(pageNumber),
                    onAyahTap: widget.onAyahTap,
                    selectedAyah: widget.selectedAyah,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
