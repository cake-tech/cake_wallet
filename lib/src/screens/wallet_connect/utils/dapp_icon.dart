import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_tor.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

/// Icon URL of a dApp, or null when Tor is enabled.
///
/// The URL is chosen by the dApp and loading it bypasses Tor, which would let
/// the dApp log the user's real IP address.
String? wcDappIconUrl(PairingMetadata? metadata) {
  if (isWalletConnectTorRequired(getIt.get<SettingsStore>())) {
    return null;
  }
  final icons = metadata?.icons ?? const <String>[];
  return icons.isNotEmpty ? icons.first : null;
}
