import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'dart:convert';
import 'package:cake_wallet/store/yat/yat_exception.dart';
import 'package:http/http.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'yat_store.g.dart';

class YatLink {
  static const partnerId = ''; // 'CW';
  static const baseDevUrl = ''; // 'https://yat.fyi';
  static const baseReleaseUrl = ''; // 'https://y.at';
  static const signInSuffix = ''; // '/partner/$partnerId/link-email';
  static const createSuffix = ''; // '/create';
  static const managePath = ''; // '/partner/$partnerId/manage';
  static const queryParameter = ''; // '?address_json=';
  static const apiDevUrl = ''; // 'https://a.yat.fyi';
  static const apiReleaseUrl = ''; // 'https://a.y.at';
  static const requestDevUrl = ''; // 'https://a.yat.fyi/emoji_id/';
  static const requestReleaseUrl = ''; //'https://a.y.at/emoji_id/';
  static const startFlowUrl = ''; // 'https://www.y03btrk.com/4RQSJ/6JHXF/';
  static const isDevMode = true;
  static const tags = <String, List<String>>{"XMR" : ['0x1001', '0x1002'],
    "BTC" : ['0x1003'], "LTC" : ['0x1019']};

  static String get apiUrl => YatLink.isDevMode
      ? YatLink.apiDevUrl
      : YatLink.apiReleaseUrl;

  static String get emojiIdUrl => apiUrl + '/emoji_id/';

  static String get baseUrl => YatLink.isDevMode
          ? YatLink.baseDevUrl
          : YatLink.baseReleaseUrl;
}

Future<List<String>> fetchYatAddress(String emojiId, String ticker) async {
  throw Exception();
  //final url = YatLink.emojiIdUrl + emojiId + '/payment';
  //final response = await get(url);
  
  //if (response.statusCode != 200) {
  //  throw YatException(text: response.body.toString());
  //}
  
  //final addresses = <String>[];
  //final currency = ticker.toUpperCase();
  //final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  //final result = responseJSON['result'] as Map<dynamic, dynamic>;
  //result.forEach((dynamic key, dynamic value) {
  //  final tag = key as String ?? '';
  //  final record = value as Map<String, dynamic>;
  
  //  if (YatLink.tags[currency]?.contains(tag) ?? false) {
  //    final address = record['address'] as String;
  //    if (address?.isNotEmpty ?? false) {
  //      addresses.add(address);
  //    }
  //  }
  //});

  //return addresses;
  return [];
}

Future<String> fetchYatAccessToken(String refreshToken) async {
  throw Exception();
  //try {
  //  final url = YatLink.apiUrl + '/auth/token/refresh';
  //  final bodyJson = json.encode({'refresh_token': refreshToken});
  //  final response = await post(
  //    url,
  //    headers: <String, String>{
  //      'Content-Type': 'application/json',
  //      'Accept': '*/*'
  //    },
  //    body: bodyJson);
    
  //  if (response.statusCode != 200) {
  //    throw YatException(text: response.body.toString());
  //  }
    
  //  final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  //  return  responseJSON['access_token'] as String;
  //}catch(_) {
  //  return '';
  //}
  return '';
}

Future<String> fetchYatApiKey(String accessKey) async {
  throw Exception();
  //try {
  //  final url = YatLink.apiUrl + '/api_keys';
  //  final bodyJson = json.encode({'name': 'CW'});
  //  final response = await post(
  //    url,
  //    headers: <String, String>{
  //      'Authorization': 'Bearer $accessKey',
  //      'Content-Type': 'application/json',
  //      'Accept': '*/*'
  //    },
  //    body: bodyJson);

  //  if (response.statusCode != 200) {
  //    throw YatException(text: response.body.toString());
  //  }
    
  //  final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  //  return  responseJSON['api_key'] as String;
  //}catch(_) {
  //  return '';
  //}
  return '';
}

Future<void> updateEmojiIdAddress(String emojiId, String address, String apiKey, WalletType type) async {
  throw Exception();
  //final url = YatLink.emojiIdUrl + emojiId;
  //final cur = walletTypeToCryptoCurrency(type);
  //final curFormatted = cur.toString().toUpperCase();
  //var tag = '';

  //if (type == WalletType.monero && !address.startsWith('4')) {
  //  tag = YatLink.tags[curFormatted].last;
  //} else {
  //  tag = YatLink.tags[curFormatted].first;
  //}

  //final bodyJson = json.encode({
  //  'insert': [{
  //    'data': address,
  //    'tag': tag
  //  }]
  //});
  //final response = await patch(
  //  url,
  //  headers: <String, String>{
  //    'x-api-key': apiKey,
  //    'Content-Type': 'application/json',
  //    'Accept': '*/*'
  //  },
  //  body: bodyJson);

  //if (response.statusCode != 200) {
  //  throw YatException(text: response.body.toString());
  //}
}

