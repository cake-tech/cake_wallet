import 'dart:async';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_zano/api/model/balance.dart';
import 'package:cw_zano/api/model/create_wallet_result.dart';
import 'package:cw_zano/api/zano_api.dart';
import 'package:cw_zano/zano_balance.dart';
import 'package:cw_zano/zano_transaction_history.dart';
import 'package:cw_zano/zano_transaction_info.dart';
import 'package:mobx/src/api/observable_collections.dart';
import 'package:cw_zano/api/wallet.dart' as zano_wallet;
import 'dart:convert';
import 'dart:ffi';

import 'package:cw_zano/api/signatures.dart';
import 'package:cw_zano/api/types.dart';
import 'package:ffi/ffi.dart';

import 'api/model/zano_wallet_keys.dart';
import 'new_zano_addresses_base.dart';

typedef _load_wallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Int8);
typedef _LoadWallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, int);

class NewZanoWallet extends WalletBase<ZanoBalance, ZanoTransactionHistory, ZanoTransactionInfo> {
  @override
  SyncStatus syncStatus;

  Timer? _autoSaveTimer;

  static const int _autoSaveInterval = 30;

  NewZanoWallet(super.walletInfo)
      : balance = ObservableMap.of({CryptoCurrency.zano: ZanoBalance(total: 0, unlocked: 0)}),
        walletAddresses = NewZanoWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus() {
    transactionHistory = ZanoTransactionHistory();
  }

  Future<void> init() async {
    print("NewZanoWallet init");
    if (walletInfo.isRecovery) {
      print("is recovery");
    }
    _autoSaveTimer =
        Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  String getTransactionAddress(int accountIndex, int addressIndex) {
    print("NewZanoWallet getTransactionAddress");
    return "";
  }

  @override
  ObservableMap<CryptoCurrency, ZanoBalance> balance;

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    // TODO: implement calculateEstimatedFee
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(String password) {
    // TODO: implement changePassword
    throw UnimplementedError();
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    print("NewZanoWallet connecttoNode");
    try {
      syncStatus = ConnectingSyncStatus();
      _setupNode(address: "195.201.107.230:33336", login: "", password: "");
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print("connectToNode error $e");
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) {
    // TODO: implement createTransaction
    throw UnimplementedError();
  }

  @override
  Future<Map<String, ZanoTransactionInfo>> fetchTransactions() {
    // TODO: implement fetchTransactions
    throw UnimplementedError();
  }

  @override
  ZanoWalletKeys get keys => ZanoWalletKeys(
      privateSpendKey: "", privateViewKey: "", publicSpendKey: "", publicViewKey: "");

  @override
  Future<void> renameWalletFiles(String newWalletName) {
    // TODO: implement renameWalletFiles
    throw UnimplementedError();
  }

  @override
  Future<void> rescan({required int height}) {
    // TODO: implement rescan
    throw UnimplementedError();
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    if (hWallet != null) await zano_wallet.store(hWallet!);
  }

  @override
  // TODO: implement seed
  String? seed = "Тут пока пусто";

  @override
  Future<void> startSync() {
    // TODO: implement startSync
    throw UnimplementedError();
  }

  @override
  Future<void>? updateBalance() {
    // TODO: implement updateBalance
    throw UnimplementedError();
  }

  @override
  NewZanoWalletAddresses walletAddresses;

  CreateWalletResult? createWalletResult;
  List<Balance>? balances;
  int? hWallet;
  final assetIds = <String, String>{};

  final _setupNodeNative =
      zanoApi.lookup<NativeFunction<setup_node>>('setup_node').asFunction<SetupNode>();
  final _createWalletNative =
      zanoApi.lookup<NativeFunction<create_wallet>>('create_wallet').asFunction<CreateWallet>();

  final _loadWalletNative =
      zanoApi.lookup<NativeFunction<_load_wallet>>('load_wallet').asFunction<_LoadWallet>();

  bool _setupNode(
      {required String address,
      required String login,
      required String password,
      bool useSSL = false,
      bool isLightWallet = false}) {
    final addressPointer = address.toNativeUtf8();
    final loginPointer = login.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final errorMessagePointer = ''.toNativeUtf8();
    print(
        "setup_node address $address login $login password $password useSSL $useSSL isLightWallet $isLightWallet");
    final result = _intToBool(_setupNodeNative(addressPointer, loginPointer, passwordPointer,
        _boolToInt(useSSL), _boolToInt(isLightWallet), errorMessagePointer));
    print("setup_node result $result");
    calloc.free(addressPointer);
    calloc.free(loginPointer);
    calloc.free(passwordPointer);
    return result;
  }

  String _createWalletSync(
      {required String path, required String password, required String language, int nettype = 0}) {
    final pathPointer = path.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final languagePointer = language.toNativeUtf8();
    final errorMessagePointer = ''.toNativeUtf8();
    print("create_wallet path $path password $password language $language");
    final result = _convertUTF8ToString(
        pointer: _createWalletNative(
            pathPointer, passwordPointer, languagePointer, nettype, errorMessagePointer));
    print("create_wallet $result");
    calloc.free(pathPointer);
    calloc.free(passwordPointer);
    calloc.free(languagePointer);

    return result;
  }

  void createWallet({required String path, required String password}) {
    final createResult = _createWalletSync(path: path, password: password, language: "");
    final address = _parseResult(createResult)!;
    walletAddresses.address = address;
  }

  String loadWallet(String path, String password) {
    print('load_wallet path $path password $password');
    final pathPointer = path.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final result = _convertUTF8ToString(
      pointer: _loadWalletNative(pathPointer, passwordPointer, 0),
    );
    print('load_wallet result $result');
    return result;
  }

  int _boolToInt(bool value) => value ? 1 : 0;
  bool _intToBool(int value) => value != 0;
  String _convertUTF8ToString({required Pointer<Utf8> pointer}) {
    final str = pointer.toDartString();
    calloc.free(pointer);
    return str;
  }

  // TODO: kind of stupid thing, in one method parsing json and then setting properties of a class
  String? _parseResult(String result) {
    final map = json.decode(result) as Map<String, dynamic>;
    if (map['result'] != null) {
      createWalletResult =
          CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
      balances = createWalletResult!.wi.balances;
      hWallet = createWalletResult!.walletId;
      assetIds.clear();
      for (final balance in createWalletResult!.wi.balances) {
        assetIds[balance.assetInfo.assetId] = balance.assetInfo.ticker;
      }
      return createWalletResult!.wi.address;
    }
    return null;
  }
}
