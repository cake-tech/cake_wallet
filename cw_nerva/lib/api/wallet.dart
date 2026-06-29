import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_nerva/api/account_list.dart';
import 'package:cw_nerva/api/exceptions/setup_wallet_exception.dart';
import 'package:monero/nerva.dart' as nerva;
import 'package:mutex/mutex.dart';

int getSyncingHeight() {
  // final height = nerva.NERVA_cw_WalletListener_height(getWlptr());
  final h2 = nerva.Wallet_blockChainHeight(wptr!);
  // printV("height: $height / $h2");
  return h2;
}

bool isNeededToRefresh() {
  // final ret = nerva.NERVA_cw_WalletListener_isNeedToRefresh(getWlptr());
  // nerva.NERVA_cw_WalletListener_resetNeedToRefresh(getWlptr());
  return true;
}

bool isNewTransactionExist() {
  // final ret =
  //     nerva.NERVA_cw_WalletListener_isNewTransactionExist(getWlptr());
  // nerva.NERVA_cw_WalletListener_resetIsNewTransactionExist(getWlptr());
  // NOTE: I don't know why nerva is being funky, but
  return true;
}

String getFilename() => nerva.Wallet_filename(wptr!);

// Nerva uses the standard 25-word Monero mnemonic only (no polyseed).
String getSeed() => getSeedLegacy(null);

String getSeedLegacy(String? language) {
  final cakepassphrase = getPassphrase();
  var legacy = nerva.Wallet_seed(wptr!, seedOffset: cakepassphrase);
  switch (language) {
    case "Chinese (Traditional)": language = "Chinese (simplified)"; break;
    case "Chinese (Simplified)": language = "Chinese (simplified)"; break;
    case "Korean": language = "English"; break;
    case "Czech": language = "English"; break;
    case "Japanese": language = "English"; break;
  }
  if (nerva.Wallet_status(wptr!) != 0) {
    nerva.Wallet_setSeedLanguage(wptr!, language: language ?? "English");
    legacy = nerva.Wallet_seed(wptr!, seedOffset: cakepassphrase);
  }
  if (nerva.Wallet_status(wptr!) != 0) {
    final err = nerva.Wallet_errorString(wptr!);
    if (legacy.isNotEmpty) {
      return "$err\n\n$legacy";
    }
    return err;
  }
  return legacy;
}
Map<int, Map<int, Map<int, String>>> addressCache = {};

String getPassphrase() {
  return nerva.Wallet_getCacheAttribute(wptr!, key: "cakewallet.passphrase");
}

String getAddress({int accountIndex = 0, int addressIndex = 1}) {
  while (nerva.Wallet_numSubaddresses(wptr!, accountIndex: accountIndex)-1 < addressIndex) {
    printV("adding subaddress");
    nerva.Wallet_addSubaddress(wptr!, accountIndex: accountIndex);
  }
  addressCache[wptr!.address] ??= {};
  addressCache[wptr!.address]![accountIndex] ??= {};
  addressCache[wptr!.address]![accountIndex]![addressIndex] ??= nerva.Wallet_address(wptr!,
        accountIndex: accountIndex, addressIndex: addressIndex);
  return addressCache[wptr!.address]![accountIndex]![addressIndex]!;
}

int getFullBalance({int accountIndex = 0}) {
  if (wptr == null) return 0;
  return nerva.Wallet_balance(wptr!, accountIndex: accountIndex);
}
int getUnlockedBalance({int accountIndex = 0}) {
  if (wptr == null) return 0;
  return nerva.Wallet_unlockedBalance(wptr!, accountIndex: accountIndex);
}
int getCurrentHeight() {
  if (wptr == null) return 0;
  return nerva.Wallet_blockChainHeight(wptr!);
}

int cachedNodeHeight = 0;
int getNodeHeightSync() {
  if (wptr == null) return 0;
  (() async {
    final wptrAddress = wptr!.address;
    cachedNodeHeight = await Isolate.run(() async {
      return nerva.Wallet_daemonBlockChainHeight(Pointer.fromAddress(wptrAddress));
    });
  })();
  return cachedNodeHeight;
}

