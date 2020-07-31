import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/base_exchange_widget.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';

class ExchangeTemplatePage extends BasePage {
  ExchangeTemplatePage(this.exchangeViewModel);

  final ExchangeViewModel exchangeViewModel;

  @override
  String get title => S.current.exchange_new_template;

  @override
  Color get backgroundLightColor => PaletteDark.wildVioletBlue;

  @override
  Color get backgroundDarkColor => PaletteDark.wildVioletBlue;

  @override
  Widget trailing(BuildContext context) =>
      PresentProviderPicker(exchangeViewModel: exchangeViewModel);

  @override
  Widget body(BuildContext context) =>
      BaseExchangeWidget(exchangeViewModel: exchangeViewModel, isTemplate: true);
}