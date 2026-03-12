import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';

part 'template_view_model.g.dart';

class TemplateViewModel = TemplateViewModelBase with _$TemplateViewModel;

abstract class TemplateViewModelBase with Store {
  final WalletBase _wallet;
  final AppStore _appStore;
  final FiatConversionStore _fiatConversationStore;

  TemplateViewModelBase({
    required WalletBase wallet,
    required AppStore appStore,
    required FiatConversionStore fiatConversationStore,
  })  : _wallet = wallet,
        _appStore = appStore,
        _fiatConversationStore = fiatConversationStore,
        _currency = wallet.currency,
        output = Output(wallet, appStore, fiatConversationStore, () => wallet.currency) {
    output = Output(_wallet, _appStore, _fiatConversationStore, () => _currency);
  }

  @observable
  Output output;

  @observable
  String name = '';

  @observable
  String address = '';

  @observable
  CryptoCurrency _currency;

  @observable
  bool isCryptoSelected = true;

  @action
  void setCryptoCurrency(bool value) => isCryptoSelected = value;

  @action
  void reset() {
    name = '';
    address = '';
    isCryptoSelected = true;
    output.reset();
  }

  Template toTemplate({required String cryptoCurrency, required String fiatCurrency}) {
    return Template(
        isCurrencySelectedRaw: isCryptoSelected,
        nameRaw: name,
        addressRaw: address,
        cryptoCurrencyRaw: cryptoCurrency,
        fiatCurrencyRaw: fiatCurrency,
        amountRaw: output.cryptoAmount,
        amountFiatRaw: output.fiatAmount);
  }

  @action
  void changeSelectedCurrency(CryptoCurrency currency) {
    isCryptoSelected = true;
    _currency = currency;
  }

  @computed
  CryptoCurrency get selectedCurrency => _currency;
}
