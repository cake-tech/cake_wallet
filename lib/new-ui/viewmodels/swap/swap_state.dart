part of "swap_bloc.dart";

@immutable
sealed class SwapState {
  const SwapState();
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
    ExchangeProviderDescription? forcedProvider,
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
        forcedProvider: forcedProvider ?? this.forcedProvider,
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
}

abstract class SwapStateWithTrade extends SwapState {
  const SwapStateWithTrade({required this.trade});

  final Trade trade;
}

final class SwapCreated extends SwapStateWithTrade {
  const SwapCreated({required super.trade});
}
