import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

import "fakes.dart";

const _usdt = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const _otherToken = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
const _router = "0x1b6257cae4192e62b629efca21771be3d759183d";
const _required = 1000000;
const _swapAndExecuteData = "0x9be111d10000000000000000000000000000000000000000000000000000000000000000";

void main() {
  late EVM? realEvm;

  setUp(() => realEvm = evm);
  tearDown(() => evm = realEvm);

  Future<(PendingTransaction?, _FakeEvm)> createTransaction({
    required String token,
    required int allowance,
    String routerData = _swapAndExecuteData,
    WalletType walletType = WalletType.ethereum,
  }) async {
    final chain = _FakeEvm(token: token, allowance: BigInt.from(allowance));
    evm = chain;

    final provider = SwapsXyzExchangeProvider(settingsStore: _Settings());
    final tx = await provider.createTransaction(
      _FakeWallet(walletType),
      _trade(token, routerData: routerData),
    );
    return (tx, chain);
  }

  Future<(PendingTransaction, _FakeEvm)> createSwap({
    required String token,
    required int allowance,
  }) async {
    final (tx, chain) = await createTransaction(token: token, allowance: allowance);
    return (tx!, chain);
  }

  test("an approval is signed for the confirmation but not sent until commit", () async {
    final (tx, chain) = await createSwap(token: _otherToken, allowance: 0);

    expect(chain.log, ["sign approve $_required"]);
    expect(tx.fee, _FakeTx.approvalFee);

    await tx.commit();

    expect(chain.log, [
      "sign approve $_required",
      "send approve $_required",
      "sign swap",
      "send swap",
    ]);
    expect(tx.evmTxHashFromRawHex, "hash of swap");
    expect(tx.fee, _FakeTx.swapFee);
  });

  test("usdt is reset to 0 and re-approved, all after commit", () async {
    final (tx, chain) = await createSwap(token: _usdt, allowance: 5);

    expect(chain.log, ["sign approve 0"]);

    await tx.commit();

    expect(chain.log, [
      "sign approve 0",
      "send approve 0",
      "sign approve $_required",
      "send approve $_required",
      "sign swap",
      "send swap",
    ]);
    expect(tx.evmTxHashFromRawHex, "hash of swap");
  });

  test("with enough allowance the swap is returned unsent", () async {
    final (tx, chain) = await createSwap(token: _otherToken, allowance: _required);

    expect(chain.log, ["sign swap"]);
    expect(tx.evmTxHashFromRawHex, "hash of swap");
  });

  for (final routerData in ["", "0x"]) {
    test("a deposit address route (data \"$routerData\") is left to the regular send", () async {
      final (tx, chain) = await createTransaction(
        token: _otherToken,
        allowance: 0,
        routerData: routerData,
      );

      expect(tx, isNull);
      expect(chain.log, isEmpty);
    });
  }

  test("an alt-vm source wallet is left to the regular send", () async {
    final (tx, chain) = await createTransaction(
      token: _otherToken,
      allowance: 0,
      walletType: WalletType.bitcoin,
    );

    expect(tx, isNull);
    expect(chain.log, isEmpty);
  });
}

SwapsXyzTrade _trade(String token, {required String routerData}) => SwapsXyzTrade(
  vmId: SwapsXyzVmId.evm,
  needToRegister: false,
  sourceTokenAddress: token,
  sourceTokenDecimals: 6,
  sourceTokenAmountRaw: "$_required",
  requiresTokenApproval: true,
  fundingAddress: _router,
  state: TradeState.created,
  depositAmount: Money.parse("1", CryptoCurrency.usdterc20),
  payoutAmount: Money.parse("0.0005", CryptoCurrency.eth),
  id: "swaps-xyz-tx-id",
  provider: ExchangeProviderDescription.swapsXyz,
  payoutAddress: "payout-address",
  refundAddress: "refund-address",
  routerData: routerData,
  routerValue: "0",
);

class _FakeEvm implements EVM {
  _FakeEvm({required this.token, required this.allowance});

  final String token;
  BigInt allowance;

  final List<String> log = [];

  @override
  Future<bool> isApprovalRequired(
    WalletBase wallet,
    String tokenContract,
    String spender,
    BigInt requiredAmount,
  ) async => allowance < requiredAmount;

  @override
  Future<BigInt?> getAllowance(WalletBase wallet, String tokenContract, String spender) async =>
      allowance;

  @override
  Future<PendingTransaction> createTokenApproval(
    WalletBase wallet,
    Money amount,
    String spender,
    TransactionPriority? priority, {
    bool useBlinkProtection = true,
  }) async {
    if (token == _usdt && allowance > BigInt.zero && amount.amount > BigInt.zero) {
      throw StateError("usdt approval signed before the allowance was reset");
    }

    log.add("sign approve ${amount.amount}");
    return _FakeTx(
      "approve ${amount.amount}",
      log,
      fee: _FakeTx.approvalFee,
      onSent: () => allowance = amount.amount,
    );
  }

  @override
  Future<PendingTransaction> createRawCallDataTransaction(
    WalletBase wallet,
    String to,
    String dataHex,
    Money valueWei,
    TransactionPriority? priority, {
    bool useBlinkProtection = true,
    String? sourceTokenAddress,
    BigInt? sourceTokenAmount,
  }) async {
    if (sourceTokenAmount != null && allowance < sourceTokenAmount) {
      throw StateError("swap signed before its allowance was on-chain");
    }

    log.add("sign swap");
    return _FakeTx("swap", log, fee: _FakeTx.swapFee);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not faked on _FakeEvm");
}

class _FakeTx with PendingTransaction {
  _FakeTx(this.name, this._log, {required this.fee, this.onSent});

  static final approvalFee = Money.parse("0.001", CryptoCurrency.eth);
  static final swapFee = Money.parse("0.004", CryptoCurrency.eth);

  final String name;
  final List<String> _log;
  final void Function()? onSent;

  @override
  final Money fee;

  @override
  String get id => name;

  @override
  Money get amount => Money.zero(CryptoCurrency.eth);

  @override
  String get amountFormatted => "0";

  @override
  String get hex => name;

  @override
  String? get evmTxHashFromRawHex => "hash of $name";

  @override
  Future<void> commit() async {
    _log.add("send $name");
    onSent?.call();
  }

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError();
}

class _FakeWallet implements WalletBase {
  _FakeWallet(this.type);

  @override
  final WalletType type;

  @override
  int? get chainId => 1;

  @override
  CryptoCurrency get currency => CryptoCurrency.eth;

  @override
  ObservableMap<CryptoCurrency, Balance> get balance => ObservableMap();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not faked on _FakeWallet");
}

class _Settings extends FakeSettingsStore {
  @override
  bool useBlinkProtection = false;

  @override
  TransactionPriority? getPriority(WalletType walletType, {int? chainId}) => null;
}
