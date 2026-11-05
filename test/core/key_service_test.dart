import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements SecureStorage {}

String _key(String name) =>
    generateStoreKeyFor(key: SecretStoreKey.moneroWalletPassword, walletName: name);

WalletInfo _wallet({required String id, required String name}) => WalletInfo.external(
    id: id, name: name, type: WalletType.bitcoin, isRecovery: false, restoreHeight: 0,
    date: DateTime.now(), dirPath: '', path: '', address: '', showIntroCakePayCard: false);

void main() {
  late _MockStorage storage;
  late KeyService keys;
  final store = <String, String>{};

  setUp(() {
    store.clear();
    storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((i) async => store[i.namedArguments[#key] as String]);
    keys = KeyService(storage);
  });

  test('legacy wallet reads its name key, never another wallet\'s id-shaped key (S11)', () async {
    store[_key('main')] = encodeWalletPassword(password: 'main-pass');
    store[_key('Bitcoin_Main')] = encodeWalletPassword(password: 'other-pass');

    final main = _wallet(id: 'bitcoin_main', name: 'main');
    expect(await keys.getWalletPasswordForWallet(main), 'main-pass');
  });

  test('UUID wallet reads only its id key', () async {
    const id = '3f2a9c1e-1111-4222-8333-944455556666';
    store[_key(id)] = encodeWalletPassword(password: 'uuid-pass');
    store[_key('Bitcoin')] = encodeWalletPassword(password: 'name-pass');

    expect(await keys.getWalletPasswordForWallet(_wallet(id: id, name: 'Bitcoin')), 'uuid-pass');
  });

  test('UUID wallet without an id key fails instead of falling back to the name', () async {
    const id = '3f2a9c1e-1111-4222-8333-944455556666';
    store[_key('Bitcoin')] = encodeWalletPassword(password: 'name-pass');

    expect(keys.getWalletPasswordForWallet(_wallet(id: id, name: 'Bitcoin')), throwsA(anything));
  });
}