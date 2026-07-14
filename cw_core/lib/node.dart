import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:blockchain_utils/hex/hex.dart';
import 'package:cw_core/node_list.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import 'db/sqlite.dart';

Uri createUriFromElectrumAddress(String address, String path) =>
    Uri.tryParse('tcp://$address$path')!;

Future<void> validateBuiltinNodes() async {
  // ensures nodes stored as builtin in the db correspond to the nodes in the .yml files

  final builtinFromDb = await Node.getAllBuiltin();
  final builtinFromList = await loadAllDefaultNodes();

  for (final listNode in builtinFromList) {
    // preserve proxy settings from user
    try {
      final matchedDbNode = builtinFromDb.firstWhere((dbNode) => dbNode.uri == listNode.uri);
      listNode.socksProxyAddress = matchedDbNode.socksProxyAddress;
    } catch (e) {}
  }

  final dbSet = builtinFromDb.toSet();
  final listSet = builtinFromList.toSet();

  final nodesToDelete = dbSet.difference(listSet);
  final nodesToAdd = listSet.difference(dbSet);

  for (final node in nodesToDelete) await node.delete();
  for (final node in nodesToAdd) await node.save();
}

class Node {
  Node({
    this.id = 0,
    this.label,
    this.login,
    this.password,
    this.useSSL,
    this.isPow = false,
    this.trusted = false,
    this.socksProxyAddress,
    this.path = '',
    this.isEnabledForAutoSwitching = false,
    this.isOfficial = false,
    this.isBuiltin = false,
    this.isDefault = false,
    String? uri,
    WalletType? type,
  }) {
    if (uri != null) {
      uriRaw = uri;
    }
    if (type != null) {
      this.type = type;
    }
  }

  @override
  String toString() {
    return """Node(
  uriRaw: $uriRaw,
  path: $path,
  login: $login,
  password: $password,
  useSSL: $useSSL,
  trusted: $trusted,
  socksProxyAddress: $socksProxyAddress,
  isEnabledForAutoSwitching: $isEnabledForAutoSwitching,
  isOfficial: $isOfficial,
  isBuiltin: $isBuiltin,
  isDefault: $isDefault
 })""";
  }

  Node.fromMap(Map<String, Object?> map)
      : id = (map[selfIdColumn] ?? 0) as int,
        uriRaw = map['uri'] as String? ?? '',
        path = map['path'] as String? ?? '',
        login = map['login'] as String?,
        label = map['label'] as String?,
        password = map['password'] as String?,
        isPow = _getBoolFromDB(map['isPow']),
        useSSL = _getBoolFromDB(map['useSSL']),
        typeRaw = (map["typeRaw"] ?? 0) as int,
        trusted = _getBoolFromDB(map['trusted']),
        socksProxyAddress = map['socksProxyAddress'] as String?,
        isEnabledForAutoSwitching = _getBoolFromDB(map['isEnabledForAutoSwitching']),
        isOfficial = _getBoolFromDB(map['isOfficial']),
        isBuiltin = _getBoolFromDB(map['isBuiltin']),
        isDefault = _getBoolFromDB(map['isDefault']);

