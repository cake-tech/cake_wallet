import "package:cake_wallet/cake_pay/src/cake_pay_exceptions.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_card.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_order.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_payment_method.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_stablecoin.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_vendor.dart";
import "package:cake_wallet/cake_pay/src/services/cake_pay_service.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/order/order.dart";
import "package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart";
import "package:cake_wallet/view_model/send/output.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart" show ObservableList, ObservableMap;
import "package:mocktail/mocktail.dart";

class _Service extends Mock implements CakePayService {}

class _Wallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _Send extends Mock implements SendViewModel {}

class _Orders extends Mock implements Box<Order> {}

class _OrderRecord extends Mock implements Order {}

class _Output extends Mock implements Output {}

class _Balance extends Balance {
  _Balance(CryptoCurrency currency)
      : super(Money.fromInt(100000000, currency), Money.zero(currency));
}

const _contract = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";
const _address = "0x6490e244136af11ca7c7ff8997916e01e4a39b1c";

void main() {
  final token = Erc20Token(
    name: "USD Coin",
    symbol: "USDC",
    contractAddress: _contract.toLowerCase(),
    decimal: 6,
  );
  final vendor = CakePayVendor(
    id: 1,
    name: "Vendor",
    available: true,
    country: "US",
    card: CakePayCard(
      id: 1,
      name: "Gift Card",
      fiatCurrency: FiatCurrency.usd,
      denominationItems: [Denomination(value: 25, cardId: 1)],
    ),
  );
  late _Service service;
  late _Wallet wallet;
  late _Send send;
  late _Orders orders;
  late _Output output;
  late CakePayBuyCardViewModel viewModel;
  late CakePayOrder order;
  late Map<String, dynamic> orderJson;
  late DateTime invoiceExpiry;
  late ExecutionState state;
  late CryptoCurrency currency;

  CakePayStablecoinQuote quote({
    DateTime? expiry,
    String? contract = _contract,
  }) =>
      CakePayStablecoinQuote(
        address: _address,
        amount: "25.061219",
        contract: contract,
        offeredUntil: expiry ?? invoiceExpiry.add(const Duration(minutes: 1)),
      );

  Future<CakePayStablecoinQuote> requestQuote() => service.getStablecoinQuote(
        orderId: any(named: "orderId"),
        paymentMethod: any(named: "paymentMethod"),
        chain: any(named: "chain"),
      );

  Future<CakePayOrder> createOrderRequest() => service.createOrder(
        cardId: any(named: "cardId"),
        price: any(named: "price"),
        quantity: any(named: "quantity"),
        confirmsNoVpn: any(named: "confirmsNoVpn"),
        confirmsVoidedRefund: any(named: "confirmsVoidedRefund"),
        confirmsTermsAgreed: any(named: "confirmsTermsAgreed"),
      );

  CakePayBuyCardViewModel createViewModel() => CakePayBuyCardViewModel(
        vendor: vendor,
        cakePayService: service,
        sendViewModel: send,
        orders: orders,
      )..selectedDenomination = ("25", 1);

  Future<void> purchaseStablecoin([CakePayPaymentMethod method = CakePayPaymentMethod.USDC]) async {
    await viewModel.prepareStablecoinOrder();
    viewModel.chooseMethod(method);
    await viewModel.createOrder();
  }

  setUpAll(() {
    registerFallbackValue(CryptoCurrency.eth);
    registerFallbackValue(WalletType.ethereum);
    registerFallbackValue(InitialExecutionState());
    registerFallbackValue(_OrderRecord());
  });

  setUp(() {
    service = _Service();
    wallet = _Wallet();
    send = _Send();
    orders = _Orders();
    output = _Output();
    state = InitialExecutionState();
    currency = CryptoCurrency.baseEth;
    invoiceExpiry = DateTime.now().add(const Duration(minutes: 15));
    orderJson = {
      "order_id": "order-1",
      "external_id": null,
      "amount_usd": 25.0,
      "status": "new",
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
        "BTC": {
          "price": "0.00025",
          "amount_from": 0.00025,
          "address": "bc1qdeposit",
          "paymentUrls": {"BIP21": "bitcoin:bc1qdeposit?amount=0.00025"},
        },
        for (final coin in ["USDC", "USDT"])
          coin: {
            "requires_quote": true,
            "networks": [
              {"chain": "tron", "name": "Tron"},
              {"chain": "base", "name": "Base"},
            ],
          },
        "invoice_time": DateTime.now().millisecondsSinceEpoch,
        "expiration_time": invoiceExpiry.millisecondsSinceEpoch,
        "commission": null,
      },
    };
    order = CakePayOrder.fromMap(orderJson);
    invoiceExpiry = order.paymentData.expirationTime;
    when(() => wallet.type).thenReturn(WalletType.ethereum);
    when(() => wallet.currency).thenReturn(CryptoCurrency.baseEth);
    when(() => wallet.id).thenReturn("wallet-1");
    when(() => wallet.balance).thenReturn(ObservableMap.of({token: _Balance(token)}));
    when(() => send.wallet).thenReturn(wallet);
    when(() => send.walletType).thenReturn(WalletType.ethereum);
    when(() => send.outputs).thenReturn(ObservableList.of([output]));
    when(() => send.selectedCryptoCurrency).thenAnswer((_) => currency);
    when(() => send.selectedCryptoCurrency = any()).thenAnswer(
      (invocation) => currency = invocation.positionalArguments.single as CryptoCurrency,
    );
    when(() => send.state).thenAnswer((_) => state);
    when(() => send.state = any()).thenAnswer(
      (invocation) => state = invocation.positionalArguments.single as ExecutionState,
    );
    when(
      () => send.translateErrorMessage(any(), any(), any()),
    ).thenAnswer((invocation) => invocation.positionalArguments.first.toString());
    when(() => send.createTransaction()).thenAnswer((_) async => null);
    when(() => orders.add(any())).thenAnswer((_) async => 0);
    when(createOrderRequest).thenAnswer((_) async => order);
    when(requestQuote).thenAnswer((_) async => quote());
    viewModel = createViewModel();
  });

  tearDown(() => viewModel.dispose());

  test(
    "quotes the current chain of an Ethereum-created wallet and prepares the exact token and amount",
    () async {
      final otherUsdc = Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0x0000000000000000000000000000000000000001",
        decimal: 6,
      );
      when(() => wallet.balance)
          .thenReturn(ObservableMap.of({otherUsdc: _Balance(otherUsdc), token: _Balance(token)}));
      expect(await viewModel.prepareStablecoinOrder(),
          unorderedEquals([CakePayPaymentMethod.USDC, CakePayPaymentMethod.USDT]));
      verifyNever(requestQuote);
      verifyNever(() => send.createTransaction());
      viewModel.chooseMethod(CakePayPaymentMethod.USDC);
      when(() => send.createTransaction()).thenAnswer((_) async {
        expect(currency, same(token));
        verify(() => output.address = _address).called(1);
        verify(() => output.setCryptoAmount("25.061219")).called(1);
        return null;
      });
      await viewModel.createOrder();
      verify(createOrderRequest).called(1);
      verify(
        () => service.getStablecoinQuote(orderId: "order-1", paymentMethod: "USDC", chain: "base"),
      ).called(1);
      verify(() => send.createTransaction()).called(1);
      final record = verify(() => orders.add(captureAny())).captured.single as Order;
      expect(record.from, "USDC");
      expect(record.amount, "25.061219");
      expect(record.receiveAddress, _address);
    },
  );

  test("choosing USDT requests its quote and selects its token", () async {
    const usdtContract = "0x0000000000000000000000000000000000000002";
    final usdt = Erc20Token(
      name: "Tether USD",
      symbol: "USDT",
      contractAddress: usdtContract,
      decimal: 6,
    );
    when(
      () => wallet.balance,
    ).thenReturn(ObservableMap.of({token: _Balance(token), usdt: _Balance(usdt)}));
    when(
      requestQuote,
    ).thenAnswer((_) async => quote(contract: usdtContract));
    await purchaseStablecoin(CakePayPaymentMethod.USDT);
    verify(
      () => service.getStablecoinQuote(orderId: "order-1", paymentMethod: "USDT", chain: "base"),
    ).called(1);
    expect(currency, same(usdt));
  });

  test("uses quote expiry when it precedes invoice expiry", () async {
    final deadline = DateTime.now().add(const Duration(minutes: 1));
    when(requestQuote).thenAnswer((_) async => quote(expiry: deadline));
    await purchaseStablecoin();
    expect(viewModel.expirationTime, deadline);
  });

  test("uses invoice expiry when it precedes quote expiry", () async {
    await purchaseStablecoin();
    expect(viewModel.expirationTime, invoiceExpiry);
  });

  test("does not prepare a payment after the quoted price has expired", () async {
    when(
      requestQuote,
    ).thenAnswer((_) async => quote(expiry: DateTime.now().subtract(const Duration(seconds: 1))));
    await purchaseStablecoin();
    expect(state, isA<FailureState>());
    verifyNever(() => send.createTransaction());
    verifyNever(() => orders.add(any()));
  });

  test("marks payment expired when its deadline passes during transaction preparation", () async {
    when(() => send.createTransaction()).thenAnswer((_) async {
      viewModel.expirationTime = DateTime.now().subtract(const Duration(seconds: 1));
      return null;
    });
    await purchaseStablecoin();
    verify(() => send.createTransaction()).called(1);
    expect(viewModel.isOrderExpired, isTrue);
    expect(state, isA<FailureState>());
  });

  test("shows a readable quote error and quotes a new invoice when retried", () async {
    when(requestQuote).thenThrow(const CakePayResponseException("Choose another payment method."));
    await purchaseStablecoin();
    expect(state, isA<FailureState>());
    expect((state as FailureState).error, contains("Choose another payment method."));
    verifyNever(() => send.createTransaction());
    verifyNever(() => orders.add(any()));
    orderJson["order_id"] = "order-2";
    order = CakePayOrder.fromMap(orderJson);
    when(requestQuote).thenAnswer((_) async => quote());
    await purchaseStablecoin();
    verify(createOrderRequest).called(2);
    verify(() => service.getStablecoinQuote(
          orderId: "order-2",
          paymentMethod: "USDC",
          chain: "base",
        )).called(1);
    verify(() => send.createTransaction()).called(1);
  });

  test(
    "rejects a coin not offered on the current network without quoting another network",
    () async {
      for (final coin in order.paymentData.stablecoins) {
        coin.networks.removeWhere((network) => network.id == "base");
      }
      expect(await viewModel.prepareStablecoinOrder(), isEmpty);
      expect(state, isA<FailureState>());
      verifyNever(requestQuote);
      verifyNever(() => send.createTransaction());
    },
  );

  for (final contract in [null, "0x0000000000000000000000000000000000000003"]) {
    test("rejects a quote with ${contract == null ? "no" : "an unavailable"} token contract",
        () async {
      when(requestQuote).thenAnswer((_) async => quote(contract: contract));
      await purchaseStablecoin();
      expect(state, isA<FailureState>());
      expect(currency, CryptoCurrency.baseEth);
      verifyNever(() => send.createTransaction());
    });
  }

  test("keeps the existing insufficient-funds failure from transaction preparation", () async {
    when(() => send.createTransaction()).thenAnswer((_) async {
      send.state = FailureState("Not enough USDC or gas.");
      return null;
    });
    await purchaseStablecoin();
    expect(state, isA<FailureState>());
    expect((state as FailureState).error, "Not enough USDC or gas.");
  });

  test("offers only the coin supported on the current network and prepares that payment", () async {
    order.paymentData.stablecoins
        .firstWhere((coin) => coin.method == CakePayPaymentMethod.USDT)
        .networks
        .removeWhere((network) => network.id == "base");
    final methods = await viewModel.prepareStablecoinOrder();
    expect(methods, [CakePayPaymentMethod.USDC]);
    viewModel.chooseMethod(methods.single);
    await viewModel.createOrder();
    verify(createOrderRequest).called(1);
    verify(() =>
            service.getStablecoinQuote(orderId: "order-1", paymentMethod: "USDC", chain: "base"))
        .called(1);
    verify(() => send.createTransaction()).called(1);
  });

  test("does not request a quote when the order has no stablecoins", () async {
    order.paymentData.stablecoins.clear();
    expect(await viewModel.prepareStablecoinOrder(), isEmpty);
    expect(state, isA<FailureState>());
    verifyNever(requestQuote);
    verifyNever(() => send.createTransaction());
  });

  test("rejects an expired invoice before requesting a quote", () async {
    (orderJson["payment_data"] as Map<String, dynamic>)["expiration_time"] =
        DateTime.now().subtract(const Duration(seconds: 1)).millisecondsSinceEpoch;
    order = CakePayOrder.fromMap(orderJson);
    await purchaseStablecoin();
    expect((state as FailureState).error, contains("expired"));
    verifyNever(requestQuote);
    verifyNever(() => send.createTransaction());
  });

  test("retains the existing Bitcoin payment without requesting a stablecoin quote", () async {
    viewModel.dispose();
    when(() => send.walletType).thenReturn(WalletType.bitcoin);
    when(() => wallet.type).thenReturn(WalletType.bitcoin);
    when(() => wallet.currency).thenReturn(CryptoCurrency.btc);
    when(() => wallet.isSoftwareWallet).thenReturn(false);
    viewModel = createViewModel();
    await viewModel.createOrder();
    verifyNever(requestQuote);
    verify(() => send.createTransaction()).called(1);
    verify(() => output.address = "bc1qdeposit").called(1);
    verify(() => output.setCryptoAmount("0.00025")).called(1);
  });

  test("reports an unsupported wallet before creating an order", () async {
    viewModel.dispose();
    when(() => send.walletType).thenReturn(WalletType.nano);
    when(() => wallet.type).thenReturn(WalletType.nano);
    when(() => wallet.currency).thenReturn(CryptoCurrency.nano);
    viewModel = createViewModel();
    await viewModel.createOrder();
    expect((state as FailureState).error, contains("Unsupported wallet type"));
    verifyNever(createOrderRequest);
  });
}
