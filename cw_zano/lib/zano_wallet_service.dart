import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zano/api/api_calls.dart';
import 'package:cw_zano/api/consts.dart';
import 'package:cw_zano/api/exceptions/already_exists_exception.dart';
import 'package:cw_zano/api/exceptions/create_wallet_exception.dart';
import 'package:cw_zano/api/exceptions/restore_from_seed_exception.dart';
import 'package:cw_zano/api/exceptions/wrong_seed_exception.dart';
import 'package:cw_zano/api/model/create_wallet_result.dart';
import 'package:cw_zano/model/zano_asset.dart';
import 'package:cw_zano/model/zano_balance.dart';
import 'package:cw_zano/zano_formatter.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class ZanoNewWalletCredentials extends WalletCredentials {
  ZanoNewWalletCredentials({required String name, String? password}) : super(name: name, password: password);
}

class ZanoRestoreWalletFromSeedCredentials extends WalletCredentials {
  ZanoRestoreWalletFromSeedCredentials({required String name, required String password, required int height, required this.mnemonic})
      : super(name: name, password: password, height: height);

  final String mnemonic;
}

class ZanoRestoreWalletFromKeysCredentials extends WalletCredentials {
  ZanoRestoreWalletFromKeysCredentials(
      {required String name, required String password, required this.language, required this.address, required this.viewKey, required this.spendKey, required int height})
      : super(name: name, password: password, height: height);

  final String language;
  final String address;
  final String viewKey;
  final String spendKey;
}

class ZanoWalletService extends WalletService<ZanoNewWalletCredentials, ZanoRestoreWalletFromSeedCredentials, ZanoRestoreWalletFromKeysCredentials> {
  ZanoWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static bool walletFilesExist(String path) => !File(path).existsSync() && !File('$path.keys').existsSync();

  int hWallet = 0;

  @override
  WalletType getType() => WalletType.zano;

  @override
  Future<ZanoWallet> create(WalletCredentials credentials, {bool? isTestnet}) async {
    print('zanowallet service create isTestnet $isTestnet'); // TODO: remove
    try {
      final wallet = ZanoWallet(credentials.walletInfo!);
      await wallet.connectToNode(node: Node());
      final path = await pathForWallet(name: credentials.name, type: getType());
      final json = ApiCalls.createWallet(language: '', path: path, password: credentials.password!);
      final map = jsonDecode(json) as Map<String, dynamic>;
      _checkForCreateWalletError(map);
      final createWalletResult = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
      _parseCreateWalletResult(createWalletResult, wallet);
      await wallet.store();
      await wallet.init(createWalletResult.wi.address);
      wallet.addInitialAssets();
      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('ZanoWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      return ApiCalls.isWalletExist(path: path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('ZanoWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<ZanoWallet> openWallet(String name, String password) async {
    try {
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) {
        await repairOldAndroidWallet(name);
      }

      final walletInfo = walletInfoSource.values.firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;
      final wallet = ZanoWallet(walletInfo);
      await wallet.connectToNode(node: Node());
      final json = wallet.loadWallet(path, password);
      debugPrint('load wallet result $json');
      final map = jsonDecode(json) as Map<String, dynamic>;
      _checkForCreateWalletError(map);
      final createWalletResult = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
      _parseCreateWalletResult(createWalletResult, wallet);
      await wallet.store();
      await wallet.init(createWalletResult.wi.address);
      return wallet;
    } catch (e) {
      rethrow;
      // TODO: uncomment after merge
      //await restoreWalletFilesFromBackup(name);
    }
  }

  void _checkForCreateWalletError(Map<String, dynamic> map) {
    if (map['error'] != null) {
      final code = map['error']!['code'] ?? '';
      final message = map['error']!['message'] ?? '';
      throw CreateWalletException('Error creating/loading wallet $code $message');
    }
    if (map['result'] == null) {
      throw CreateWalletException('Error creating/loading wallet, empty response');
    }
  }

  void _parseCreateWalletResult(CreateWalletResult result, ZanoWallet wallet) {
    hWallet = result.walletId;
    wallet.hWallet = hWallet;
    wallet.walletAddresses.address = result.wi.address;
    for (final item in result.wi.balances) {
      if (item.assetInfo.ticker == 'ZANO') {
        wallet.balance[CryptoCurrency.zano] = ZanoBalance(
          total: item.total,
          unlocked: item.unlocked,
          decimalPoint: ZanoFormatter.defaultDecimalPoint,
        );
      } else {
        for (final asset in wallet.balance.keys) {
          if (asset is ZanoAsset && asset.assetId == item.assetInfo.assetId) {
            wallet.balance[asset] = ZanoBalance(
              total: item.total,
              unlocked: item.unlocked,
              decimalPoint: asset.decimalPoint,
            );
          }
        }
      }
    }
    if (result.recentHistory.history != null) {
      wallet.transfers = result.recentHistory.history!;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }

    final walletInfo = walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(wallet, getType()));
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));
    final currentWallet = ZanoWallet(currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<ZanoWallet> restoreFromKeys(ZanoRestoreWalletFromKeysCredentials credentials, {bool? isTestnet}) async {
    throw UnimplementedError('Restore from keys not implemented');
  }

  @override
  Future<ZanoWallet> restoreFromSeed(ZanoRestoreWalletFromSeedCredentials credentials, {bool? isTestnet}) async {
    try {
      final wallet = ZanoWallet(credentials.walletInfo!);
      await wallet.connectToNode(node: Node());
      final path = await pathForWallet(name: credentials.name, type: getType());
      final json = ApiCalls.restoreWalletFromSeed(path: path, password: credentials.password!, seed: credentials.mnemonic);
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['result'] != null) {
        final createWalletResult = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
        _parseCreateWalletResult(createWalletResult, wallet);
        await wallet.store();
        await wallet.init(createWalletResult.wi.address);
        wallet.addInitialAssets();
        return wallet;
      } else if (map['error'] != null) {
        final code = map['error']['code'] as String;
        final message = map['error']['message'] as String;
        if (code == Consts.errorWrongSeed) {
          throw WrongSeedException(message);
        } else if (code == Consts.errorAlreadyExists) {
          throw AlreadyExistsException(message);
        }
        throw RestoreFromSeedException(code, message);
      }
      throw RestoreFromSeedException('', '');
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      print('ZanoWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<void> repairOldAndroidWallet(String name) async {
    try {
      if (!Platform.isAndroid) {
        return;
      }

      final oldAndroidWalletDirPath = await outdatedAndroidPathForWalletDir(name: name);
      final dir = Directory(oldAndroidWalletDirPath);

      if (!dir.existsSync()) {
        return;
      }

      final newWalletDirPath = await pathForWalletDir(name: name, type: getType());

      dir.listSync().forEach((f) {
        final file = File(f.path);
        final name = f.path.split('/').last;
        final newPath = newWalletDirPath + '/$name';
        final newFile = File(newPath);

        if (!newFile.existsSync()) {
          newFile.createSync();
        }
        newFile.writeAsBytesSync(file.readAsBytesSync());
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
