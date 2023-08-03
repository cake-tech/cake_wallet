import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';

part 'template_view_model.g.dart';

class TemplateViewModel = TemplateViewModelBase with _$TemplateViewModel;

abstract class TemplateViewModelBase with Store {
  final CryptoCurrency cryptoCurrency;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final FiatConversionStore _fiatConversationStore;

  TemplateViewModelBase(
      {required this.cryptoCurrency,
      required WalletBase wallet,
      required SettingsStore settingsStore,
      required FiatConversionStore fiatConversationStore})
      : _wallet = wallet,
        _settingsStore = settingsStore,
        _fiatConversationStore = fiatConversationStore,
        output = Output(wallet, settingsStore, fiatConversationStore,
            () => wallet.currency) {
    output = Output(
        _wallet, _settingsStore, _fiatConversationStore, () => cryptoCurrency);
  }

  @observable
  Output output;

  @observable
  String name = '';

  @observable
  String address = '';

  @observable
  bool isCurrencySelected = true;

  @observable
  bool isFiatSelected = false;

  @action
  void selectCurrency() {
    isCurrencySelected = true;
    isFiatSelected = false;
  }

  @action
  void selectFiat() {
    isFiatSelected = true;
    isCurrencySelected = false;
  }

  @action
  void reset() {
    name = '';
    address = '';
    isCurrencySelected = true;
    isFiatSelected = false;
    output.reset();
  }

  Template toTemplate(
      {required String cryptoCurrency, required String fiatCurrency}) {
    return Template(
        isCurrencySelectedRaw: isCurrencySelected,
        nameRaw: name,
        addressRaw: address,
        cryptoCurrencyRaw: cryptoCurrency,
        fiatCurrencyRaw: fiatCurrency,
        amountRaw: output.cryptoAmount,
        amountFiatRaw: output.fiatAmount);
  }
}
