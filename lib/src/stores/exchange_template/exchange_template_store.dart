import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_template.dart';

part 'exchange_template_store.g.dart';

class ExchangeTemplateStore = ExchangeTemplateBase with _$ExchangeTemplateStore;

abstract class ExchangeTemplateBase with Store {
  ExchangeTemplateBase({this.templateSource}) {
    templates = ObservableList<ExchangeTemplate>();
    update();
  }

  @observable
  ObservableList<ExchangeTemplate> templates;

  Box<ExchangeTemplate> templateSource;

  @action
  void update() =>
      templates.replaceRange(0, templates.length, templateSource.values.toList());

  @action
  Future addTemplate({String amount, String depositCurrency, String receiveCurrency,
    String provider, String depositAddress, String receiveAddress}) async {
    final template = ExchangeTemplate(
        amount: amount,
        depositCurrency: depositCurrency,
        receiveCurrency: receiveCurrency,
        provider: provider,
        depositAddress: depositAddress,
        receiveAddress: receiveAddress);
    await templateSource.add(template);
  }

  @action
  Future remove({ExchangeTemplate template}) async => await template.delete();
}