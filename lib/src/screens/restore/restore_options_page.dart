import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class RestoreOptionsPage extends BasePage {
  static const _aspectRatioImage = 2.086;

  String get title => S.current.restore_restore_wallet;
  Color get backgroundColor => Palette.creamyGrey;

  final _imageSeedKeys = Image.asset('assets/images/seedKeys.png');
  final _imageRestoreSeed = Image.asset('assets/images/restoreSeed.png');

  @override
  Widget body(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
        ),
        child: Column(
          children: <Widget>[
            Flexible(
              child: RestoreButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.restoreWalletOptionsFromWelcome);
                },
                image: _imageSeedKeys,
                aspectRatioImage: _aspectRatioImage,
                titleColor: Palette.lightViolet,
                color: Palette.lightViolet,
                title: S.of(context).restore_title_from_seed_keys,
                description: S.of(context).restore_description_from_seed_keys,
                textButton: S.of(context).restore_next,
              ),
            ),
            Flexible(
                child: RestoreButton(
              onPressed: () {},
              image: _imageRestoreSeed,
              aspectRatioImage: _aspectRatioImage,
              titleColor: Palette.cakeGreen,
              color: Palette.cakeGreen,
              title: S.of(context).restore_title_from_backup,
              description: S.of(context).restore_description_from_backup,
              textButton: S.of(context).restore_next,
            ))
          ],
        ),
      );
}
