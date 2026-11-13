import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

/// These types are always BIP39 in Cake, and often don't store their derivation type.
const alwaysBip39Types = {
  WalletType.ethereum,
  WalletType.polygon,
  WalletType.base,
  WalletType.arbitrum,
  WalletType.bsc,
  WalletType.robinhood,
  WalletType.solana,
  WalletType.tron,
  WalletType.zcash,
  WalletType.bitcoinCash,
  WalletType.dogecoin,
};

/// Thrown when a network would be derived for a group whose seed can't derive it
/// (Polyseed, legacy Monero, Electrum, hardware, restored from keys, ...).
class GroupNotOmnichainCompatibleException extends CakeException {
  GroupNotOmnichainCompatibleException(this.groupId)
      : super("This wallet group's seed type doesn't support adding networks");
  final String groupId;
}

/// The single rule for "may other networks be derived from this wallet's seed".
Future<bool> isOmnichainCompatible(WalletInfo wallet) async {
  if (!isBIP39Wallet(wallet.type)) return false;
  // Any hardware type (incl. air-gapped signers), not only the ones in `isHardwareWallet`:
  // the seed is never in the app either way. Matches the migration's previous check.
  if (wallet.hardwareWalletType != null) return false;
  if (wallet.isNonSeedWallet) return false;

  if (alwaysBip39Types.contains(wallet.type)) return true;

  final derivation = await wallet.getDerivationInfo();
  return derivation.derivationType == DerivationType.bip39;
}

/// Compatible when the group has at least one ready wallet and every ready wallet is.
/// Placeholders (`isReady == false`) have no seed of their own; they get derived from the
/// group's seed on activation, so they don't decide compatibility.
Future<bool> isOmnichainCompatibleGroup(List<WalletInfo> wallets) async {
  final ready = wallets.where((w) => w.isReady).toList();
  if (ready.isEmpty) return false;
  for (final wallet in ready) {
    if (!await isOmnichainCompatible(wallet)) return false;
  }
  return true;
}
