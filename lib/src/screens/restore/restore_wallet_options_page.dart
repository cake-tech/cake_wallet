import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';

class RestoreWalletOptionsPage extends BasePage {
  RestoreWalletOptionsPage(
      {@required this.type,
      @required this.onRestoreFromSeed,
      @required this.onRestoreFromKeys});

  final WalletType type;
  final Function(BuildContext context) onRestoreFromSeed;
  final Function(BuildContext context) onRestoreFromKeys;

  @override
  String get title => S.current.restore_seed_keys_restore;

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
        return 'Restore your wallet from 12 word combination code';
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
        return 'Restore your wallet from generated WIF string from your private keys';
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
        return 'Restore from WIF';
      default:
        return '';
    }
  }
}
