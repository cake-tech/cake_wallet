import 'package:cake_wallet/src/screens/nano_accounts/nano_account_list_page.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/header_tile.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_cell.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_widget.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class ReceivePage extends BasePage {
  ReceivePage({required this.addressListViewModel})
      : _cryptoAmountFocus = FocusNode(),
        _amountController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    _amountController.addListener(() {
      if (_formKey.currentState!.validate()) {
        addressListViewModel.changeAmount(_amountController.text);
      }
    });
  }

  final WalletAddressListViewModel addressListViewModel;
  final TextEditingController _amountController;
  final GlobalKey<FormState> _formKey;
  static const _heroTag = 'receive_page';

  @override
  String get title => S.current.receive;

  @override
  bool get gradientBackground => true;

  @override
  bool get resizeToAvoidBottomInset => true;

  final FocusNode _cryptoAmountFocus;

  @override
  Widget middle(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
          color: pageIconColor(context)),
    );
  }

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) =>
          GradientBackground(scaffold: scaffold);

  @override
  Widget trailing(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: Semantics(
          label: S.of(context).share,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            iconSize: 25,
            onPressed: () {
              ShareUtil.share(
                text: addressListViewModel.uri.toString(),
                context: context,
              );
            },
            icon: Icon(
              Icons.share,
              size: 20,
              color: pageIconColor(context),
            ),
          ),
        ));
  }

  @override
  Widget body(BuildContext context) {
    final isElectrumWallet = addressListViewModel.isElectrumWallet;
    return (addressListViewModel.type == WalletType.monero ||
            addressListViewModel.type == WalletType.haven ||
            addressListViewModel.type == WalletType.nano ||
        isElectrumWallet)
        ? KeyboardActions(
            config: KeyboardActionsConfig(
                keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
                keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
                nextFocus: false,
                actions: [
                  KeyboardActionsItem(
                    focusNode: _cryptoAmountFocus,
                    toolbarButtons: [(_) => KeyboardDoneButton()],
                  )
                ]),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 50, 24, 24),
                    child: QRWidget(
                        addressListViewModel: addressListViewModel,
                        formKey: _formKey,
                        heroTag: _heroTag,
                        amountTextFieldFocusNode: _cryptoAmountFocus,
                        amountController: _amountController,
                        isLight: currentTheme.type == ThemeType.light),
                  ),
                  Observer(
                      builder: (_) => ListView.separated(
                          padding: EdgeInsets.all(0),
                          separatorBuilder: (context, _) => const HorizontalSectionDivider(),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: addressListViewModel.items.length,
                          itemBuilder: (context, index) {
                            final item = addressListViewModel.items[index];
                            Widget cell = Container();

                            if (item is WalletAccountListHeader) {
                              cell = HeaderTile(
                                  showTrailingButton: true,
                                  walletAddressListViewModel: addressListViewModel,
                                  trailingButtonTap: () async {
                                    if (addressListViewModel.type == WalletType.monero ||
                                        addressListViewModel.type == WalletType.haven) {
                                      await showPopUp<void>(
                                          context: context,
                                          builder: (_) => getIt.get<MoneroAccountListPage>());
                                    } else {
                                      await showPopUp<void>(
                                          context: context,
                                          builder: (_) => getIt.get<NanoAccountListPage>());
                                    }
                                  },
                                  title: S.of(context).accounts,
                                  trailingIcon: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Theme.of(context).extension<ReceivePageTheme>()!.iconsColor,
                                  ));
                            }

                            if (item is WalletAddressListHeader) {
                                cell = HeaderTile(
                                    title: S.of(context).addresses,
                                    walletAddressListViewModel: addressListViewModel,
                                    showTrailingButton: !addressListViewModel.isAutoGenerateSubaddressEnabled,
                                    showSearchButton: true,
                                    trailingButtonTap: () =>
                                        Navigator.of(context).pushNamed(Routes.newSubaddress),
                                    trailingIcon: Icon(
                                      Icons.add,
                                      size: 20,
                                      color: Theme.of(context)
                                          .extension<ReceivePageTheme>()!
                                          .iconsColor,
                                    ));
                              }

                            if (item is WalletAddressListItem) {
                              cell = Observer(builder: (_) {
                                final isCurrent =
                                    item.address == addressListViewModel.address.address;
                                final backgroundColor = isCurrent
                                    ? Theme.of(context).extension<ReceivePageTheme>()!.currentTileBackgroundColor
                                    : Theme.of(context).extension<ReceivePageTheme>()!.tilesBackgroundColor;
                                final textColor = isCurrent
                                    ? Theme.of(context).extension<ReceivePageTheme>()!.currentTileTextColor
                                    : Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor;

                                return AddressCell.fromItem(item,
                                    isCurrent: isCurrent,
                                    hasBalance: addressListViewModel.isElectrumWallet,
                                    backgroundColor: backgroundColor,
                                    textColor: textColor,
                                    onTap: (_) => addressListViewModel.setAddress(item),
                                    onEdit: () => Navigator.of(context)
                                        .pushNamed(Routes.newSubaddress, arguments: item));
                              });
                            }

                            return index != 0
                                ? cell
                                : ClipRRect(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(30),
                                        topRight: Radius.circular(30)),
                                    child: cell,
                                  );
                          })),
                ],
              ),
            ))
        : Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Expanded(
                  flex: 7,
                  child: QRWidget(
                      formKey: _formKey,
                      heroTag: _heroTag,
                      addressListViewModel: addressListViewModel,
                      amountTextFieldFocusNode: _cryptoAmountFocus,
                      amountController: _amountController,
                      isLight: currentTheme.type == ThemeType.light),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(),
                ),
                Text(S.of(context).electrum_address_disclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor)),
              ],
            ),
          );
  }
}
