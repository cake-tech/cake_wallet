import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class EverstakeTermsText extends StatefulWidget {
  const EverstakeTermsText(this.acceptance, {super.key});

  final String Function(String terms) acceptance;

  @override
  State<EverstakeTermsText> createState() => _EverstakeTermsTextState();
}

class _EverstakeTermsTextState extends State<EverstakeTermsText> {
  static const _linkMarker = "\u{FFFC}";

  late final _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => launchUrl(
          Uri.https("everstake.com", "/terms-of-use"),
          mode: LaunchMode.externalApplication,
        );

  @override
  void dispose() {
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final [before, after] = widget.acceptance(_linkMarker).split(_linkMarker);

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: S.of(context).everstake_terms,
            style: TextStyle(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: colorScheme.primary,
            ),
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: after),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
