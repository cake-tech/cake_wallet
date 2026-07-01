import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:mobx/mobx.dart';

part 'secure_preferences.g.dart';

class DevSecurePreferences = DevSecurePreferencesBase with _$DevSecurePreferences;

enum PreferenceType {
  unknown,
  string,
  int,
  double,
  bool,
  listString
}

abstract class DevSecurePreferencesBase with Store {
  DevSecurePreferencesBase() {
    secureStorageShared.readAll().then((value) {
      values = value;
    });
  }

  @observable
  Map<String, String> values = {};

  @computed
  List<String> get keys => values.keys.toList()..sort();

  @action
  Future<void> delete(String key) async {
    
  }

  dynamic get(String key) {
    if (!values.containsKey(key)) {
      return null;
    }
    if (!key.startsWith("MONERO_WALLET_")) return values[key]!;
    try {
      final decodedPassword = decodeWalletPassword(password: values[key]!);
      return values[key]! + "\n\nDecoded: $decodedPassword";
    } catch (e) {
      return values[key]! +"\n$e";
    }
  }

  Future<void> set(String key, PreferenceType type, dynamic value) async {
    
  }

  PreferenceType getPreferenceType(String key) {
    if (!values.containsKey(key)) {
      return PreferenceType.unknown;
    }
    final value = values[key];
    if (value is String) {
      return PreferenceType.string;
    }
    if (value is bool) {
      return PreferenceType.bool;
    }
    if (value is int) {
      return PreferenceType.int;
    }
    if (value is double) {
      return PreferenceType.double;
    }
    if (value is List<String>) {
      return PreferenceType.listString;
    }
    return PreferenceType.unknown;
  }
}
