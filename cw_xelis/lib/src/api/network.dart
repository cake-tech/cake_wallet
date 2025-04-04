export 'package:xelis_flutter/src/api/network.dart';
import 'package:xelis_flutter/src/api/network.dart';

extension NetworkName on Network {
  String get name {
    switch (this) {
      case Network.mainnet:
        return 'mainnet';
      case Network.testnet:
        return 'testnet';
      case Network.dev:
        return 'dev';
    }
  }

  static Network fromName(String name) {
    switch (name) {
      case 'mainnet':
        return Network.mainnet;
      case 'testnet':
        return Network.testnet;
      case 'dev':
        return Network.dev;
      default:
        throw ArgumentError('Unknown network name: $name');
    }
  }
}