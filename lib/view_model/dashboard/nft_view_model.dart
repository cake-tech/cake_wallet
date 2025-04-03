import 'dart:convert';
import 'dart:developer';

import 'package:cake_wallet/entities/solana_nft_asset_model.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/wallet_connect/bottom_sheet/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/message_display_widget.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:http/http.dart' as http;
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
    getNFTAssetByWallet();

    reaction((_) => appStore.wallet, (_) => getNFTAssetByWallet());
  }

  final AppStore appStore;
  final BottomSheetService bottomSheetService;

  @observable
  bool isLoading;

  @observable
  bool isImportNFTLoading;

  ObservableList<NFTAssetModel> nftAssetByWalletModels;

  ObservableList<SolanaNFTAssetModel> solanaNftAssetModels;

  @action
  Future<void> getNFTAssetByWallet() async {
    final walletType = appStore.wallet!.type;

    if (!isNFTACtivatedChain(walletType)) return;

    final walletAddress = appStore.wallet!.walletInfo.address;
    log('Fetching wallet NFTs for $walletAddress');

    final chainName = getChainNameBasedOnWalletType(walletType);
    // the [chain] refers to the chain network that the nft is on
    // the [format] refers to the number format type of the responses
    // the [normalizedMetadata] field is a boolean that determines if
    // the response would include a json string of the NFT Metadata that can be decoded
    // and used within the wallet
    // the [excludeSpam] field is a boolean that determines if spam nfts be excluded from the response.

    Uri uri;
    if (walletType == WalletType.solana) {
      uri = Uri.https(
        'solana-gateway.moralis.io',
        '/account/$chainName/$walletAddress/nft',
      );
    } else {
      uri = Uri.https(
        'deep-index.moralis.io',
        '/api/v2.2/$walletAddress/nft',
        {
          "chain": chainName,
          "format": "decimal",
          "media_items": "false",
          "exclude_spam": "true",
          "normalizeMetadata": "true",
        },
      );
    }

    try {
      isLoading = true;

      final response = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "X-API-Key": secrets.moralisApiKey,
        },
      );

      final decodedResponse = jsonDecode(response.body);

      if (walletType == WalletType.solana) {
        final results = await Future.wait(
          (decodedResponse as List<dynamic>).map(
            (x) {
              final data = x as Map<String, dynamic>;
              final mint = data['mint'] as String? ?? '';
              return getSolanaNFTDetails(mint, chainName);
            },
          ).toList(),
        );

        solanaNftAssetModels.clear();

        solanaNftAssetModels.addAll(results);
      } else {
        final result =
            WalletNFTsResponseModel.fromJson(decodedResponse as Map<String, dynamic>).result ?? [];

        nftAssetByWalletModels.clear();

        nftAssetByWalletModels.addAll(result);
      }

      isLoading = false;
    } catch (e) {
      isLoading = false;
      log(e.toString());
    }
  }

  Future<SolanaNFTAssetModel> getSolanaNFTDetails(String address, String chainName) async {
    final uri = Uri.https(
      'solana-gateway.moralis.io',
      '/nft/$chainName/$address/metadata',
    );

    final response = await http.get(
      uri,
      headers: {
        "Accept": "application/json",
        "X-API-Key": secrets.moralisApiKey,
      },
    );

    final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

    return SolanaNFTAssetModel.fromJson(decodedResponse);
  }

  @action
  Future<void> importNFT(String tokenAddress, String? tokenId) async {
    final chainName = getChainNameBasedOnWalletType(appStore.wallet!.type);
    // the [chain] refers to the chain network that the nft is on
    // the [format] refers to the number format type of the responses
    // the [normalizedMetadata] field is a boolean that determines if
    // the response would include a json string of the NFT Metadata that can be decoded
    // and used within the wallet

    try {
      isImportNFTLoading = true;

      if (appStore.wallet!.type == WalletType.solana) {
        final result = await getSolanaNFTDetails(tokenAddress, chainName);

        solanaNftAssetModels.add(result);
      } else {
        final uri = Uri.https(
          'deep-index.moralis.io',
          '/api/v2.2/nft/$tokenAddress/$tokenId',
          {
            "chain": chainName,
            "format": "decimal",
            "media_items": "false",
            "normalizeMetadata": "true",
          },
        );

        final response = await http.get(
          uri,
          headers: {
            "Accept": "application/json",
            "X-API-Key": secrets.moralisApiKey,
          },
        );

        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

        final nftAsset = NFTAssetModel.fromJson(decodedResponse);

        nftAssetByWalletModels.add(nftAsset);
      }
    } catch (e) {
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(
          message: e.toString(),
        ),
      );
    } finally {
      isImportNFTLoading = false;
    }
  }
}
