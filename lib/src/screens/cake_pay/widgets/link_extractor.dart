import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget ClickableLinksText(
    {required String text, required TextStyle textStyle, required TextStyle linkStyle}) {
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
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode:
                        LaunchMode.externalApplication // This opens the URL in the external browser
                    );
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
