import 'package:mobx/mobx.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/common/secret_store_key.dart';
import 'package:cake_wallet/src/domain/common/encrypt.dart';

class AuthService with Store {
  AuthService({this.secureStorage, this.sharedPreferences});

  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  Future setPassword(String password) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPassword = encodedPinCode(pin: password);
    await secureStorage.write(key: key, value: encodedPassword);
  }

  Future<bool> canAuthenticate() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final walletName = sharedPreferences.getString('current_wallet_name') ?? '';
    var password = '';

    try {
      password = await secureStorage.read(key: key);
    } catch (e) {
      print(e);
    }

    return walletName.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> authenticate(String pin) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPin = await secureStorage.read(key: key);
    final decodedPin = decodedPinCode(pin: encodedPin);

    return decodedPin == pin;
  }
}
