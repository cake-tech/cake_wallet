import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";

class AnyPayRouter {
  static AnyPayDecision route(
    AnyPayRequest request,
    WalletSnapshot snapshot,
    AnyPayResolution resolution,
  ) {
    if (request.rawInput.trim().isEmpty) {
      return const AnyPayEmptyInput();
    }

    final detection = request.detection;
    final detectedType = detection.detectedWalletType;

    if (!detection.isValid || detectedType == null) {
      return const AnyPayApplyToCurrentWallet();
    }

    if (detectedType == WalletType.solana && !snapshot.hasSolanaProxy) {
      return const AnyPayApplyToCurrentWallet();
    }

    if (detectedType == WalletType.tron && !snapshot.hasTronProxy) {
      return const AnyPayApplyToCurrentWallet();
    }

    if (isEVMCompatibleChain(detectedType)) {
      if (!snapshot.hasEvmProxy) {
        return const AnyPayApplyToCurrentWallet();
      }

      return _routeEvm(request, snapshot, resolution);
    }

    if (resolution is TokenUnknown) {
      return AnyPayUnsupportedToken(resolution.contract);
    }

    if (detectedType == snapshot.type) {
      return AnyPayApplyToCurrentWallet(
        token: resolution is TokenResolved ? resolution.token : null,
        amountOverride: resolution is TokenResolved ? resolution.amountOverride : null,
        fallbackCurrency: _nativeRequestCurrency(request),
      );
    }

    return AnyPayCrossChainPayment(
      targetWalletType: detectedType,
      wallets: snapshot.walletsOfType(detectedType),
      token: resolution is TokenResolved ? resolution.token : null,
      amountOverride: resolution is TokenResolved ? resolution.amountOverride : null,
    );
  }

  static AnyPayDecision _routeEvm(
    AnyPayRequest request,
    WalletSnapshot snapshot,
    AnyPayResolution resolution,
  ) {
    final requestedChainId = requestedEvmChainId(request, snapshot);

    if (requestedChainId == null) {
      if (snapshot.currentWalletIsEvm) {
        return const AnyPayApplyToCurrentWallet();
      }

      return const AnyPayEvmNetworkChoice();
    }

    if (!snapshot.supportedEvmChains.containsKey(requestedChainId)) {
      return AnyPayUnsupportedNetwork(requestedChainId);
    }

    if (resolution is TokenUnknown) {
      return AnyPayUnsupportedToken(resolution.contract);
    }

    int targetChainId = requestedChainId;
    if (resolution is TokenResolved && resolution.chainId != null) {
      targetChainId = resolution.chainId!;
    }

    final token = resolution is TokenResolved ? resolution.token : null;
    final amountOverride = resolution is TokenResolved ? resolution.amountOverride : null;

    if (snapshot.currentWalletIsEvm && snapshot.currentChainId == targetChainId) {
      return AnyPayApplyToCurrentWallet(
        token: token,
        amountOverride: amountOverride,
        fallbackCurrency: _nativeRequestCurrency(request),
      );
    }

    final targetWalletType = snapshot.supportedEvmChains[targetChainId]!;

    return AnyPayCrossChainPayment(
      targetWalletType: targetWalletType,
      targetChainId: targetChainId,
      wallets: snapshot.walletsOfType(targetWalletType),
      token: token,
      amountOverride: amountOverride,
    );
  }

  static CryptoCurrency? _nativeRequestCurrency(AnyPayRequest request) {
    if (request.paymentRequest.scheme.isEmpty || request.hasContract || request.amount.isEmpty) {
      return null;
    }
    return request.detection.detectedCurrency;
  }

  static int? requestedEvmChainId(AnyPayRequest request, WalletSnapshot snapshot) {
    final binding = request.chainBinding;

    if (binding is ExplicitEvmChain) {
      return binding.chainId;
    }

    if (binding is ChainlessEvm) {
      // the eip 681 spec says we should use the current chain id if there is no chainId in the incoming request
      return snapshot.currentWalletIsEvm ? snapshot.currentChainId ?? 1 : 1;
    }

    return null;
  }
}
