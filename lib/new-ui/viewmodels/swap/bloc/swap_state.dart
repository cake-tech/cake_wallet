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

  List<ExchangeProviderDescription> get usableProviders;

  @override
  bool get canInitiateSwap {
    if(source case final ExternalSwapSource s) {
      if(s.refundAddress.isEmpty) {
        return false;
      }
    }

    if(payoutAddress == null) {
      return false;
    }

    return true;
  }
}

final class SwapInputState extends SwapStateWithInputs {
  const SwapInputState({
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

  final List<ExchangeProviderDescription> availableProviders;
  final List<ExchangeProviderDescription> enabledProviders;
  final ExchangeProviderDescription? forcedProvider;
  final bool forceDecentralizedProviders;

  @override
  List<ExchangeProviderDescription> get usableProviders =>
      forcedProvider != null ? [forcedProvider!] : enabledProviders.where((item) => !forceDecentralizedProviders || !item.isCentralized).toList();

  SwapInputState copyWith({
    SwapAmount? depositAmount,
    SwapAmount? payoutAmount,
    SwapSource? source,
    SwapAddress? payoutAddress,
    bool? isFixedRate,
    List<ExchangeProviderDescription>? availableProviders,
    List<ExchangeProviderDescription>? enabledProviders,
    ExchangeProviderDescription? Function()? forcedProvider,
    bool? forceDecentralizedProviders,
  }) =>
      SwapInputState(
        depositAmount: depositAmount ?? this.depositAmount,
        payoutAmount: payoutAmount ?? this.payoutAmount,
        source: source ?? this.source,
        payoutAddress: payoutAddress ?? this.payoutAddress,
        isFixedRate: isFixedRate ?? this.isFixedRate,
        availableProviders: availableProviders ?? this.availableProviders,
        enabledProviders: enabledProviders ?? this.enabledProviders,
        forcedProvider: forcedProvider != null ? forcedProvider.call() : this.forcedProvider,
        forceDecentralizedProviders: forceDecentralizedProviders ?? this.forceDecentralizedProviders
      );
}

final class SwapStateCreating extends SwapStateWithInputs {
  const SwapStateCreating({
    required this.selectedProvider,
    required this.source,
    required this.request,
  });

  final TradeRequest request;

  final ExchangeProviderDescription selectedProvider;

  @override
  SwapAmount get depositAmount => request.depositAmount;

  @override
  SwapAmount get payoutAmount => request.payoutAmount;

  @override
  final SwapSource source;

  @override
  SwapAddress get payoutAddress => request.payoutAddress;

  @override
  bool get isFixedRate => request.isFixedRate;

  @override
  List<ExchangeProviderDescription> get usableProviders => [selectedProvider];

  SwapStateCreating copyWith({
    ExchangeProviderDescription? selectedProvider,
    TradeRequest? request,
    SwapSource? source,
  }) =>
      SwapStateCreating(
        selectedProvider: selectedProvider ?? this.selectedProvider,
        request: request ?? this.request,
        source: source ?? this.source,
      );

  SwapStateCreationError toError(Object error) =>
      SwapStateCreationError(
          selectedProvider: selectedProvider, request: request, source: source, error: error);
}

final class SwapStateCreationError extends SwapStateCreating implements SwapFailureState {
  const SwapStateCreationError({required super.selectedProvider, required super.source, required super.request, required this.error});

  @override
  final Object error;

}

final class SwapAwaitingWalletSwitch extends SwapStateCreating {
  const SwapAwaitingWalletSwitch({
    required super.selectedProvider,
    required this.source,
    required super.request,
  }) : super(source: source);

  @override
  final InternalSwapSource source;
}

abstract class SwapStateWithTrade extends SwapState {
  const SwapStateWithTrade({required this.source, required this.trade});

  final Trade trade;
  final SwapSource source;
}

final class SwapGeneratingTransaction extends SwapStateWithTrade {
  const SwapGeneratingTransaction({required super.trade, required super.source});
}

final class SwapAwaitingExternalSend extends SwapStateWithTrade {
  const SwapAwaitingExternalSend({required this.uri, required super.trade, required this.source})
      : super(source: source);

  @override
  final ExternalSwapSource source;

  final PaymentURI uri;
}


final class SwapCreated extends SwapStateWithTrade {
  const SwapCreated({required super.trade, required super.source});
}

abstract class SwapStateWithTransaction extends SwapStateWithTrade {
  const SwapStateWithTransaction({required super.trade, required this.transaction, required super.source});


  final PendingTransaction transaction;
}

final class SwapAwaitingSend extends SwapStateWithTransaction {
  const SwapAwaitingSend({required super.trade, required super.transaction, required super.source});
}

final class SwapAwaitingHardwareWallet extends SwapStateWithTransaction {
  const SwapAwaitingHardwareWallet({required this.type, required super.trade, required super.transaction, required super.source});

  final HardwareWalletType type;
}

final class SwapSending extends SwapStateWithTransaction {
  const SwapSending({required super.trade, required super.transaction, required super.source});
}

final class SwapTransactionCommitted extends SwapStateWithTransaction {
  const SwapTransactionCommitted({required super.trade, required super.transaction, required super.source});
}
