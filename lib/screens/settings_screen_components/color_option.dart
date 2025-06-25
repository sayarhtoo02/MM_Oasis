import 'package:flutter/material.dart';

class ColorOption extends StatelessWidget {
  final Color color;
  final Color currentColor;
  final Function(Color) onColorChanged;

  const ColorOption({
    super.key,
    required this.color,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: currentColor == color ? colorScheme.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: currentColor == color
            ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
            : null,
      ),
    );
  }
}