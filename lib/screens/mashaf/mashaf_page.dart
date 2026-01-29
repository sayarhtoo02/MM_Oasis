import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quran_provider.dart';
import '../../models/mashaf_models.dart';
import '../../services/database/oasismm_database.dart';
import 'mashaf_header_footer.dart';
import 'mashaf_line_builder.dart';

/// A single page in the Mashaf view
class MashafPage extends StatefulWidget {
  final int pageNumber;
  final bool isLandscape;
  final Map<String, dynamic>? surahInfo;
  final int juzNumber;
  final String hizbInfo;
  final Function(int surah, int ayah)? onAyahTap;
  final Map<String, dynamic>? selectedAyah;

  const MashafPage({
    super.key,
    required this.pageNumber,
    this.isLandscape = false,
    this.surahInfo,
    required this.juzNumber,
    required this.hizbInfo,
    this.onAyahTap,
    this.selectedAyah,
  });

  @override
  State<MashafPage> createState() => _MashafPageState();
}

class _MashafPageState extends State<MashafPage> {
  List<MashafPageLine>? _lines;
  bool _isLoading = true;
  String _currentSurahName = '';

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final provider = Provider.of<QuranProvider>(context, listen: false);
    final lines = await provider.getMashafPage(widget.pageNumber);

    String surahName = '';
    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      if (firstLine.surahNumber > 0) {
        try {
          final surahs = await OasisMMDatabase.getSurahs();
          final surah = surahs.firstWhere(
            (s) => s['id'] == firstLine.surahNumber,
            orElse: () => {},
          );
          if (surah.isNotEmpty) {
            surahName = surah['name_transliteration'] ?? surah['name'] ?? '';
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _lines = lines;
        _isLoading = false;
        _currentSurahName = surahName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_lines == null || _lines!.isEmpty) {
      return const Center(
        child: Text(
          'Error loading page',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final isLeftPage = widget.pageNumber % 2 == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Spine shadow gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isLeftPage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  end: isLeftPage
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.05, 1.0],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              MashafHeader(
                surahName: _currentSurahName,
                juzNumber: widget.juzNumber,
                hizbInfo: widget.hizbInfo,
              ),
              Expanded(child: _buildPageContent()),
              MashafFooter(pageNumber: widget.pageNumber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF5D4037), width: 3),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD4AF37), width: 1),
          color: Colors.white.withValues(alpha: 0.5),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;

            double dynamicFontSize;
            final surahCount =
                _lines?.where((l) => l.lineType == 'surah_name').length ?? 0;
            if (isLandscape) {
              final factor = surahCount >= 3
                  ? 24.0
                  : (surahCount >= 2 ? 22.0 : 19.5);
              dynamicFontSize = (availableWidth / factor).clamp(24.0, 48.0);
            } else {
              final factor = surahCount >= 2 ? 31.0 : 29.0;
              dynamicFontSize = (availableHeight / factor).clamp(18.0, 42.0);
            }

            final lineBuilder = MashafLineBuilder(
              context: context,
              fontSize: dynamicFontSize,
              onAyahTap: widget.onAyahTap,
              selectedAyah: widget.selectedAyah,
            );

            final children = lineBuilder.buildLines(_lines!);

            if (isLandscape) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
