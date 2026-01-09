import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/haven_seed_store.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/fs_migration.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_info_legacy.dart' as wiLegacy;
import 'package:cake_wallet/exchange/trade.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:collection/collection.dart';

const newCakeWalletMoneroUri = 'xmr-node.cakewallet.com:18081';
const cakeWalletBitcoinElectrumUri = 'electrum.cakewallet.com:50002';
const cakeWalletSilentPaymentsElectrsUri = 'electrs.cakewallet.com:50001';
const publicBitcoinTestnetElectrumAddress = 'electrs.cakewallet.com';
const publicBitcoinTestnetElectrumPort = '50002';
const publicBitcoinTestnetElectrumUri =
    '$publicBitcoinTestnetElectrumAddress:$publicBitcoinTestnetElectrumPort';
const cakeWalletLitecoinElectrumUri = 'ltc-electrum.cakewallet.com:50002';
const havenDefaultNodeUri = 'nodes.havenprotocol.org:443';
const ethereumDefaultNodeUri = 'ethereum-rpc.publicnode.com';
const polygonDefaultNodeUri = 'polygon-bor-rpc.publicnode.com';
const cakeWalletBitcoinCashDefaultNodeUri = 'bitcoincash.stackwallet.com:50002';
const nanoDefaultNodeUri = 'rpc.nano.to';
const nanoDefaultPowNodeUri = 'rpc.nano.to';
const solanaDefaultNodeUri = 'solana-mainnet.core.chainstack.com';
const tronDefaultNodeUri = 'api.trongrid.io';
const newCakeWalletBitcoinUri = 'btc-electrum.cakewallet.com:50002';
const wowneroDefaultNodeUri = 'node3.monerodevs.org:34568';
const zanoDefaultNodeUri = '37.27.100.59:10500';
const moneroWorldNodeUri = '.moneroworld.com';
const decredDefaultUri = "default-spv-nodes";
const dogecoinDefaultNodeUri = 'dogecoin.stackwallet.com:50022';
const baseDefaultNodeUri = 'base.nownodes.io';
const arbitrumDefaultNodeUri = 'arbitrum.nownodes.io';