  static bool _getBoolFromDB(value, {bool? defaultValue}) {
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value == 1;
    } else {
      return defaultValue ?? false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      selfIdColumn: id,
      'uri': uriRaw,
      'path': path,
      'login': login,
      "label": label,
      'password': password,
      "isPow": isPow ? 1 : 0,
      'useSSL': (useSSL ?? false) ? 1 : 0,
      "typeRaw": typeRaw,
      'trusted': trusted ? 1 : 0,
      'socksProxyAddress': socksProxyAddress,
      'isEnabledForAutoSwitching': isEnabledForAutoSwitching ? 1 : 0,
      "isOfficial": isOfficial ? 1 : 0,
      "isBuiltin": isBuiltin ? 1 : 0,
      "isDefault": isDefault ? 1 : 0
    };
  }

  Node.fromUri(Uri uri, WalletType type)
      : id = 0,
        uriRaw =
            "${uri.host}${uri.hasPort ? ':${uri.port}' : (uri.queryParameters['port']?.isNotEmpty == true ? ':${uri.queryParameters['port']}' : '')}",
        path = uri.path,
        login = uri.userInfo.contains(':')
            ? uri.userInfo.split(':')[0]
            : uri.queryParameters['username'],
        password = uri.userInfo.contains(':')
            ? uri.userInfo.split(':')[1]
            : uri.queryParameters['password'],
        useSSL = uri.queryParameters['protocol'] == 'https',
        trusted = uri.queryParameters['trusted'] == 'true',
        isPow = false,
        isEnabledForAutoSwitching = false,
        isOfficial = false,
        isBuiltin = false,
        isDefault = false,
        typeRaw = serializeToInt(type);

  Future<int> delete() async {
    return await db!.delete(tableName, where: '${selfIdColumn} = ?', whereArgs: [id]);
  }

  static Future<int> deleteAll() async {
    return await db!.delete(tableName, where: "isPow = ?", whereArgs: [0]);
  }

  static Future<int> deleteAllPow() async {
    return await db!.delete(tableName, where: "isPow = ?", whereArgs: [1]);
  }

  Future<int> save() async {
    final json = toMap();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    id = await db!.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Node>> selectList(String where, List<dynamic> whereArgs,
      {String? orderBy}) async {
    if (orderBy == null) {
      orderBy = selfIdColumn;
    }
    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return List.generate(list.length, (index) => Node.fromMap(list[index]));
  }

  static Future<Node?> select(String where, List<dynamic> whereArgs, {String? orderBy}) async {
    if (orderBy == null) {
      orderBy = selfIdColumn;
    }
    final list = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return list.isEmpty ? null : Node.fromMap(list.first);
  }

  static Future<List<Node>> getAll() async {
    return selectList("isPow = ?", [0]);
  }

  static Future<List<Node>> getAllBuiltin() async {
    return selectList("isPow = ? AND isBuiltin = ?", [0, 1]);
  }

  static Future<List<Node>> getAllPowBuiltin() async {
    return selectList("isPow = ? AND isBuiltin = ?", [1, 1]);
  }

  static Future<List<Node>> getAllForWalletType(WalletType type) async {
    return selectList("typeRaw = ? AND isPow = ?", [serializeToInt(type), 0]);
  }

  static Future<Node?> getDefaultForWalletType(WalletType type) async {
    return (await selectList(
            "typeRaw = ? AND isPow = ? AND isDefault = ?", [serializeToInt(type), 0, 1]))
        .firstOrNull;
  }

  static Future<Node?> getDefaultPowForWalletType(WalletType type) async {
    return (await selectList(
            "typeRaw = ? AND isPow = ? AND isDefault = ?", [serializeToInt(type), 1, 1]))
        .firstOrNull;
  }

  static Future<List<Node>> getAllForWalletTypePow(WalletType type) async {
    return selectList("typeRaw = ? AND isPow = ?", [serializeToInt(type), 1]);
  }

  static Future<List<Node>> getAllPow() async {
    return selectList("isPow = ?", [1]);
  }

  static Future<Node?> get(int id) async {
    return select("${selfIdColumn} = ?", [id]);
  }

  int id;
  late String uriRaw;
  String? login;
  String? password;
  late int typeRaw;
  bool? useSSL;
  bool trusted;
  bool isPow;
  String? socksProxyAddress;
  String? path;
  bool? isElectrs;
  bool? supportsSilentPayments;
  bool? supportsMweb;
  bool isEnabledForAutoSwitching;
  bool isOfficial;
  bool isBuiltin;
  bool isDefault;

  String? label;

  static String get tableName => "Node";
  static String get selfIdColumn => "${tableName}Id";

  bool get isSSL => useSSL ?? false;

  bool get useSocksProxy => socksProxyAddress == null ? false : socksProxyAddress!.isNotEmpty;

  Uri get uri {
    try {
      return _uri;
    } catch (e) {
      printV(e);
      return Uri();
    }
  }

  Uri get _uri {
    switch (type) {
      case WalletType.monero:
      case WalletType.zcash:
      case WalletType.haven:
      case WalletType.wownero:
        return Uri.http(uriRaw, '');
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
        return createUriFromElectrumAddress(uriRaw, path!);
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.bsc:
      case WalletType.arbitrum:
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.zano:
      case WalletType.decred:
        return Uri.parse(
            "http${isSSL ? "s" : ""}://$uriRaw${path!.startsWith("/") || path!.isEmpty ? path : "/$path"}");
      case WalletType.none:
        throw Exception('Unexpected type ${type.toString()} for Node uri');
    }
  }

  bool get isValidProxyAddress => socksProxyAddress?.contains(':') ?? false;

  @override
  bool operator ==(other) =>
      other is Node &&
      (other.uriRaw == uriRaw &&
          other.login == login &&
          other.label == label &&
          other.password == password &&
          other.typeRaw == typeRaw &&
          other.useSSL == useSSL &&
          other.trusted == trusted &&
          other.socksProxyAddress == socksProxyAddress &&
          other.path == path);

  @override
  int get hashCode =>
      uriRaw.hashCode ^
      login.hashCode ^
      label.hashCode ^
      password.hashCode ^
      typeRaw.hashCode ^
      useSSL.hashCode ^
      trusted.hashCode ^
      socksProxyAddress.hashCode ^
      path.hashCode;

  WalletType get type => deserializeFromInt(typeRaw);

  set type(WalletType type) => typeRaw = serializeToInt(type);

  Future<bool> requestNode() async {
    try {
      switch (type) {
        case WalletType.monero:
        case WalletType.haven:
        case WalletType.wownero:
          return requestMoneroNode();
        case WalletType.nano:
        case WalletType.banano:
          return requestNanoNode();
        case WalletType.bitcoin:
        case WalletType.litecoin:
        case WalletType.bitcoinCash:
        case WalletType.ethereum:
        case WalletType.polygon:
        case WalletType.base:
        case WalletType.arbitrum:
        case WalletType.bsc:
        case WalletType.solana:
        case WalletType.tron:
        case WalletType.dogecoin:
        case WalletType.zcash:
          return requestElectrumServer();
        case WalletType.zano:
          return requestZanoNode();
        case WalletType.decred:
          return requestDecredNode();
        case WalletType.none:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestZanoNode() async {
    final path = '/json_rpc';
    final rpcUri = isSSL ? Uri.https(uri.authority, path) : Uri.http(uri.authority, path);
    final body = {'jsonrpc': '2.0', 'id': '0', 'method': "getinfo"};

    try {
      final jsonBody = json.encode(body);

      final response = await ProxyWrapper().post(
        clearnetUri: rpcUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      final resBody = json.decode(response.body) as Map<String, dynamic>;

      return resBody['result']['height'] != null;
    } catch (e) {
      printV("error: $e");
      return false;
    }
  }

  Future<bool> requestMoneroNode({String methodName = 'get_info'}) async {
    if (useSocksProxy) {
      return await requestNodeWithProxy();
    }

    final path = '/json_rpc';
    final rpcUri = isSSL ? Uri.https(uri.authority, path) : Uri.http(uri.authority, path);
    final body = {'jsonrpc': '2.0', 'id': '0', 'method': methodName};

    try {
      final jsonBody = json.encode(body);

      final response = await ProxyWrapper().post(
          clearnetUri: rpcUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonBody,
          allowMitmMoneroBypassSSLCheck: true);
      // Check if we received a 401 Unauthorized response
      if (response.statusCode == 401) {
        final daemonRpc = DaemonRpc(
          rpcUri.toString(),
          username: login ?? '',
          password: password ?? '',
        );
        final response = await daemonRpc.call('get_info', {});
        return !(response['offline'] as bool);
      }

      final responseString = await response.body;

      if ((responseString.contains("400 Bad Request") // Some other generic error
              ||
              responseString.contains("plain HTTP request was sent to HTTPS port") // Cloudflare
              ||
              response.headers["location"] != null // Generic reverse proxy
              ||
              responseString
                  .contains("301 Moved Permanently") // Poorly configured generic reverse proxy
          ) &&
          !(useSSL ?? false)) {
        final oldUseSSL = useSSL;
        useSSL = true;
        try {
          final ret = await requestMoneroNode(methodName: methodName);
          if (ret == true) {
            await save();
            return ret;
          }
          useSSL = oldUseSSL;
        } catch (e) {
          useSSL = oldUseSSL;
        }
      }

      final resBody = json.decode(response.body) as Map<String, dynamic>;
      return !(resBody['result']['offline'] as bool);
    } catch (e) {
      printV("error: $e");
      return false;
    }
  }

  Future<bool> requestNodeWithProxy() async {
    if (!isValidProxyAddress && !CakeTor.instance!.enabled) {
      return false;
    }

    String? proxy = socksProxyAddress;

    if ((proxy?.isEmpty ?? true) && CakeTor.instance!.enabled) {
      proxy = "${InternetAddress.loopbackIPv4.address}:${CakeTor.instance!.port}";
    }
    printV("proxy: $proxy");
    if (proxy == null) {
      return false;
    }
    final proxyAddress = proxy.split(':')[0];
    final proxyPort = int.parse(proxy.split(':')[1]);
    try {
      final socket = await Socket.connect(proxyAddress, proxyPort, timeout: Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  // TODO: this will return true most of the time, even if the node has useSSL set to true while
  // it doesn't support SSL or vice versa, because it will connect normally, but it will fail if
  // you try to communicate with it
  Future<bool> requestElectrumServer() async {
    try {
      final ProxySocket socket;
      socket = await ProxyWrapper().getSocksSocket(useSSL ?? false, uri.host, uri.port);

      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNanoNode() async {
    try {
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: {"Content-Type": "application/json", "nano-app": "cake-wallet"},
        body: jsonEncode(
          {
            "action": "account_balance",
            "account": "nano_38713x95zyjsqzx6nm1dsom1jmm668owkeb9913ax6nfgj15az3nu8xkx579",
          },
        ),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 ||
          data["error"] != null ||
          data["balance"] == null ||
          data["receivable"] == null) {
        throw Exception(
            "Error while trying to get balance! ${data["error"] != null ? data["error"] : ""}");
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestEthereumServer() async {
    try {
      final req = await ProxyWrapper()
          .getHttpClient()
          .getUrl(
            uri,
          )
          .timeout(Duration(seconds: 15));
      final response = await req.close();

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (err) {
      printV("Failed to request ethereum server: $err");
      return false;
    }
  }

  Future<bool> requestDecredNode() async {
    if (uri.host == "default-spv-nodes") {
      // Just show default port as ok. The wallet will connect to a list of known
      // nodes automatically.
      return true;
    }
    try {
      final socket = await Socket.connect(uri.host, uri.port, timeout: Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// https://github.com/ManyMath/digest_auth/
/// HTTP Digest authentication.
///
/// Adapted from https://github.com/dart-lang/http/issues/605#issue-963962341.
///
/// Created because http_auth was not working for Monero daemon RPC responses.
class DigestAuth {
  final String username;
  final String password;
  String? realm;
  String? nonce;
  String? uri;
  String? qop = "auth";
  int _nonceCount = 0;

  DigestAuth(this.username, this.password);

  /// Initialize Digest parameters from the `WWW-Authenticate` header.
  void initFromAuthorizationHeader(String authInfo) {
    final Map<String, String>? values = _splitAuthenticateHeader(authInfo);
    if (values != null) {
      realm = values['realm'];
      // Check if the nonce has changed.
      if (nonce != values['nonce']) {
        nonce = values['nonce'];
        _nonceCount = 0; // Reset nonce count when nonce changes.
      }
    }
  }

  /// Generate the Digest Authorization header.
  String getAuthString(String method, String uri) {
    this.uri = uri;
    _nonceCount++;
    String cnonce = _computeCnonce();
    String nc = _formatNonceCount(_nonceCount);

    String ha1 = md5Hash("$username:$realm:$password");
    String ha2 = md5Hash("$method:$uri");
    String response = md5Hash("$ha1:$nonce:$nc:$cnonce:$qop:$ha2");

    return 'Digest username="$username", realm="$realm", nonce="$nonce", uri="$uri", qop=$qop, nc=$nc, cnonce="$cnonce", response="$response"';
  }

  /// Helper to parse the `WWW-Authenticate` header.
  Map<String, String>? _splitAuthenticateHeader(String? header) {
    if (header == null || !header.startsWith('Digest ')) {
      return null;
    }
    String token = header.substring(7); // Remove 'Digest '.
    final Map<String, String> result = {};

    final components = token.split(',').map((token) => token.trim());
    for (final component in components) {
      final kv = component.split('=');
      final key = kv[0];
      final value = kv.sublist(1).join('=').replaceAll('"', '');
      result[key] = value;
    }
    return result;
  }

  /// Helper to compute a random cnonce.
  String _computeCnonce() {
    final math.Random rnd = math.Random();
    final List<int> values = List<int>.generate(16, (i) => rnd.nextInt(256));
    return hex.encode(values);
  }

  /// Helper to format the nonce count.
  String _formatNonceCount(int count) => count.toRadixString(16).padLeft(8, '0');

  /// Compute the MD5 hash of a string.
  String md5Hash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }
}

class DaemonRpc {
  final String rpcUrl;
  final String username;
  final String password;

  DaemonRpc(this.rpcUrl, {required this.username, required this.password});

  /// Perform a JSON-RPC call with Digest Authentication.
  Future<Map<String, dynamic>> call(String method, Map<String, dynamic> params) async {
    final client = ProxyWrapper().getHttpIOClient();
    final DigestAuth digestAuth = DigestAuth(username, password);

    // Initial request to get the `WWW-Authenticate` header.
    final initialResponse = await client.post(
      Uri.parse(rpcUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': '0',
        'method': method,
        'params': params,
      }),
    );

    if (initialResponse.statusCode != 401 ||
        !initialResponse.headers.containsKey('www-authenticate')) {
      throw Exception('Unexpected response: ${initialResponse.body}');
    }

    // Extract Digest details from `WWW-Authenticate` header.
    final String authInfo = initialResponse.headers['www-authenticate']!;
    digestAuth.initFromAuthorizationHeader(authInfo);

    // Create Authorization header for the second request.
    String uri = Uri.parse(rpcUrl).path;
    String authHeader = digestAuth.getAuthString('POST', uri);

    // Make the authenticated request.
    final authenticatedResponse = await client.post(
      Uri.parse(rpcUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': '0',
        'method': method,
        'params': params,
      }),
    );

    if (authenticatedResponse.statusCode != 200) {
      throw Exception('RPC call failed: ${authenticatedResponse.body}');
    }

    final Map<String, dynamic> result =
        jsonDecode(authenticatedResponse.body) as Map<String, dynamic>;
    if (result['error'] != null) {
      throw Exception('RPC Error: ${result['error']}');
    }

    return result['result'] as Map<String, dynamic>;
  }
}
