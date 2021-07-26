import 'package:cake_wallet/src/widgets/standart_switch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UnspentCoinsSwitchRow extends StatelessWidget {
  UnspentCoinsSwitchRow(
       {this.title,
        this.titleFontSize = 14,
        this.switchValue,
        this.onSwitchValueChange});

  final String title;
  final double titleFontSize;
  final bool switchValue;
  final void Function(bool value) onSwitchValueChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).backgroundColor,
      child: Padding(
        padding:
        const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .primaryTextTheme.overline.color),
                  textAlign: TextAlign.left),
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: StandartSwitch(
                    value: switchValue,
                    onTaped: () => onSwitchValueChange(!switchValue))
              )
            ]),
      ),
    );
  }
}