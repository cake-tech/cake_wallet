import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PayjoinServerType { relay, directory }

class PayjoinServer {
  PayjoinServer({
    required this.url,
    required this.type,
    this.isDefault = false,
    this.isLive = false,
    this.isTesting = false,
  });

  final String url;
  final PayjoinServerType type;
  final bool isDefault;
  bool isLive;
  bool isTesting;

  String get label {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type == PayjoinServerType.relay ? 'relay' : 'directory',
        'isDefault': isDefault,
      };

  factory PayjoinServer.fromJson(Map<String, dynamic> json) => PayjoinServer(
        url: json['url'] as String,
        type: json['type'] == 'relay'
            ? PayjoinServerType.relay
            : PayjoinServerType.directory,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  static const defaultRelays = [
    'https://pj.bobspacebkk.com',
    'https://pj.benalleng.com',
    'https://ohttp.achow101.com',
  ];

  static const defaultDirectories = [
    'https://pj.benalleng.com',
    'https://payjo.in',
    'https://lets.payjo.in',
  ];

  static List<PayjoinServer> builtinRelays() => defaultRelays
      .map((u) => PayjoinServer(url: u, type: PayjoinServerType.relay, isDefault: true))
      .toList();

  static List<PayjoinServer> builtinDirectories() => defaultDirectories
      .map((u) =>
          PayjoinServer(url: u, type: PayjoinServerType.directory, isDefault: true))
      .toList();

  static ({List<String> relays, List<String> directories}) loadUrlsFromPrefs(
    SharedPreferences prefs,
  ) {
    final removedRelays = Set<String>.from(
        prefs.getStringList(PreferencesKey.payjoinRemovedDefaultRelays) ?? []);
    final removedDirectories = Set<String>.from(
        prefs.getStringList(PreferencesKey.payjoinRemovedDefaultDirectories) ?? []);

    final relays = <String>[
      ...defaultRelays.where((u) => !removedRelays.contains(u)),
    ];
    final directories = <String>[
      ...defaultDirectories.where((u) => !removedDirectories.contains(u)),
    ];

    final relaysJson = prefs.getString(PreferencesKey.payjoinRelays);
    if (relaysJson != null) {
      for (final item in jsonDecode(relaysJson) as List) {
        final server = PayjoinServer.fromJson(item as Map<String, dynamic>);
        if (!relays.contains(server.url)) {
          relays.add(server.url);
        }
      }
    }

    final dirsJson = prefs.getString(PreferencesKey.payjoinDirectories);
    if (dirsJson != null) {
      for (final item in jsonDecode(dirsJson) as List) {
        final server = PayjoinServer.fromJson(item as Map<String, dynamic>);
        if (!directories.contains(server.url)) {
          directories.add(server.url);
        }
      }
    }

    return (relays: relays, directories: directories);
  }
}
