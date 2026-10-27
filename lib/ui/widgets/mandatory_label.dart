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

    if (!isRequired) {
      return Text(cleanText, style: style);
    }

    return Text.rich(
      TextSpan(
        text: cleanText,
        style: style,
        children: [
          const TextSpan(text: ' '),
          TextSpan(
            text: '*',
            style: TextStyle(
              color: starColor,
              fontWeight: FontWeight.bold,
              fontSize: (style?.fontSize != null) ? (style!.fontSize! + 1) : 14,
            ),
          ),
        ],
      ),
    );
  }
}
