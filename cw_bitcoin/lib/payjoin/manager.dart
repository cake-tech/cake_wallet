import 'dart:math';

import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/receive.dart';
import 'package:payjoin_flutter/uri.dart';

class PayjoinManager {
  static const List<String> _ohttpRelayUrls = [
    'https://pj.bobspacebkk.com',
    'https://ohttp.achow101.com',
  ];

  static const payjoinDirectoryUrl = 'https://payjo.in';

  Future<Receiver> initReceiver(bool isTestnet, String address) async {
    try {
      final payjoinDirectory = await Url.fromStr(payjoinDirectoryUrl);
      final ohttpKeys = await fetchOhttpKeys(
        ohttpRelay: await _randomOhttpRelayUrl(),
        payjoinDirectory: payjoinDirectory,
      );
      return await Receiver.create(
        address: address,
        network: isTestnet ? Network.testnet : Network.bitcoin,
        directory: payjoinDirectory,
        ohttpKeys: ohttpKeys,
        ohttpRelay: await _randomOhttpRelayUrl(),
      );
    } catch (e) {
      throw Exception('Error initializing payjoin Receiver: $e');
    }
  }

  // Top-level function to generate random OHTTP relay URL
  Future<Url> _randomOhttpRelayUrl() => Url.fromStr(
        _ohttpRelayUrls[Random.secure().nextInt(_ohttpRelayUrls.length)],
      );
}