Future<void> defaultSettingsMigration(
    {required int version,
    required SharedPreferences sharedPreferences,
    required SecureStorage secureStorage,
    required Box<Trade> tradeSource,
    required Box<Contact> contactSource,
    required Box<HavenSeedStore> havenSeedStore}) async {
  if (Platform.isIOS) {
    await ios_migrate_v1(tradeSource, contactSource);
  }

  // check current nodes for nullability regardless of the version
  await checkCurrentNodes(sharedPreferences);

  final isNewInstall =
      sharedPreferences.getInt(PreferencesKey.currentDefaultSettingsMigrationVersion) == null;

  await _validateWalletInfoBoxData();

  await sharedPreferences.setBool(PreferencesKey.isNewInstall, isNewInstall);

  final currentVersion =
      sharedPreferences.getInt(PreferencesKey.currentDefaultSettingsMigrationVersion) ?? 0;

  if (currentVersion >= version) {
    return;
  }

  final migrationVersionsLength = version - currentVersion;
  final migrationVersions =
      List<int>.generate(migrationVersionsLength, (i) => currentVersion + (i + 1));

  /// When you add a new case, increase the initialMigrationVersion parameter in the main.dart file.
  /// This ensures that this switch case runs the newly added case.
  await Future.forEach(migrationVersions, (int version) async {
    try {
      switch (version) {
        case 1:
          await sharedPreferences.setString(
              PreferencesKey.currentFiatCurrencyKey, FiatCurrency.usd.toString());
          await sharedPreferences.setInt(PreferencesKey.currentTransactionPriorityKeyLegacy,
              monero!.getDefaultTransactionPriority().raw);
          await sharedPreferences.setInt(
              PreferencesKey.currentBalanceDisplayModeKey, BalanceDisplayMode.availableBalance.raw);
          await sharedPreferences.setBool('save_recipient_address', true);
          await resetToDefault();

          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.monero,
            currentNodePreferenceKey: PreferencesKey.currentNodeIdKey,
            useSSL: true,
            trusted: true,
          );
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.bitcoin,
            currentNodePreferenceKey: PreferencesKey.currentBitcoinElectrumSererIdKey,
            useSSL: true,
          );
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.litecoin,
            currentNodePreferenceKey: PreferencesKey.currentLitecoinElectrumSererIdKey,
            useSSL: true,
          );
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.haven,
            currentNodePreferenceKey: PreferencesKey.currentHavenNodeIdKey,
          );
          break;
        case 2:
          await replaceNodesMigration();
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.monero,
            newDefaultUri: newCakeWalletMoneroUri,
            currentNodePreferenceKey: PreferencesKey.currentNodeIdKey,
            useSSL: true,
            trusted: true,
            oldUri: [
              'xmr-node-uk.cakewallet.com:18081',
              'eu-node.cakewallet.io:18081',
              'node.cakewallet.io:18081'
            ],
          );
          break;
        case 3:
          await updateNodeTypes();
          await addWalletNodeList(type: WalletType.bitcoin);

          break;
        case 4:
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.bitcoin,
            newDefaultUri: newCakeWalletBitcoinUri,
            currentNodePreferenceKey: PreferencesKey.currentBitcoinElectrumSererIdKey,
            useSSL: true,
          );
          break;

        case 5:
          await addAddressesForMoneroWallets();
          break;

        case 6:
          await updateDisplayModes(sharedPreferences);
          break;

        case 9:
          await generateBackupPassword(secureStorage);
          break;

        case 10:
          await changeTransactionPriorityAndFeeRateKeys(sharedPreferences);
          break;

        case 11:
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.monero,
            newDefaultUri: newCakeWalletMoneroUri,
            currentNodePreferenceKey: PreferencesKey.currentNodeIdKey,
            trusted: true,
            oldUri: ['.cakewallet.com'],
          );
          break;

        case 12:
          await checkCurrentNodes(sharedPreferences);
          break;

        case 13:
          await resetBitcoinElectrumServer(sharedPreferences);
          break;

        case 15:
          await addWalletNodeList(type: WalletType.litecoin);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.litecoin,
            currentNodePreferenceKey: PreferencesKey.currentLitecoinElectrumSererIdKey,
          );
          await checkCurrentNodes(sharedPreferences);
          break;

        case 16:
          await addWalletNodeList(type: WalletType.haven);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.haven,
            currentNodePreferenceKey: PreferencesKey.currentHavenNodeIdKey,
          );
          await checkCurrentNodes(sharedPreferences);
          break;

        case 17:
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.haven,
            currentNodePreferenceKey: PreferencesKey.currentHavenNodeIdKey,
          );
          break;

        case 18:
          addWalletNodeList(type: WalletType.monero);
          break;

        case 19:
          await validateBitcoinSavedTransactionPriority(sharedPreferences);
          break;
        case 20:
          await migrateExchangeStatus(sharedPreferences);
          break;
        case 21:
          await addWalletNodeList(type: WalletType.ethereum);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.ethereum,
            currentNodePreferenceKey: PreferencesKey.currentEthereumNodeIdKey,
          );
          break;
        case 22:
          await addWalletNodeList(type: WalletType.nano);
          await addNanoPowNodeList();
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.nano,
            currentNodePreferenceKey: PreferencesKey.currentNanoNodeIdKey,
          );
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.nano,
            currentNodePreferenceKey: PreferencesKey.currentNanoPowNodeIdKey,
            newDefaultUri: nanoDefaultPowNodeUri,
          );
          break;
        case 23:
          await addWalletNodeList(type: WalletType.bitcoinCash);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.bitcoinCash,
            currentNodePreferenceKey: PreferencesKey.currentBitcoinCashNodeIdKey,
          );
          break;
        case 24:
          await addWalletNodeList(type: WalletType.polygon);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.polygon,
            currentNodePreferenceKey: PreferencesKey.currentPolygonNodeIdKey,
          );
          break;
        case 25:
          await rewriteSecureStoragePin(secureStorage: secureStorage);
          break;
        case 26:

          /// commented out as it was a probable cause for some users to have white screen issues
          /// maybe due to multiple access on Secure Storage at once
          /// or long await time on start of the app
          // await insecureStorageMigration(secureStorage: secureStorage, sharedPreferences: sharedPreferences);
          break;
        case 27:
          await addWalletNodeList( type: WalletType.solana);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.solana,
            currentNodePreferenceKey: PreferencesKey.currentSolanaNodeIdKey,
          );
          break;

        case 28:
          await _updateMoneroPriority(sharedPreferences);
          break;
        case 29:
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.bitcoin,
            newDefaultUri: newCakeWalletBitcoinUri,
            currentNodePreferenceKey: PreferencesKey.currentBitcoinElectrumSererIdKey,
            useSSL: true,
            oldUri: ['.cakewallet.com'],
          );
          break;
        case 30:
          await disableServiceStatusFiatDisabled(sharedPreferences);
          break;
        case 31:
          await updateNanoNodeList();
          break;
        case 32:
          await updateBtcNanoWalletInfos();
          break;
        case 33:
          await addWalletNodeList(type: WalletType.tron);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.tron,
            currentNodePreferenceKey: PreferencesKey.currentTronNodeIdKey,
          );
          break;
        case 34:
          addWalletNodeList(type: WalletType.bitcoin);
        case 35:
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.bitcoin,
            newDefaultUri: newCakeWalletBitcoinUri,
            currentNodePreferenceKey: PreferencesKey.currentBitcoinElectrumSererIdKey,
            useSSL: true,
            oldUri: ['electrs.cakewallet.com'],
          );
          break;
        case 36:
          await addWalletNodeList(type: WalletType.wownero);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.wownero,
            currentNodePreferenceKey: PreferencesKey.currentWowneroNodeIdKey,
          );
          break;
        case 37:
          // removed as it would be replaced again anyway
          // await replaceTronDefaultNode(sharedPreferences: sharedPreferences, nodes: nodes);
          break;
        case 38:
          await fixBtcDerivationPaths();
          break;
        case 39:
          _fixNodesUseSSLFlag();
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.nano,
            newDefaultUri: nanoDefaultNodeUri,
            currentNodePreferenceKey: PreferencesKey.currentNanoNodeIdKey,
            useSSL: true,
            oldUri: ['rpc.nano.to'],
          );
          break;
        case 40:
          await removeMoneroWorld(sharedPreferences: sharedPreferences);
          break;
        case 41:
          _changeExchangeProviderAvailability(
            sharedPreferences,
            providerName: "SwapTrade",
            enabled: false,
          );
          addWalletNodeList(type: WalletType.bitcoin);
          addWalletNodeList(type: WalletType.tron);
          break;
        case 42:
          _fixNodesUseSSLFlag();
          break;
        case 43:
          _fixNodesUseSSLFlag();
          _changeExchangeProviderAvailability(
            sharedPreferences,
            providerName: "THORChain",
            enabled: false,
          );
          _changeExchangeProviderAvailability(
            sharedPreferences,
            providerName: "SimpleSwap",
            enabled: false,
          );
          break;
        case 44:
          _fixNodesUseSSLFlag();
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.bitcoin,
            newDefaultUri: newCakeWalletBitcoinUri,
            currentNodePreferenceKey: PreferencesKey.currentBitcoinElectrumSererIdKey,
            useSSL: true,
            oldUri: ['cakewallet.com'],
          );
          _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.tron,
            newDefaultUri: tronDefaultNodeUri,
            currentNodePreferenceKey: PreferencesKey.currentTronNodeIdKey,
            useSSL: true,
            oldUri: [
              'tron-rpc.publicnode.com:443',
              'api.trongrid.io',
            ],
          );
          break;
        case 45:
          // await _backupHavenSeeds(havenSeedStore);

          addWalletNodeList(type: WalletType.polygon);
          addWalletNodeList(type: WalletType.ethereum);
          _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.tron,
            newDefaultUri: tronDefaultNodeUri,
            currentNodePreferenceKey: PreferencesKey.currentTronNodeIdKey,
            useSSL: true,
            oldUri: [
              'tron-rpc.publicnode.com:443',
              'trx.nownodes.io',
            ],
          );
          _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.solana,
            newDefaultUri: solanaDefaultNodeUri,
            currentNodePreferenceKey: PreferencesKey.currentSolanaNodeIdKey,
            useSSL: true,
            oldUri: ['rpc.ankr.com'],
          );
          break;
        case 46:
          await _fixNodesUseSSLFlag();
          await addWalletNodeList(type: WalletType.litecoin);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.solana,
            newDefaultUri: solanaDefaultNodeUri,
            currentNodePreferenceKey: PreferencesKey.currentSolanaNodeIdKey,
            useSSL: true,
            oldUri: [
              'rpc.ankr.com',
              'api.mainnet-beta.solana.com:443',
              'solana-rpc.publicnode.com:443',
            ],
          );
          await _updateNode(
            currentUri: "ethereum.publicnode.com",
            newUri: "ethereum-rpc.publicnode.com",
            useSSL: true,
          );
          await _updateNode(
            currentUri: "polygon-bor.publicnode.com",
            newUri: "polygon-bor-rpc.publicnode.com",
            useSSL: true,
          );
        case 47:
          await addWalletNodeList(type: WalletType.zano);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.zano,
            currentNodePreferenceKey: PreferencesKey.currentZanoNodeIdKey,
          );
          _changeExchangeProviderAvailability(
            sharedPreferences,
            providerName: "SimpleSwap",
            enabled: true,
          );
          _changeExchangeProviderAvailability(
            sharedPreferences,
            providerName: "SwapTrade",
            enabled: false,
          );
          break;
        case 48:
          await addWalletNodeList(type: WalletType.decred);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.decred,
            currentNodePreferenceKey: PreferencesKey.currentDecredNodeIdKey,
          );
          break;
        case 49:
          _changeExchangeProviderAvailability(
            sharedPreferences,
            providerName: "SwapTrade",
            enabled: true,
          );
          break;
        case 50:
          migrateExistingNodesToUseAutoSwitching();
          break;
        case 51:
          _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.zano,
            currentNodePreferenceKey: PreferencesKey.currentZanoNodeIdKey,
          );
          await addWalletNodeList(type: WalletType.dogecoin);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.dogecoin,
            currentNodePreferenceKey: PreferencesKey.currentDogecoinNodeIdKey,
          );
          break;
        case 52:
          await addWalletNodeList(type: WalletType.base);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.base,
            currentNodePreferenceKey: PreferencesKey.currentBaseNodeIdKey,
          );
          break;
         case 53:
          await addWalletNodeList(type: WalletType.arbitrum);
          await _changeDefaultNode(
            sharedPreferences: sharedPreferences,
            type: WalletType.arbitrum,
            currentNodePreferenceKey: PreferencesKey.currentArbitrumNodeIdKey,
          );
          break;
         case 54:
          await _backupWowneroSeeds(havenSeedStore);
          break;

        default:
          break;
      }

      await sharedPreferences.setInt(
          PreferencesKey.currentDefaultSettingsMigrationVersion, version);
    } catch (e, s) {
      printV('Migration error: ${e.toString()}');
      printV('Migration error: ${s}');
    }
  });

  await sharedPreferences.setInt(PreferencesKey.currentDefaultSettingsMigrationVersion, version);
}

