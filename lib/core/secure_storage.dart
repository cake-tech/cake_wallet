final SecureStorage secureStorageShared = FakeSecureStorage();

abstract class SecureStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String? value});
  Future<void> delete({required String key});
  // Legacy
  Future<String?> readNoIOptions({required String key});
}

class FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String? value}) async {}

  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> readNoIOptions({required String key}) async => null;
}
