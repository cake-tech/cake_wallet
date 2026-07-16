import 'dart:convert';

import 'package:cake_wallet/entities/payjoin/payjoin_server.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PayjoinServerListViewModel extends ChangeNotifier {
  PayjoinServerListViewModel() {
    relays.addAll(PayjoinServer.builtinRelays());
    directories.addAll(PayjoinServer.builtinDirectories());
    _loadCustom().then((_) {
      notifyListeners();
      checkHealth();
    });
  }

  final List<PayjoinServer> relays = [];
  final List<PayjoinServer> directories = [];
  final http.Client _client = http.Client();

  bool _isTesting = false;
  bool get isTesting => _isTesting;

  Future<void> _loadCustom() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final removedRelays = Set<String>.from(
          prefs.getStringList(PreferencesKey.payjoinRemovedDefaultRelays) ?? []);
      final removedDirs = Set<String>.from(
          prefs.getStringList(PreferencesKey.payjoinRemovedDefaultDirectories) ?? []);
      relays.removeWhere((r) => removedRelays.contains(r.url));
      directories.removeWhere((d) => removedDirs.contains(d.url));

      final relaysJson = prefs.getString(PreferencesKey.payjoinRelays);
      if (relaysJson != null) {
        final list = jsonDecode(relaysJson) as List;
        for (final item in list) {
          final server = PayjoinServer.fromJson(item as Map<String, dynamic>);
          if (!relays.any((r) => r.url == server.url)) {
            relays.add(server);
          }
        }
      }
      final dirsJson = prefs.getString(PreferencesKey.payjoinDirectories);
      if (dirsJson != null) {
        final list = jsonDecode(dirsJson) as List;
        for (final item in list) {
          final server = PayjoinServer.fromJson(item as Map<String, dynamic>);
          if (!directories.any((d) => d.url == server.url)) {
            directories.add(server);
          }
        }
      }
    } catch (e) {
      printV('Failed to load payjoin servers: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customRelays = relays.where((r) => !r.isDefault).toList();
      final customDirs = directories.where((d) => !d.isDefault).toList();
      await prefs.setString(
          PreferencesKey.payjoinRelays, jsonEncode(customRelays.map((r) => r.toJson()).toList()));
      await prefs.setString(
          PreferencesKey.payjoinDirectories, jsonEncode(customDirs.map((d) => d.toJson()).toList()));
    } catch (e) {
      printV('Failed to save payjoin servers: $e');
    }
  }

  void addServer(String url, PayjoinServerType type) {
    final list = type == PayjoinServerType.relay ? relays : directories;
    if (list.any((s) => s.url == url)) return;
    list.add(PayjoinServer(url: url, type: type));
    _save();
    notifyListeners();
  }

  void removeServer(PayjoinServer server) {
    final list = server.type == PayjoinServerType.relay ? relays : directories;
    list.remove(server);
    if (server.isDefault) {
      _saveDefaultRemoved(server);
    } else {
      _save();
    }
    notifyListeners();
  }

  Future<void> _saveDefaultRemoved(PayjoinServer server) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = server.type == PayjoinServerType.relay
          ? PreferencesKey.payjoinRemovedDefaultRelays
          : PreferencesKey.payjoinRemovedDefaultDirectories;
      final existing = prefs.getStringList(key) ?? [];
      existing.add(server.url);
      await prefs.setStringList(key, existing);
    } catch (e) {
      printV('Failed to save removed default: $e');
    }
  }

  Future<void> checkHealth() async {
    _isTesting = true;
    notifyListeners();

    final allServers = [...relays, ...directories];
    await Future.wait(allServers.map((server) async {
      server.isTesting = true;
      notifyListeners();
      try {
        final uri = Uri.parse(server.url).resolve('/health');
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 10));
        server.isLive = response.statusCode >= 200 && response.statusCode < 400;
      } catch (e) {
        server.isLive = false;
      } finally {
        server.isTesting = false;
        notifyListeners();
      }
    }));

    _isTesting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