Future<void> _updateNode({
  required String currentUri,
  String? newUri,
  bool? useSSL,
}) async {
  final nodes = await Node.getAll();

  for (Node node in nodes) {
    if (node.uriRaw == currentUri) {
      if (newUri != null) {
        node.uriRaw = newUri;
      }
      if (useSSL != null) {
        node.useSSL = useSSL;
      }
      await node.save();
    }
  }
}

/// generic function for changing any wallet default node
/// instead of making a new function for each change
Future<void> _changeDefaultNode({
  required SharedPreferences sharedPreferences,
  required WalletType type,
  required String currentNodePreferenceKey,
  bool useSSL = true,
  bool trusted = false,
  String? newDefaultUri, // ignore, if you want to use the default node uri
  List<String>?
      oldUri, // ignore, if you want to force replace the node regardless of the user's current node
}) async {
  List<Node> nodes = await Node.getAll();

  final currentNodeId = sharedPreferences.getInt(currentNodePreferenceKey);
  final bool shouldReplace;
  if (currentNodeId == null) {
    shouldReplace = true;
  } else {
    final currentNode = nodes.firstWhere((node) => node.id == currentNodeId);
    shouldReplace = oldUri?.any((e) => currentNode.uriRaw.contains(e)) ?? true;
  }

  if (shouldReplace) {
    newDefaultUri ??= _getDefaultNodeUri(type);
    var newNodeId =
        nodes.firstWhereOrNull((element) => element.uriRaw == newDefaultUri)?.id;

    // new node doesn't exist, then add it
    if (newNodeId == null) {
      final newNode = Node(
        uri: newDefaultUri,
        type: type,
        useSSL: useSSL,
        trusted: trusted,
      );

      await newNode.save();
      newNodeId = newNode.id;
    }

    await sharedPreferences.setInt(currentNodePreferenceKey, newNodeId);
  }
}

