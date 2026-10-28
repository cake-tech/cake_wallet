import 'dart:convert';

import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/custom_block_explorers.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which explorer list a wallet uses: one per currency, or for EVM wallets,
/// one per network, since those wallets switch between networks.
class BlockExplorerScope {
  const BlockExplorerScope(this.walletType, {this.chainId});

  factory BlockExplorerScope.forWallet(WalletBase wallet) => BlockExplorerScope(
        wallet.type,
        chainId: isEVMCompatibleChain(wallet.type) ? wallet.chainId : null,
      );

  final WalletType walletType;
  final int? chainId;

  String get key => chainId != null ? 'evm_$chainId' : walletType.name;

  /// Bitcoin's explorer must be a mempool.space instance, because it also
  /// serves fee estimates and block timestamps.
  bool get usesMempool => walletType == WalletType.bitcoin;
}

/// An explorer the user added.
class SavedBlockExplorer {
  const SavedBlockExplorer({required this.id, required this.name, required this.url});

  factory SavedBlockExplorer.fromJson(Map<String, dynamic> json) => SavedBlockExplorer(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        url: json['url'] as String,
      );

  final String id;
  final String name;

  /// The explorer's address, or a template with `{txid}`. For Bitcoin, a
  /// normalized mempool.space base URL.
  final String url;

  String get host =>
      Uri.tryParse(url.replaceAll(CustomBlockExplorers.txIdPlaceholder, 'txid'))?.host ?? url;

  String get displayName => name.isNotEmpty ? name : host;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'url': url};
}

/// User-added block explorers and the selected one, per [BlockExplorerScope],
/// stored in SharedPreferences so they are included in app backups. Like
/// nodes, they are managed from a wallet's settings and shared by all wallets
/// of that currency (or EVM network). No selection means the built-in default.
///
/// The selected Bitcoin explorer is mirrored to
/// [CustomBlockExplorers.mempoolApiPrefsKey], which cw_bitcoin reads for fee
/// estimates and block timestamps.
class BlockExplorerSettings {
  BlockExplorerSettings(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  static const prefsKey = 'custom_block_explorers';

  static const _unsupportedTypes = {WalletType.none, WalletType.haven};

  /// Whether wallets of [type] can use a custom explorer.
  static bool supports(WalletType type) =>
      availableWalletTypes.contains(type) && !_unsupportedTypes.contains(type);

  /// Whether [wallet] shows the Block explorers setting. Testnet wallets
  /// always use the default explorer, so they don't.
  static bool isAvailableFor(WalletBase wallet) => supports(wallet.type) && !wallet.isTestnet;

  /// Whether [value] is acceptable as an explorer address in [scope].
  static bool isValidExplorer(BlockExplorerScope scope, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return scope.usesMempool
        ? CustomBlockExplorers.isValidBaseUrl(trimmed)
        : CustomBlockExplorers.isValidExplorer(trimmed);
  }

  List<SavedBlockExplorer> explorers(BlockExplorerScope scope) => _scope(scope).explorers;

  SavedBlockExplorer? selected(BlockExplorerScope scope) {
    final data = _scope(scope);
    for (final explorer in data.explorers) {
      if (explorer.id == data.selectedId) return explorer;
    }
    return null;
  }

  Future<SavedBlockExplorer> add(BlockExplorerScope scope,
      {required String name, required String url}) async {
    final data = _scope(scope);
    final explorer = SavedBlockExplorer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      url: _normalize(scope, url),
    );
    await _save(scope, data.explorers..add(explorer), data.selectedId);
    return explorer;
  }

  Future<void> update(BlockExplorerScope scope, SavedBlockExplorer explorer) async {
    final data = _scope(scope);
    final updated = [
      for (final existing in data.explorers)
        existing.id == explorer.id
            ? SavedBlockExplorer(
                id: explorer.id, name: explorer.name.trim(), url: _normalize(scope, explorer.url))
            : existing,
    ];
    await _save(scope, updated, data.selectedId);
  }

  /// Removes an explorer; if it was selected, the default is used again.
  Future<void> remove(BlockExplorerScope scope, String id) async {
    final data = _scope(scope);
    await _save(
      scope,
      data.explorers..removeWhere((explorer) => explorer.id == id),
      data.selectedId == id ? null : data.selectedId,
    );
  }

  /// Selects an explorer by id, or the built-in default when [id] is null.
  Future<void> select(BlockExplorerScope scope, String? id) async {
    final data = _scope(scope);
    await _save(scope, data.explorers, id);
  }

  /// The selected Bitcoin mempool.space address, or an empty string for the default.
  String get mempoolApiUrl =>
      _sharedPreferences.getString(CustomBlockExplorers.mempoolApiPrefsKey) ?? '';

  /// The selected explorer's link for a transaction, or null to use the default.
  ///
  /// Testnet wallets always use the default, since a custom explorer is
  /// assumed to index mainnet.
  String? customTxUrl(WalletType type, String txId, {int? chainId, bool isTestnet = false}) {
    if (isTestnet) return null;

    final scope = BlockExplorerScope(type, chainId: isEVMCompatibleChain(type) ? chainId : null);
    final explorer = selected(scope);
    if (explorer == null) return null;

    return CustomBlockExplorers.buildTxUrl(explorer.url, txId);
  }

  String _normalize(BlockExplorerScope scope, String url) =>
      scope.usesMempool ? CustomBlockExplorers.normalizeBaseUrl(url) : url.trim();

  _ScopeData _scope(BlockExplorerScope scope) {
    final entry = _readAll()[scope.key];
    if (entry is! Map) return _ScopeData([], null);

    final explorers = <SavedBlockExplorer>[];
    final rawList = entry['explorers'];
    if (rawList is List) {
      for (final item in rawList) {
        try {
          explorers.add(SavedBlockExplorer.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (_) {}
      }
    }

    final selectedId = entry['selected'];
    return _ScopeData(explorers, selectedId is String ? selectedId : null);
  }

  Map<String, dynamic> _readAll() {
    final raw = _sharedPreferences.getString(prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(
      BlockExplorerScope scope, List<SavedBlockExplorer> explorers, String? selectedId) async {
    if (selectedId != null && !explorers.any((explorer) => explorer.id == selectedId)) {
      selectedId = null;
    }

    final all = _readAll();
    if (explorers.isEmpty) {
      all.remove(scope.key);
    } else {
      all[scope.key] = {
        'explorers': [for (final explorer in explorers) explorer.toJson()],
        'selected': selectedId,
      };
    }

    if (all.isEmpty) {
      await _sharedPreferences.remove(prefsKey);
    } else {
      await _sharedPreferences.setString(prefsKey, jsonEncode(all));
    }

    if (scope.usesMempool) await _syncMempoolUrl(scope);
  }

  Future<void> _syncMempoolUrl(BlockExplorerScope scope) async {
    final url = selected(scope)?.url ?? '';
    if (url.isEmpty) {
      await _sharedPreferences.remove(CustomBlockExplorers.mempoolApiPrefsKey);
    } else {
      await _sharedPreferences.setString(CustomBlockExplorers.mempoolApiPrefsKey, url);
    }
  }
}

class _ScopeData {
  _ScopeData(this.explorers, this.selectedId);

  final List<SavedBlockExplorer> explorers;
  final String? selectedId;
}
