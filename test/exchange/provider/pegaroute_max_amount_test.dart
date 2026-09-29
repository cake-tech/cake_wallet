import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_max_amount.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../pegaroute_flow_test.dart';

class MaxEvm extends TestEvm {
  String? fee = '1000000000000000';
  @override
  String? getEVMNativeEstimatedFee(WalletBase wallet) => fee;
}

class MaxBitcoin extends CWBitcoin {
  late Money amount;
  UnspentCoinType? coinType;
  @override
  bool isTestnet(Object wallet) => false;
  @override
  Future<Money> estimateFakeSendAllTxAmount(WalletBase wallet, TransactionPriority priority,
      {UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any}) async {
    coinType = coinTypeToSpendFrom;
    return amount;
  }
}

void main() {
  late TestWallet wallet;
  late MaxEvm facade;
  setUpAll(() => registerFallbackValue(const TestPriority()));
  setUp(() {
    wallet = TestWallet();
    facade = MaxEvm();
    evm = facade;
    when(() => wallet.updateEstimatedFeesParams(any())).thenAnswer((_) async {});
  });
  tearDown(() { evm = null; bitcoin = null; });

  for (final currency in [CryptoCurrency.eth, CryptoCurrency.bnb,
      CryptoCurrency.baseEth, CryptoCurrency.arbEth, CryptoCurrency.maticpoly]) {
    test('${currency.title}/${currency.tag} Max subtracts fees in base units', () async {
      final balance = Money.parse('1.001000000000000001', currency);
      final amount = await pegarouteMaxAmount(wallet, balance, const TestPriority());
      expect(amount.toString(), '1.000000000000000001');
      verify(() => wallet.updateEstimatedFeesParams(any())).called(1);
    });
  }

  for (final fee in [null, '', '0', '-1', 'bad', '1000000000000000000', '2000000000000000000']) {
    test('native Max rejects invalid or unaffordable fee $fee', () async {
      facade.fee = fee;
      await expectLater(pegarouteMaxAmount(wallet, Money.parse('1', CryptoCurrency.eth),
          const TestPriority()), throwsStateError);
    });
  }

  test('native Max propagates a failed fee refresh and rejects a missing priority', () async {
    final balance = Money.parse('1', CryptoCurrency.eth);
    when(() => wallet.updateEstimatedFeesParams(any())).thenThrow(StateError('Offline fee failure'));
    await expectLater(pegarouteMaxAmount(wallet, balance, const TestPriority()), throwsStateError);
    await expectLater(pegarouteMaxAmount(wallet, balance, null), throwsStateError);
  });

  test('token Max does not subtract the native fee', () async {
    for (final currency in [CryptoCurrency.usdc, CryptoCurrency.usdcsol]) {
      final balance = Money.parse('3.681039', currency);
      expect(await pegarouteMaxAmount(wallet, balance, null), same(balance));
    }
    verifyNever(() => wallet.updateEstimatedFeesParams(any()));
  });

  for (final entry in [(CryptoCurrency.btc, WalletType.bitcoin),
      (CryptoCurrency.bch, WalletType.bitcoinCash),
      (CryptoCurrency.ltc, WalletType.litecoin),
      (CryptoCurrency.doge, WalletType.dogecoin)]) {
    test('${entry.$1.title} Max uses the wallet fee estimate', () async {
      final estimator = MaxBitcoin()..amount = Money.parse('0.99999', entry.$1);
      bitcoin = estimator;
      when(() => wallet.type).thenReturn(entry.$2);
      final amount = await pegarouteMaxAmount(wallet, Money.parse('1', entry.$1), const TestPriority());
      expect(amount, same(estimator.amount));
      expect(estimator.coinType, entry.$2 == WalletType.litecoin
          ? UnspentCoinType.nonMweb : UnspentCoinType.any);
    });
  }

  test('UTXO Max rejects a failed, full-balance, or wrong-asset estimate', () async {
    final estimator = MaxBitcoin();
    bitcoin = estimator;
    when(() => wallet.type).thenReturn(WalletType.bitcoin);
    for (final amount in [Money.zero(CryptoCurrency.btc), Money.parse('1', CryptoCurrency.btc),
        Money.parse('2', CryptoCurrency.btc), Money.parse('0.9', CryptoCurrency.ltc)]) {
      estimator.amount = amount;
      await expectLater(pegarouteMaxAmount(wallet, Money.parse('1', CryptoCurrency.btc),
          const TestPriority()), throwsStateError);
    }
  });

  test('native wallets without a fee-aware Max calculator remain blocked', () async {
    for (final currency in [CryptoCurrency.xmr, CryptoCurrency.sol, CryptoCurrency.trx, CryptoCurrency.zec]) {
      expect(PegaRouteExchangeProvider.supportsMax(wallet, currency), false);
      await expectLater(pegarouteMaxAmount(wallet, Money.parse('1', currency),
          const TestPriority()), throwsStateError);
    }
  });
}