String _getDefaultNodeUri(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return newCakeWalletMoneroUri;
    case WalletType.bitcoin:
      return newCakeWalletBitcoinUri;
    case WalletType.litecoin:
      return cakeWalletLitecoinElectrumUri;
    case WalletType.haven:
      return havenDefaultNodeUri;
    case WalletType.ethereum:
      return ethereumDefaultNodeUri;
    case WalletType.nano:
      return nanoDefaultNodeUri;
    case WalletType.bitcoinCash:
      return cakeWalletBitcoinCashDefaultNodeUri;
    case WalletType.polygon:
      return polygonDefaultNodeUri;
    case WalletType.solana:
      return solanaDefaultNodeUri;
    case WalletType.tron:
      return tronDefaultNodeUri;
    case WalletType.wownero:
      return wowneroDefaultNodeUri;
    case WalletType.zano:
      return zanoDefaultNodeUri;
    case WalletType.decred:
      return decredDefaultUri;
    case WalletType.dogecoin:
      return dogecoinDefaultNodeUri;
    case WalletType.base:
      return baseDefaultNodeUri;
    case WalletType.arbitrum:
      return arbitrumDefaultNodeUri;
    case WalletType.banano:
    case WalletType.none:
      return '';
  }
}

void _changeExchangeProviderAvailability(SharedPreferences sharedPreferences,
    {required String providerName, required bool enabled}) {
  final Map<String, dynamic> exchangeProvidersSelection =
      json.decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
          as Map<String, dynamic>;

  exchangeProvidersSelection[providerName] = enabled;

  sharedPreferences.setString(
    PreferencesKey.exchangeProvidersSelection,
    json.encode(exchangeProvidersSelection),
  );
}

Future<void> _fixNodesUseSSLFlag() async {
  final nodes = await Node.getAll();
  for (Node node in nodes) {
    switch (node.uriRaw) {
      case cakeWalletLitecoinElectrumUri:
      case cakeWalletBitcoinElectrumUri:
      case newCakeWalletBitcoinUri:
      case newCakeWalletMoneroUri:
        node.useSSL = true;
        node.trusted = true;
        await node.save();
    }
  }
}

Future<void> updateNanoNodeList() async {
  final nodes = await Node.getAll();
  final nodeList = await loadDefaultNodes(WalletType.nano);
  var listOfNewEndpoints = <String>[
    "app.natrium.io",
    "rainstorm.city",
    "node.somenano.com",
    "nanoslo.0x.no",
    "www.bitrequest.app",
  ];
  // add new nodes:
  for (final node in nodeList) {
    if (listOfNewEndpoints.contains(node.uriRaw) && !nodes.contains(node)) {
      await node.save();
    }
  }

  // update the nautilus node:
  final nautilusNode =
      nodes.firstWhereOrNull((element) => element.uriRaw == "node.perish.co");
  if (nautilusNode != null) {
    nautilusNode.uriRaw = "node.nautilus.io";
    nautilusNode.path = "/api";
    nautilusNode.useSSL = true;
    await nautilusNode.save();
  }
}

Future<void> disableServiceStatusFiatDisabled(SharedPreferences sharedPreferences) async {
  final currentFiat = await sharedPreferences.getInt(PreferencesKey.currentFiatApiModeKey) ?? -1;
  if (currentFiat == -1 || currentFiat == FiatApiMode.enabled.raw) {
    return;
  }

  if (currentFiat == FiatApiMode.disabled.raw || currentFiat == FiatApiMode.torOnly.raw) {
    await sharedPreferences.setBool(PreferencesKey.disableBulletinKey, true);
  }
}

Future<void> _backupWowneroSeeds(Box<HavenSeedStore> havenSeedStore) async {
  final future = wownero?.backupSeeds(havenSeedStore);
  if (future != null) await future;
  return;
}

Future<void> _updateMoneroPriority(SharedPreferences sharedPreferences) async {
  final currentPriority =
      await sharedPreferences.getInt(PreferencesKey.moneroTransactionPriority) ??
          monero!.getDefaultTransactionPriority().serialize();

  // was set to automatic but automatic should be 0
  if (currentPriority == 1) {
    sharedPreferences.setInt(PreferencesKey.moneroTransactionPriority,
        monero!.getDefaultTransactionPriority().serialize()); // 0
  }
}

Future<void> _validateWalletInfoBoxData() async {
  try {
    final root = await getAppDir();

    for (var type in WalletType.values) {
      if (type == WalletType.none) {
        continue;
      }

      String prefix = walletTypeToString(type).toLowerCase();
      Directory walletsDir = Directory('${root.path}/wallets/$prefix/');

      if (!walletsDir.existsSync()) {
        continue;
      }

      List<String> walletNames = walletsDir.listSync().map((e) => e.path.split("/").last).toList();

      for (var name in walletNames) {
        final Directory dir;
        try {
          dir = Directory(await pathForWalletDir(name: name, type: type));
        } catch (_) {
          continue;
        }

        final walletFiles = dir.listSync();
        final hasCacheFile = walletFiles.any((element) => element.path.contains("$name/$name"));

        if (!hasCacheFile) {
          continue;
        }

        if (type == WalletType.monero || type == WalletType.haven) {
          final hasKeysFile = walletFiles.any((element) => element.path.contains(".keys"));

          if (!hasKeysFile) {
            continue;
          }
        }

        final id = prefix + '_' + name;
        final exist = (await WalletInfo.getAll()).any((el) => el.id == id);

        if (exist) {
          continue;
        }

        final walletInfo = WalletInfo.external(
          id: id,
          type: type,
          name: name,
          isRecovery: true,
          restoreHeight: 0,
          date: DateTime.now(),
          dirPath: dir.path,
          path: '${dir.path}/$name',
          address: '',
          showIntroCakePayCard: false,
        );

        await walletInfo.save();
      }
    }
  } catch (_) {}
}

