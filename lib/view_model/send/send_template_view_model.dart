import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/send/template_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:cake_wallet/core/template_validator.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';

part 'send_template_view_model.g.dart';

class SendTemplateViewModel = SendTemplateViewModelBase with _$SendTemplateViewModel;

abstract class SendTemplateViewModelBase with Store {
  final WalletBase _wallet;
  final AppStore _appStore;
  final SendTemplateStore _sendTemplateStore;
  final FiatConversionStore _fiatConversationStore;

  SendTemplateViewModelBase(
      this._wallet, this._appStore, this._sendTemplateStore, this._fiatConversationStore)
      : recipients = ObservableList<TemplateViewModel>() {
    addRecipient();
  }

  ObservableList<TemplateViewModel> recipients;

  @action
  void addRecipient() {
    recipients.add(TemplateViewModel(
        wallet: _wallet,
        appStore: _appStore,
        fiatConversationStore: _fiatConversationStore));
  }

  @action
  void removeRecipient(TemplateViewModel recipient) {
    recipients.remove(recipient);
  }

  AmountValidator get amountValidator =>
      AmountValidator(currency: walletTypeToCryptoCurrency(_wallet.type));

  AddressValidator get addressValidator =>
      AddressValidator(type: _wallet.currency, isTestnet: _wallet.isTestnet);

  TemplateValidator get templateValidator => TemplateValidator();

  bool get hasMultiRecipient =>
      _wallet.type != WalletType.haven &&
      _wallet.type != WalletType.ethereum &&
      _wallet.type != WalletType.polygon &&
      _wallet.type != WalletType.base &&
      _wallet.type != WalletType.arbitrum &&
      _wallet.type != WalletType.solana &&
      _wallet.type != WalletType.tron;

  @computed
  CryptoCurrency get cryptoCurrency => _wallet.currency;

  @computed
  String get fiatCurrency => _appStore.settingsStore.fiatCurrency.title;

  @computed
  int get fiatCurrencyDecimals => _appStore.settingsStore.fiatCurrency.decimals;

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

  bool get hasMultipleTokens =>
      isEVMCompatibleChain(_wallet.type) ||
      _wallet.type == WalletType.solana ||
      _wallet.type == WalletType.tron;
}
