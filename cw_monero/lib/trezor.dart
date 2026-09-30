import "dart:convert";

import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:mutex/mutex.dart";
import "package:trezor_flutter/trezor_flutter.dart";

class MoneroTrezorService extends HardwareWalletService {
  MoneroTrezorService(this.client);

  final TrezorClient client;

  static final Mutex _mutex = Mutex();

  static Future<T> runBlocking<T>(Future<T> Function() operation) => _mutex.protect(operation);
}

class MoneroTrezorWatchCredentials {
  const MoneroTrezorWatchCredentials(this.watchKey, this.address);

  final String watchKey;
  final String address;
}

class Trezor {
  Trezor(this.service);

  final MoneroTrezorService service;

  Future<MoneroTrezorWatchCredentials> getWatchCredentials() async {
    final credentials = await MoneroTrezorService.runBlocking(TrezorMonero(service.client).getWatchCredentials);

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
    final keyImages = await MoneroTrezorService.runBlocking(
      () => TrezorMonero(service.client).syncKeyImages(txIds),
    );

    return jsonEncode(keyImages.toMap());
  }

  Future<String> signTransaction(String json) => MoneroTrezorService.runBlocking(
        () =>
            TrezorMonero(service.client).signTransaction(jsonDecode(json) as Map<String, dynamic>),
      );
}
