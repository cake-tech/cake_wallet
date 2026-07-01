import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KeyboardDoneButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.only(right: 24.0, top: 8.0, bottom: 8.0),
      onPressed: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Text(
        S.of(context).done,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
