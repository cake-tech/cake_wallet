import "package:pigeon/pigeon.dart";

@ConfigurePigeon(
  PigeonOptions(
    dartOut: "lib/src/keychain_api.g.dart",
    dartOptions: DartOptions(),
    kotlinOut: "android/src/main/kotlin/com/cakewallet/cw_keychain/KeychainApi.g.kt",
    kotlinOptions: KotlinOptions(package: "com.cakewallet.cw_keychain"),
    swiftOut: "darwin/Classes/KeychainApi.g.swift",
    swiftOptions: SwiftOptions(),
  ),
)
class KeychainData {
  KeychainData({
    required this.name,
    required this.walletTypeRaw,
    required this.seed,
    required this.seedTypeRaw,
    required this.blockHeight,
    required this.passphrase,
  });

  final String name;
  final int walletTypeRaw;
  final String seed;
  final int? seedTypeRaw;
  final int? blockHeight;
  final String? passphrase;
}

@HostApi()
abstract class KeychainPlatformApi {
  bool available();

  @async
  List<KeychainData> getAll();

  @async
  String put(KeychainData item);

  @async
  void delete(String id);

  @async
  KeychainData? get(String id);
}
