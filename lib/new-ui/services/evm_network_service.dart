import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/node.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:hive/hive.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite/sqflite.dart";

class RpcChainIdMismatchException implements Exception {
  const RpcChainIdMismatchException({
    required this.url,
    required this.answeredChainId,
    required this.expectedChainId,
  });

  final String url;
  final int answeredChainId;
  final int expectedChainId;
}

class RpcNoAnswerException implements Exception {
  const RpcNoAnswerException(this.url);

  final String url;
}

class NetworkInUseException implements Exception {
  const NetworkInUseException({required this.walletCount, required this.contactCount});

  final int walletCount;
  final int contactCount;
}

class EvmNetworkService {
  EvmNetworkService(this._settingsStore, this._sharedPreferences, this._contacts);

  final SettingsStore _settingsStore;
  final SharedPreferences _sharedPreferences;
  final Box<Contact> _contacts;

  Future<int> walletCount(int chainId) async => (await WalletInfo.selectList(
        "type = ? AND chainId = ?",
        [WalletType.evm.index, chainId],
      ))
          .length;

  int contactCount(int chainId) => _contacts.values
      .where((contact) => contact.raw == EvmNativeCurrencies.addedNetworkRaw(chainId))
      .length;

  EvmNetwork networkFromEntry(ChainListEntry entry) {
    final rpcUrls = entry.rpcUrls;

    return EvmNetwork(
      chainId: entry.chainId,
      name: entry.name,
      symbol: entry.symbol,
      decimals: entry.decimals,
      tag: tagFor(entry.shortName.isNotEmpty ? entry.shortName : entry.name),
      rpcUrl: rpcUrls.first,
      failoverUrl: rpcUrls.length > 1 ? rpcUrls[1] : null,
      explorerUrl: entry.explorerUrl,
      iconUrl: entry.iconUrl,
    );
  }

  Future<void> checkRpc(String url, int chainId) async {
    final node = EvmNetwork.nodeFor(url, chainId);
    final answered = await node.requestEvmChainId();

    if (answered == null) {
      throw RpcNoAnswerException(url);
    }

    if (answered != chainId) {
      throw RpcChainIdMismatchException(
        url: url,
        answeredChainId: answered,
        expectedChainId: chainId,
      );
    }

    if (await node.requestEvmBlockNumber() == null) {
      throw RpcNoAnswerException(url);
    }
  }

  Future<EvmNetwork> enable(EvmNetwork network, {List<String> rpcCandidates = const []}) async {
    EvmNetwork checked = network;
    if (rpcCandidates.isEmpty) {
      await _checkRpcs(network);
    } else {
      final answering = await firstAnsweringRpcs(
        rpcCandidates,
        (url) => checkRpc(url, network.chainId),
      );
      checked = network.withRpcUrls(answering.first, answering.length > 1 ? answering[1] : null);
    }

    final enabled = checked
        .withUniqueTag(await EvmNetwork.getAll())
        .copyWith(isEnabled: true, enabledAt: DateTime.now().millisecondsSinceEpoch);
    final hasNodes = (await Node.getAllForEvmChain(network.chainId)).isNotEmpty;
    final rpcsReplaced =
        checked.rpcUrl != network.rpcUrl || checked.failoverUrl != network.failoverUrl;

    await _saveNetwork(enabled, shouldReplaceNodes: !hasNodes || rpcsReplaced, previous: network);
    await _registerAndReloadNetworks(enabled);
    return enabled;
  }

  Future<EvmNetwork> disable(EvmNetwork network) async {
    final wallets = await walletCount(network.chainId);
    if (wallets > 0) {
      throw NetworkInUseException(
        walletCount: wallets,
        contactCount: contactCount(network.chainId),
      );
    }

    final disabled = network.copyWith(isEnabled: false);
    await disabled.save();
    await _registerAndReloadNetworks(disabled);
    return disabled;
  }

