import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClickableLinksText extends StatelessWidget {
  const ClickableLinksText({
    required this.text,
    required this.textStyle,
    this.linkStyle,
  });

  final String text;
  final TextStyle textStyle;
  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> spans = [];
    RegExp linkRegExp = RegExp(r'(https?://[^\s]+)');
    Iterable<Match> matches = linkRegExp.allMatches(text);

    int previousEnd = 0;
    matches.forEach((match) {
      if (match.start > previousEnd) {
        spans.add(TextSpan(text: text.substring(previousEnd, match.start), style: textStyle));
      }
      String url = text.substring(match.start, match.end);
      if (url.toLowerCase().endsWith('.md')) {
        spans.add(
          TextSpan(
            text: url,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                   fontSize: 18,
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: url,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(Uri.parse(url));
              },
          ),
        );
      }
      previousEnd = match.end;
    });

    if (previousEnd < text.length) {
      spans.add(TextSpan(text: text.substring(previousEnd), style: textStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
