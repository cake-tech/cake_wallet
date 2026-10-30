import "dart:async";

import "package:cake_wallet/cake_pay/src/cake_pay_exceptions.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_order.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_stablecoin_quote.dart";
import "package:cake_wallet/cake_pay/src/services/cake_pay_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/stablecoin_checkout/stablecoin_checkout_bloc.dart";
import "package:cake_wallet/order/order.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart" show ObservableMap;
import "package:mocktail/mocktail.dart";

class _MockCakePayService extends Mock implements CakePayService {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockOrders extends Mock implements Box<Order> {}

class _MockOrderRecord extends Mock implements Order {}

class _Balance extends Balance {
  _Balance(Money available) : super(available, Money.zero(available.currency));
}

const _baseUsdc = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";
const _tronUsdt = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
const _depositAddress = "0x6490e244136af11ca7c7ff8997916e01e4a39b1c";

final _now = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);
final _expirationTime = _now.add(const Duration(minutes: 15));

CakePayOrder _order({String status = "new"}) => CakePayOrder.fromMap({
      "order_id": "order-1",
      "external_id": null,
      "amount_usd": 25.0,
      "status": status,
      "vouchers": null,
      "cards": [
        {
          "card_id": 1,
          "external_id": null,
          "price": "25.00",
          "quantity": 1,
          "currency_code": "USD",
          "name": "Gift Card",
          "card_image_url": null,
          "subtotal": "25.00",
        },
      ],
      "payment_data": {
        for (final coin in ["USDC", "USDT"])
          coin: {
            "amount_from": 25.0,
            "price": "25.0",
            "paymentUrls": {"BIP21": ""},
            "address": "",
            "requires_quote": true,
            "networks": [
              {"chain": "base", "name": "Base"},
              {"chain": "tron", "name": "Tron"},
            ],
          },
        "invoice_time": _now.millisecondsSinceEpoch,
        "expiration_time": _expirationTime.millisecondsSinceEpoch,
        "commission": null,
      },
    });

CakePayStablecoinQuote _baseQuote({DateTime? offeredUntil}) => CakePayStablecoinQuote(
      paymentMethod: "USDC",
      chain: "base",
      chainName: "Base",
      address: _depositAddress,
      amount: "25.061219",
      fee: "0.061219",
      contract: _baseUsdc,
      paymentRequest: "ethereum:$_baseUsdc@8453/transfer?address=$_depositAddress&uint256=25061219",
      offeredUntil: offeredUntil ?? _now.add(const Duration(minutes: 62)),
    );

const _tronQuote = CakePayStablecoinQuote(
  paymentMethod: "USDT",
  chain: "tron",
  chainName: "Tron",
  address: "TDepositAddress",
  amount: "28.23",
  fee: "3.23",
  contract: _tronUsdt,
  paymentRequest: "TDepositAddress",
);

