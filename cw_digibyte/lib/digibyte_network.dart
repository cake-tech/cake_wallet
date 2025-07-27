/// Defines the available DigiByte networks.
///
/// We don't rely on code generation for this enum; instead we manually
/// provide helper getters and a deserializer.  The `value` and
/// `wifNetVer` properties correspond to the human‑readable name and the
/// network byte used for WIF keys, respectively.
enum DigibyteNetwork {
  mainnet('mainnet', wifNetVer: 0x80),
  testnet('testnet', wifNetVer: 0xf1);

  const DigibyteNetwork(this.value, {required this.wifNetVer});

  final String value;
  final int wifNetVer;

  /// Convert a string (e.g. from JSON) into a [DigibyteNetwork].
  static DigibyteNetwork deserialize(String name) {
    switch (name) {
      case 'mainnet':
        return DigibyteNetwork.mainnet;
      case 'testnet':
        return DigibyteNetwork.testnet;
      default:
        throw ArgumentError('Unknown DigiByte network name: $name');
    }
  }
}

