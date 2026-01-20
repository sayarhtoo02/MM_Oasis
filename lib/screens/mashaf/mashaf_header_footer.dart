import 'package:flutter/material.dart';

/// Header widget for Mashaf page
class MashafHeader extends StatelessWidget {
  final String surahName;
  final int juzNumber;
  final String hizbInfo;

  const MashafHeader({
    super.key,
    required this.surahName,
    required this.juzNumber,
    required this.hizbInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Surah name (left)
          Text(
            surahName.isNotEmpty ? 'Surah $surahName' : 'Surah',
            style: const TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Indopak',
            ),
          ),
          // Juz info (center)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Juz $juzNumber',
              style: const TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Hizb info (right)
          Text(
            hizbInfo,
            style: const TextStyle(color: Color(0xFF5D4037), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Footer widget for Mashaf page
class MashafFooter extends StatelessWidget {
  final int pageNumber;

  const MashafFooter({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 10, color: Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          Text(
            '$pageNumber',
            style: const TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star, size: 10, color: Color(0xFFD4AF37)),
        ],
      ),
    );
  }
}
