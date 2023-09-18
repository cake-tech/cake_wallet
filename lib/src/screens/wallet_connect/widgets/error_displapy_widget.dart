import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class ErrorWidgetDisplay extends StatelessWidget {
  final String errorText;

  const ErrorWidgetDisplay({super.key, required this.errorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.current.error,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          errorText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
