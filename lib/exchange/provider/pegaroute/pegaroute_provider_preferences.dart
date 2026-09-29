import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for the currently recognized Pegasus route providers.
/// Pegasus remains responsible for returning available routes for each request.
class PegarouteProviderPreferences {
  PegarouteProviderPreferences(this._preferences) : states = ObservableMap.of(_read(_preferences));

  static const providers = {
    'instaswap': 'Instaswap',
    'thorchain': 'THORChain',
    'maya': 'Maya',
    'openocean': 'OpenOcean',
  };

  final SharedPreferences _preferences;
  final ObservableMap<String, bool> states;

  bool isEnabled(String provider) => states[provider] == true;

  Future<void> setEnabled(String provider, bool enabled) async {
    if (!providers.containsKey(provider)) throw ArgumentError.value(provider, 'provider');
    runInAction(() => states[provider] = enabled);
    await _preferences.setString(PreferencesKey.pegarouteProviderStatesKey, jsonEncode(states));
  }

  static Map<String, bool> _read(SharedPreferences preferences) {
    final raw = preferences.get(PreferencesKey.pegarouteProviderStatesKey);
    if (raw == null) return {for (final provider in providers.keys) provider: true};
    try {
      final value = raw is String ? jsonDecode(raw) : null;
      if (value is Map<String, dynamic>) {
        return {
          for (final provider in providers.keys)
            provider: !value.containsKey(provider) || value[provider] == true,
        };
      }
    } on FormatException {
      // Corrupt preferences must not silently re-enable an excluded provider.
    }
    return {for (final provider in providers.keys) provider: false};
  }
}
