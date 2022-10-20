import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
// import 'package:esys_flutter_share/esys_flutter_share.dart';
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
  ReceivePage({required this.addressListViewModel}) : _cryptoAmountFocus = FocusNode();

  final WalletAddressListViewModel addressListViewModel;

  @override
  String get title => S.current.receive;

  @override
  Color get backgroundLightColor => currentTheme.type == ThemeType.bright
      ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomInset => false;

  final FocusNode _cryptoAmountFocus;

  @override
  Widget leading(BuildContext context) {
    final _backButton = Icon(Icons.arrow_back_ios,
      color: Theme.of(context).accentTextTheme!.headline2!.backgroundColor!,
      size: 16,);

    return SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: TextButton(
          // FIX-ME: Style
            //highlightColor: Colors.transparent,
            //splashColor: Colors.transparent,
            //padding: EdgeInsets.all(0),
            onPressed: () => onClose(context),
            child: _backButton),
      ),
    );
  }

  @override
  Widget middle(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
          color: Theme.of(context).accentTextTheme!.headline2!.backgroundColor!),
    );
  }

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).accentColor,
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor,
          ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: scaffold);

  @override
  Widget trailing(BuildContext context) {
    final shareImage =
        Image.asset('assets/images/share.png',
            color: Theme.of(context).accentTextTheme!.headline2!.backgroundColor!);

    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: TextButton(
            // FIX-ME: Style
            //highlightColor: Colors.transparent,
            //splashColor: Colors.transparent,
            //padding: EdgeInsets.all(0),
            onPressed: () {
              // FIX-ME: Share esys_flutter_share.dart
              // Share.text(S.current.share_address,
              //   addressListViewModel.address.address, 'text/plain')
            },
            child: shareImage),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return (addressListViewModel.type == WalletType.monero || addressListViewModel.type == WalletType.haven)
        ? KeyboardActions(
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).accentTextTheme!.bodyText1!
                .backgroundColor!,
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
                padding: EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: QRWidget(
                    addressListViewModel: addressListViewModel,
                    isAmountFieldShow: true,
                    amountTextFieldFocusNode: _cryptoAmountFocus,
                    isLight: currentTheme.type == ThemeType.light),
              ),
              Observer(
                  builder: (_) => ListView.separated(
                      padding: EdgeInsets.all(0),
                      separatorBuilder: (context, _) => Container(
                          height: 1, color: Theme.of(context).dividerColor),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: addressListViewModel.items.length,
                      itemBuilder: (context, index) {
                        final item = addressListViewModel.items[index];
                        Widget cell = Container();

                        if (item is WalletAccountListHeader) {
                          cell = HeaderTile(
                              onTap: () async => await showPopUp<void>(
                                  context: context,
                                  builder: (_) =>
                                      getIt.get<MoneroAccountListPage>()),
                              title: S.of(context).accounts,
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color:
                                Theme.of(context).textTheme!.headline4!.color!,
                              ));
                        }

                        if (item is WalletAddressListHeader) {
                          cell = HeaderTile(
                              onTap: () => Navigator.of(context)
                                  .pushNamed(Routes.newSubaddress),
                              title: S.of(context).addresses,
                              icon: Icon(
                                Icons.add,
                                size: 20,
                                color:
                                Theme.of(context).textTheme!.headline4!.color!,
                              ));
                        }

                        if (item is WalletAddressListItem) {
                          cell = Observer(builder: (_) {
                            final isCurrent = item.address ==
                                addressListViewModel.address.address;
                            final backgroundColor = isCurrent
                                ? Theme.of(context)
                                .textTheme!
                                .headline2!
                                .decorationColor!
                                : Theme.of(context)
                                .textTheme!
                                .headline3!
                                .decorationColor!;
                            final textColor = isCurrent
                                ? Theme.of(context).textTheme!.headline2!.color!
                                : Theme.of(context).textTheme!.headline3!.color!;

                            return AddressCell.fromItem(item,
                                isCurrent: isCurrent,
                                backgroundColor: backgroundColor,
                                textColor: textColor,
                                onTap: (_) => addressListViewModel.setAddress(item),
                                onEdit: () => Navigator.of(context).pushNamed(
                                    Routes.newSubaddress,
                                    arguments: item));
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
        )) : Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: QRWidget(
                addressListViewModel: addressListViewModel,
                isAmountFieldShow: true,
                amountTextFieldFocusNode: _cryptoAmountFocus,
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
                  color: Theme.of(context)
                      .accentTextTheme!
                      .headline3!
                      .backgroundColor!)),
        ],
      ),
    );
  }
}
