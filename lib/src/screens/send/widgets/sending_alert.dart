import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/stores/send/sending_state.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/stores/send/send_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SendingAlert extends StatefulWidget {
  SendingAlert({@required this.sendStore});

  final SendStore sendStore;

  @override
  SendingAlertState createState() => SendingAlertState(sendStore);
}

class SendingAlertState extends State<SendingAlert> {
  SendingAlertState(this.sendStore);

  final SendStore sendStore;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final state = sendStore.state;

        if (state is TransactionCommitted) {
          return Stack(
            children: <Widget>[
              Container(
                color: Theme.of(context).backgroundColor,
                  child: Center(
                    child: Image.asset(
                        'assets/images/birthday_cake.png'),
                  ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 220, left: 24, right: 24),
                  child: Text(
                    S.of(context).send_success,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryTextTheme.title.color,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: PrimaryButton(
                  onPressed: () => Navigator.of(context).pop(),
                  text: S.of(context).send_got_it,
                  color: Colors.blue,
                  textColor: Colors.white
                )
              )
            ],
          );
        }

        return Stack(
          children: <Widget>[
            Container(
              color: Theme.of(context).backgroundColor,
              child: Center(
                child: Image.asset(
                    'assets/images/birthday_cake.png'),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(
                decoration: BoxDecoration(color: Theme.of(context).backgroundColor.withOpacity(0.25)),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 220),
                    child: Text(
                      S.of(context).send_sending,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryTextTheme.title.color,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      }
    );
  }
}