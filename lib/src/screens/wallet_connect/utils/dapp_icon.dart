import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

/// Icon URL of a dApp, or null when Tor is running.
///
/// The URL is chosen by the dApp and loading it bypasses Tor, which would let
/// the dApp log the user's real IP address.
String? wcDappIconUrl(PairingMetadata? metadata) {
  if (CakeTor.instance!.started) {
    return null;
  }
  final icons = metadata?.icons ?? const <String>[];
  return icons.isNotEmpty ? icons.first : null;
}
