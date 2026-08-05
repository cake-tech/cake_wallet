import "package:cw_keychain/cw_keychain.dart";
import "package:cw_keychain/src/keychain_api.g.dart";
import "package:flutter_test/flutter_test.dart";

class _FakeKeychainPlatformApi extends KeychainPlatformApi {
  final List<String> deleted = <String>[];

  @override
  Future<List<KeychainData>> getAll() => Future.value(<KeychainData>[
    KeychainData(name: "stored", walletTypeRaw: 0, seed: "seed"),
  ]);

  @override
  Future<String> put(KeychainData item) => Future.value(item.name);

  @override
  Future<void> delete(String id) {
    deleted.add(id);
    return Future<void>.value();
  }

  @override
  Future<KeychainData> get(String id) => Future.value(
    KeychainData(name: id, walletTypeRaw: 0, seed: "seed"),
  );
}

void main() {
  test("getAll delegates to the platform api", () async {
    final CwKeychain keychain = CwKeychain(api: _FakeKeychainPlatformApi());

    expect((await keychain.getAll()).single.name, "stored");
  });

  test("put delegates to the platform api", () async {
    final CwKeychain keychain = CwKeychain(api: _FakeKeychainPlatformApi());
    final KeychainData item = KeychainData(
      name: "added",
      walletTypeRaw: 0,
      seed: "seed",
    );

    expect(await keychain.put(item), "added");
  });

  test("delete delegates to the platform api", () async {
    final _FakeKeychainPlatformApi api = _FakeKeychainPlatformApi();
    final CwKeychain keychain = CwKeychain(api: api);

    await keychain.delete("abc");

    expect(api.deleted, <String>["abc"]);
  });

  test("get delegates to the platform api", () async {
    final CwKeychain keychain = CwKeychain(api: _FakeKeychainPlatformApi());

    expect((await keychain.get("abc")).name, "abc");
  });
}
