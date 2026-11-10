import "package:cake_wallet/monero/monero.dart" as xmr;
import "package:cake_wallet/view_model/wallet_account_list/monero_account_list/monero_account_list_view_model.dart";
import "package:cake_wallet/wownero/wownero.dart" as wow;
import "package:cw_core/account.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableList;
import "package:mocktail/mocktail.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWownero extends Mock implements wow.Wownero {}

class _MockWowneroAccountList extends Mock implements wow.WowneroAccountList {}

void main() {
  late xmr.Monero? originalMonero;
  late wow.Wownero? originalWownero;
  late _MockWallet wallet;
  late _MockWownero wowneroAdapter;
  late _MockWowneroAccountList accountList;

  setUp(() {
    originalMonero = xmr.monero;
    originalWownero = wow.wownero;

    wallet = _MockWallet();
    wowneroAdapter = _MockWownero();
    accountList = _MockWowneroAccountList();

    xmr.monero = null;
    wow.wownero = wowneroAdapter;

    when(() => wallet.type).thenReturn(WalletType.wownero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.wow);
    when(() => wowneroAdapter.getAccountList(wallet)).thenReturn(accountList);
    when(() => wowneroAdapter.getCurrentAccount(wallet))
        .thenReturn(Account(id: 1, label: "Selected", balance: "2.00000000001"));
    when(() => accountList.accounts).thenReturn(
      ObservableList.of([
        Account(id: 0, label: "Primary", balance: "0.0"),
        Account(id: 1, label: "Selected", balance: "2.00000000001"),
      ]),
    );
    when(() => wowneroAdapter.getAccountFullBalance(0)).thenReturn(Money.zero(CryptoCurrency.wow));
    when(() => wowneroAdapter.getAccountFullBalance(1))
        .thenReturn(Money.fromInt(200000000001, CryptoCurrency.wow));
  });

  tearDown(() {
    xmr.monero = originalMonero;
    wow.wownero = originalWownero;
  });

  test("Wownero accounts retain exact amounts and select through the Wownero adapter", () async {
    final viewModel = MoneroAccountListViewModel(wallet);

    expect(viewModel.selected.id, 1);
    expect(viewModel.selected.label, "Selected");
    expect(viewModel.accounts.first.isFunded, isFalse);
    expect(viewModel.selected.balance.amount, BigInt.from(200000000001));
    await viewModel.select(viewModel.selected);
    verify(() => wowneroAdapter.setCurrentAccount(wallet, 1, "Selected", "2.00000000001"))
        .called(1);
  });
}
