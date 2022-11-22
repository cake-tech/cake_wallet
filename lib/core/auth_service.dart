import 'package:mobx/mobx.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';

class AuthService with Store {
  AuthService({required this.secureStorage, required this.sharedPreferences});

  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  Future<void> setPassword(String password) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPassword = encodedPinCode(pin: password);
    await secureStorage.write(key: key, value: encodedPassword);
  }

  Future<bool> canAuthenticate() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final walletName =
        sharedPreferences.getString(PreferencesKey.currentWalletName) ?? '';
    var password = '';

    try {
      password = await secureStorage.read(key: key) ?? '';
    } catch (e) {
      print(e);
    }

    return walletName.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> authenticate(String pin) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPin = await secureStorage.read(key: key);
    final decodedPin = decodedPinCode(pin: encodedPin!);

    return decodedPin == pin;
  }

  void saveLastAuthTime(){
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    sharedPreferences.setInt(PreferencesKey.lastAuthTimeMilliseconds, timestamp);
  }

  bool requireAuth(){  
      final timestamp = sharedPreferences.getInt(PreferencesKey.lastAuthTimeMilliseconds);
      final duration =  _durationToRequireAuth(timestamp ?? 0);
      final requiredPinInterval = getIt.get<SettingsStore>().pinTimeOutDuration;
     
      return duration >= requiredPinInterval.value;
    }

  int _durationToRequireAuth(int timestamp){

      DateTime before = DateTime.fromMillisecondsSinceEpoch(timestamp);
      DateTime now = DateTime.now();
      Duration timeDifference = now.difference(before);

      return timeDifference.inMinutes; 
  }
}
