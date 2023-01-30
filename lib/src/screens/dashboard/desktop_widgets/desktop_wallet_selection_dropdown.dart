import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class DesktopWalletSelectionDropDown extends StatefulWidget {
  final WalletListViewModel walletListViewModel;

  DesktopWalletSelectionDropDown(this.walletListViewModel, {Key? key}) : super(key: key);

  @override
  State<DesktopWalletSelectionDropDown> createState() => _DesktopWalletSelectionDropDownState();
}

class _DesktopWalletSelectionDropDownState extends State<DesktopWalletSelectionDropDown> {
  final moneroIcon = Image.asset('assets/images/monero_logo.png', height: 24, width: 24);
  final bitcoinIcon = Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
  final litecoinIcon = Image.asset('assets/images/litecoin_icon.png', height: 24, width: 24);
  final havenIcon = Image.asset('assets/images/haven_logo.png', height: 24, width: 24);
  final nonWalletTypeIcon = Image.asset('assets/images/close.png', height: 24, width: 24);

  final double tileHeight = 60;

  Flushbar<void>? _progressBar;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return DropdownButton<WalletListItem>(
      items: widget.walletListViewModel.wallets
          .map((wallet) => DropdownMenuItem(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: walletListItemTile(wallet),
                ),
                value: wallet,
              ))
          .toList(),
      onChanged: (selectedWallet) async {
        if (selectedWallet!.isCurrent || !selectedWallet.isEnabled) {
          return;
        }

        final confirmed = await showPopUp<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertWithTwoActions(
                      alertTitle: S.of(context).change_wallet_alert_title,
                      alertContent: S.of(context).change_wallet_alert_content(selectedWallet.name),
                      leftButtonText: S.of(context).cancel,
                      rightButtonText: S.of(context).change,
                      actionLeftButton: () => Navigator.of(context).pop(false),
                      actionRightButton: () => Navigator.of(context).pop(true));
                }) ??
            false;

        if (confirmed) {
          await _loadWallet(selectedWallet);
        }
      },
      dropdownColor: themeData.textTheme.bodyText1?.decorationColor,
      style: TextStyle(color: themeData.primaryTextTheme.headline6?.color),
      selectedItemBuilder: (context) => widget.walletListViewModel.wallets
          .map((wallet) => ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: walletListItemTile(wallet),
              ))
          .toList(),
      value: widget.walletListViewModel.wallets.firstWhere((element) => element.isCurrent),
      underline: const SizedBox(),
      focusColor: Colors.transparent,
    );
  }

  Widget walletListItemTile(WalletListItem wallet) {
    return Container(
      height: tileHeight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          wallet.isEnabled ? _imageFor(type: wallet.type) : nonWalletTypeIcon,
          SizedBox(width: 10),
          Flexible(
            child: Text(
              wallet.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryTextTheme.headline6!.color!,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )
        ],
      ),
    );
  }

  Image _imageFor({required WalletType type}) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.monero:
        return moneroIcon;
      case WalletType.litecoin:
        return litecoinIcon;
      case WalletType.haven:
        return havenIcon;
      default:
        return nonWalletTypeIcon;
    }
  }

  Future<void> _loadWallet(WalletListItem wallet) async {
    if (await widget.walletListViewModel.checkIfAuthRequired()) {
      await Navigator.of(context).pushNamed(Routes.auth,
          arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
        if (!isAuthenticatedSuccessfully) {
          return;
        }

        try {
          auth.changeProcessText(S.of(context).wallet_list_loading_wallet(wallet.name));
          await widget.walletListViewModel.loadWallet(wallet);
          auth.hideProgressText();
          auth.close();
          setState(() {});
        } catch (e) {
          auth.changeProcessText(
              S.of(context).wallet_list_failed_to_load(wallet.name, e.toString()));
        }
      });
    } else {
      try {
        changeProcessText(S.of(context).wallet_list_loading_wallet(wallet.name));
        await widget.walletListViewModel.loadWallet(wallet);
        hideProgressText();
        setState(() {});
      } catch (e) {
        changeProcessText(S.of(context).wallet_list_failed_to_load(wallet.name, e.toString()));
      }
    }
  }

  void changeProcessText(String text) {
    _progressBar = createBar<void>(text, duration: null)..show(context);
  }

  void hideProgressText() {
    _progressBar?.dismiss();
    _progressBar = null;
  }
}
