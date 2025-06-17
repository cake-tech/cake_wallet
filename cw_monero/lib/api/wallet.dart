import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/exceptions/setup_wallet_exception.dart';
import 'package:monero/monero.dart' as monero;
import 'package:mutex/mutex.dart';
import 'package:polyseed/polyseed.dart';

bool debugMonero = false;

int getSyncingHeight() {
  // final height = monero.MONERO_cw_WalletListener_height(getWlptr());
  if (currentWallet == null) return 0;
  final h2 = currentWallet!.blockChainHeight();
  // printV("height: $height / $h2");
  return h2;
}

bool isNeededToRefresh() {
  final wl = getWlptr();
  if (wl == null) return false;
  final ret = wl.isNeedToRefresh();
  wl.resetNeedToRefresh();
  return ret;
}

bool isNewTransactionExist() {
  final wlptr = getWlptr();
  if (wlptr == null) return false;
  final ret = wlptr.isNewTransactionExist();
  wlptr.resetIsNewTransactionExist();
  return ret;
}

String getFilename() => currentWallet!.filename();

String getSeed() {
  // monero.Wallet_setCacheAttribute(wptr!, key: "cakewallet.seed", value: seed);
  final cakepolyseed =
      currentWallet!.getCacheAttribute(key: "cakewallet.seed");
  final cakepassphrase = getPassphrase();

  final weirdPolyseed = currentWallet!.getPolyseed(passphrase: cakepassphrase);
  if (weirdPolyseed != "") return weirdPolyseed;

  if (cakepolyseed != "") {
    if (cakepassphrase != "") {
      try {
        final lang = PolyseedLang.getByPhrase(cakepolyseed);
        final coin = PolyseedCoin.POLYSEED_MONERO;
        final ps = Polyseed.decode(cakepolyseed, lang, coin);
        if (ps.isEncrypted || cakepassphrase == "") return ps.encode(lang, coin);
        ps.crypt(cakepassphrase);
        return ps.encode(lang, coin);
      } catch (e) {
        printV(e);
      }
    }
    return cakepolyseed;
  }

  final bip39 = currentWallet!.getCacheAttribute(key: "cakewallet.seed.bip39");

  if(bip39.isNotEmpty) return bip39;

  final legacy = getSeedLegacy(null);
  return legacy;
}

String? getSeedLanguage(String? language) {
  switch (language) {
    case "Chinese (Traditional)": language = "Chinese (simplified)"; break;
    case "Chinese (Simplified)": language = "Chinese (simplified)"; break;
    case "Korean": language = "English"; break;
    case "Czech": language = "English"; break;
    case "Japanese": language = "English"; break;
  }
  return language;
}

String getSeedLegacy(String? language) {
  final cakepassphrase = getPassphrase();
  language = getSeedLanguage(language);
  var legacy = currentWallet!.seed(seedOffset: cakepassphrase);
  if (currentWallet!.status() != 0) {
    if (currentWallet!.errorString().contains("seed_language")) {
      currentWallet!.setSeedLanguage(language: "English");
      legacy = currentWallet!.seed(seedOffset: cakepassphrase);
    }
  }

  if (language != null) {
    currentWallet!.setSeedLanguage(language: language);
    final status = currentWallet!.status();
    if (status != 0) {
      final err = currentWallet!.errorString();
      if (legacy.isNotEmpty) {
        return "$err\n\n$legacy";
      }
      return err;
    }
    legacy = currentWallet!.seed(seedOffset: cakepassphrase);
  }

  if (currentWallet!.status() != 0) {
    final err = currentWallet!.errorString();
    if (legacy.isNotEmpty) {
      return "$err\n\n$legacy";
    }
    return err;
  }
  return legacy;
}

String getPassphrase() {
  return currentWallet!.getCacheAttribute(key: "cakewallet.passphrase");
}

Map<int, Map<int, Map<int, String>>> addressCache = {};

String getAddress({int accountIndex = 0, int addressIndex = 0}) {
  // printV("getaddress: ${accountIndex}/${addressIndex}: ${monero.Wallet_numSubaddresses(wptr!, accountIndex: accountIndex)}: ${monero.Wallet_address(wptr!, accountIndex: accountIndex, addressIndex: addressIndex)}");
  // this could be a while loop, but I'm in favor of making it if to not cause freezes
  if (currentWallet!.numSubaddresses(accountIndex: accountIndex)-1 < addressIndex) {
    if (currentWallet!.numSubaddressAccounts() < accountIndex) {
      currentWallet!.addSubaddressAccount();
    } else {
      currentWallet!.addSubaddress(accountIndex: accountIndex);
    }
  }
  addressCache[currentWallet!.ffiAddress()] ??= {};
  addressCache[currentWallet!.ffiAddress()]![accountIndex] ??= {};
  addressCache[currentWallet!.ffiAddress()]![accountIndex]![addressIndex] ??= currentWallet!.address(
        accountIndex: accountIndex, addressIndex: addressIndex);
  return addressCache[currentWallet!.ffiAddress()]![accountIndex]![addressIndex]!;
}

