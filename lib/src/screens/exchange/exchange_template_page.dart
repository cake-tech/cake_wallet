import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cake_wallet/src/stores/exchange_template/exchange_template_store.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/base_exchange_widget.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ExchangeTemplatePage extends BasePage {
  @override
  String get title => S.current.exchange_new_template;

  @override
  Color get backgroundColor => PaletteDark.walletCardSubAddressField;

  @override
  Widget trailing(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeStore>(context);

    return PresentProviderPicker(exchangeStore: exchangeStore);
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
    final exchangeStore = Provider.of<ExchangeStore>(context);
    final walletStore = Provider.of<WalletStore>(context);
    final exchangeTemplateStore = Provider.of<ExchangeTemplateStore>(context);

    return BaseExchangeWidget(
        exchangeStore: exchangeStore,
        walletStore: walletStore,
        exchangeTemplateStore: exchangeTemplateStore,
        isTemplate: true
    );
  }
}