import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class RestoreOptionsPage extends BasePage {

  @override
  String get title => S.current.restore_restore_wallet;

  final imageSeedKeys = Image.asset('assets/images/restore_wallet_image.png');
  final imageBackup = Image.asset('assets/images/backup.png');

  @override
  Widget body(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            RestoreButton(
                onPressed: () =>
                    Navigator.pushNamed(
                        context, Routes.restoreWalletOptionsFromWelcome),
                image: imageSeedKeys,
                title: S.of(context).restore_title_from_seed_keys,
                description: S.of(context).restore_description_from_seed_keys
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: RestoreButton(
                  onPressed: () {},
                  image: imageBackup,
                  title: S.of(context).restore_title_from_backup,
                  description: S.of(context).restore_description_from_backup
              ),
            )
          ],
        ),
      )
    );
  }
}
