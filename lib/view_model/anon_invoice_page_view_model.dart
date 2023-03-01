import 'package:cw_core/crypto_currency.dart';
import 'package:mobx/mobx.dart';

part 'anon_invoice_page_view_model.g.dart';

class AnonInvoicePageViewModel = AnonInvoicePageViewModelBase with _$AnonInvoicePageViewModel;

abstract class AnonInvoicePageViewModelBase with Store {
  AnonInvoicePageViewModelBase() : selectedCurrency = CryptoCurrency.xmr;

  List<CryptoCurrency> get currencies => CryptoCurrency.all;

  @observable
  CryptoCurrency selectedCurrency;

  @computed
  int get selectedCurrencyIndex => currencies.indexOf(selectedCurrency);

  @action
  void selectCurrency(CryptoCurrency currency) {
    selectedCurrency = currency;
  }

  @action
  void reset() {
    //
  }
}
