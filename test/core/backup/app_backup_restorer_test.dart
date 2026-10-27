import "package:cake_wallet/core/backup/app_backup_restorer.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/secret_store_key.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockBackupService extends Mock implements BackupServiceV3 {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  final pinKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
  late _MockSecureStorage secureStorage;
  late AppBackupRestorer restorer;

  setUp(() {
    secureStorage = _MockSecureStorage();
    restorer = AppBackupRestorer(_MockBackupService(), secureStorage);
  });

  test("hasPin is false until a PIN is stored", () async {
    when(() => secureStorage.read(key: pinKey)).thenAnswer((_) async => null);
    expect(await restorer.hasPin(), isFalse);

    when(() => secureStorage.read(key: pinKey)).thenAnswer((_) async => "");
    expect(await restorer.hasPin(), isFalse);

    when(() => secureStorage.read(key: pinKey)).thenAnswer((_) async => "encoded-pin");
    expect(await restorer.hasPin(), isTrue);
  });
}