Future<void> validateBitcoinSavedTransactionPriority(SharedPreferences sharedPreferences) async {
  if (bitcoin == null) {
    return;
  }
  final int? savedBitcoinPriority =
      sharedPreferences.getInt(PreferencesKey.bitcoinTransactionPriority);
  if (!bitcoin!.getTransactionPriorities().any((element) => element.raw == savedBitcoinPriority)) {
    await sharedPreferences.setInt(PreferencesKey.bitcoinTransactionPriority,
        bitcoin!.getMediumTransactionPriority().serialize());
  }
}

Future<void> replaceNodesMigration() async {
  final replaceNodes = <String, Node>{
    'eu-node.cakewallet.io:18081':
    Node(uri: 'xmr-node-eu.cakewallet.com:18081', type: WalletType.monero),
    'node.cakewallet.io:18081':
    Node(uri: 'xmr-node-usa-east.cakewallet.com:18081', type: WalletType.monero),
    'node.xmr.ru:13666': Node(uri: 'node.monero.net:18081', type: WalletType.monero)
  };

  List<Node> nodes = await Node.getAll();
  nodes.forEach((Node node) async {
    final nodeToReplace = replaceNodes[node.uri];

    if (nodeToReplace != null) {
      node.uriRaw = nodeToReplace.uriRaw;
      node.login = nodeToReplace.login;
      node.password = nodeToReplace.password;
      await node.save();
    }
  });
}

Future<Node?> getBitcoinTestnetDefaultElectrumServer()async {
  final nodes = await Node.getAll();

  return nodes
          .firstWhereOrNull((Node node) => node.uriRaw == publicBitcoinTestnetElectrumUri) ??
      nodes.firstWhereOrNull((node) => node.type == WalletType.bitcoin);
}

Future<Node?> getDefaultNode({required WalletType type}) async {
  final nodes = await Node.getAll();
  final defaultUri = _getDefaultNodeUri(type);
  return nodes.firstWhereOrNull((Node node) => node.uriRaw == defaultUri) ??
      nodes.firstWhereOrNull((node) => node.type == type);
}

Future<void> insecureStorageMigration({
  required SharedPreferences sharedPreferences,
  required SecureStorage secureStorage,
}) async {
  bool? allowBiometricalAuthentication =
      sharedPreferences.getBool(SecureKey.allowBiometricalAuthenticationKey);
  bool? useTOTP2FA = sharedPreferences.getBool(SecureKey.useTOTP2FA);
  bool? shouldRequireTOTP2FAForAccessingWallet =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForAccessingWallet);
  bool? shouldRequireTOTP2FAForSendsToContact =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForSendsToContact);
  bool? shouldRequireTOTP2FAForSendsToNonContact =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForSendsToNonContact);
  bool? shouldRequireTOTP2FAForSendsToInternalWallets =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForSendsToInternalWallets);
  bool? shouldRequireTOTP2FAForExchangesToInternalWallets =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForExchangesToInternalWallets);
  bool? shouldRequireTOTP2FAForExchangesToExternalWallets =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForExchangesToExternalWallets);
  bool? shouldRequireTOTP2FAForAddingContacts =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForAddingContacts);
  bool? shouldRequireTOTP2FAForCreatingNewWallets =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForCreatingNewWallets);
  bool? shouldRequireTOTP2FAForAllSecurityAndBackupSettings =
      sharedPreferences.getBool(SecureKey.shouldRequireTOTP2FAForAllSecurityAndBackupSettings);
  int? selectedCake2FAPreset = sharedPreferences.getInt(SecureKey.selectedCake2FAPreset);
  String? totpSecretKey = sharedPreferences.getString(SecureKey.totpSecretKey);
  int? pinTimeOutDuration = sharedPreferences.getInt(SecureKey.pinTimeOutDuration);
  int? lastAuthTimeMilliseconds = sharedPreferences.getInt(SecureKey.lastAuthTimeMilliseconds);

  try {
    await secureStorage.write(
        key: SecureKey.allowBiometricalAuthenticationKey,
        value: allowBiometricalAuthentication.toString());
    await secureStorage.write(key: SecureKey.useTOTP2FA, value: useTOTP2FA.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForAccessingWallet,
        value: shouldRequireTOTP2FAForAccessingWallet.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForSendsToContact,
        value: shouldRequireTOTP2FAForSendsToContact.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForSendsToNonContact,
        value: shouldRequireTOTP2FAForSendsToNonContact.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForSendsToInternalWallets,
        value: shouldRequireTOTP2FAForSendsToInternalWallets.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForExchangesToInternalWallets,
        value: shouldRequireTOTP2FAForExchangesToInternalWallets.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForExchangesToExternalWallets,
        value: shouldRequireTOTP2FAForExchangesToExternalWallets.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForAddingContacts,
        value: shouldRequireTOTP2FAForAddingContacts.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForCreatingNewWallets,
        value: shouldRequireTOTP2FAForCreatingNewWallets.toString());
    await secureStorage.write(
        key: SecureKey.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
        value: shouldRequireTOTP2FAForAllSecurityAndBackupSettings.toString());
    await secureStorage.write(
        key: SecureKey.selectedCake2FAPreset, value: selectedCake2FAPreset.toString());
    await secureStorage.write(key: SecureKey.totpSecretKey, value: totpSecretKey.toString());
    await secureStorage.write(
        key: SecureKey.pinTimeOutDuration, value: pinTimeOutDuration.toString());
    await secureStorage.write(
        key: SecureKey.lastAuthTimeMilliseconds, value: lastAuthTimeMilliseconds.toString());
  } catch (e) {
    printV("Error migrating shared preferences to secure storage!: $e");
    // this actually shouldn't be that big of a problem since we don't delete the old keys in this update
    // and we read and write to the new locations when loading storage, the migration is just for extra safety
  }
}

