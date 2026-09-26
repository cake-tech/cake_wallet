import "package:cake_wallet/entities/solana_nft_asset_model.dart";
import "package:cake_wallet/entities/wallet_nft_response.dart";
import "package:cw_core/imported_nft.dart";

class SavedNFTs {
  Future<Map<String, SolanaNFTAssetModel>> solanaNFTs(String walletName) async {
    final rows = await ImportedNFT.getAllForWallet(walletName, ImportedNFT.solanaChain);

    return {
      for (final row in rows)
        row.identifier: SolanaNFTAssetModel(
          address: row.identifier,
          mint: row.identifier,
          name: row.name,
          symbol: row.symbol,
          description: row.description,
          imageOriginalUrl: row.imageUrl,
          isOwned: row.isOwned,
        ),
    };
  }

  Future<void> addSolana(String walletName, SolanaNFTAssetModel asset) async {
    final mint = asset.mint;

    if (mint == null || mint.isEmpty) {
      return;
    }

    await _rowForSolana(walletName, mint, asset).save();
  }

  Future<void> refreshSolana(String walletName, List<SolanaNFTAssetModel> assets) async {
    for (final asset in assets) {
      final mint = asset.mint;

      if (mint == null) {
        continue;
      }

      await ImportedNFT.updateMetadata(_rowForSolana(walletName, mint, asset));
    }
  }

  Future<List<NFTAssetModel>> evmNFTs(String walletName, String chain) async {
    final rows = await ImportedNFT.getAllForWallet(walletName, chain);

    return rows
        .map(
          (row) => NFTAssetModel(
            tokenAddress: _tokenAddressOf(row.identifier),
            tokenId: _tokenIdOf(row.identifier),
            name: row.name,
            symbol: row.symbol,
            normalizedMetadata: NormalizedMetadata(
              name: row.name,
              description: row.description,
              image: row.imageUrl,
            ),
          ),
        )
        .toList();
  }

  Future<void> addEvm(String walletName, String chain, NFTAssetModel asset) async {
    final identifier = evmIdentifier(asset);

    if (identifier == null) {
      return;
    }

    await ImportedNFT(
      walletName: walletName,
      chain: chain,
      identifier: identifier,
      name: asset.name,
      symbol: asset.symbol,
      description: asset.normalizedMetadata?.description,
      imageUrl: asset.normalizedMetadata?.imageUrl,
    ).save();
  }

  Future<void> removeSolana(String walletName, String mint) =>
      ImportedNFT.deleteOne(walletName, ImportedNFT.solanaChain, mint);

  static String? evmIdentifier(NFTAssetModel asset) {
    final address = asset.tokenAddress;
    final tokenId = asset.tokenId;

    if (address == null || address.isEmpty) {
      return null;
    }

    return "$address:${tokenId ?? ""}";
  }

  ImportedNFT _rowForSolana(String walletName, String mint, SolanaNFTAssetModel asset) =>
      ImportedNFT(
        walletName: walletName,
        chain: ImportedNFT.solanaChain,
        identifier: mint,
        name: asset.name,
        symbol: asset.symbol,
        description: asset.description,
        imageUrl: asset.imageOriginalUrl,
        isOwned: asset.isOwned,
      );

  String _tokenAddressOf(String identifier) => identifier.split(":").first;

  String _tokenIdOf(String identifier) {
    final parts = identifier.split(":");

    return parts.length > 1 ? parts.sublist(1).join(":") : "";
  }
}
