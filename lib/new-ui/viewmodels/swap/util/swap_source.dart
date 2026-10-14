import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/wallet_info.dart";

sealed class SwapSource {
  const SwapSource();

  String get displayName;

  SwapSource withAddress(String refundAddress);
}

final class ExternalSwapSource extends SwapSource {
  const ExternalSwapSource(this.refundAddress);

  final String refundAddress;

  @override
  String get displayName => S.current.external;

  @override
  ExternalSwapSource withAddress(String refundAddress) => ExternalSwapSource(refundAddress);
}

final class InternalSwapSource extends SwapSource {
  const InternalSwapSource(this.sourceWallet, {this.refundAddress});

  final WalletInfo sourceWallet;
  final String? refundAddress;

  @override
  String get displayName => sourceWallet.name;

  @override
  InternalSwapSource withAddress(String? refundAddress) =>
      InternalSwapSource(sourceWallet, refundAddress: refundAddress);
}
