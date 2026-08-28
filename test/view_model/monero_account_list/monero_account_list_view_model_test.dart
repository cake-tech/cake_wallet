import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/monero/monero.dart" as xmr;
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cake_wallet/wownero/wownero.dart" as wow;
import "package:cw_core/balance.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableList;
import "package:mocktail/mocktail.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockWownero extends Mock implements wow.Wownero {}

class _MockWowneroAccountList extends Mock implements wow.WowneroAccountList {}

void main() {
  late xmr.Monero? originalMonero;
  late wow.Wownero? originalWownero;
  late _MockWallet wallet;
  late _MockSettingsStore settingsStore;
  late _MockWownero wowneroAdapter;
  late _MockWowneroAccountList accountList;

  setUp(() {
    originalMonero = xmr.monero;
    originalWownero = wow.wownero;

    wallet = _MockWallet();
    settingsStore = _MockSettingsStore();
    wowneroAdapter = _MockWownero();
    accountList = _MockWowneroAccountList();

    xmr.monero = null;
    wow.wownero = wowneroAdapter;

    when(() => wallet.type).thenReturn(WalletType.wownero);
    when(() => settingsStore.balanceDisplayMode).thenReturn(BalanceDisplayMode.displayableBalance);
    when(() => wowneroAdapter.getAccountList(wallet)).thenReturn(accountList);
    when(() => wowneroAdapter.getCurrentAccount(wallet))
        .thenReturn(wow.Account(id: 1, label: "Selected", balance: "2.0"));
    when(() => accountList.accounts).thenReturn(
      ObservableList.of([
        wow.Account(id: 0, label: "Primary", balance: "1.0"),
        wow.Account(id: 1, label: "Selected", balance: "2.0"),
      ]),
    );
  });

  tearDown(() {
    xmr.monero = originalMonero;
    wow.wownero = originalWownero;
  });

  test("selected account uses the Wownero adapter", () {
    final viewModel = MoneroAccountListViewModel(wallet, settingsStore);

    expect(viewModel.selected.id, 1);
    expect(viewModel.selected.label, "Selected");
  });
}
