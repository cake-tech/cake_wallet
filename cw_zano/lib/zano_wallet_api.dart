import 'dart:convert';

import 'package:cw_core/transaction_priority.dart';
import 'package:cw_zano/api/api_calls.dart';
import 'package:cw_zano/api/model/asset_id_params.dart';
import 'package:cw_zano/api/model/get_address_info_result.dart';
import 'package:cw_zano/api/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/api/model/get_wallet_info_result.dart';
import 'package:cw_zano/api/model/get_wallet_status_result.dart';
import 'package:cw_zano/api/model/proxy_to_daemon_params.dart';
import 'package:cw_zano/api/model/proxy_to_daemon_result.dart';
import 'package:cw_zano/api/model/transfer.dart';
import 'package:cw_zano/model/zano_asset.dart';
import 'package:flutter/foundation.dart';

import 'api/model/store_result.dart';

enum _LogType { none, simple, json }

mixin ZanoWalletApi {
  static const _defaultNodeUri = '195.201.107.230:33336';
  static const _statusDelivered = 'delivered';
  static const _maxAttempts = 10;
  static const _logType = _LogType.simple;

  int _hWallet = 0;

  int get hWallet => _hWallet;

  set hWallet(int value) {
    _hWallet = value;
  }

  int getCurrentTxFee(TransactionPriority priority) => ApiCalls.getCurrentTxFee(priority: priority.raw);

  void setPassword(String password) => ApiCalls.setPassword(hWallet: hWallet, password: password);

  void closeWallet() => ApiCalls.closeWallet(hWallet: hWallet);

  Future<bool> setupNode() async => ApiCalls.setupNode(
        address: _defaultNodeUri,
        login: '',
        password: '',
        useSSL: false,
        isLightWallet: false,
      );

  GetWalletInfoResult getWalletInfo() {
    final json = ApiCalls.getWalletInfo(hWallet);
    final result = GetWalletInfoResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
    switch (_logType) {
      case _LogType.json:
        debugPrint('get_wallet_info $json');
        break;
      case _LogType.simple:
        debugPrint('get_wallet_info got ${result.wi.balances.length} balances: ${result.wi.balances}');
    }

    return result;
  }

  GetWalletStatusResult getWalletStatus() {
    final json = ApiCalls.getWalletStatus(hWallet: hWallet);
    final status = GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
    switch (_logType) {
      case _LogType.json:
        debugPrint('get_wallet_status $json');
        break;
      case _LogType.simple:
        debugPrint(
            'get_wallet_status connected: ${status.isDaemonConnected} in refresh: ${status.isInLongRefresh} wallet state: ${status.walletState}');
    }
    return status;
  }

  Future<String> invokeMethod(String methodName, Object params) async {
    var invokeResult =
        ApiCalls.asyncCall(methodName: 'invoke', hWallet: hWallet, params: '{"method": "$methodName","params": ${jsonEncode(params)}}');
    var map = jsonDecode(invokeResult) as Map<String, dynamic>;
    int attempts = 0;
    if (map['job_id'] != null) {
      final jobId = map['job_id'] as int;
      do {
        await Future.delayed(Duration(milliseconds: attempts < 2 ? 100 : 500));
        final result = ApiCalls.tryPullResult(jobId);
        map = jsonDecode(result) as Map<String, dynamic>;
        if (map['status'] != null && map['status'] == _statusDelivered && map['result'] != null) {
          return result;
        }
      } while (++attempts < _maxAttempts);
    }
    return invokeResult;
  }

  Future<List<ZanoAsset>> getAssetsWhitelist() async {
    try {
      final json = await invokeMethod('assets_whitelist_get', '{}');
      /*if (_logType == _LogType.json)*/ debugPrint('assets_whitelist_get $json');
      final map = jsonDecode(json) as Map<String, dynamic>?;
      _checkForErrors(map);
      List<ZanoAsset> assets(String type) =>
          (map?['result']?['result']?[type] as List<dynamic>?)?.map((e) => ZanoAsset.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      final localWhitelist = assets('local_whitelist');
      final globalWhitelist = assets('global_whitelist');
      final ownAssets = assets('own_assets');
      if (_logType == _LogType.simple)
        print('assets_whitelist_get got local whitelist: ${localWhitelist.length} ($localWhitelist); '
            'global whitelist: ${globalWhitelist.length} ($globalWhitelist); '
            'own assets: ${ownAssets.length} ($ownAssets)');
      return [...localWhitelist, ...globalWhitelist, ...ownAssets];
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Future<ZanoAsset?> addAssetsWhitelist(String assetId) async {
    try {
      final json = await invokeMethod('assets_whitelist_add', AssetIdParams(assetId: assetId));
      if (_logType == _LogType.json) print('assets_whitelist_add $assetId $json');
      final map = jsonDecode(json) as Map<String, dynamic>?;
      _checkForErrors(map);
      if (map!['result']!['result']!['status']! == 'OK') {
        final assetDescriptor = ZanoAsset.fromJson(map['result']!['result']!['asset_descriptor']! as Map<String, dynamic>);
        if (_logType == _LogType.simple) print('assets_whitelist_add added ${assetDescriptor.fullName} ${assetDescriptor.ticker}');
        return assetDescriptor;
      } else {
        if (_logType == _LogType.simple) print('assets_whitelist_add status ${map['result']!['result']!['status']!}');
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<bool> removeAssetsWhitelist(String assetId) async {
    try {
      final json = await invokeMethod('assets_whitelist_remove', AssetIdParams(assetId: assetId));
      if (_logType == _LogType.json) print('assets_whitelist_remove $assetId $json');
      final map = jsonDecode(json) as Map<String, dynamic>?;
      _checkForErrors(map);
      if (_logType == _LogType.simple) print('assets_whitelist_remove status ${map!['result']!['result']!['status']!}');
      return (map!['result']!['result']!['status']! == 'OK');
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<ProxyToDaemonResult?> _proxyToDaemon(String uri, String body) async {
    final json = await invokeMethod('proxy_to_daemon', ProxyToDaemonParams(body: body, uri: uri));
    final map = jsonDecode(json) as Map<String, dynamic>?;
    _checkForErrors(map);
    return ProxyToDaemonResult.fromJson(map!['result']['result'] as Map<String, dynamic>);
  }

  Future<ZanoAsset?> getAssetInfo(String assetId) async {
    final methodName = 'get_asset_info';
    final params = AssetIdParams(assetId: assetId);
    final result = await _proxyToDaemon('/json_rpc', '{"method": "$methodName","params": ${jsonEncode(params)}}');
    if (_logType == _LogType.json) print('$methodName $assetId ${result?.body}');
    if (result == null) {
      debugPrint('get_asset_info empty result');
      return null;
    }
    final map = jsonDecode(result.body) as Map<String, dynamic>?;
    if (map!['error'] != null) {
      if (_logType == _LogType.simple) print('get_asset_info $assetId error ${map['error']!['code']} ${map['error']!['message']}');
      return null;
    } else if (map['result']!['status']! == 'OK') {
      final assetDescriptor = ZanoAsset.fromJson(map['result']!['asset_descriptor']! as Map<String, dynamic>);
      if (_logType == _LogType.simple) print('get_asset_info $assetId ${assetDescriptor.fullName} ${assetDescriptor.ticker}');
      return assetDescriptor;
    } else {
      if (_logType == _LogType.simple) print('get_asset_info $assetId status ${map['result']!['status']!}');
      return null;
    }
  }

  Future<StoreResult?> store() async {
    try {
      final json = await invokeMethod('store', '{}');
      final map = jsonDecode(json) as Map<String, dynamic>?;
      _checkForErrors(map);
      return StoreResult.fromJson(map!['result']['result'] as Map<String, dynamic>);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<List<Transfer>> getRecentTxsAndInfo() async {
    try {
      final json = await invokeMethod('get_recent_txs_and_info', GetRecentTxsAndInfoParams(offset: 0, count: 30));
      //debugPrint('get_recent_txs_and_info $json');
      final map = jsonDecode(json) as Map<String, dynamic>?;
      _checkForErrors(map);
      final transfers = map?['result']?['result']?['transfers'] as List<dynamic>?;
      if (transfers == null) {
        print('get_recent_txs_and_info empty transfers');
        return [];
      }
      return transfers.map((e) => Transfer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  GetAddressInfoResult getAddressInfo(String address) => GetAddressInfoResult.fromJson(
        jsonDecode(ApiCalls.getAddressInfo(address: address)) as Map<String, dynamic>,
      );

  void _checkForErrors(Map<String, dynamic>? map) {
    if (map == null) {
      throw 'empty response';
    }

    final result = map['result'];
    if (result == null) {
      throw 'empty response';
    }

    if (result['error'] != null) {
      final code = result['error']!['code'] ?? '';
      final message = result['error']!['message'] ?? '';
      throw 'error $code $message';
    }
  }
}
