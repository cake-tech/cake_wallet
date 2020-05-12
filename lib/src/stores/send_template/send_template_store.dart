import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/template.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'send_template_store.g.dart';

class SendTemplateStore = SendTemplateBase with _$SendTemplateStore;

abstract class SendTemplateBase with Store {
  SendTemplateBase({this.templateSource}) {
    templates = ObservableList<Template>();
    update();
  }

  @observable
  ObservableList<Template> templates;

  @observable
  bool isValid;

  @observable
  String errorMessage;

  Box<Template> templateSource;

  @action
  void update() =>
      templates.replaceRange(0, templates.length, templateSource.values.toList());

  @action
  Future addTemplate({String name, String address, String cryptoCurrency, String amount}) async {
    final template = Template(name: name, address: address,
                              cryptoCurrency: cryptoCurrency, amount: amount);
    await templateSource.add(template);
  }

  @action
  Future remove({Template template}) async => await template.delete();

  void validateTemplate(String value) {
    const pattern = '''^[^`,'"]{1,106}\$''';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_template;
  }
}