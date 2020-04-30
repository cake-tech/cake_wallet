import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';
import 'package:provider/provider.dart';

class RestoreWalletOptionsPage extends BasePage {

  @override
  String get title => S.current.restore_seed_keys_restore;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  final imageSeed = Image.asset('assets/images/restore_seed.png');
  final imageKeys = Image.asset('assets/images/restore_keys.png');

  @override
  Widget body(BuildContext context) {
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    return Container(
      padding: EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            RestoreButton(
                onPressed: () {
                  seedLanguageStore.setCurrentRoute(Routes.restoreWalletFromSeed);
                  Navigator.pushNamed(context, Routes.seedLanguage);
                },
                image: imageSeed,
                title: S.of(context).restore_title_from_seed,
                description: S.of(context).restore_description_from_seed
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: RestoreButton(
                  onPressed: () {
                    seedLanguageStore.setCurrentRoute(Routes.restoreWalletFromKeys);
                    Navigator.pushNamed(context, Routes.seedLanguage);
                  },
                  image: imageKeys,
                  title: S.of(context).restore_title_from_keys,
                  description: S.of(context).restore_description_from_keys
              ),
            )
          ],
        ),
      )
    );


      /*BaseRestoreWidget(
      firstRestoreButton: RestoreButton(
        onPressed: () {
          seedLanguageStore.setCurrentRoute(Routes.restoreWalletFromSeed);
          Navigator.pushNamed(context, Routes.seedLanguage);
        },
        imageWidget: ImageWidget(
            image: _imageSeed,
            aspectRatioImage: _aspectRatioImage,
            isLargeScreen: isLargeScreen),
        titleColor: Palette.lightViolet,
        color: Palette.lightViolet,
        title: S.of(context).restore_title_from_seed,
        description: S.of(context).restore_description_from_seed,
        textButton: S.of(context).restore_next,
      ),
      secondRestoreButton: RestoreButton(
        onPressed: () {
          seedLanguageStore.setCurrentRoute(Routes.restoreWalletFromKeys);
          Navigator.pushNamed(context, Routes.seedLanguage);
        },
        imageWidget: ImageWidget(
            image: _imageKeys,
            aspectRatioImage: _aspectRatioImage,
            isLargeScreen: isLargeScreen),
        titleColor: Palette.cakeGreen,
        color: Palette.cakeGreen,
        title: S.of(context).restore_title_from_keys,
        description: S.of(context).restore_description_from_keys,
        textButton: S.of(context).restore_next,
      ),
      isLargeScreen: isLargeScreen,
    );*/
  }
}
