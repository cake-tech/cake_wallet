import 'package:cake_wallet/view_model/send/template_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:cake_wallet/core/template_validator.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';

part 'send_template_view_model.g.dart';

class SendTemplateViewModel = SendTemplateViewModelBase with _$SendTemplateViewModel;

abstract class SendTemplateViewModelBase with Store {
  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final SendTemplateStore _sendTemplateStore;
  final FiatConversionStore _fiatConversationStore;

  SendTemplateViewModelBase(
      this._wallet, this._settingsStore, this._sendTemplateStore, this._fiatConversationStore)
      : recipients = ObservableList<TemplateViewModel>() {
    addRecipient();
  }

  ObservableList<TemplateViewModel> recipients;

  @action
  void addRecipient() {
    recipients.add(TemplateViewModel(
        wallet: _wallet,
        settingsStore: _settingsStore,
        fiatConversationStore: _fiatConversationStore));
  }

  @action
  void removeRecipient(TemplateViewModel recipient) {
    recipients.remove(recipient);
  }

  AmountValidator get amountValidator =>
      AmountValidator(currency: walletTypeToCryptoCurrency(_wallet.type));

  AddressValidator get addressValidator => AddressValidator(type: _wallet.currency);

  TemplateValidator get templateValidator => TemplateValidator();

  bool get hasMultiRecipient =>
      _wallet.type != WalletType.haven &&
      _wallet.type != WalletType.ethereum &&
      _wallet.type != WalletType.polygon &&
      _wallet.type != WalletType.solana;

  @computed
  CryptoCurrency get cryptoCurrency => _wallet.currency;

  @computed
  String get fiatCurrency => _settingsStore.fiatCurrency.title;

  @computed
  ObservableList<Template> get templates => _sendTemplateStore.templates;

  @action
  void updateTemplate() => _sendTemplateStore.update();

  @action
  void addTemplate(
      {required String name,
      required bool isCurrencySelected,
      required String cryptoCurrency,
      required String address,
      required String amount,
      required String amountFiat,
      required List<Template> additionalRecipients}) {
    _sendTemplateStore.addTemplate(
        name: name,
        isCurrencySelected: isCurrencySelected,
        address: address,
        cryptoCurrency: cryptoCurrency,
        fiatCurrency: fiatCurrency,
        amount: amount,
        amountFiat: amountFiat,
        additionalRecipients: additionalRecipients);
    updateTemplate();
  }

  @action
  void removeTemplate({required Template template}) {
    _sendTemplateStore.remove(template: template);
    updateTemplate();
  }

  @computed
  List<CryptoCurrency> get walletCurrencies => _wallet.balance.keys.toList();
}