  Future<EvmNetwork> save(EvmNetwork edited, {EvmNetwork? previous}) async {
    final isChainIdChange = previous != null && previous.chainId != edited.chainId;
    if (isChainIdChange) {
      await _throwIfInUse(previous.chainId);
    }

    final hasWallets = await walletCount(edited.chainId) > 0;
    final allowedEdit = hasWallets && previous != null
        ? edited
            .withRpcUrls(previous.rpcUrl, previous.failoverUrl)
            .copyWith(symbol: previous.symbol, decimals: previous.decimals)
        : edited;
    final network = allowedEdit.withUniqueTag(
      await EvmNetwork.getAll(),
      beforeEdit: previous,
      hasWallets: hasWallets,
    );

    final needsRpcCheck = previous == null || isChainIdChange || _rpcsDiffer(previous, network);
    if (needsRpcCheck) {
      await _checkRpcs(network);
    }

    await _saveNetwork(
      network,
      shouldReplaceNodes: needsRpcCheck && !hasWallets,
      previous: isChainIdChange ? null : previous,
    );

    if (isChainIdChange) {
      await _remove(previous);
    } else if (previous != null && !hasWallets && _currencyDiffers(previous, network)) {
      evm!.unregisterNetwork(network.chainId);
    }

    await _registerAndReloadNetworks(network);
    return network;
  }

  Future<void> delete(EvmNetwork network) async {
    await _throwIfInUse(network.chainId);

    await _remove(network);
    await _settingsStore.loadEvmNetworks();
  }

  static String tagFor(String source) {
    final alphanumerics = source.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9]"), "");
    return alphanumerics.length > 10 ? alphanumerics.substring(0, 10) : alphanumerics;
  }

  static final _knownTickers =
      CryptoCurrency.all.map((currency) => currency.title.toUpperCase()).toSet();

  // Fiat prices are looked up by symbol, so a clone on a ticker the app knows shows its price
  static bool borrowsKnownTicker(
    String symbol, {
    required List<ChainListEntry> popularEntries,
    required bool isPopular,
    required double? tvl,
  }) {
    if (isPopular || (tvl != null && tvl > 0)) {
      return false;
    }

    final ticker = symbol.trim().toUpperCase();
    return _knownTickers.contains(ticker) ||
        popularEntries.any((entry) => entry.symbol.toUpperCase() == ticker);
  }

  static const _maxRpcCandidates = 4;

  static Future<List<String>> firstAnsweringRpcs(
    List<String> candidates,
    Future<void> Function(String url) check,
  ) async {
    final answering = <String>[];
    Exception? firstFailure;

    for (final url in candidates.take(_maxRpcCandidates)) {
      try {
        await check(url);
        answering.add(url);
      } on RpcNoAnswerException catch (e) {
        firstFailure ??= e;
      } on RpcChainIdMismatchException catch (e) {
        firstFailure ??= e;
      }

      if (answering.length == 2) {
        break;
      }
    }

    if (answering.isEmpty) {
      throw firstFailure ?? const RpcNoAnswerException("");
    }

    return answering;
  }

  Future<void> _throwIfInUse(int chainId) async {
    final wallets = await walletCount(chainId);
    final contacts = contactCount(chainId);
    if (wallets > 0 || contacts > 0) {
      throw NetworkInUseException(walletCount: wallets, contactCount: contacts);
    }
  }

  static bool _rpcsDiffer(EvmNetwork previous, EvmNetwork network) =>
      previous.rpcUrl != network.rpcUrl || previous.failoverUrl != network.failoverUrl;

  static bool _currencyDiffers(EvmNetwork previous, EvmNetwork network) =>
      previous.symbol != network.symbol ||
      previous.decimals != network.decimals ||
      previous.tag != network.tag;

  Future<void> _checkRpcs(EvmNetwork network) async {
    await checkRpc(network.rpcUrl, network.chainId);

    final failoverUrl = network.failoverUrl;
    if (failoverUrl != null) {
      await checkRpc(failoverUrl, network.chainId);
    }
  }

  Future<void> _saveNetwork(
    EvmNetwork network, {
    required bool shouldReplaceNodes,
    required EvmNetwork? previous,
  }) async {
    await db!.transaction((txn) async {
      await txn.insert(
        EvmNetwork.tableName,
        network.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (shouldReplaceNodes) {
        await network.replaceRpcNodes(txn, previous);
      }
    });
  }

  Future<void> _remove(EvmNetwork network) async {
    await db!.transaction((txn) async {
      await txn.delete(EvmNetwork.tableName, where: "chainId = ?", whereArgs: [network.chainId]);
      await network.deleteNodes(txn);
    });

    await _sharedPreferences.remove(PreferencesKey.currentEvmChainNodeIdKey(network.chainId));
    evm!.unregisterNetwork(network.chainId);
  }

  Future<void> _registerAndReloadNetworks(EvmNetwork network) async {
    evm!.registerNetwork(network);
    await _settingsStore.loadEvmNetworks();
  }
}