bool isConnectedSync() {
  if (wptr == null) return false;
  return nerva.Wallet_connected(wptr!) != 0;
}

Future<bool> setupNodeSync(
    {required String address,
    String? login,
    String? password,
    bool useSSL = false,
    bool isLightWallet = false,
    String? socksProxyAddress}) async {
  printV('''
{
  wptr!,
  daemonAddress: $address,
  useSsl: $useSSL,
  proxyAddress: $socksProxyAddress ?? '',
  daemonUsername: $login ?? '',
  daemonPassword: $password ?? ''
}
''');
  final addr = wptr!.address;
  await Isolate.run(() {
    nerva.Wallet_init(Pointer.fromAddress(addr),
        daemonAddress: address,
        useSsl: useSSL,
        proxyAddress: socksProxyAddress ?? '',
        daemonUsername: login ?? '',
        daemonPassword: password ?? '');
  });
  // nerva.Wallet_init3(wptr!, argv0: '', defaultLogBaseName: 'nervac', console: true);

  final status = nerva.Wallet_status(wptr!);

  if (status != 0) {
    final error = nerva.Wallet_errorString(wptr!);
    printV("error: $error");
    throw SetupWalletException(message: error);
  }

  return status == 0;
}

void startRefreshSync() {
  // nerva.Wallet_refreshAsync(wptr!);
  nerva.Wallet_startRefresh(wptr!);
}

Future<bool> connectToNode() async {
  return true;
}

void setRefreshFromBlockHeight({required int height}) =>
    nerva.Wallet_setRefreshFromBlockHeight(wptr!,
        refresh_from_block_height: height);

void setRecoveringFromSeed({required bool isRecovery}) =>
    nerva.Wallet_setRecoveringFromSeed(wptr!, recoveringFromSeed: isRecovery);

final storeMutex = Mutex();

int lastStorePointer = 0;
int lastStoreHeight = 0;
void storeSync() async {
  final addr = wptr!.address;
  final synchronized = await Isolate.run(() {
    return nerva.Wallet_synchronized(Pointer.fromAddress(addr));
  });
  if (lastStorePointer == wptr!.address &&
      lastStoreHeight + 5000 < nerva.Wallet_blockChainHeight(wptr!) &&
      !synchronized) {
    return;
  }
  lastStorePointer = wptr!.address;
  lastStoreHeight = nerva.Wallet_blockChainHeight(wptr!);
  await storeMutex.acquire();
  Isolate.run(() {
    nerva.Wallet_store(Pointer.fromAddress(addr));
  });
  storeMutex.release();
}

void setPasswordSync(String password) {
  nerva.Wallet_setPassword(wptr!, password: password);

  final status = nerva.Wallet_status(wptr!);
  if (status != 0) {
    throw Exception(nerva.Wallet_errorString(wptr!));
  }
}

void closeCurrentWallet() {
  nerva.Wallet_stop(wptr!);
}

String getSecretViewKey() => nerva.Wallet_secretViewKey(wptr!);

String getPublicViewKey() => nerva.Wallet_publicViewKey(wptr!);

String getSecretSpendKey() => nerva.Wallet_secretSpendKey(wptr!);

String getPublicSpendKey() => nerva.Wallet_publicSpendKey(wptr!);

class SyncListener {
  SyncListener(this.onNewBlock, this.onNewTransaction)
      : _cachedBlockchainHeight = 0,
        _lastKnownBlockHeight = 0,
        _initialSyncHeight = 0;

  void Function(int, int, double) onNewBlock;
  void Function() onNewTransaction;

  Timer? _updateSyncInfoTimer;
  int _cachedBlockchainHeight;
  int _lastKnownBlockHeight;
  int _initialSyncHeight;

