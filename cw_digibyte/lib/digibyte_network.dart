import 'package:json_annotation/json_annotation.dart';

part 'digibyte_network.g.dart';

@JsonEnum()
enum DigibyteNetwork {
  @JsonValue('mainnet')
  mainnet('mainnet', wifNetVer: 0x80),
  @JsonValue('testnet')
  testnet('testnet', wifNetVer: 0xf1);

  const DigibyteNetwork(this.value, {required this.wifNetVer});

  final String value;
  final int wifNetVer;

  static DigibyteNetwork deserialize(String name) =>
      _$DigibyteNetworkEnumMap.entries
          .firstWhere((e) => e.value == name)
          .key;
}
