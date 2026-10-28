import 'package:flutter/material.dart';

/// A reusable widget that displays a field label with a prominent red asterisk (*)
/// to indicate mandatory / required form fields.
class MandatoryLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isRequired;
  final Color starColor;

  const MandatoryLabel(
    this.text, {
    super.key,
    this.isRequired = true,
    this.style,
    this.starColor = const Color(0xFFE53935), // Vivid Red
  });

  @override
  Widget build(BuildContext context) {
    // Strip trailing ' *' or '*' if already present in the string
    String cleanText = text;
    if (cleanText.endsWith(' *')) {
      cleanText = cleanText.substring(0, cleanText.length - 2);
    } else if (cleanText.endsWith('*')) {
      cleanText = cleanText.substring(0, cleanText.length - 1).trimRight();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
    );
    final effectiveStyle = style ?? defaultStyle;

    if (!isRequired) {
      return Text(cleanText, style: effectiveStyle);
    }

    return Text.rich(
      TextSpan(
        text: cleanText,
        style: effectiveStyle,
        children: [
          const TextSpan(text: ' '),
          TextSpan(
            text: '*',
            style: TextStyle(
              color: starColor,
              fontWeight: FontWeight.bold,
              fontSize: (effectiveStyle.fontSize != null) ? (effectiveStyle.fontSize! + 1) : 14,
            ),
          ),
        ],
      ),
    );
  }
}