void main() {
  late _MockCakePayService service;
  late _MockWallet wallet;
  late _MockOrders orders;
  late ObservableMap<CryptoCurrency, Balance> walletBalances;
  late StablecoinCheckoutBloc bloc;

  final usdcOnBase = Erc20Token(
    name: "USD Coin",
    symbol: "USDC",
    contractAddress: _baseUsdc,
    decimal: 6,
  );
  final usdtOnTron = TronToken(
    name: "Tether USD",
    symbol: "USDT",
    contractAddress: _tronUsdt,
    decimal: 6,
  );

  Future<CakePayStablecoinQuote> quoteRequest() => service.getStablecoinQuote(
        orderId: any(named: "orderId"),
        paymentMethod: any(named: "paymentMethod"),
        chain: any(named: "chain"),
      );

  void stubQuote(CakePayStablecoinQuote quote) => when(quoteRequest).thenAnswer((_) async => quote);

  void stubQuoteError(Object error) => when(quoteRequest).thenThrow(error);

  void stubWallet(
    WalletType type, {
    int? chainId,
    Map<CryptoCurrency, Balance> balances = const {},
  }) {
    when(() => wallet.type).thenReturn(type);
    when(() => wallet.chainId).thenReturn(chainId);
    walletBalances
      ..clear()
      ..addAll(balances);
  }

  StablecoinPaymentData coin(String paymentMethod) =>
      bloc.coins.firstWhere((coin) => coin.paymentMethod == paymentMethod);

  StablecoinNetwork network(String chain) =>
      bloc.state.coin.networks.firstWhere((network) => network.chain == chain);

  Future<StablecoinCheckoutState> selectNetwork(String chain) {
    final settled = bloc.stream.firstWhere((state) => state is! StablecoinCheckoutLoading);
    bloc.add(NetworkSelected(network(chain)));
    return settled;
  }

  Future<StablecoinCheckoutState> selectCoin(String paymentMethod) {
    final selected = bloc.stream.first;
    bloc.add(CoinSelected(coin(paymentMethod)));
    return selected;
  }

  Future<void> processEvents() => Future<void>.delayed(Duration.zero);

  setUpAll(() {
    S.current = const S();
    registerFallbackValue(_order().toOrder(from: "", amount: "", receiveAddress: "", walletId: ""));
  });

  setUp(() {
    service = _MockCakePayService();
    wallet = _MockWallet();
    orders = _MockOrders();
    walletBalances = ObservableMap();

    when(() => wallet.id).thenReturn("wallet-1");
    when(() => wallet.balance).thenReturn(walletBalances);
    when(() => orders.values).thenReturn([]);
    when(() => orders.add(any())).thenAnswer((_) async => 0);
    stubWallet(WalletType.bitcoin);

    bloc = StablecoinCheckoutBloc(
      order: _order(),
      wallet: wallet,
      cakePayService: service,
      orders: orders,
    );
  });

  tearDown(() => bloc.close());

  group("quote requests", () {
    test("picking a network quotes it for the selected coin and records the order", () async {
      stubQuote(_baseQuote());

      final state = await selectNetwork("base");

      verify(
        () => service.getStablecoinQuote(orderId: "order-1", paymentMethod: "USDC", chain: "base"),
      ).called(1);
      expect(state, isA<StablecoinCheckoutQuoted>());
      expect((state as StablecoinCheckoutQuoted).quote.address, _depositAddress);
      final record = verify(() => orders.add(captureAny())).captured.single as Order;
      expect(record.id, "order-1");
      expect(record.from, "USDC");
      expect(record.amount, "25.061219");
      expect(record.receiveAddress, _depositAddress);
      expect(record.walletId, "wallet-1");
    });

    test("tapping the network that already has a quote does not request again", () async {
      stubQuote(_baseQuote());

      await selectNetwork("base");
      bloc.add(NetworkSelected(network("base")));
      await processEvents();

      verify(quoteRequest).called(1);
    });

    test("a new quote updates the order record instead of adding another", () async {
      final record = _MockOrderRecord();
      when(() => record.id).thenReturn("order-1");
      when(record.save).thenAnswer((_) async {});
      when(() => orders.values).thenReturn([record]);
      stubQuote(_tronQuote);

      await selectCoin("USDT");
      await selectNetwork("tron");

      verify(() => record.from = "USDT").called(1);
      verify(() => record.amount = "28.23").called(1);
      verify(() => record.receiveAddress = "TDepositAddress").called(1);
      verify(record.save).called(1);
      verifyNever(() => orders.add(any()));
    });

    test("shows the backend's message and lets the same network be retried", () async {
      stubQuoteError(
        const CakePayResponseException("This payment is too small for USDT on Tron."),
      );
      await selectCoin("USDT");

      final failure = await selectNetwork("tron");

      expect(
        (failure as StablecoinCheckoutFailure).message,
        "This payment is too small for USDT on Tron.",
      );

      stubQuote(_tronQuote);
      expect(await selectNetwork("tron"), isA<StablecoinCheckoutQuoted>());
    });

    test("falls back to a generic message when the request fails without one", () async {
      stubQuoteError(Exception("Connection reset"));

      final failure = await selectNetwork("base");

      expect((failure as StablecoinCheckoutFailure).message, S.current.please_try_again_later);
    });

    test("asks to log in again when the session expired", () async {
      stubQuoteError(const CakePayUnauthorizedException());

      final failure = await selectNetwork("base");

      expect((failure as StablecoinCheckoutFailure).message, S.current.cake_pay_session_expired);
    });

    test("switching the coin clears the network and the quote", () async {
      stubQuote(_baseQuote());
      await selectNetwork("base");

      final state = await selectCoin("USDT");

      expect(state, isA<StablecoinCheckoutReady>());
      expect(state.coin.paymentMethod, "USDT");
      expect(state.network, isNull);
    });

    test("ignores a coin switch while a quote is loading", () async {
      final pending = Completer<CakePayStablecoinQuote>();
      when(quoteRequest).thenAnswer((_) => pending.future);
      bloc.add(NetworkSelected(network("base")));
      await processEvents();

      bloc.add(CoinSelected(coin("USDT")));
      await processEvents();
      final settled = bloc.stream.first;
      pending.complete(_baseQuote());

      expect(await settled, isA<StablecoinCheckoutQuoted>());
      expect(bloc.state.coin.paymentMethod, "USDC");
    });
  });

  group("expiry", () {
    test("counts down to the invoice when the quote outlives it", () async {
      stubQuote(_baseQuote());

      final state = await selectNetwork("base");

      expect((state as StablecoinCheckoutQuoted).deadline, _expirationTime);
    });

    test("counts down to the quote when it ends first, then offers a new one", () async {
      final offeredUntil = _now.add(const Duration(minutes: 5));
      stubQuote(_baseQuote(offeredUntil: offeredUntil));

      final state = await selectNetwork("base");
      expect((state as StablecoinCheckoutQuoted).deadline, offeredUntil);

      bloc.add(ExpiryTicked(_now.add(const Duration(minutes: 4))));
      await processEvents();
      expect(bloc.state, isA<StablecoinCheckoutQuoted>());

      bloc.add(ExpiryTicked(offeredUntil));
      await processEvents();
      expect(bloc.state, isA<StablecoinCheckoutQuoteExpired>());

      stubQuote(_baseQuote());
      final settled = bloc.stream.firstWhere((state) => state is! StablecoinCheckoutLoading);
      bloc.add(const NewQuoteRequested());
      expect(await settled, isA<StablecoinCheckoutQuoted>());
    });

    test("tapping the network of an expired quote does not request again", () async {
      final offeredUntil = _now.add(const Duration(minutes: 5));
      stubQuote(_baseQuote(offeredUntil: offeredUntil));
      await selectNetwork("base");
      bloc.add(ExpiryTicked(offeredUntil));
      await processEvents();

      bloc.add(NetworkSelected(network("base")));
      await processEvents();

      expect(bloc.state, isA<StablecoinCheckoutQuoteExpired>());
      verify(quoteRequest).called(1);
    });

    test("a quote without offered_until only expires with the invoice", () async {
      stubQuote(_tronQuote);
      await selectCoin("USDT");
      await selectNetwork("tron");

      bloc.add(ExpiryTicked(_expirationTime.subtract(const Duration(seconds: 1))));
      await processEvents();
      expect(bloc.state, isA<StablecoinCheckoutQuoted>());

      bloc.add(ExpiryTicked(_expirationTime));
      await processEvents();
      expect(bloc.state, isA<StablecoinCheckoutOrderExpired>());
    });

    test("an expired order stays expired and stops accepting choices", () async {
      bloc.add(ExpiryTicked(_expirationTime));
      await processEvents();

      bloc
        ..add(CoinSelected(coin("USDT")))
        ..add(NetworkSelected(network("base")));
      await processEvents();

      expect(bloc.state, isA<StablecoinCheckoutOrderExpired>());
      verifyNever(quoteRequest);
    });

    test("drops a quote that arrives after the order expired", () async {
      final pending = Completer<CakePayStablecoinQuote>();
      when(quoteRequest).thenAnswer((_) => pending.future);
      bloc.add(NetworkSelected(network("base")));
      await processEvents();

      bloc.add(ExpiryTicked(_expirationTime));
      await processEvents();
      pending.complete(_baseQuote());
      await processEvents();

      expect(bloc.state, isA<StablecoinCheckoutOrderExpired>());
    });
  });

  group("pay in Cake Wallet", () {
    test("is offered when the wallet is on the network and holds enough of the token", () async {
      stubWallet(
        WalletType.base,
        chainId: 8453,
        balances: {usdcOnBase: _Balance(Money.parse("30", usdcOnBase))},
      );
      stubQuote(_baseQuote());

      final state = await selectNetwork("base") as StablecoinCheckoutQuoted;

      expect(state.canPayInCakeWallet, isTrue);
      final request = state.paymentRequest;
      expect(request.address, _depositAddress);
      expect(request.contractAddress, _baseUsdc);
      expect(request.chainId, 8453);
      expect(request.rawTokenAmount, "25061219");
    });

    test("is not offered when the balance is below the quoted amount", () async {
      stubWallet(
        WalletType.base,
        chainId: 8453,
        balances: {usdcOnBase: _Balance(Money.parse("25.06", usdcOnBase))},
      );
      stubQuote(_baseQuote());

      final state = await selectNetwork("base") as StablecoinCheckoutQuoted;

      expect(state.canPayInCakeWallet, isFalse);
    });

    test("is offered once the balance covers the quote", () async {
      stubWallet(
        WalletType.base,
        chainId: 8453,
        balances: {usdcOnBase: _Balance(Money.parse("20", usdcOnBase))},
      );
      stubQuote(_baseQuote());
      final quoted = await selectNetwork("base") as StablecoinCheckoutQuoted;
      expect(quoted.canPayInCakeWallet, isFalse);

      walletBalances[usdcOnBase] = _Balance(Money.parse("30", usdcOnBase));
      await processEvents();

      expect((bloc.state as StablecoinCheckoutQuoted).canPayInCakeWallet, isTrue);
    });

    test("is not offered when the wallet is on another network", () async {
      stubWallet(
        WalletType.ethereum,
        chainId: 1,
        balances: {usdcOnBase: _Balance(Money.parse("30", usdcOnBase))},
      );
      stubQuote(_baseQuote());

      final state = await selectNetwork("base") as StablecoinCheckoutQuoted;

      expect(state.canPayInCakeWallet, isFalse);
    });

    test("pays a Tron quote with the token contract, not the bare address", () async {
      stubWallet(
        WalletType.tron,
        balances: {usdtOnTron: _Balance(Money.parse("50", usdtOnTron))},
      );
      stubQuote(_tronQuote);
      await selectCoin("USDT");

      final state = await selectNetwork("tron") as StablecoinCheckoutQuoted;

      expect(state.canPayInCakeWallet, isTrue);
      final request = state.paymentRequest;
      expect(request.address, "TDepositAddress");
      expect(request.amount, "28.23");
      expect(request.contractAddress, _tronUsdt);
      expect(request.scheme, "tron");
    });
  });

  group("order status", () {
    test("reports the order record once the status moves on", () async {
      final record = _order().toOrder(
        from: "USDC",
        amount: "25.061219",
        receiveAddress: _depositAddress,
        walletId: "wallet-1",
      );
      when(() => orders.values).thenReturn([record]);
      when(
        () => service.findOrderById(orderId: "order-1"),
      ).thenAnswer((_) async => _order(status: "paid"));

      final updated = bloc.stream.first;
      bloc.add(const OrderPollTicked());

      expect((await updated as StablecoinCheckoutOrderStatusChanged).orderRecord, record);
    });

    test("stays put while the order is still awaiting payment", () async {
      when(() => service.findOrderById(orderId: "order-1")).thenAnswer((_) async => _order());

      bloc.add(const OrderPollTicked());
      await processEvents();

      expect(bloc.state, isA<StablecoinCheckoutReady>());
    });

    testWidgets("polls the order every 20 seconds", (tester) async {
      when(
        () => service.findOrderById(orderId: "order-1"),
      ).thenAnswer((_) async => _order(status: "paid"));
      final pollingBloc = StablecoinCheckoutBloc(
        order: _order(),
        wallet: wallet,
        cakePayService: service,
        orders: orders,
      );

      await tester.pump(const Duration(seconds: 19));
      expect(pollingBloc.state, isA<StablecoinCheckoutReady>());

      await tester.pump(const Duration(seconds: 1));
      expect(pollingBloc.state, isA<StablecoinCheckoutOrderStatusChanged>());

      unawaited(pollingBloc.close());
    });
  });
}
