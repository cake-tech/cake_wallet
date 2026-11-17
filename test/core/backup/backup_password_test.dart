import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/default_settings_migration.dart";
import "package:cake_wallet/entities/secret_store_key.dart";
import "package:cw_core/generate_name.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pattern = RegExp(r"^([A-Z][a-z]+[0-9]-){7}[A-Z][a-z]+[0-9]$");

  test("generates eight capitalized word-digit segments joined by dashes", () async {
    final passwords = [for (var i = 0; i < 20; i++) await generateWordPassword()];

    for (final password in passwords) {
      expect(password, matches(pattern));
    }
    expect(passwords.toSet(), hasLength(passwords.length));
  });

  test("generateBackupPassword stores a word password only when none exists", () async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final empty = _MockSecureStorage();
    when(() => empty.read(key: key)).thenAnswer((_) async => null);
    when(() => empty.delete(key: key)).thenAnswer((_) async {});
    when(() => empty.write(key: key, value: any(named: "value"))).thenAnswer((_) async {});

    await generateBackupPassword(empty);

    final stored = verify(() => empty.write(key: key, value: captureAny(named: "value")))
        .captured
        .single as String;
    expect(stored, matches(pattern));

    final existing = _MockSecureStorage();
    when(() => existing.read(key: key)).thenAnswer((_) async => "Already1-Set2");

    await generateBackupPassword(existing);

    verifyNever(() => existing.write(key: key, value: any(named: "value")));
  });

  test("removeBackupPassword deletes the stored password without writing a new one", () async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final storage = _MockSecureStorage();
    when(() => storage.delete(key: key)).thenAnswer((_) async {});

    await removeBackupPassword(storage);

    verify(() => storage.delete(key: key)).called(1);
    verifyNever(() => storage.write(key: key, value: any(named: "value")));
  });
}
