import "package:cw_keychain/src/keychain_api.g.dart";

export "src/keychain_api.g.dart" show KeychainData;

class CwKeychain {

  CwKeychain({KeychainPlatformApi? api}) : _api = api ?? KeychainPlatformApi();


  final KeychainPlatformApi _api;

  // checks if api is available
  // on apple, always true. on android, true if we have gms and google cloud backup
  // PLEASE check this before you call ANY other function, they WILL throw if this is false
  Future<bool> available() async {
    try {
      return _api.available();
    } catch(e) {
      return false;
    }
  }

  Future<List<KeychainData>> getAll() => _api.getAll();

  // returns id, id is in form "$name_$walletTypeRaw"
  // if you submit another item with the same id, it will overwrite!!!
  Future<String> put(KeychainData item) => _api.put(item);

  // stays silent if id doesn't exist
  Future<void> delete(String id) => _api.delete(id);

  Future<KeychainData?> get(String id) => _api.get(id);
}
