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
  Future<void> addTemplate(
      {required String name,
      required bool isCurrencySelected,
      required String address,
      required String cryptoCurrency,
      required String fiatCurrency,
      required String amount,
      required String amountFiat,
      required List<Template> additionalRecipients}) async {
    final template = Template(
        nameRaw: name,
        isCurrencySelectedRaw: isCurrencySelected,
        addressRaw: address,
        cryptoCurrencyRaw: cryptoCurrency,
        fiatCurrencyRaw: fiatCurrency,
        amountRaw: amount,
        amountFiatRaw: amountFiat,
        additionalRecipientsRaw: additionalRecipients);
    await templateSource.add(template);
  }

  @action
  Future<void> remove({required Template template}) async => await template.delete();
}
