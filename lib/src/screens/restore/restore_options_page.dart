import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_button.dart';
import 'package:cake_wallet/src/screens/restore/widgets/image_widget.dart';
import 'package:cake_wallet/src/screens/restore/widgets/base_restore_widget.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class RestoreOptionsPage extends BasePage {
  RestoreOptionsPage({@required this.type});
  
  static const _aspectRatioImage = 2.086;
  final WalletType type;

  @override
  String get title => S.current.restore_restore_wallet;

  @override
  Color get backgroundColor => Palette.creamyGrey;

  final _imageSeedKeys = Image.asset('assets/images/seedKeys.png');
  final _imageRestoreSeed = Image.asset('assets/images/restoreSeed.png');

  @override
  Widget body(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.height > largeHeight;

    return BaseRestoreWidget(
      firstRestoreButton: RestoreButton(
        onPressed: () =>
          Navigator.pushNamed(
              context, Routes.restoreWalletOptionsFromWelcome),
        imageWidget: ImageWidget(
          image: _imageSeedKeys,
          aspectRatioImage: _aspectRatioImage,
          isLargeScreen: isLargeScreen,
        ),
        titleColor: Palette.lightViolet,
        color: Palette.lightViolet,
        title: S.of(context).restore_title_from_seed_keys,
        description: S.of(context).restore_description_from_seed_keys,
        textButton: S.of(context).restore_next,
      ),
      secondRestoreButton: RestoreButton(
        onPressed: () {},
        imageWidget: ImageWidget(
          image: _imageRestoreSeed,
          aspectRatioImage: _aspectRatioImage,
          isLargeScreen: isLargeScreen,
        ),
        titleColor: Palette.cakeGreen,
        color: Palette.cakeGreen,
        title: S.of(context).restore_title_from_backup,
        description: S.of(context).restore_description_from_backup,
        textButton: S.of(context).restore_next,
      ),
      isLargeScreen: isLargeScreen,
    );
  }
}
