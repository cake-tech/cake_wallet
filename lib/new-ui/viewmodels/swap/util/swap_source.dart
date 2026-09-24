import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/wallet_info.dart";

sealed class SwapSource {
  const SwapSource();

  String get displayName;
}

final class ExternalSwapSource extends SwapSource {
  const ExternalSwapSource(this.refundAddress);

  final String refundAddress;

  @override
  String get displayName => S.current.external;
}

final class InternalSwapSource extends SwapSource {
  const InternalSwapSource(this.sourceWallet);

  final WalletInfo sourceWallet;

  @override
  String get displayName => sourceWallet.name;
}
