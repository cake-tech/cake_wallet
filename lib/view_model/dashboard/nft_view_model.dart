import "dart:async";
import 'dart:convert';

import "package:cake_wallet/entities/saved_nfts.dart";
import 'package:cake_wallet/entities/solana_nft_asset_model.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import "package:cake_wallet/solana/solana.dart";
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/utils/debounce.dart';
import "package:cw_core/utils/ipfs_url.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

import 'package:cake_wallet/entities/wallet_nft_response.dart';
import 'package:cake_wallet/store/app_store.dart';

part 'nft_view_model.g.dart';

class NFTViewModel = NFTViewModelBase with _$NFTViewModel;

abstract class NFTViewModelBase with Store {
  NFTViewModelBase(this.appStore, this.bottomSheetService)
      : isLoading = false,
        isImportNFTLoading = false,
        nftAssetByWalletModels = ObservableList(),
        solanaNftAssetModels = ObservableList() {
    if (isEVMCompatibleChain(appStore.wallet!.type)) {
      reaction((_) {
        final wallet = appStore.wallet;
        if (wallet != null) return wallet.chainId;

        return null;
      }, (_) => _fetchDebounce.run(() => getNFTAssetByWallet()));
    }
  }

  final AppStore appStore;
  bool _nftErrorPopupShown = false;
  final BottomSheetService bottomSheetService;
  final Debounce _fetchDebounce = Debounce(const Duration(milliseconds: 500));

  Future<void> _lastFetch = Future.value();
  String? _loadedWalletAddress;
  Completer<void>? _queuedFetch;

  final SavedNFTs _savedNFTs = SavedNFTs();
  int _currentRefreshId = 0;

  static const _requestTimeout = Duration(seconds: 20);
  static const _runDeadline = Duration(minutes: 2);

  Map<String, String> get _moralisHeaders => {
        "Accept": "application/json",
        "X-API-Key": secrets.moralisApiKey,
      };

  @observable
  bool isLoading;

  @observable
  bool isImportNFTLoading;

  @observable
  int unresolvedNFTCount = 0;

  ObservableList<NFTAssetModel> nftAssetByWalletModels;

  ObservableList<SolanaNFTAssetModel> solanaNftAssetModels;

  bool get isSolanaWallet => appStore.wallet?.type == WalletType.solana;

  String? get currentWalletName => appStore.wallet?.name;

  @action
  void onWalletChanged() {
    nftAssetByWalletModels.clear();
    solanaNftAssetModels.clear();
    unresolvedNFTCount = 0;
    _nftErrorPopupShown = false;
    _fetchDebounce.run(getNFTAssetByWallet);
  }

  @action
  Future<void> getNFTAssetByWallet() {
    final queued = _queuedFetch;

    if (queued != null) {
      return queued.future;
    }

    final done = Completer<void>();
    _queuedFetch = done;

    final waitFor = _lastFetch;
    _lastFetch = done.future;

    unawaited(_fetchAfterPreviousRun(waitFor, done));

    return done.future;
  }

  Future<void> _fetchAfterPreviousRun(Future<void> waitFor, Completer<void> done) async {
    await waitFor;

    if (identical(_queuedFetch, done)) {
      _queuedFetch = null;
    }

    try {
      final wallet = appStore.wallet!;

      if (!isNFTACtivatedChain(wallet.type, chainId: wallet.chainId)) {
        return;
      }

      final walletAddress = wallet.walletInfo.address;
      final chainName = getChainNameBasedOnWalletType(wallet.type, chainId: wallet.chainId);
      isLoading = true;

      final refreshId = ++_currentRefreshId;

      if (isSolanaWallet) {
        await _getSolanaNFTAssets(wallet, walletAddress, chainName, refreshId)
            .timeout(_runDeadline);
      } else {
        await _getEvmNFTAssets(wallet.name, walletAddress, chainName, refreshId);
      }

      _nftErrorPopupShown = false;
    } catch (e) {
      printV("Fetching wallet NFTs failed: ${e.toString()}");
      if (!_nftErrorPopupShown) {
        _nftErrorPopupShown = true;
        bottomSheetService.queueBottomSheet(
          isModalDismissible: true,
          widget: BottomSheetMessageDisplayWidget(
            message: S.current.moralis_nft_error,
          ),
        );
      }
    } finally {
      isLoading = false;
      done.complete();
    }
  }

