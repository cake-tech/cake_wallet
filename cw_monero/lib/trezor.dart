import "dart:convert";

import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:trezor_flutter/trezor_flutter.dart";

class MoneroTrezorService extends HardwareWalletService {
  MoneroTrezorService(this.client);

  final TrezorClient client;
}

class MoneroTrezorWatchCredentials {
  const MoneroTrezorWatchCredentials(this.watchKey, this.address);

  final String watchKey;
  final String address;
}

class Trezor {
  Trezor(this.service);

  final MoneroTrezorService service;

  String? _sessionPassphrase;

  Future<void> newPassphraseSession(String? passphrase) async {
    if (passphrase == null) return;

    if (_sessionPassphrase == passphrase) return;
    _sessionPassphrase = passphrase;
    return service.client.createChannel(passphrase: _sessionPassphrase);
  }

  Future<MoneroTrezorWatchCredentials> getWatchCredentials() async {
    final credentials = await TrezorMonero(service.client).getWatchCredentials();

    return MoneroTrezorWatchCredentials(credentials.$1, credentials.$2);
  }

  Future<String> keyImageSync(String tdis) async {
    final tdisMap = jsonDecode(tdis) as Map<String, dynamic>;
    final tdisList = tdisMap["tdis"] as List<dynamic>;

    final txIds = <MoneroKeyImageTxData>[];
    for (final tdi in tdisList) {
      txIds.add(
        MoneroKeyImageTxData(
          outKey: tdi["out_key"] as String,
          txPubKey: tdi["tx_pub_key"] as String,
          internalOutputIndex: tdi["internal_output_index"] as int,
          subAddrMajor: tdi["sub_addr_major"] as int,
          subAddrMinor: tdi["sub_addr_minor"] as int,
          additionalTxPubKeys:
              (tdi["additional_tx_pub_keys"] as List?)?.map((e) => e as String).toList() ?? [],
        ),
      );
    }
    final keyImages = await TrezorMonero(service.client).syncKeyImages(txIds);

    return jsonEncode(keyImages.toMap());
  }

  Future<String> signTransaction(String json) =>
      TrezorMonero(service.client).signTransaction(jsonDecode(json) as Map<String, dynamic>);
}
