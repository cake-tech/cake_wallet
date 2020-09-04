import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';

class RestoreWalletOptionsPage extends BasePage {
  RestoreWalletOptionsPage(
      {@required this.type,
      @required this.onRestoreFromSeed,
      @required this.onRestoreFromKeys});

  final WalletType type;
  final Function(BuildContext context) onRestoreFromSeed;
  final Function(BuildContext context) onRestoreFromKeys;

  @override
  String get title => S.current.restore_restore_wallet;

  final imageSeed = Image.asset('assets/images/restore_seed.png');
  final imageKeys = Image.asset('assets/images/restore_keys.png');

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
                  onPressed: () => onRestoreFromSeed(context),
                  image: imageSeed,
                  title: S.of(context).restore_title_from_seed,
                  description: _fromSeedDescription(context)),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: RestoreButton(
                    onPressed: () => onRestoreFromKeys(context),
                    image: imageKeys,
                    title: _fromKeyTitle(context),
                    description: _fromKeyDescription(context)),
              )
            ],
          ),
        ));
  }

  String _fromSeedDescription(BuildContext context) {
    switch (type) {
      case WalletType.monero:
        return S.of(context).restore_description_from_seed;
      case WalletType.bitcoin:
        // TODO: Add transaction for bitcoin description.
        return S.of(context).restore_bitcoin_description_from_seed;
      default:
        return '';
    }
  }

  String _fromKeyDescription(BuildContext context) {
    switch (type) {
      case WalletType.monero:
        return S.of(context).restore_description_from_keys;
      case WalletType.bitcoin:
        // TODO: Add transaction for bitcoin description.
        return S.of(context).restore_bitcoin_description_from_keys;
      default:
        return '';
    }
  }

  String _fromKeyTitle(BuildContext context) {
    switch (type) {
      case WalletType.monero:
        return S.of(context).restore_title_from_keys;
      case WalletType.bitcoin:
        // TODO: Add transaction for bitcoin description.
        return S.of(context).restore_bitcoin_title_from_keys;
      default:
        return '';
    }
  }
}
