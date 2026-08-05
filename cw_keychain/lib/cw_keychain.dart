import "package:cw_keychain/src/keychain_api.g.dart";
import "package:flutter/foundation.dart";

export "src/keychain_api.g.dart" show KeychainData;

class CwKeychain {

  CwKeychain({KeychainPlatformApi? api}) : _api = api ?? KeychainPlatformApi();

  static bool get isSupported =>
      <TargetPlatform>[.android, .iOS, .macOS].contains(defaultTargetPlatform);

  final KeychainPlatformApi _api;

  Future<bool> available() async {
    try {
      return _api.available();
    } catch(e) {
      return false;
    }
  }

  Future<List<KeychainData>> getAll() => _api.getAll();

  Future<String> put(KeychainData item) => _api.put(item);

  Future<void> delete(String id) => _api.delete(id);

  Future<KeychainData?> get(String id) => _api.get(id);
}
