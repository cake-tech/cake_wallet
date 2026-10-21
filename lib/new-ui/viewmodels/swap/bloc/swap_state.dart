part of "swap_bloc.dart";

@immutable
sealed class SwapState {
  const SwapState();

  bool get canInitiateSwap => false;
}

abstract interface class SwapFailureState {
  Object get error;
}

final class SwapStateNotLoaded extends SwapState {
  const SwapStateNotLoaded();
}

abstract class SwapStateWithInputs extends SwapState {
  const SwapStateWithInputs();

  SwapAmount get depositAmount;

  SwapAmount get payoutAmount;

  SwapSource get source;

  SwapAddress? get payoutAddress;

  bool get isFixedRate;

  bool get isExternalSend => source is ExternalSwapSource;

  bool get isSwapAll => depositAmount.isSwapAll;

  String get memo;

  List<ExchangeProviderDescription> get usableProviders;

  RateRequest get rateRequest => isFixedRate
      ? FixedRateRequest(depositCurrency: depositAmount.currency, payoutAmount: payoutAmount.cryptoAmount)
      : FloatingRateRequest(depositAmount: depositAmount.cryptoAmount, payoutCurrency: payoutAmount.currency);

  @override
  bool get canInitiateSwap => payoutAddress != null;
}

final class SwapInputState extends SwapStateWithInputs {
  const SwapInputState({
    required this.hasSwapAll, required this.memo,
    required this.depositAmount,
    required this.payoutAmount,
    required this.source,
    required this.payoutAddress,
    required this.isFixedRate,
    required this.availableProviders,
    required this.enabledProviders,
    required this.forceDecentralizedProviders,
    this.forcedProvider,
  });

  @override
  final SwapAmount depositAmount;
  @override
  final SwapAmount payoutAmount;
  @override
  final SwapSource source;
  @override
  final SwapAddress? payoutAddress;
  @override
  final bool isFixedRate;
  @override
  final String memo;

  final bool hasSwapAll;

  final List<ExchangeProviderDescription> availableProviders;
  final List<ExchangeProviderDescription> enabledProviders;
  final ExchangeProviderDescription? forcedProvider;
  final bool forceDecentralizedProviders;

  @override
  List<ExchangeProviderDescription> get usableProviders =>
      (forcedProvider != null ? [forcedProvider!] : enabledProviders)
          .where(_supportedForSwap)
          .toList();

  bool _supportedForSwap(ExchangeProviderDescription provider) =>
      (!forceDecentralizedProviders || !provider.isCentralized) &&
      (!isSwapAll || provider.supportsSwapAll) &&
      (payoutAmount.currency.memoLabelType == null || provider.supportsMemoOrDestinationTag);

  SwapInputState copyWith({
    SwapAmount? depositAmount,
    SwapAmount? payoutAmount,
    SwapSource? source,
    String? memo,
    bool? hasSwapAll,
    SwapAddress? Function()? payoutAddress,
    bool? isFixedRate,
    List<ExchangeProviderDescription>? availableProviders,
    List<ExchangeProviderDescription>? enabledProviders,
    ExchangeProviderDescription? Function()? forcedProvider,
    bool? forceDecentralizedProviders,
  }) => SwapInputState(
    memo: memo ?? this.memo,
    depositAmount: depositAmount ?? this.depositAmount,
    payoutAmount: payoutAmount ?? this.payoutAmount,
    hasSwapAll: hasSwapAll ?? this.hasSwapAll,
    source: source ?? this.source,
    payoutAddress: payoutAddress != null ? payoutAddress.call() : this.payoutAddress,
    isFixedRate: isFixedRate ?? this.isFixedRate,
    availableProviders: availableProviders ?? this.availableProviders,
    enabledProviders: enabledProviders ?? this.enabledProviders,
    forcedProvider: forcedProvider != null ? forcedProvider.call() : this.forcedProvider,
    forceDecentralizedProviders: forceDecentralizedProviders ?? this.forceDecentralizedProviders,
  );
}

final class SwapStateCreating extends SwapStateWithInputs {
  const SwapStateCreating({
    required this.selectedProvider,
    required this.source,
    required this.request,
    required this.depositAmount,
    required this.payoutAmount,
    required this.payoutAddress,
  });

  final TradeRequest request;

  final ExchangeProviderDescription selectedProvider;

  @override
  final SwapAmount depositAmount;

  @override
  final SwapAmount payoutAmount;

  @override
  final SwapSource source;

  @override
  final SwapAddress payoutAddress;

  @override
  bool get isFixedRate => request.isFixedRate;

  @override
  String get memo => request.toAddressExtraId ?? "";

  @override
  List<ExchangeProviderDescription> get usableProviders => [selectedProvider];

  SwapStateCreating copyWith({
    ExchangeProviderDescription? selectedProvider,
    TradeRequest? request,
    SwapSource? source,
    SwapAmount? depositAmount,
    SwapAmount? payoutAmount,
    SwapAddress? payoutAddress,
  }) => SwapStateCreating(
    selectedProvider: selectedProvider ?? this.selectedProvider,
    request: request ?? this.request,
    source: source ?? this.source,
    depositAmount: depositAmount ?? this.depositAmount,
    payoutAmount: payoutAmount ?? this.payoutAmount,
    payoutAddress: payoutAddress ?? this.payoutAddress,
  );

