import 'package:cake_wallet/view_model/send/output.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:cake_wallet/core/template_validator.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';

part 'send_template_view_model.g.dart';

class SendTemplateViewModel = SendTemplateViewModelBase
    with _$SendTemplateViewModel;

abstract class SendTemplateViewModelBase with Store {
  SendTemplateViewModelBase(this._wallet, this._settingsStore,
      this._sendTemplateStore, this._fiatConversationStore) {

    output = Output(_wallet, _settingsStore, _fiatConversationStore);
  }

  Output output;

  Validator get amountValidator => AmountValidator(type: _wallet.type);

  Validator get addressValidator => AddressValidator(type: _wallet.currency);

  Validator get templateValidator => TemplateValidator();

  CryptoCurrency get currency => _wallet.currency;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  @computed
  ObservableList<Template> get templates => _sendTemplateStore.templates;

  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final SendTemplateStore _sendTemplateStore;
  final FiatConversionStore _fiatConversationStore;

  void updateTemplate() => _sendTemplateStore.update();

  void addTemplate(
      {String name,
        String address,
        String cryptoCurrency,
        String amount}) {
    _sendTemplateStore.addTemplate(
        name: name,
        address: address,
        cryptoCurrency: cryptoCurrency,
        amount: amount);
    updateTemplate();
  }

  void removeTemplate({Template template}) {
    _sendTemplateStore.remove(template: template);
    updateTemplate();
  }
}
