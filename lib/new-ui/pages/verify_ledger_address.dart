import "package:cw_core/wallet_base.dart";

Future<void> verifyLedgerAddress({
  required WalletBase wallet,
  required Future<bool> Function() ensureConnected,
  required bool Function() isCurrentWallet,
  required Future<void> Function(WalletBase wallet) verifyAddress,
}) async {
  if (!await ensureConnected() || !isCurrentWallet()) return;
  await verifyAddress(wallet);
}
