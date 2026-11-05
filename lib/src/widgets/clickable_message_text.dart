import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

/// Renders arbitrary text and turns any http(s) URL it contains into a link
/// that opens in the external browser. Used to display a payer's free-form
/// LNURL message where embedded links must be tappable.
class ClickableMessageText extends StatefulWidget {
  const ClickableMessageText({
    required this.text,
    required this.textStyle,
    this.linkStyle,
    super.key,
  });

  final String text;
  final TextStyle textStyle;
  final TextStyle? linkStyle;

  @override
  State<ClickableMessageText> createState() => _ClickableMessageTextState();
}

class _ClickableMessageTextState extends State<ClickableMessageText> {
  static final RegExp _linkRegExp = RegExp(r"(https?:\/\/[^\s]+)");
  static const String _trailingPunctuation = '.,;:!?)]}"\'';

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  // A greedy [^\s]+ match swallows trailing sentence punctuation into the URL.
  // Keep only the leading portion as the link and render the rest as plain text.
  int _linkEnd(String url) {
    var end = url.length;
    while (end > 0 && _trailingPunctuation.contains(url[end - 1])) {
      end--;
    }
    return end;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final text = widget.text;
    final spans = <InlineSpan>[];
    var previousEnd = 0;

    for (final match in _linkRegExp.allMatches(text)) {
      if (match.start > previousEnd) {
        spans.add(
          TextSpan(text: text.substring(previousEnd, match.start), style: widget.textStyle),
        );
      }

      final matched = text.substring(match.start, match.end);
      final linkEnd = _linkEnd(matched);
      final url = matched.substring(0, linkEnd);
      final trailing = matched.substring(linkEnd);

      final recognizer = TapGestureRecognizer()..onTap = () => _launch(url);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(text: url, style: widget.linkStyle ?? widget.textStyle, recognizer: recognizer),
      );

      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing, style: widget.textStyle));
      }

      previousEnd = match.end;
    }

    if (previousEnd < text.length) {
      spans.add(TextSpan(text: text.substring(previousEnd), style: widget.textStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
