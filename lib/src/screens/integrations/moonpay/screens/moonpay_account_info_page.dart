import 'dart:convert';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:flutter/material.dart';

class MoonPayAccountInfoPage extends BasePage {
  MoonPayAccountInfoPage({required this.rawData});

  final dynamic rawData;

  @override
  String get title => 'Virtual Account (Iron)';

  String get _json {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(rawData);
    } catch (_) {
      return rawData.toString();
    }
  }

  @override
  Widget body(BuildContext context) {
    final textTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
        fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Account Details',
            textAlign: TextAlign.center,
            style: textTextStyle,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _json,
                style: textTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
