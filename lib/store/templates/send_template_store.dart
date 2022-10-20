import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/entities/template.dart';

part 'send_template_store.g.dart';

class SendTemplateStore = SendTemplateBase with _$SendTemplateStore;

abstract class SendTemplateBase with Store {
  SendTemplateBase({required this.templateSource})
  : templates = ObservableList<Template>() {
    update();
  }

  @observable
  ObservableList<Template> templates;

  Box<Template> templateSource;

  @action
  void update() =>
      templates.replaceRange(0, templates.length, templateSource.values.toList());

  @action
  Future addTemplate({
    required  String name,
    required  bool isCurrencySelected,
    required  String address,
    required  String cryptoCurrency,
    required  String fiatCurrency,
    required  String amount,
    required  String amountFiat}) async {
    final template = Template(
      name: name,
      isCurrencySelected: isCurrencySelected,
      address: address,
      cryptoCurrency: cryptoCurrency,
      fiatCurrency: fiatCurrency,
      amount: amount,
      amountFiat: amountFiat);
    await templateSource.add(template);
  }

  @action
  Future remove({required Template template}) async => await template.delete();
}