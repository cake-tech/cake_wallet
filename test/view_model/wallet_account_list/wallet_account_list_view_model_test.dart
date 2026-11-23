import "package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

import "fake_account_wallet.dart";

void main() {
  late FakeAccountWallet wallet;

  setUp(() {
    wallet = FakeAccountWallet(
      currentAccountIndex: 1,
      accounts: [
        FakeWalletAccount(index: 0, label: "Primary", balance: Money.zero(CryptoCurrency.xmr)),
        FakeWalletAccount(
          index: 1,
          label: "Savings",
          balance: Money.fromInt(200000000001, CryptoCurrency.xmr),
        ),
      ],
    );
  });

  test("lists wallet accounts and marks the selected one", () {
    final viewModel = WalletAccountListViewModel(wallet);

    expect(viewModel.accounts.map((item) => item.id), [0, 1]);
    expect(viewModel.accounts.map((item) => item.label), ["Primary", "Savings"]);
    expect(viewModel.accounts.first.isFunded, isFalse);
    expect(viewModel.selectedAccount?.id, 1);
    expect(viewModel.selectedAccount?.balance.amount, BigInt.from(200000000001));
    expect(viewModel.currency, CryptoCurrency.xmr);
  });

  test("select switches the wallet account and updates the selection", () async {
    final viewModel = WalletAccountListViewModel(wallet);
    final selections = <int?>[];
    final dispose = reaction((_) => viewModel.selectedAccount?.id, selections.add);
    addTearDown(dispose);

    await viewModel.select(viewModel.accounts.first);

    expect(wallet.currentAccountIndex, 0);
    expect(viewModel.selectedAccount?.id, 0);
    expect(viewModel.accounts.where((item) => item.isSelected).map((item) => item.id), [0]);
    expect(selections, [0]);
  });

  test("updates when an account label or balance changes", () {
    final viewModel = WalletAccountListViewModel(wallet);
    final labels = <String?>[];
    final dispose = reaction((_) => viewModel.selectedAccount?.label, labels.add);
    addTearDown(dispose);

    wallet.account(1).label = "Long-term";
    wallet.account(1).balance = FakeBalance(Money.fromInt(5, CryptoCurrency.xmr));

    expect(labels, ["Long-term"]);
    expect(viewModel.selectedAccount?.label, "Long-term");
    expect(viewModel.selectedAccount?.balance.amount, BigInt.from(5));
  });

  test("updates when an account is added", () async {
    final viewModel = WalletAccountListViewModel(wallet);
    final counts = <int>[];
    final dispose = reaction((_) => viewModel.accounts.length, counts.add);
    addTearDown(dispose);

    await wallet.addAccount(label: "Spending");

    expect(counts, [3]);
    expect(viewModel.accounts.last.label, "Spending");
  });

  test("a wallet without accounts shows a single account 0", () async {
    final singleWallet = SingleAccountWallet(Money.fromInt(42, CryptoCurrency.ltc));
    final viewModel = WalletAccountListViewModel(singleWallet);

    expect(viewModel.accounts, hasLength(1));
    expect(viewModel.accounts.single.id, 0);
    expect(viewModel.accounts.single.balance.amount, BigInt.from(42));
    expect(viewModel.selectedAccount?.id, 0);
    await viewModel.select(viewModel.accounts.single);
    expect(singleWallet.currentAccountIndex, 0);
  });
}