int getFullBalance({int accountIndex = 0}) =>
    currentWallet?.balance(accountIndex: accountIndex) ?? 0;

int getUnlockedBalance({int accountIndex = 0}) =>
    currentWallet?.unlockedBalance(accountIndex: accountIndex) ?? 0;

int getCurrentHeight() => currentWallet?.blockChainHeight() ?? 0;


int cachedNodeHeight = 0;
bool isHeightRefreshing = false;
int getNodeHeightSync() {
  if (isHeightRefreshing == false) {
    (() async {
      try {
        isHeightRefreshing = true;
        final wptrAddress = currentWallet!.ffiAddress();
        cachedNodeHeight = await Isolate.run(() async {
          return monero.Wallet_daemonBlockChainHeight(Pointer.fromAddress(wptrAddress));
        });
      } finally {
        isHeightRefreshing = false;
      }
    })();
  }
  return cachedNodeHeight;
}

bool isConnectedSync() => currentWallet?.connected() != 0;

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
  final addr = currentWallet!.ffiAddress();
  printV("init: start");
  await Isolate.run(() {
    monero.Wallet_init(Pointer.fromAddress(addr),
        daemonAddress: address,
        useSsl: useSSL,
        proxyAddress: socksProxyAddress ?? '',
        daemonUsername: login ?? '',
        daemonPassword: password ?? '');
  });
  printV("init: end");

  final status = currentWallet!.status();

  if (status != 0) {
    final error = currentWallet!.errorString();
    if (error != "no tx keys found for this txid") {
      printV("error: $error");
      throw SetupWalletException(message: error);
    }
  }

  if (true) {
    currentWallet!.init3(
      argv0: '',
      defaultLogBaseName: 'moneroc',
      console: true,
      logPath: '',
    );
  }

  return status == 0;
}

void startRefreshSync() {
  currentWallet!.startRefresh();
}


void setRefreshFromBlockHeight({required int height}) {
  currentWallet!.setRefreshFromBlockHeight(
    refresh_from_block_height: height);
}

void setRecoveringFromSeed({required bool isRecovery}) {
  currentWallet!.setRecoveringFromSeed(recoveringFromSeed: isRecovery);
  currentWallet!.store();
}

final storeMutex = Mutex();


int lastStorePointer = 0;
int lastStoreHeight = 0;
void storeSync({bool force = false}) async {
  final addr = currentWallet!.ffiAddress();
  final synchronized = await Isolate.run(() {
    return monero.Wallet_synchronized(Pointer.fromAddress(addr));
  });
  if (lastStorePointer == addr &&
      lastStoreHeight + 75000 > currentWallet!.blockChainHeight() &&
      !synchronized && 
      !force) {
    return;
  }
  lastStorePointer = currentWallet!.ffiAddress();
  lastStoreHeight = currentWallet!.blockChainHeight();
  await storeMutex.acquire();
  await Isolate.run(() {
    monero.Wallet_store(Pointer.fromAddress(addr));
  });
  storeMutex.release();
}

void setPasswordSync(String password) {
  currentWallet!.setPassword(password: password);

  final status = currentWallet!.status();
  if (status != 0) {
    throw Exception(currentWallet!.errorString());
  }
}

void closeCurrentWallet() {
  currentWallet!.stop();
}

String getSecretViewKey() => currentWallet!.secretViewKey();

String getPublicViewKey() => currentWallet!.publicViewKey();

String getSecretSpendKey() => currentWallet!.secretSpendKey();

String getPublicSpendKey() => currentWallet!.publicSpendKey();

class SyncListener {
  SyncListener(this.onNewBlock, this.onNewTransaction)
      : _cachedBlockchainHeight = 0,
        _lastKnownBlockHeight = 0,
        _initialSyncHeight = 0 {
          _start();
        }

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

  void _start() {
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
      // printV("syncHeight: $syncHeight, _lastKnownBlockHeight: $_lastKnownBlockHeight, bchHeight: $bchHeight");
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

void startRefresh() => startRefreshSync();

Future<void> store() async => _storeSync(0);

Future<bool> isConnected() async => isConnectedSync();

Future<int> getNodeHeight() async => getNodeHeightSync();

void rescanBlockchainAsync() => currentWallet!.rescanBlockchainAsync();

String getSubaddressLabel(int accountIndex, int addressIndex) {
  return currentWallet!.getSubaddressLabel(
      accountIndex: accountIndex, addressIndex: addressIndex);
}

Future setTrustedDaemon(bool trusted) async =>
    currentWallet!.setTrustedDaemon(arg: trusted);

Future<bool> trustedDaemon() async => currentWallet!.trustedDaemon();

String signMessage(String message, {String address = ""}) {
  return currentWallet!.signMessage(message: message, address: address);
}

bool verifyMessage(String message, String address, String signature) {
  return currentWallet!.verifySignedMessage(message: message, address: address, signature: signature);
}

Map<String, List<int>> debugCallLength() => monero.debugCallLength;
