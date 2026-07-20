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

  SwapAddress get refundAddress;

  SwapAddress? get payoutAddress;

  bool get isFixedRate;

  bool get isExternalSend => refundAddress is! CurrentSwapAddress;
}

final class SwapInputState extends SwapStateWithInputs {
  const SwapInputState({
    required this.depositAmount,
    required this.payoutAmount,
    required this.refundAddress,
    required this.payoutAddress,
    required this.isFixedRate,
    required this.availableProviders,
    required this.enabledProviders,
    this.forcedProvider,
  });

  @override
  final SwapAmount depositAmount;
  @override
  final SwapAmount payoutAmount;
  @override
  final SwapAddress refundAddress;
  @override
  final SwapAddress? payoutAddress;
  @override
  final bool isFixedRate;

  final List<ExchangeProviderDescription> availableProviders;
  final List<ExchangeProviderDescription> enabledProviders;
  final ExchangeProviderDescription? forcedProvider;

  List<ExchangeProviderDescription> get usableProviders =>
      forcedProvider != null ? [forcedProvider!] : enabledProviders;
}

final class SwapStateCreating extends SwapStateWithInputs {
  const SwapStateCreating({required this.selectedProvider, required this.request});

  final TradeRequest request;

  final ExchangeProviderDescription selectedProvider;

  @override
  SwapAmount get depositAmount => request.depositAmount;

  @override
  SwapAmount get payoutAmount => request.payoutAmount;

  @override
  SwapAddress get refundAddress => request.refundAddress;

  @override
  SwapAddress get payoutAddress => request.payoutAddress;

  @override
  bool get isFixedRate => request.isFixedRate;
}

final class SwapStateWithTrade extends SwapStateWithInputs {
  SwapStateWithTrade({required this.trade});

  final Trade trade;



  @override
  SwapAmount get depositAmount => trade.depositAmount;

  @override
  SwapAmount get payoutAmount => trade.payoutAmount;

  @override
  SwapAddress get refundAddress => trade.refundAddress;

  @override
  SwapAddress get payoutAddress => trade.payoutAddress;

  @override
  bool get isFixedRate => true;

}
