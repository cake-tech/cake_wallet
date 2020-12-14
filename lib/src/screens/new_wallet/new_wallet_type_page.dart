import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';

class NewWalletTypePage extends BasePage {
  NewWalletTypePage({this.onTypeSelected, this.isNewWallet = true});

  final void Function(BuildContext, WalletType) onTypeSelected;
  final bool isNewWallet;

  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage =
               Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title => isNewWallet
                      ? S.current.new_wallet
                      : S.current.wallet_list_restore_wallet;

  @override
  Widget body(BuildContext context) =>
      WalletTypeForm(
          onTypeSelected: onTypeSelected,
          walletImage: currentTheme.isDarkTheme
              ? walletTypeImage : walletTypeLightImage);
}

class WalletTypeForm extends StatefulWidget {
  WalletTypeForm({this.onTypeSelected, this.walletImage});

  final void Function(BuildContext, WalletType) onTypeSelected;
  final Image walletImage;

  @override
  WalletTypeFormState createState() => WalletTypeFormState();
}

class WalletTypeFormState extends State<WalletTypeForm> {
  static const aspectRatioImage = 1.22;

  final moneroIcon =
      Image.asset('assets/images/monero_logo.png', height: 24, width: 24);
  final bitcoinIcon =
      Image.asset('assets/images/bitcoin.png', height: 24, width: 24);

  WalletType selected;
  List<WalletType> types;

  @override
  void initState() {
    types = [WalletType.bitcoin, WalletType.monero];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: AspectRatio(
                  aspectRatio: aspectRatioImage,
                  child: FittedBox(child: widget.walletImage, fit: BoxFit.fill)),
            ),
            Padding(
              padding: EdgeInsets.only(top: 48),
              child: Text(
                S.of(context).choose_wallet_currency,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryTextTheme.title.color),
              ),
            ),
            ...types.map((type) => Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: SelectButton(
                      image: _iconFor(type),
                      text: walletTypeToString(type),
                      isSelected: selected == type,
                      onTap: () => setState(() => selected = type)),
                ))
          ],
        ),
        bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        bottomSection: PrimaryButton(
          onPressed: () => widget.onTypeSelected(context, selected),
          text: S.of(context).seed_language_next,
          color: Colors.green,
          textColor: Colors.white,
          isDisabled: selected == null,
        ),
      ),
    );
  }

  Image _iconFor(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return moneroIcon;
      case WalletType.bitcoin:
        return bitcoinIcon;
      default:
        return null;
    }
  }
}
