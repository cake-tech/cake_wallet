import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:flutter/material.dart';

class UnspentCoinsSwitchRow extends StatelessWidget {
  UnspentCoinsSwitchRow(
      {required this.title,
      required this.switchValue,
      required this.onSwitchValueChange,
      this.titleFontSize = 14});

  final String title;
  final double titleFontSize;
  final bool switchValue;
  final void Function(bool value) onSwitchValueChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.left,
            ),
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: StandardSwitch(
                value: switchValue,
                onTapped: () => onSwitchValueChange(!switchValue),
              ),
            )
          ],
        ),
      ),
    );
  }
}
