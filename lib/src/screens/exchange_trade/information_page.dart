import 'dart:ui';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';

class InformationPage extends StatelessWidget {
  InformationPage({required this.information});

  final String information;

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Center(
        child: Container(
          margin: EdgeInsets.only(
            left: 24,
            right: 24
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            color: Theme.of(context).textTheme!.bodyLarge!.decorationColor!
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Text(
                  information,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Lato',
                    decoration: TextDecoration.none,
                    color: Theme.of(context).accentTextTheme!.bodySmall!.decorationColor!
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: PrimaryButton(
                  onPressed: () => Navigator.of(context).pop(),
                  text: S.of(context).send_got_it,
                  color: Theme.of(context).accentTextTheme!.bodySmall!.backgroundColor!,
                  textColor: Theme.of(context).primaryTextTheme!.titleLarge!.color!
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}
