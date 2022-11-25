import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:path_provider/path_provider.dart';

class FailurePage extends StatelessWidget {
  final String? error;
  final StackTrace? stackTrace;

  FailurePage({Key? key, this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.warning,
                color: theme.errorColor,
                size: 50,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Oops, we got some error.",
                  style: theme.textTheme.headline1?.copyWith(fontSize: 20),
                ),
              ),
              Text(
                "Please send crash report to our support team to make the application better.",
                textAlign: TextAlign.center,
                style: theme.textTheme.headline1?.copyWith(fontSize: 16),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: PrimaryButton(
                  onPressed: _sendExceptionFile,
                  text: S.of(context).send,
                  textColor: Colors.white,
                  color: theme.accentTextTheme.bodyText1!.color!,
                ),
              ),
              PrimaryButton(
                onPressed: () {
                },
                text: "Don't Send",
                color: Theme.of(context).accentTextTheme.caption!.color!,
                textColor:
                    Theme.of(context).primaryTextTheme.headline6!.color!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendExceptionFile() async {
    final appDocDir = await getApplicationDocumentsDirectory();

    final file = File('${appDocDir.path}/error.txt');

    print(file.readAsStringSync());

    final MailOptions mailOptions = MailOptions(
      subject: 'Mobile App Issue',
      recipients: ['support@cakewallet.com'],
      attachments: [file.path],
    );

    await FlutterMailer.send(mailOptions);

    // clear file content
    // file.writeAsString("", mode: FileMode.write);
  }
}
