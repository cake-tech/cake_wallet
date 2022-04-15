import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:flushbar/flushbar.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/wallet_types.g.dart';

class NewWalletTypePage extends BasePage {
  NewWalletTypePage(this.walletNewVM, {this.onTypeSelected, this.isNewWallet});

  final void Function(BuildContext, WalletType) onTypeSelected;
  final bool isNewWallet;
  final WalletNewVM walletNewVM;

  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage =
      Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title =>
      isNewWallet ? S.current.new_wallet : S.current.wallet_list_restore_wallet;

  @override
  Widget body(BuildContext context) => WalletTypeForm(walletNewVM, isNewWallet,
      onTypeSelected: onTypeSelected,
      walletImage: currentTheme.type == ThemeType.dark
          ? walletTypeImage
          : walletTypeLightImage);
}

class WalletTypeForm extends StatefulWidget {
  WalletTypeForm(this.walletNewVM, this.isNewWallet,
      {this.onTypeSelected, this.walletImage});

  final void Function(BuildContext, WalletType) onTypeSelected;
  final WalletNewVM walletNewVM;
  final bool isNewWallet;
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
  final litecoinIcon =
      Image.asset('assets/images/litecoin_icon.png', height: 24, width: 24);
  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage =
      Image.asset('assets/images/wallet_type_light.png');
  final havenIcon =
      Image.asset('assets/images/haven_logo.png', height: 24, width: 24);

  WalletType selected;
  List<WalletType> types;
  Flushbar<void> _progressBar;

  @override
  void initState() {
    types = availableWalletTypes;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableWithBottomSection(
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
                    text: walletTypeToDisplayName(type),
                    isSelected: selected == type,
                    onTap: () => setState(() => selected = type)),
              ))
        ],
      ),
      bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
      bottomSection: PrimaryButton(
        onPressed: () => onTypeSelected(),
        text: S.of(context).seed_language_next,
        color: Theme.of(context).accentTextTheme.body2.color,
        textColor: Colors.white,
        isDisabled: selected == null,
      ),
    );
  }

  Image _iconFor(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return moneroIcon;
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.litecoin:
        return litecoinIcon;
      case WalletType.haven:
        return havenIcon;
      default:
        return null;
    }
  }

  Future<void> onTypeSelected() async {
    if (!widget.isNewWallet) {
      widget.onTypeSelected(context, selected);
      return;
    }

    try {
      _changeProcessText(S.of(context).creating_new_wallet);
      widget.walletNewVM.type = selected;
      await widget.walletNewVM
          .create(options: 'English'); // FIXME: Unnamed constant
      await _progressBar?.dismiss();
      final state = widget.walletNewVM.state;

      if (state is ExecutedSuccessfullyState) {
        widget.onTypeSelected(context, selected);
      }

      if (state is FailureState) {
        _changeProcessText(
            S.of(context).creating_new_wallet_error(state.error));
      }
    } catch (e) {
      _changeProcessText(S.of(context).creating_new_wallet_error(e.toString()));
    }
  }

  void _changeProcessText(String text) {
    _progressBar = createBar<void>(text, duration: null)..show(context);
  }
}
