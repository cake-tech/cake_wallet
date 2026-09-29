import "package:flutter/material.dart";

/// Renders [text] as a centered [RichText], making every case-insensitive
/// occurrence of [highlightWord] bold.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    required this.text,
    required this.highlightWord,
    super.key,
  });

  final String text;
  final String highlightWord;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5);
    final highlightStyle = baseStyle?.copyWith(fontWeight: FontWeight.w700);

    final regex = RegExp(RegExp.escape(highlightWord), caseSensitive: false);
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(text: text, style: baseStyle),
      );
    }

    final List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      if (start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, start), style: baseStyle));
      }

      spans.add(TextSpan(text: text.substring(start, end), style: highlightStyle));

      lastMatchEnd = end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }
}