Future<void> rewriteSecureStoragePin({required SecureStorage secureStorage}) async {
  // the bug only affects ios/mac:
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  // first, get the encoded pin:
  final keyForPinCode = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
  String? encodedPin;
  try {
    encodedPin = await secureStorage.read(key: keyForPinCode);
  } catch (e) {
    // either we don't have a pin, or we can't read it (maybe even because of the bug!)
    // the only option here is to abort the migration or we risk losing the pin and locking the user out
    return;
  }

  if (encodedPin == null) {
    return;
  }

  // ensure we overwrite by deleting the old key first:
  await secureStorage.delete(key: keyForPinCode);
  await secureStorage.write(
    key: keyForPinCode,
    value: encodedPin,
    // TODO: find a way to add those with the generated secure storage
    // iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    // mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}

Future<void> updateNodeTypes() async {
  List<Node> nodes = await Node.getAll();
  nodes.forEach((node) async {
    if (node.type == null) {
      node.type = WalletType.monero;
      await node.save();
    }
  });
}

Future<void> addAddressesForMoneroWallets() async {
  final moneroWalletsInfo = (await WalletInfo.getAll()).where((info) => info.type == WalletType.monero);
  moneroWalletsInfo.forEach((info) async {
    try {
      final walletPath = await pathForWallet(name: info.name, type: WalletType.monero);
      final addressFilePath = '$walletPath.address.txt';
      final addressFile = File(addressFilePath);

      if (!addressFile.existsSync()) {
        return;
      }

      final addressText = await addressFile.readAsString();
      info.address = addressText;
      await info.save();
    } catch (e) {
      printV(e.toString());
    }
  });
}

Future<void> updateDisplayModes(SharedPreferences sharedPreferences) async {
  final currentBalanceDisplayMode =
      sharedPreferences.getInt(PreferencesKey.currentBalanceDisplayModeKey) ?? -1;
  final balanceDisplayMode = currentBalanceDisplayMode < 2 ? 3 : 2;
  await sharedPreferences.setInt(PreferencesKey.currentBalanceDisplayModeKey, balanceDisplayMode);
}

Future<void> generateBackupPassword(SecureStorage secureStorage) async {
  final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);

  if ((await secureStorage.read(key: key))?.isNotEmpty ?? false) {
    return;
  }

  final password = encrypt.Key.fromSecureRandom(32).base16;
  await secureStorage.delete(key: key);
  await secureStorage.write(key: key, value: password);
}

Future<void> changeTransactionPriorityAndFeeRateKeys(SharedPreferences sharedPreferences) async {
  final legacyTransactionPriority =
      sharedPreferences.getInt(PreferencesKey.currentTransactionPriorityKeyLegacy)!;
  await sharedPreferences.setInt(
      PreferencesKey.moneroTransactionPriority, legacyTransactionPriority);
  await sharedPreferences.setInt(PreferencesKey.bitcoinTransactionPriority,
      bitcoin!.getMediumTransactionPriority().serialize());
}

Future<void> fixBtcDerivationPaths() async {
  for (WalletInfo walletInfo in await WalletInfo.getAll()) {
    if (walletInfo.type == WalletType.bitcoin ||
        walletInfo.type == WalletType.bitcoinCash ||
        walletInfo.type == WalletType.litecoin) {
      final derivationInfo = await walletInfo.getDerivationInfo();
      if (derivationInfo?.derivationPath == "m/0'/0") {
        derivationInfo!.derivationPath = "m/0'";
        await walletInfo.save();
      }
    }
  }
}
Future<void> updateBtcNanoWalletInfos() async {}
// Future<void> updateBtcNanoWalletInfos() async {
//   for (WalletInfo walletInfo in await WalletInfo.getAll()) {
//     if (walletInfo.type == WalletType.nano || walletInfo.type == WalletType.bitcoin) {
//       final derivationInfo = await walletInfo.getDerivationInfo();
//       derivationInfo = DerivationInfo(
//         derivationPath: derivationInfo?.derivationPath,
//         derivationType: derivationInfo?.derivationType,
//         address: walletInfo.address,
//         transactionsCount: walletInfo.restoreHeight,
//       );
//       await walletInfo.save();
//     }
//   }
// }

Future<void> checkCurrentNodes(
    SharedPreferences sharedPreferences) async {
  final currentMoneroNodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentBitcoinElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
  final currentLitecoinElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentLitecoinElectrumSererIdKey);
  final currentHavenNodeId = sharedPreferences.getInt(PreferencesKey.currentHavenNodeIdKey);
  final currentEthereumNodeId = sharedPreferences.getInt(PreferencesKey.currentEthereumNodeIdKey);
  final currentPolygonNodeId = sharedPreferences.getInt(PreferencesKey.currentPolygonNodeIdKey);
  final currentBaseNodeId = sharedPreferences.getInt(PreferencesKey.currentBaseNodeIdKey);
  final currentArbitrumNodeId = sharedPreferences.getInt(PreferencesKey.currentArbitrumNodeIdKey);
  final currentNanoNodeId = sharedPreferences.getInt(PreferencesKey.currentNanoNodeIdKey);
  final currentNanoPowNodeId = sharedPreferences.getInt(PreferencesKey.currentNanoPowNodeIdKey);
  final currentDecredNodeId = sharedPreferences.getInt(PreferencesKey.currentDecredNodeIdKey);
  final currentBitcoinCashNodeId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinCashNodeIdKey);
  final currentDogecoinNodeId =
  sharedPreferences.getInt(PreferencesKey.currentDogecoinNodeIdKey);
  final currentSolanaNodeId = sharedPreferences.getInt(PreferencesKey.currentSolanaNodeIdKey);
  final currentTronNodeId = sharedPreferences.getInt(PreferencesKey.currentTronNodeIdKey);
  final currentWowneroNodeId = sharedPreferences.getInt(PreferencesKey.currentWowneroNodeIdKey);
  final currentZanoNodeId = sharedPreferences.getInt(PreferencesKey.currentZanoNodeIdKey);
  List<Node> nodeSource = await Node.getAll();
  List<Node> powNodeSource = await Node.getAllPow();

  final currentMoneroNode =
      nodeSource.firstWhereOrNull((node) => node.id == currentMoneroNodeId);
  final currentBitcoinElectrumServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentBitcoinElectrumSeverId);
  final currentLitecoinElectrumServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentLitecoinElectrumSeverId);
  final currentHavenNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentHavenNodeId);
  final currentEthereumNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentEthereumNodeId);
  final currentPolygonNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentPolygonNodeId);
  final currentBaseNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentBaseNodeId);
  final currentArbitrumNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentArbitrumNodeId);
  final currentNanoNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentNanoNodeId);
  final currentDecredNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentDecredNodeId);
  final currentNanoPowNodeServer =
      powNodeSource.firstWhereOrNull((node) => node.id == currentNanoPowNodeId);
  final currentBitcoinCashNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentBitcoinCashNodeId);
  final currentDogecoinNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentDogecoinNodeId);
  final currentSolanaNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentSolanaNodeId);
  final currentTronNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentTronNodeId);
  final currentWowneroNodeServer =
      nodeSource.firstWhereOrNull((node) => node.id == currentWowneroNodeId);
  final currentZanoNode =
      nodeSource.firstWhereOrNull((node) => node.id == currentZanoNodeId);

  if (currentMoneroNode == null) {
    final newCakeWalletNode = Node(uri: newCakeWalletMoneroUri, type: WalletType.monero);
    await newCakeWalletNode.save();
    await sharedPreferences.setInt(PreferencesKey.currentNodeIdKey, newCakeWalletNode.id);
  }

  if (currentBitcoinElectrumServer == null) {
    final cakeWalletElectrum =
    Node(uri: cakeWalletBitcoinElectrumUri, type: WalletType.bitcoin, useSSL: false, isEnabledForAutoSwitching: true);
    await cakeWalletElectrum.save();
    final cakeWalletElectrumTestnet =
    Node(uri: publicBitcoinTestnetElectrumUri, type: WalletType.bitcoin, useSSL: false);
    await cakeWalletElectrumTestnet.save();
    await sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey, cakeWalletElectrum.id);
  }

  if (currentLitecoinElectrumServer == null) {
    final cakeWalletElectrum =
    Node(uri: cakeWalletLitecoinElectrumUri, type: WalletType.litecoin, useSSL: false);
    await cakeWalletElectrum.save();
    await sharedPreferences.setInt(
        PreferencesKey.currentLitecoinElectrumSererIdKey, cakeWalletElectrum.id);
  }

  if (currentHavenNodeServer == null) {
    final node = Node(uri: havenDefaultNodeUri, type: WalletType.haven);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentHavenNodeIdKey, node.id);
  }

  if (currentEthereumNodeServer == null) {
    final node = Node(uri: ethereumDefaultNodeUri, type: WalletType.ethereum);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentEthereumNodeIdKey, node.id);
  }

  if (currentNanoNodeServer == null) {
    final node = Node(uri: nanoDefaultNodeUri, useSSL: true, type: WalletType.nano);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentNanoNodeIdKey, node.id);
  }

  if (currentNanoPowNodeServer == null) {
    Node? node = powNodeSource
        .firstWhereOrNull((node) => node.uri.toString() == nanoDefaultPowNodeUri);
    if (node == null) {
      node = Node(uri: nanoDefaultPowNodeUri, useSSL: true, type: WalletType.nano, isPow:true);
      await node.save();
    }
    await sharedPreferences.setInt(PreferencesKey.currentNanoPowNodeIdKey, node.id);
  }

  if (currentBitcoinCashNodeServer == null) {
    final node =
    Node(uri: cakeWalletBitcoinCashDefaultNodeUri, type: WalletType.bitcoinCash, useSSL: false);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentBitcoinCashNodeIdKey, node.id);
  }

  if (currentDogecoinNodeServer == null) {
    final node = Node(uri: dogecoinDefaultNodeUri, type: WalletType.dogecoin, useSSL: true);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentDogecoinNodeIdKey, node.id);
  }

  if (currentPolygonNodeServer == null) {
    final node = Node(uri: polygonDefaultNodeUri, type: WalletType.polygon);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentPolygonNodeIdKey, node.id);
  }

  if (currentBaseNodeServer == null) {
    final node = Node(uri: baseDefaultNodeUri, type: WalletType.base);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentBaseNodeIdKey, node.id);
  }

  if (currentArbitrumNodeServer == null) {
    final node = Node(uri: arbitrumDefaultNodeUri, type: WalletType.arbitrum);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentArbitrumNodeIdKey, node.id);
  }

  if (currentSolanaNodeServer == null) {
    final node = Node(uri: solanaDefaultNodeUri, type: WalletType.solana);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentSolanaNodeIdKey, node.id);
  }

  if (currentTronNodeServer == null) {
    final node = Node(uri: tronDefaultNodeUri, type: WalletType.tron);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentTronNodeIdKey, node.id);
  }

  if (currentWowneroNodeServer == null) {
    final node = Node(uri: wowneroDefaultNodeUri, type: WalletType.wownero);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentWowneroNodeIdKey, node.id);
  }

  if (currentZanoNode == null) {
    final node = Node(uri: zanoDefaultNodeUri, type: WalletType.zano);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentZanoNodeIdKey, node.id);
  }

  if (currentDecredNodeServer == null) {
    final node = Node(uri: decredDefaultUri, type: WalletType.decred);
    await node.save();
    await sharedPreferences.setInt(PreferencesKey.currentDecredNodeIdKey, node.id);
  }
}

