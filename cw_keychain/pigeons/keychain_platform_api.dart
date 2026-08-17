import "package:pigeon/pigeon.dart";

@ConfigurePigeon(
  PigeonOptions(
    dartOut: "lib/src/keychain_api.g.dart",
    dartOptions: DartOptions(),
    // kotlinOut: "android/src/main/kotlin/com/cakewallet/cw_keychain/KeychainApi.g.kt",
    // kotlinOptions: KotlinOptions(package: "com.cakewallet.cw_keychain"),
    swiftOut: "darwin/Classes/KeychainApi.g.swift",
    swiftOptions: SwiftOptions(),
  ),
)


// if we get an unknown version of keychain data, this is returned.
// this ensures wallets created in newer versions are still visible on the list in older ones
// they won't be readable, but at least we can show a "please update" message
class UnsupportedKeychainData {
  UnsupportedKeychainData({required this.name, required this.walletTypeRaw});

  final String name;
  final int walletTypeRaw;
}

class KeychainDataV1 {
  KeychainDataV1({
    required this.name,
    required this.walletTypeRaw,
    required this.seed,
    required this.derivationTypeRaw,
    required this.networkRaw,
    this.seedTypeRaw,
    this.blockHeight,
    this.passphrase,
    this.derivationPath,
    this.version = 1,
  });

  final int version;
  final String name;
  final int walletTypeRaw;
  final String seed;
  final int networkRaw;
  final int derivationTypeRaw;
  final String? derivationPath;
  final int? seedTypeRaw;
  final int? blockHeight;
  final String? passphrase;
}

@HostApi()
abstract class KeychainPlatformApi {
  bool available();

  @async
  List<KeychainDataV1> getAll();

  @async
  String put(KeychainDataV1 item);

  @async
  void delete(String id);

  @async
  KeychainDataV1? get(String id);

  @async
  List<UnsupportedKeychainData> getUnsupported();

  @async
  void putFakeUnsupported();
}
