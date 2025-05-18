import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';

class InformationPage extends StatelessWidget {
  InformationPage({required this.information, super.key});

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
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Text(
                  information,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Lato',
                    decoration: TextDecoration.none,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: PrimaryButton(
                  key: ValueKey('information_page_got_it_button_key'),
                  onPressed: () => Navigator.of(context).pop(),
                  text: S.of(context).got_it,
                  color: Theme.of(context).colorScheme.surface,
                  textColor: Theme.of(context).colorScheme.primary,
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}
