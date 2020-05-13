import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/src/stores/exchange/limits_state.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/top_panel.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/provider_picker.dart';

class ExchangeTemplatePage extends BasePage {
  @override
  String get title => 'New template';

  @override
  Color get backgroundColor => PaletteDark.walletCardSubAddressField;

  final Image arrowBottom =
  Image.asset('assets/images/arrow_bottom_purple_icon.png', color: Colors.white, height: 8);

  @override
  Widget trailing(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);

    return FlatButton(
        onPressed: () => _presentProviderPicker(context),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(S.of(context).exchange,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.white)),
                Observer(
                    builder: (_) => Text('${exchangeStore.provider.title}',
                        style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w400,
                            color:PaletteDark.walletCardText)))
              ],
            ),
            SizedBox(width: 5),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: arrowBottom,
            )
          ],
        )
    );
  }

  void _presentProviderPicker(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);
    final items = exchangeStore.providersForCurrentPair();
    final selectedItem = items.indexOf(exchangeStore.provider);

    showDialog<void>(
        builder: (_) => ProviderPicker(
            items: items,
            selectedAtIndex: selectedItem,
            title: S.of(context).change_exchange_provider,
            onItemSelected: (ExchangeProvider provider) =>
                exchangeStore.changeProvider(provider: provider)),
        context: context);
  }

  @override
  Widget body(BuildContext context) => ExchangeTemplateForm();
}

class ExchangeTemplateForm extends StatefulWidget{
  @override
  ExchangeTemplateFormState createState() => ExchangeTemplateFormState();
}

class ExchangeTemplateFormState extends State<ExchangeTemplateForm> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}