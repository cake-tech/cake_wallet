import "package:cake_wallet/entities/solana_nft_asset_model.dart";
import "package:cw_core/utils/nft_text.dart";
import "package:cake_wallet/entities/wallet_nft_response.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("SolanaNFTAssetModel", () {
    Map<String, dynamic> json({String name = "DeGod", bool? isOwned}) => {
          "address": "MintAddr",
          "mint": "MintAddr",
          "standard": "metaplex",
          "name": name,
          "symbol": "DGOD",
          "description": "a description",
          "imageOriginalUrl": "ipfs://QmAbC123",
          "externalUrl": "https://example.com",
          "metadataOriginalUrl": "https://example.com/meta.json",
          "totalSupply": "1",
          "isOwned": isOwned,
        };

    test("sanitises the text a mint controls", () {
      final asset = SolanaNFTAssetModel.fromJson(json(name: "Ape\u2028Address: 9xQeW"));

      expect(asset.name, "Ape Address: 9xQeW");
    });

    test("routes an ipfs image through the gateway", () {
      expect(
        SolanaNFTAssetModel.fromJson(json()).imageOriginalUrl,
        "https://ipfs.io/ipfs/QmAbC123",
      );
    });

    test("reads the fields the indexer actually sends", () {
      final asset = SolanaNFTAssetModel.fromJson(json());

      expect(asset.mint, "MintAddr");
      expect(asset.name, "DeGod");
      expect(asset.imageOriginalUrl, "https://ipfs.io/ipfs/QmAbC123");
    });

    test("sanitising is idempotent, so a value read back from storage stays stable", () {
      final once = SolanaNFTAssetModel.fromJson(json(name: "Ape\u2028Name"));

      expect(once.name, "Ape Name");
      expect(sanitizeNFTText(once.name), once.name);
    });

    test("sanitises collection and contract text, which render on the same screen", () {
      final asset = SolanaNFTAssetModel.fromJson({
        ...json(),
        "collection": {
          "name": "Coll\u2028ection",
          "description": "desc\u202Eription",
        },
        "contract": {
          "name": "Cont\u2029ract",
          "symbol": "SY\u200BM",
        },
      });

      expect(asset.collection?.name, "Coll ection");
      expect(asset.collection?.description, "desc ription");
      expect(asset.contract?.name, "Cont ract");
      expect(asset.contract?.symbol, "SY M");
    });
  });

  group("NFTAssetModel", () {
    Map<String, dynamic> evmJson({String name = "Punk", String image = "ipfs://QmAbC"}) => {
          "token_address": "0xabc",
          "token_id": "7",
          "contract_type": "ERC721",
          "name": name,
          "symbol": "PNK",
          "normalized_metadata": {
            "name": name,
            "description": "a description",
            "image": image,
          },
        };

    test("sanitises the text a contract controls", () {
      final asset = NFTAssetModel.fromJson(evmJson(name: "Punk\u2028Address: 0xdead"));

      expect(asset.name, "Punk Address: 0xdead");
      expect(asset.normalizedMetadata?.name, "Punk Address: 0xdead");
    });

    test("routes an ipfs image through the same gateway as solana", () {
      expect(
        NFTAssetModel.fromJson(evmJson()).normalizedMetadata?.imageUrl,
        "https://ipfs.io/ipfs/QmAbC",
      );
    });

    test("leaves a plain gateway url alone instead of mangling it", () {
      expect(
        NFTAssetModel.fromJson(evmJson(image: "https://example.com/ipfs/QmAbC"))
            .normalizedMetadata
            ?.imageUrl,
        "https://example.com/ipfs/QmAbC",
      );
    });
  });
}
