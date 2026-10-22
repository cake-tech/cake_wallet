import "dart:math";

import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_account.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart";
import "package:mocktail/mocktail.dart";

typedef TestWallet = WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>;

class FakeBalance extends Balance {
  FakeBalance(Money total) : super(total, Money.zero(total.currency));
}

class FakeWalletInfo extends Mock implements WalletInfo {}

class FakeWalletAccount implements WalletAccount<Balance> {
  FakeWalletAccount({required this.index, required String label, required Money balance})
      : _label = Observable(label),
        _balance = Observable<Balance>(FakeBalance(balance));

  @override
  final int index;

  final Observable<String> _label;
  final Observable<Balance> _balance;

  @override
  String get label => _label.value;

  set label(String value) => runInAction(() => _label.value = value);

  @override
  Balance get balance => _balance.value;

  set balance(Balance value) => runInAction(() => _balance.value = value);
}

class FakeAccountWallet extends Mock implements TestWallet {
  FakeAccountWallet({
    required List<FakeWalletAccount> accounts,
    int currentAccountIndex = 0,
    this.currency = CryptoCurrency.xmr,
    WalletInfo? walletInfo,
  })  : _accounts = ObservableList.of(accounts),
        _currentAccountIndex = Observable(currentAccountIndex),
        walletInfo = walletInfo ?? FakeWalletInfo();

  final ObservableList<FakeWalletAccount> _accounts;
  final Observable<int> _currentAccountIndex;

  int saveCount = 0;

  @override
  final CryptoCurrency currency;

  @override
  WalletInfo walletInfo;

  @override
  bool get hasAccountsSupport => true;

  @override
  int get currentAccountIndex => _currentAccountIndex.value;

  @override
  List<WalletAccount<Balance>> get walletAccounts => List.of(_accounts);

  @override
  WalletAccount<Balance> get currentWalletAccount => account(currentAccountIndex);

  FakeWalletAccount account(int index) => _accounts.firstWhere((item) => item.index == index);

  @override
  Future<void> setCurrentAccount(int accountIndex) async {
    if (!_accounts.any((item) => item.index == accountIndex)) {
      throw ArgumentError("Unknown account $accountIndex");
    }
    runInAction(() => _currentAccountIndex.value = accountIndex);
  }

  @override
  Future<int> addAccount({required String label}) async {
    final index = _accounts.map((item) => item.index).fold(-1, max) + 1;
    runInAction(
      () => _accounts.add(
        FakeWalletAccount(index: index, label: label, balance: Money.zero(currency)),
      ),
    );
    return index;
  }

  @override
  Future<void> renameAccount({required int index, required String label}) async =>
      account(index).label = label;

  @override
  Future<void> save() async => saveCount++;
}

class SingleAccountWallet extends TestWallet {
  SingleAccountWallet(Money balance)
      : balance = ObservableMap.of({CryptoCurrency.ltc: FakeBalance(balance)}),
        super(FakeWalletInfo(), DerivationInfo());

  @override
  final ObservableMap<CryptoCurrency, Balance> balance;

  @override
  WalletType get type => WalletType.litecoin;

  @override
  CryptoCurrency get currency => CryptoCurrency.ltc;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
