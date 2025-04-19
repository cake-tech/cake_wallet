import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences.g.dart';

class DevSharedPreferences = DevSharedPreferencesBase with _$DevSharedPreferences;

enum PreferenceType {
  unknown,
  string,
  int,
  double,
  bool,
  listString
}

abstract class DevSharedPreferencesBase with Store {
  DevSharedPreferencesBase() {
    SharedPreferences.getInstance().then((value) {
      sharedPreferences = value;
    });
  }

  @observable
  SharedPreferences? sharedPreferences;

  @computed
  List<String> get keys => (sharedPreferences?.getKeys().toList()?..sort()) ?? [];

  @action
  Future<void> delete(String key) async {
    if (sharedPreferences == null) {
      return;
    }
    await sharedPreferences!.remove(key);
  }

  dynamic get(String key) {
    if (sharedPreferences == null) {
      return null;
    }
    return sharedPreferences!.get(key);
  }

  Future<void> set(String key, PreferenceType type, dynamic value) async {
    if (sharedPreferences == null) {
      return;
    }
    switch (type) {
      case PreferenceType.string:
        await sharedPreferences!.setString(key, value as String);
        break;
      case PreferenceType.bool:
        await sharedPreferences!.setBool(key, value as bool);
        break;
      case PreferenceType.int:
        await sharedPreferences!.setInt(key, value as int);
        break;
      case PreferenceType.double:
        await sharedPreferences!.setDouble(key, value as double);
        break;
      case PreferenceType.listString:
        await sharedPreferences!.setStringList(key, List<String>.from(value as Iterable<dynamic>));
        break;
      default:
        throw Exception("Unknown preference type: $type");
    }
  }

  PreferenceType getPreferenceType(String key) {
    if (sharedPreferences == null) {
      return PreferenceType.unknown;
    }
    final value = sharedPreferences!.get(key);
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
