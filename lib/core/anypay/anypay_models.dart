import "package:cake_wallet/core/universal_address_detector.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

sealed class ChainBinding {
  const ChainBinding();
}

class ExplicitEvmChain extends ChainBinding {
  const ExplicitEvmChain(this.chainId);

  final int chainId;
}

class ChainlessEvm extends ChainBinding {
  const ChainlessEvm();
}

class NoEvmBinding extends ChainBinding {
  const NoEvmBinding();
}

class AnyPayRequest {
  AnyPayRequest({
    required this.rawInput,
    required this.paymentRequest,
    required this.detection,
    required this.chainBinding,
  });

  final String rawInput;
  final PaymentRequest paymentRequest;
  final AddressDetectionResult detection;
  final ChainBinding chainBinding;

  String get address => paymentRequest.address;

  String get amount => paymentRequest.amount;

  String? get contractAddress => paymentRequest.contractAddress;

  bool get hasContract => contractAddress != null && contractAddress!.isNotEmpty;

  bool get isLightning => detection.detectedCurrency == CryptoCurrency.btcln;
}

class WalletSnapshot {
  WalletSnapshot({
    required this.type,
    required this.currentWalletIsEvm,
    required this.currentChainId,
    required this.wallets,
    required this.supportedEvmChains,
    required this.hasEvmProxy,
    required this.hasSolanaProxy,
    required this.hasTronProxy,
  });

  final WalletType type;
  final bool currentWalletIsEvm;
  final int? currentChainId;
  final List<WalletInfo> wallets;
  final Map<int, WalletType> supportedEvmChains;
  final bool hasEvmProxy;
  final bool hasSolanaProxy;
  final bool hasTronProxy;

  List<WalletInfo> walletsOfType(WalletType walletType) =>
      wallets.where((wallet) => wallet.type == walletType).toList();
}

sealed class AnyPayResolution {
  const AnyPayResolution();
}

class NoTokenRequested extends AnyPayResolution {
  const NoTokenRequested();
}

class TokenResolved extends AnyPayResolution {
  const TokenResolved({required this.token, this.chainId, this.amountOverride});

  final CryptoCurrency token;
  final int? chainId;
  final String? amountOverride;
}

class TokenUnknown extends AnyPayResolution {
  const TokenUnknown(this.contract);

  final String contract;
}

sealed class AnyPayDecision {
  const AnyPayDecision();
}

class AnyPayApplyToCurrentWallet extends AnyPayDecision {
  const AnyPayApplyToCurrentWallet({
    this.token,
    this.amountOverride,
    this.fallbackCurrency,
  });

  final CryptoCurrency? token;
  final String? amountOverride;
  final CryptoCurrency? fallbackCurrency;
}

class AnyPayEvmNetworkChoice extends AnyPayDecision {
  const AnyPayEvmNetworkChoice();
}

class AnyPayCrossChainPayment extends AnyPayDecision {
  const AnyPayCrossChainPayment({
    required this.targetWalletType,
    required this.wallets,
    this.targetChainId,
    this.token,
    this.amountOverride,
  });

  final WalletType targetWalletType;
  final int? targetChainId;
  final List<WalletInfo> wallets;
  final CryptoCurrency? token;
  final String? amountOverride;

  bool get hasCompatibleWallet => wallets.isNotEmpty;
}

class AnyPayUnsupportedNetwork extends AnyPayDecision {
  const AnyPayUnsupportedNetwork(this.chainId);

  final int chainId;
}

class AnyPayUnsupportedToken extends AnyPayDecision {
  const AnyPayUnsupportedToken(this.contract);

  final String contract;
}

class AnyPayEmptyInput extends AnyPayDecision {
  const AnyPayEmptyInput();
}

class AnyPayEvaluation {
  AnyPayEvaluation({required this.request, required this.decision});

  final AnyPayRequest request;
  final AnyPayDecision decision;
}

class AnyPaySendIntent {
  AnyPaySendIntent({required this.request, this.currency});

  final AnyPayRequest request;
  final CryptoCurrency? currency;
}

class AnyPaySwapIntent {
  AnyPaySwapIntent({
    required this.request,
    required this.receiveCurrency,
    required this.targetWalletType,
    this.receiveAmount,
  });

  final AnyPayRequest request;
  final CryptoCurrency receiveCurrency;
  final WalletType targetWalletType;
  final Money? receiveAmount;

  String get recipientAddress => request.address;
}
