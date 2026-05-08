import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:trezor_flutter/trezor_flutter.dart';

class MoneroTrezorService extends HardwareWalletService {
  final TrezorClient client;

  MoneroTrezorService(this.client);
}

class MoneroTrezorWatchCredentials {
  final String watchKey;
  final String address;

  const MoneroTrezorWatchCredentials(this.watchKey, this.address);
}

class Trezor {
  final MoneroTrezorService service;

  Trezor(this.service);

  Future<MoneroTrezorWatchCredentials> getWatchCredentials() async {
    final credentials = await TrezorMonero(service.client).getWatchCredentials();

    return MoneroTrezorWatchCredentials(credentials.$1, credentials.$2);
  }

  Future<void> keyImageSync() async {
    // final txIds = <MoneroKeyImageTxId>[];
    //
    //
    // TrezorMonero(service.client).syncKeyImages(txIds);
  }
}