Future<String> visualisationForEmojiId(String emojiId) async {
  throw Exception();
  //final url = YatLink.emojiIdUrl + emojiId + '/json/VisualizerFileLocations';
  //final response = await get(url);
  //final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  //final data = responseJSON['data'] as Map<String, dynamic>;
  //final result = data['gif'] as String ?? '';
  //return result;
  return '';
}

class YatStore = YatStoreBase with _$YatStore;

abstract class YatStoreBase with Store {
  YatStoreBase({
    required this.appStore,
    required this.secureStorage})
  : _wallet = appStore.wallet,
    emoji = appStore.wallet?.walletInfo?.yatEmojiId ?? '',
    refreshToken = '',
    accessToken = '',
    apiKey = '',
    emojiIncommingSC = StreamController<String>.broadcast() {
    //reaction((_) => appStore.wallet, _onWalletChange);
    //reaction((_) => emoji, (String _) => _onEmojiChange());
    //reaction((_) => refreshToken, (String _) => _onRefreshTokenChange());
  }

  static const yatRefreshTokenKeyBase = 'yat_refresh_token';
  static const yatAccessTokenKeyBase = 'yat_access_token';
  static const yatApiKeyBase = 'yat_api_key';

  static String yatRefreshTokenKey(String name) => '${yatRefreshTokenKeyBase}_$name';
  static String yatAccessTokenKey(String name) => '${yatAccessTokenKeyBase}_$name';
  static String yatApiKey(String name) => '${yatApiKeyBase}_$name';

  AppStore appStore;

  FlutterSecureStorage secureStorage;

  @observable
  String emoji;

  @observable
  String refreshToken;

  @observable
  String accessToken;

  @observable
  String apiKey;

  StreamController<String> emojiIncommingSC;

  Stream<String> get emojiIncommingStream => emojiIncommingSC.stream;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>?
    _wallet;

  Future<void> init() async {
    if (_wallet == null) {
      return;
    }

    refreshToken = await secureStorage.read(key: yatRefreshTokenKey(_wallet!.walletInfo.name)) ?? '';
    accessToken = await secureStorage.read(key: yatAccessTokenKey(_wallet!.walletInfo.name)) ?? '';
    apiKey = await secureStorage.read(key: yatApiKey(_wallet!.walletInfo.name)) ?? '';
  }
 
  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
          TransactionInfo>
      wallet) {
    this._wallet = wallet;
    emoji = wallet?.walletInfo?.yatEmojiId ?? '';
    init();
  }

  @action
  void _onEmojiChange() {
    try {
      final walletInfo = _wallet?.walletInfo;

      if (walletInfo == null) {
        return;
      }

      walletInfo!.yatEid = emoji;

      if (walletInfo!.isInBox) {
        walletInfo!.save();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @action
  Future<void> _onRefreshTokenChange() async {
    throw Exception();
    
    //try {
    //  await secureStorage.write(key: yatRefreshTokenKey(_wallet.walletInfo.name), value: refreshToken);
    //  accessToken = await fetchYatAccessToken(refreshToken);
    //  await secureStorage.write(key: yatAccessTokenKey(_wallet.walletInfo.name), value: accessToken);
    //  apiKey = await fetchYatApiKey(accessToken);
    //  await secureStorage.write(key: yatApiKey(_wallet.walletInfo.name), value: accessToken);
    //} catch (e) {
    //  print(e.toString());
    //}
  }

  String defineQueryParameters() {
    throw Exception();
    //final result = <String, String>{};
    //final tags = YatLink.tags[_wallet.currency.toString().toUpperCase()];
    //String tag =  tags.first;
    
    //if (_wallet.type == WalletType.monero
    //  && _wallet.walletAddresses.address.startsWith('4')) {
    //  tag = tags.last;
    //}
    //result[tag] = '${_wallet.walletAddresses.address}|${_wallet.name}';
    //final addressJson = json.encode([result]);
    //final addressJsonBytes = utf8.encode(addressJson);
    
    //return base64.encode(addressJsonBytes);
    return '';
  }
}
