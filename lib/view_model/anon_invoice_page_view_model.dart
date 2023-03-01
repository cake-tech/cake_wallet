import 'package:cake_wallet/core/execution_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:mobx/mobx.dart';

part 'anon_invoice_page_view_model.g.dart';

class AnonInvoicePageViewModel = AnonInvoicePageViewModelBase with _$AnonInvoicePageViewModel;

abstract class AnonInvoicePageViewModelBase with Store {
  AnonInvoicePageViewModelBase()
      : receipientEmail = '',
        receipientName = '',
        description = '',
        amount = '',
        state = InitialExecutionState(),
        selectedCurrency = CryptoCurrency.xmr;

  List<CryptoCurrency> get currencies => CryptoCurrency.all;

  @observable
  CryptoCurrency selectedCurrency;

  @observable
  String receipientEmail;

  @observable
  String receipientName;

  @observable
  String description;

  @observable
  String amount;

  @observable
  ExecutionState state;

  @computed
  int get selectedCurrencyIndex => currencies.indexOf(selectedCurrency);

  @action
  void selectCurrency(CryptoCurrency currency) {
    selectedCurrency = currency;
  }

  @action
  void createInvoice() {
    // TODO: implement createInvoice
    state = ExecutedSuccessfullyState();
  }

  @action
  void reset() {
    //
  }
}
