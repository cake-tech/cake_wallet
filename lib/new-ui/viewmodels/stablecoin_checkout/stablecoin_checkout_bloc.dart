import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/cake_pay/src/cake_pay_exceptions.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_order.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_stablecoin_quote.dart";
import "package:cake_wallet/cake_pay/src/services/cake_pay_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/order/order.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:collection/collection.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:hive/hive.dart";
import "package:meta/meta.dart";
import "package:mobx/mobx.dart" show ReactionDisposer, reaction;

part "stablecoin_checkout_event.dart";
part "stablecoin_checkout_state.dart";

class StablecoinCheckoutBloc extends Bloc<StablecoinCheckoutEvent, StablecoinCheckoutState> {
  StablecoinCheckoutBloc({
    required this.order,
    required WalletBase wallet,
    required CakePayService cakePayService,
    required Box<Order> orders,
  })  : _wallet = wallet,
        _cakePayService = cakePayService,
        _orders = orders,
        super(StablecoinCheckoutReady(order.paymentData.stablecoins.first)) {
    on<CoinSelected>(_onCoinSelected);
    on<NetworkSelected>(_onNetworkSelected, transformer: droppable());
    on<NewQuoteRequested>(_onNewQuoteRequested, transformer: droppable());
    on<ExpiryTicked>(_onExpiryTicked);
    on<OrderPollTicked>(_onOrderPollTicked, transformer: droppable());
    on<BalanceChanged>(_onBalanceChanged);

    _balanceDisposer = reaction(
      (_) => _wallet.balance.values.toList(),
      (_) => add(const BalanceChanged()),
    );
    _expiryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(ExpiryTicked(DateTime.now())),
    );
    _orderStatusTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => add(const OrderPollTicked()),
    );
  }

  final CakePayOrder order;
  final WalletBase _wallet;
  final CakePayService _cakePayService;
  final Box<Order> _orders;
  late final ReactionDisposer _balanceDisposer;
  late final Timer _expiryTimer;
  late final Timer _orderStatusTimer;

  List<StablecoinPaymentData> get coins => order.paymentData.stablecoins;

  Order? get _orderRecord =>
      _orders.values.firstWhereOrNull((record) => record.id == order.orderId);

  void _onCoinSelected(CoinSelected event, Emitter<StablecoinCheckoutState> emit) {
    if (state is StablecoinCheckoutSelectable && event.coin != state.coin) {
      emit(StablecoinCheckoutReady(event.coin));
    }
  }

  Future<void> _onNetworkSelected(
    NetworkSelected event,
    Emitter<StablecoinCheckoutState> emit,
  ) async {
    if (state
        case StablecoinCheckoutQuoted(:final network) ||
            StablecoinCheckoutQuoteExpired(:final network) when network == event.network) {
      return;
    }
    await _requestQuote(event.network, emit);
  }

  Future<void> _onNewQuoteRequested(
    NewQuoteRequested event,
    Emitter<StablecoinCheckoutState> emit,
  ) async {
    final network = state.network;
    if (network != null) {
      await _requestQuote(network, emit);
    }
  }

  void _onExpiryTicked(ExpiryTicked event, Emitter<StablecoinCheckoutState> emit) {
    if (state is StablecoinCheckoutOrderExpired || state is StablecoinCheckoutOrderStatusChanged) {
      return;
    }

    if (!event.now.isBefore(order.paymentData.expirationTime)) {
      emit(StablecoinCheckoutOrderExpired(state.coin, state.network));
    } else if (state case StablecoinCheckoutQuoted(:final coin, :final network, :final deadline)
        when !event.now.isBefore(deadline)) {
      emit(StablecoinCheckoutQuoteExpired(coin, network));
    }
  }

  Future<void> _onOrderPollTicked(
    OrderPollTicked event,
    Emitter<StablecoinCheckoutState> emit,
  ) async {
    try {
      final updatedOrder = await _cakePayService.findOrderById(orderId: order.orderId);
      if (updatedOrder.status != order.status && state is! StablecoinCheckoutOrderStatusChanged) {
        emit(StablecoinCheckoutOrderStatusChanged(state.coin, state.network, _orderRecord));
      }
    } on CakePayUnauthorizedException {
      _orderStatusTimer.cancel();
    } catch (e) {
      printV(e);
    }
  }

  void _onBalanceChanged(BalanceChanged event, Emitter<StablecoinCheckoutState> emit) {
    if (state
        case StablecoinCheckoutQuoted(
          :final coin,
          :final network?,
          :final quote,
          :final deadline,
          :final canPayInCakeWallet,
        )) {
      final canPay = _canPayInCakeWallet(network, quote);
      if (canPay != canPayInCakeWallet) {
        emit(
          StablecoinCheckoutQuoted(
            coin,
            network,
            quote,
            deadline: deadline,
            canPayInCakeWallet: canPay,
          ),
        );
      }
    }
  }

  Future<void> _requestQuote(
    StablecoinNetwork network,
    Emitter<StablecoinCheckoutState> emit,
  ) async {
    if (state is! StablecoinCheckoutSelectable) {
      return;
    }

    final coin = state.coin;
    emit(StablecoinCheckoutLoading(coin, network));
    final result = await _fetchQuote(coin, network);
    if (state is StablecoinCheckoutLoading) {
      emit(result);
    }
  }

  Future<StablecoinCheckoutState> _fetchQuote(
    StablecoinPaymentData coin,
    StablecoinNetwork network,
  ) async {
    try {
      final quote = await _cakePayService.getStablecoinQuote(
        orderId: order.orderId,
        paymentMethod: coin.paymentMethod,
        chain: network.chain,
      );
      await _saveOrderRecord(quote);
      return StablecoinCheckoutQuoted(
        coin,
        network,
        quote,
        deadline: _deadline(quote),
        canPayInCakeWallet: _canPayInCakeWallet(network, quote),
      );
    } on CakePayUnauthorizedException {
      return StablecoinCheckoutFailure(coin, network, S.current.cake_pay_session_expired);
    } on CakePayResponseException catch (e) {
      return StablecoinCheckoutFailure(coin, network, e.message);
    } catch (e) {
      printV(e);
      return StablecoinCheckoutFailure(coin, network, S.current.please_try_again_later);
    }
  }

  DateTime _deadline(CakePayStablecoinQuote quote) {
    final offeredUntil = quote.offeredUntil;
    final expirationTime = order.paymentData.expirationTime;
    return offeredUntil != null && offeredUntil.isBefore(expirationTime)
        ? offeredUntil
        : expirationTime;
  }

  bool _canPayInCakeWallet(StablecoinNetwork network, CakePayStablecoinQuote quote) {
    final contract = quote.contract?.toLowerCase();
    if (contract == null ||
        network.currency != walletTypeToCryptoCurrency(_wallet.type, chainId: _wallet.chainId)) {
      return false;
    }

    final balance = _wallet.balance.entries.firstWhereOrNull(
      (entry) => TokenUtilities.tokenAddress(entry.key)?.toLowerCase() == contract,
    );
    if (balance == null) {
      return false;
    }

    final available = balance.value.available;
    final amount = Money.tryParse(quote.amount, available.currency);
    return amount != null && available >= amount;
  }

  Future<void> _saveOrderRecord(CakePayStablecoinQuote quote) async {
    final record = _orderRecord;
    if (record == null) {
      await _orders.add(
        order.toOrder(
          from: quote.paymentMethod,
          amount: quote.amount,
          receiveAddress: quote.address,
          walletId: _wallet.id,
        ),
      );
      return;
    }

    record
      ..from = quote.paymentMethod
      ..amount = quote.amount
      ..receiveAddress = quote.address;
    await record.save();
  }

  @override
  Future<void> close() {
    _balanceDisposer();
    _expiryTimer.cancel();
    _orderStatusTimer.cancel();
    return super.close();
  }
}