  Future<int> getNodeHeightOrUpdate(int baseHeight) async {
    if (_cachedBlockchainHeight < baseHeight || _cachedBlockchainHeight == 0) {
      _cachedBlockchainHeight = await getNodeHeight();
    }

    return _cachedBlockchainHeight;
  }

  void start() {
    _cachedBlockchainHeight = 0;
    _lastKnownBlockHeight = 0;
    _initialSyncHeight = 0;
    _updateSyncInfoTimer ??=
        Timer.periodic(Duration(milliseconds: 1200), (_) async {
      if (isNewTransactionExist()) {
        onNewTransaction();
      }

      var syncHeight = getSyncingHeight();

      if (syncHeight <= 0) {
        syncHeight = getCurrentHeight();
      }

      if (_initialSyncHeight <= 0) {
        _initialSyncHeight = syncHeight;
      }

      final bchHeight = await getNodeHeightOrUpdate(syncHeight);

      if (_lastKnownBlockHeight == syncHeight) {
        return;
      }

      _lastKnownBlockHeight = syncHeight;
      final track = bchHeight - _initialSyncHeight;
      final diff = track - (bchHeight - syncHeight);
      final ptc = diff <= 0 ? 0.0 : diff / track;
      final left = bchHeight - syncHeight;

      if (syncHeight < 0 || left < 0) {
        return;
      }

      // 1. Actual new height; 2. Blocks left to finish; 3. Progress in percents;
      onNewBlock.call(syncHeight, left, ptc);
    });
  }

  void stop() => _updateSyncInfoTimer?.cancel();
}

SyncListener setListeners(void Function(int, int, double) onNewBlock,
    void Function() onNewTransaction) {
  final listener = SyncListener(onNewBlock, onNewTransaction);
  // setListenerNative();
  return listener;
}

void onStartup() {}

void _storeSync(Object _) => storeSync();

Future<bool> _setupNodeSync(Map<String, Object?> args) async {
  final address = args['address'] as String;
  final login = (args['login'] ?? '') as String;
  final password = (args['password'] ?? '') as String;
  final useSSL = args['useSSL'] as bool;
  final isLightWallet = args['isLightWallet'] as bool;
  final socksProxyAddress = (args['socksProxyAddress'] ?? '') as String;

  return setupNodeSync(
      address: address,
      login: login,
      password: password,
      useSSL: useSSL,
      isLightWallet: isLightWallet,
      socksProxyAddress: socksProxyAddress);
}

bool _isConnected(Object _) => isConnectedSync();

int _getNodeHeight(Object _) => getNodeHeightSync();

void startRefresh() => startRefreshSync();

Future<void> setupNode(
        {required String address,
        String? login,
        String? password,
        bool useSSL = false,
        String? socksProxyAddress,
        bool isLightWallet = false}) async =>
    _setupNodeSync({
      'address': address,
      'login': login,
      'password': password,
      'useSSL': useSSL,
      'isLightWallet': isLightWallet,
      'socksProxyAddress': socksProxyAddress
    });

Future<void> store() async => _storeSync(0);

Future<bool> isConnected() async => _isConnected(0);

Future<int> getNodeHeight() async => _getNodeHeight(0);

void rescanBlockchainAsync() => nerva.Wallet_rescanBlockchainAsync(wptr!);

String getSubaddressLabel(int accountIndex, int addressIndex) {
  return nerva.Wallet_getSubaddressLabel(wptr!,
      accountIndex: accountIndex, addressIndex: addressIndex);
}

Future setTrustedDaemon(bool trusted) async =>
    nerva.Wallet_setTrustedDaemon(wptr!, arg: trusted);

Future<bool> trustedDaemon() async => nerva.Wallet_trustedDaemon(wptr!);

String signMessage(String message, {String address = ""}) {
  return nerva.Wallet_signMessage(wptr!, message: message, address: address);
}

bool verifyMessage(String message, String address, String signature) {
  return nerva.Wallet_verifySignedMessage(wptr!, message: message, address: address, signature: signature);
}

Map<String, List<int>> debugCallLength() => nerva.debugCallLength;