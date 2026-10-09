import "package:cw_core/erc20_token.dart";
import "package:cw_evm/evm_chain_transaction_info.dart";
import "package:flutter_test/flutter_test.dart";

/// A transaction as it is persisted: the contract address is stored, but the
/// currency the amount is denominated in is not.
Map<String, dynamic> persisted({required String contract, String symbol = "USDC"}) => {
      "id": "0xabc",
      "height": 100,
      "amount": "1000000",
      "exponent": 6,
      "fee": "21000",
      "direction": 0,
      "date": DateTime(2026, 1, 1).millisecondsSinceEpoch,
      "isPending": false,
      "confirmations": 12,
      "tokenSymbol": symbol,
      "to": "0xto",
      "from": "0xfrom",
      "contractAddress": contract,
    };

Erc20Token usdc({String? iconPath}) => Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: "0xUSDC",
      decimal: 6,
      iconPath: iconPath,
    );

void main() {
  group("EVMChainTransactionInfo.fromJson", () {
    test("with no tokens known the asset has no identity", () {
      // The regression: a history restored from file was denominated in a
      // placeholder with an empty contract address, so it carried no icon and
      // nothing the price lookup could key on.
      final tx = EVMChainTransactionInfo.fromJson(persisted(contract: "0xUSDC"), 1);

      final asset = tx.assetOfTransaction;
      expect(asset, isA<Erc20Token>());
      expect((asset! as Erc20Token).contractAddress, "0xUSDC");
      expect(asset.iconPath, isNull);
    });

    test("a token matched by contract address becomes the asset", () {
      final registered = usdc(iconPath: "assets/images/usdc.png");

      final tx = EVMChainTransactionInfo.fromJson(
        persisted(contract: "0xUSDC"),
        1,
        tokens: [registered],
      );

      expect(tx.assetOfTransaction, registered);
      expect(tx.assetOfTransaction?.iconPath, "assets/images/usdc.png");
      expect(tx.amount.currency, registered, reason: "the price lookup keys on this");
    });

    test("matching is case insensitive on the contract address", () {
      final registered = usdc();

      final tx = EVMChainTransactionInfo.fromJson(
        persisted(contract: "0xusdc"),
        1,
        tokens: [registered],
      );

      expect(tx.assetOfTransaction, registered);
    });

    test("a contract address that matches nothing falls back", () {
      final other =
          Erc20Token(name: "Tether", symbol: "USDT", contractAddress: "0xUSDT", decimal: 6);

      final tx = EVMChainTransactionInfo.fromJson(
        persisted(contract: "0xUSDC"),
        1,
        tokens: [other],
      );

      expect(tx.assetOfTransaction, isNot(other));
      expect(tx.amount.currency.decimals, 6, reason: "decimals must survive the fallback");
    });

    test("the chain's native symbol resolves to the native currency", () {
      final tx = EVMChainTransactionInfo.fromJson(persisted(contract: "", symbol: "ETH"), 1);

      expect(tx.assetOfTransaction?.title, "ETH");
      expect(tx.assetOfTransaction, isNot(isA<Erc20Token>()));
    });
  });
}