  Future<void> _getEvmNFTAssets(
    String walletName,
    String walletAddress,
    String chainName,
    int refreshId,
  ) async {
    final saved = await _savedNFTs.evmNFTs(walletName, chainName);

    var result = const <NFTAssetModel>[];
    Object? indexerError;

    try {
      final response = await ProxyWrapper()
          .get(
            clearnetUri: Uri.https(
              "deep-index.moralis.io",
              "/api/v2.2/$walletAddress/nft",
              {
                "chain": chainName,
                "format": "decimal",
                "media_items": "false",
                "exclude_spam": "true",
                "normalizeMetadata": "true",
              },
            ),
            headers: _moralisHeaders,
          )
          .timeout(_requestTimeout);

      result = WalletNFTsResponseModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          ).result ??
          [];
    } catch (e) {
      indexerError = e;
    }

    if (appStore.wallet?.walletInfo.address != walletAddress || refreshId != _currentRefreshId) {
      return;
    }

    final listed = result.map(SavedNFTs.evmIdentifier).toSet();

    nftAssetByWalletModels.clear();
    nftAssetByWalletModels.addAll(result);
    nftAssetByWalletModels
        .addAll(saved.where((asset) => !listed.contains(SavedNFTs.evmIdentifier(asset))));

    if (indexerError != null) {
      throw indexerError;
    }
  }

  Future<void> _getSolanaNFTAssets(
    WalletBase wallet,
    String walletAddress,
    String chainName,
    int refreshId,
  ) async {
    final importedAssets = await _savedNFTs.solanaNFTs(wallet.name);

    var indexerMints = const <String>[];
    Object? indexerError;

    try {
      indexerMints = await _fetchMintsFromIndexer(walletAddress, chainName);
    } catch (e) {
      indexerError = e;
    }

    final heldMints = await _fetchMintsHeldOnChain(wallet);
    final failedMints = <String>{};

    final assets = await _loadAssetsForMints(
      wallet: wallet,
      chainName: chainName,
      mints: <String>{...indexerMints, ...importedAssets.keys},
      heldMints: heldMints,
      importedAssets: importedAssets,
      failedMints: failedMints,
    );

    if (appStore.wallet?.walletInfo.address != walletAddress || refreshId != _currentRefreshId) {
      return;
    }

    assets.addAll(
        _assetsToKeepFromPreviousRefresh(walletAddress, assets, failedMints, indexerError != null));

    solanaNftAssetModels.clear();
    solanaNftAssetModels.addAll(assets);
    _loadedWalletAddress = walletAddress;

    final shownMints = assets.map((asset) => asset.mint).toSet();
    unresolvedNFTCount = failedMints.where((mint) => !shownMints.contains(mint)).length;

    if (heldMints != null) {
      await _savedNFTs.refreshSolana(wallet.name, assets);
    }

    if (indexerError != null) {
      throw indexerError;
    }
  }

  Future<List<String>> _fetchMintsFromIndexer(String walletAddress, String chainName) async {
    final response = await ProxyWrapper()
        .get(
          clearnetUri: Uri.https(
            "solana-gateway.moralis.io",
            "/account/$chainName/$walletAddress/nft",
          ),
          headers: _moralisHeaders,
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to fetch wallet NFTs (${response.statusCode})");
    }

    return (jsonDecode(response.body) as List<dynamic>)
        .map((entry) => (entry as Map<String, dynamic>)["mint"] as String? ?? "")
        .where((mint) => mint.isNotEmpty)
        .toList();
  }

  Future<Set<String>?> _fetchMintsHeldOnChain(WalletBase wallet) async {
    try {
      return await solana!.getHeldTokenMints(wallet);
    } catch (e) {
      printV("Could not fetch held token mints: ${e.toString()}");
      return null;
    }
  }

  Future<List<SolanaNFTAssetModel>> _loadAssetsForMints({
    required WalletBase wallet,
    required String chainName,
    required Set<String> mints,
    required Set<String>? heldMints,
    required Map<String, SolanaNFTAssetModel> importedAssets,
    required Set<String> failedMints,
  }) async {
    const batchSize = 5;
    final ordered = mints.toList();
    final assets = <SolanaNFTAssetModel>[];

    for (var i = 0; i < ordered.length; i += batchSize) {
      final described = await Future.wait(
        ordered.skip(i).take(batchSize).map((mint) async {
          try {
            final asset = await getSolanaNFTDetails(wallet, mint, chainName);
            asset.isOwned = heldMints?.contains(mint) ?? importedAssets[mint]?.isOwned;
            return asset;
          } catch (e) {
            printV("Failed to load NFT $mint: ${e.toString()}");
            failedMints.add(mint);

            final cached = importedAssets[mint];

            if (cached != null && heldMints != null) {
              cached.isOwned = heldMints.contains(mint);
            }

            return cached;
          }
        }),
      );

      assets.addAll(described.whereType<SolanaNFTAssetModel>());
    }

    return assets;
  }

  List<SolanaNFTAssetModel> _assetsToKeepFromPreviousRefresh(
    String walletAddress,
    List<SolanaNFTAssetModel> described,
    Set<String> failedMints,
    bool indexerFailed,
  ) {
    if (_loadedWalletAddress != walletAddress) {
      return const [];
    }

    final describedMints = described.map((asset) => asset.mint).toSet();

    return solanaNftAssetModels.where((asset) {
      final mint = asset.mint;

      if (mint == null || describedMints.contains(mint)) {
        return false;
      }

      return indexerFailed || failedMints.contains(mint);
    }).toList();
  }

  Future<SolanaNFTAssetModel> getSolanaNFTDetails(
    WalletBase wallet,
    String address,
    String chainName,
  ) async {
    SolanaNFTAssetModel? asset;

    try {
      asset = await _fetchMoralisNFT(address, chainName);
      asset.address = address;
      asset.mint = address;
    } catch (e) {
      printV("Moralis NFT metadata failed for $address: ${e.toString()}");
    }

    if (asset != null && (asset.imageOriginalUrl?.isNotEmpty ?? false)) {
      return asset;
    }

    // fallback for when moralis is unavailable, we still get the core details for that nft onchain
    final onChainData = await solana!.getNFTOnChainMetadata(wallet, address);

    if (asset != null) {
      if (onChainData != null) {
        asset.imageOriginalUrl = tryNormalizeIpfsUrl(onChainData.imageUrl);
      }

      return asset;
    }

    if (onChainData == null) {
      throw Exception("Could not load NFT metadata for $address");
    }

    return SolanaNFTAssetModel(
      address: address,
      mint: address,
      standard: "metaplex",
      name: onChainData.name,
      symbol: onChainData.symbol,
      imageOriginalUrl: onChainData.imageUrl,
      metadataOriginalUrl: onChainData.metadataUri,
    );
  }

  Future<SolanaNFTAssetModel> _fetchMoralisNFT(String address, String chainName) async {
    final response = await ProxyWrapper()
        .get(
          clearnetUri: Uri.https(
            "solana-gateway.moralis.io",
            "/nft/$chainName/$address/metadata",
          ),
          headers: _moralisHeaders,
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to fetch NFT metadata (${response.statusCode})");
    }

    return SolanaNFTAssetModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @action
  Future<void> onNFTSent(String walletName, String mint) async {
    await _savedNFTs.removeSolana(walletName, mint);

    if (appStore.wallet?.name == walletName) {
      solanaNftAssetModels.removeWhere((asset) => asset.mint == mint);
    }
  }

  Future<void> _importEvmNFT(
    String walletName,
    String tokenAddress,
    String? tokenId,
    String chainName,
  ) async {
    final response = await ProxyWrapper()
        .get(
          clearnetUri: Uri.https(
            "deep-index.moralis.io",
            "/api/v2.2/nft/$tokenAddress/$tokenId",
            {
              "chain": chainName,
              "format": "decimal",
              "media_items": "false",
              "normalizeMetadata": "true",
            },
          ),
          headers: _moralisHeaders,
        )
        .timeout(_requestTimeout);

    final asset = NFTAssetModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

    nftAssetByWalletModels.add(asset);

    await _savedNFTs.addEvm(walletName, chainName, asset);
  }

  @action
  Future<void> importNFT(String tokenAddress, String? tokenId) async {
    final wallet = appStore.wallet!;
    int? chainId;
    if (isEVMCompatibleChain(wallet.type)) {
      chainId = evm!.getSelectedChainId(wallet);
    }
    final chainName = getChainNameBasedOnWalletType(wallet.type, chainId: chainId);
    try {
      isImportNFTLoading = true;

      if (isSolanaWallet) {
        final result = await getSolanaNFTDetails(wallet, tokenAddress, chainName);

        try {
          result.isOwned = (await solana!.getHeldTokenMints(wallet)).contains(result.mint);
        } catch (e) {
          printV("Could not check NFT ownership: ${e.toString()}");
        }

        solanaNftAssetModels.removeWhere((asset) => asset.mint == result.mint);
        solanaNftAssetModels.add(result);

        await _savedNFTs.addSolana(wallet.name, result);
      } else {
        await _importEvmNFT(wallet.name, tokenAddress, tokenId, chainName);
      }
    } catch (e) {
      printV("Importing NFT $tokenAddress failed: ${e.toString()}");
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(
          message: S.current.nft_import_failed,
        ),
      );
    } finally {
      isImportNFTLoading = false;
    }
  }
}