Future<void> resetBitcoinElectrumServer(SharedPreferences sharedPreferences) async {
  final nodeSource = await Node.getAll();
  final currentElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
  final oldElectrumServer = nodeSource
      .firstWhereOrNull((node) => node.uri.toString().contains('electrumx.cakewallet.com'));
  var cakeWalletNode = nodeSource
      .firstWhereOrNull((node) => node.uriRaw.toString() == cakeWalletBitcoinElectrumUri);

  if (cakeWalletNode == null) {
    cakeWalletNode =
        Node(uri: cakeWalletBitcoinElectrumUri, type: WalletType.bitcoin, useSSL: false, isEnabledForAutoSwitching: true);
    // final cakeWalletElectrumTestnet =
    //     Node(uri: publicBitcoinTestnetElectrumUri, type: WalletType.bitcoin, useSSL: false);
    // await nodeSource.add(cakeWalletElectrumTestnet);
    await cakeWalletNode.save();
  }

  if (currentElectrumSeverId == oldElectrumServer?.id) {
    await sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey, cakeWalletNode.id);
  }

  await oldElectrumServer?.delete();
}

Future<void> migrateExchangeStatus(SharedPreferences sharedPreferences) async {
  final isExchangeDisabled = sharedPreferences.getBool(PreferencesKey.disableExchangeKey);
  if (isExchangeDisabled == null) {
    return;
  }

  await sharedPreferences.setInt(PreferencesKey.exchangeStatusKey,
      isExchangeDisabled ? ExchangeApiMode.disabled.raw : ExchangeApiMode.enabled.raw);

  await sharedPreferences.remove(PreferencesKey.disableExchangeKey);
}

