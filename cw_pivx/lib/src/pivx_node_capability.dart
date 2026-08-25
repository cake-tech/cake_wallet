import 'package:cw_bitcoin/electrum.dart';

import 'sapling/pivx_sapling_electrumx.dart';

/// Probe whether the ElectrumX node at [uri] serves the PIVX v1 Sapling
/// contract. Throws on a transient connection or probe failure so callers can
/// tell "node is down, retry later" apart from a determinate "connected but
/// lacks the v1 release contract" (returns false).
Future<bool> pivxNodeSupportsSapling({
  required Uri uri,
  bool? useSSL,
  required bool isTestnet,
}) async {
  final client = ElectrumClient();
  try {
    await client.connectToUri(uri, useSSL: useSSL);
    if (!client.isConnected) {
      throw Exception('Could not connect to PIVX node $uri');
    }
    final saplingClient = PIVXSaplingElectrumX(
      electrumClient: client,
      isTestnet: isTestnet,
    );
    final capabilities = await saplingClient.probeCapabilities();
    return capabilities.supportsV1ReleaseContract;
  } finally {
    await client.close();
  }
}
