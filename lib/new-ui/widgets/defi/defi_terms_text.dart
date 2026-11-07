import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

class DefiTermsLink {
  const DefiTermsLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

class DefiTermsText extends StatefulWidget {
  const DefiTermsText(this.sentence, {required this.links, super.key});

  final String Function(List<String> linkPlaceholders) sentence;
  final List<DefiTermsLink> links;

  @override
  State<DefiTermsText> createState() => _DefiTermsTextState();
}

class _DefiTermsTextState extends State<DefiTermsText> {
  static const _linkMarker = "\u{FFFC}";
  static final _linkPattern = RegExp("$_linkMarker(\\d+)$_linkMarker");

  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final links = widget.links;
    while (_recognizers.length < links.length) {
      _recognizers.add(TapGestureRecognizer());
    }
    final sentence = widget.sentence([
      for (var index = 0; index < links.length; index++) "$_linkMarker$index$_linkMarker",
    ]);
    final linkStyle = TextStyle(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary,
    );

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _linkPattern.allMatches(sentence)) {
      final index = int.parse(match.group(1)!);
      spans
        ..add(TextSpan(text: sentence.substring(start, match.start)))
        ..add(
          TextSpan(
            text: links[index].label,
            style: linkStyle,
            recognizer: _recognizers[index]..onTap = links[index].onTap,
          ),
        );
      start = match.end;
    }
    spans.add(TextSpan(text: sentence.substring(start)));

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        children: spans,
      ),
      textAlign: TextAlign.center,
    );
  }
}