  SwapStateCreationError toError(Object error) => SwapStateCreationError(
    selectedProvider: selectedProvider,
    request: request,
    source: source,
    depositAmount: depositAmount,
    payoutAmount: payoutAmount,
    payoutAddress: payoutAddress,
    error: error,
  );
}

final class SwapStateCreationError extends SwapStateCreating implements SwapFailureState {
  const SwapStateCreationError({
    required super.selectedProvider,
    required super.source,
    required super.request,
    required super.depositAmount,
    required super.payoutAmount,
    required super.payoutAddress,
    required this.error,
  });

  @override
  final Object error;
}

final class SwapInitiationError extends SwapStateWithInputs implements SwapFailureState {
  const SwapInitiationError({required this.inputs, required this.error});

  final SwapInputState inputs;

  @override
  final Object error;

  @override
  SwapAmount get depositAmount => inputs.depositAmount;

  @override
  SwapAmount get payoutAmount => inputs.payoutAmount;

  @override
  SwapSource get source => inputs.source;

  @override
  SwapAddress? get payoutAddress => inputs.payoutAddress;

  @override
  bool get isFixedRate => inputs.isFixedRate;

  @override
  String get memo => inputs.memo;

  @override
  List<ExchangeProviderDescription> get usableProviders => inputs.usableProviders;

  @override
  bool get canInitiateSwap => false;
}

abstract class SwapStateWithTrade extends SwapStateWithInputs {
  const SwapStateWithTrade({
    required this.source,
    required this.trade,
    required this.depositFiatAmount,
    required this.payoutFiatAmount,
    required this.payoutAddress,
    required this.isFixedRate,
  });

  final Trade trade;

  final Money depositFiatAmount;

  final Money payoutFiatAmount;

  @override
  final SwapSource source;

  @override
  final bool isFixedRate;

  @override
  SwapAmount get depositAmount =>
      SwapAmount(cryptoAmount: trade.depositAmount, fiatAmount: depositFiatAmount);

  @override
  SwapAmount get payoutAmount =>
      SwapAmount(cryptoAmount: trade.payoutAmount, fiatAmount: payoutFiatAmount);

  @override
  final SwapAddress payoutAddress;

  @override
  String get memo => trade.toAddressExtraId ?? "";

  @override
  List<ExchangeProviderDescription> get usableProviders => [trade.provider];

  @override
  bool get canInitiateSwap => false;
}

final class SwapGeneratingTransaction extends SwapStateWithTrade {
  const SwapGeneratingTransaction({
    required super.trade,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });

  SwapTransactionGenerationError toError(Object error) => SwapTransactionGenerationError(
    error: error,
    trade: trade,
    source: source,
    depositFiatAmount: depositFiatAmount,
    payoutFiatAmount: payoutFiatAmount,
    payoutAddress: payoutAddress,
    isFixedRate: isFixedRate,
  );
}

final class SwapAwaitingExternalSend extends SwapStateWithTrade {
  const SwapAwaitingExternalSend({
    required super.trade,
    required this.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  }) : super(source: source);

  @override
  final ExternalSwapSource source;
}

abstract class SwapStateWithTransaction extends SwapStateWithTrade {
  const SwapStateWithTransaction({
    required super.trade,
    required this.transaction,
    required this.feeFiatAmount,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });

  final PendingTransaction transaction;

  final Money feeFiatAmount;

  SwapTransactionCommitError toError(Object error) => SwapTransactionCommitError(
    error: error,
    trade: trade,
    transaction: transaction,
    feeFiatAmount: feeFiatAmount,
    source: source,
    depositFiatAmount: depositFiatAmount,
    payoutFiatAmount: payoutFiatAmount,
    payoutAddress: payoutAddress,
    isFixedRate: isFixedRate,
  );
}

final class SwapAwaitingSend extends SwapStateWithTransaction {
  const SwapAwaitingSend({
    required super.trade,
    required super.transaction,
    required super.feeFiatAmount,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });
}

final class SwapTransactionGenerationError extends SwapGeneratingTransaction
    implements SwapFailureState {
  const SwapTransactionGenerationError({
    required this.error,
    required super.trade,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });

  @override
  final Object error;
}

final class SwapAwaitingHardwareWallet extends SwapStateWithTransaction {
  const SwapAwaitingHardwareWallet({
    required this.type,
    required super.trade,
    required super.transaction,
    required super.feeFiatAmount,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });

  final HardwareWalletType type;
}

final class SwapSending extends SwapStateWithTransaction {
  const SwapSending({
    required super.trade,
    required super.transaction,
    required super.feeFiatAmount,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });
}

final class SwapTransactionCommitted extends SwapStateWithTransaction {
  const SwapTransactionCommitted({
    required super.trade,
    required super.transaction,
    required super.feeFiatAmount,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });
}

final class SwapTransactionCommitError extends SwapStateWithTransaction
    implements SwapFailureState {
  SwapTransactionCommitError({
    required this.error,
    required super.trade,
    required super.transaction,
    required super.feeFiatAmount,
    required super.source,
    required super.depositFiatAmount,
    required super.payoutFiatAmount,
    required super.payoutAddress,
    required super.isFixedRate,
  });

  @override
  final Object error;
}
