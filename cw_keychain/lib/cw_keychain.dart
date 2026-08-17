import "package:cw_keychain/src/keychain_api.g.dart";

export "src/keychain_api.g.dart" show KeychainDataV1, UnsupportedKeychainData;

class CwKeychain {

  CwKeychain({KeychainPlatformApi? api}) : _api = api ?? KeychainPlatformApi();


  final KeychainPlatformApi _api;

  // checks if api is available
  // on apple, true if we have icloud.
  // PLEASE check this before you call ANY other function, they WILL throw if this is false
  Future<bool> available() async {
    try {
      return await _api.available();
    } catch(e) {
      return false;
    }
  }

  Future<List<KeychainDataV1>> getAll() => _api.getAll();

  // returns id, id is in form "$name_$walletTypeRaw"
  // if you submit another item with the same id, it will overwrite!!!
  Future<String> put(KeychainDataV1 item) => _api.put(item);

  // stays silent if id doesn't exist
  Future<void> delete(String id) => _api.delete(id);

  Future<KeychainDataV1?> get(String id) => _api.get(id);

  Future<List<UnsupportedKeychainData>> getUnsupported() => _api.getUnsupported();


  Future<void> putFakeUnsupported() => _api.putFakeUnsupported();
}