Future<void> addNanoPowNodeList() async {
  final nodeList = await loadDefaultNanoPowNodes();
  final nodes = await Node.getAllPow();
  for (var node in nodeList) {
    if (nodes.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await node.save();
    }
  }
}

Future<Node?> getNanoDefaultPowNode() async {
  final nodes = await Node.getAll();
  return nodes.firstWhereOrNull((Node node) => node.uriRaw == nanoDefaultPowNodeUri) ??
      nodes.firstWhereOrNull((node) => (node.type == WalletType.nano));
}

Future<void> addWalletNodeList({required WalletType type}) async {
  final nodes = await Node.getAll();
  final List<Node> nodeList = await loadDefaultNodes(type);
  for (var node in nodeList) {
    if (nodes.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await node.save();
    }
  }
}

Future<void> removeMoneroWorld(
    {required SharedPreferences sharedPreferences}) async {
  final nodes = await Node.getAll();
  const cakeWalletMoneroNodeUriPattern = '.moneroworld.com';
  final currentMoneroNodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentMoneroNode = nodes.firstWhere((node) => node.id == currentMoneroNodeId);
  final needToReplaceCurrentMoneroNode =
      currentMoneroNode.uri.toString().contains(cakeWalletMoneroNodeUriPattern);

  nodes.forEach((node) async {
    if (node.type == WalletType.monero &&
        node.uri.toString().contains(cakeWalletMoneroNodeUriPattern)) {
      await node.delete();
    }
  });

  if (needToReplaceCurrentMoneroNode) {
    await _changeDefaultNode(
      sharedPreferences: sharedPreferences,
      type: WalletType.monero,
      newDefaultUri: newCakeWalletMoneroUri,
      currentNodePreferenceKey: PreferencesKey.currentNodeIdKey,
      trusted: true,
    );
  }
}

Future<void> migrateExistingNodesToUseAutoSwitching() async {
  final listOfDefaultNodesWithAutoSwitching = [
    'bitcoincash.stackwallet.com:50002',
    'bch.aftrek.org:50002',
    'btc-electrum.cakewallet.com:50002',
    'fulcrum.sethforprivacy.com:50002',
    'default-spv-nodes',
    'dcrd.sethforprivacy.com:9108',
    'ethereum-rpc.publicnode.com',
    'eth.nownodes.io',
    'ltc-electrum.cakewallet.com:50002',
    'litecoin.stackwallet.com:20063',
    'nano.nownodes.io',
    'rpc.nano.to',
    'node.nautilus.io',
    'rpc.nano.to',
    'workers.perish.co',
    'worker.nanoriver.cc',
    'xmr-node.cakewallet.com:18081',
    'node.sethforprivacy.com:443',
    'nodes.hashvault.pro:18081',
    'polygon-bor-rpc.publicnode.com',
    'matic.nownodes.io',
    'api.mainnet-beta.solana.com:443',
    'solana-rpc.publicnode.com:443',
    'solana-mainnet.core.chainstack.com',
    'api.trongrid.io',
    'trx.nownodes.io',
    'node3.monerodevs.org:34568',
    'node2.monerodevs.org:34568',
    '37.27.100.59:10500',
    'zano.cakewallet.com:11211',
    'electrum.cakewallet.com:50002',
  ];
  final nodes = await Node.getAll();
  for (var node in nodes) {
    if (listOfDefaultNodesWithAutoSwitching.contains(node.uriRaw)) {
      node.isEnabledForAutoSwitching = true;
      await node.save();
    }
  }

  final powNodes = await Node.getAllPow();

  for(var node in powNodes) {
    if (listOfDefaultNodesWithAutoSwitching.contains(node.uriRaw)) {
      node.isEnabledForAutoSwitching = true;
      node.isPow = true;
      await node.save();
    }
  }

}

