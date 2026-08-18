import "package:cw_core/payment_uris.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("TronURI", () {
    const address = "TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL";
    const contract = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";

    test("includes the TRC20 contract as the token param", () {
      final uri = TronURI(amount: "1.5", address: address, contractAddress: contract);

      expect(uri.toString(), "tron:$address?amount=1.5&token=$contract");
    });

    test("omits the token param for native TRX", () {
      final uri = TronURI(amount: "1.5", address: address);

      expect(uri.toString(), "tron:$address?amount=1.5");
      expect(uri.toString().contains("token="), false);
    });

    test("includes the token param when there is no amount", () {
      final uri = TronURI(amount: "", address: address, contractAddress: contract);

      expect(uri.toString(), "tron:$address?token=$contract");
    });

    test("converts a comma decimal separator in the amount", () {
      final uri = TronURI(amount: "1,5", address: address);

      expect(uri.toString(), "tron:$address?amount=1.5");
    });

    test("emits a bare address without amount or contract", () {
      final uri = TronURI(amount: "", address: address);

      expect(uri.toString(), "tron:$address");
    });
  });

  group("SolanaURI", () {
    const address = "4Nd1mYvNQyJ8BDVXLgkvSGpVdQMZ3hxwVFkfwXNq6Wgk";
    const mint = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB";

    test("includes the SPL mint as the spl-token param", () {
      final uri = SolanaURI(amount: "2", address: address, contractAddress: mint);

      expect(uri.toString(), "solana:$address?amount=2&spl-token=$mint");
    });

    test("omits the spl-token param for native SOL", () {
      final uri = SolanaURI(amount: "2", address: address);

      expect(uri.toString(), "solana:$address?amount=2");
      expect(uri.toString().contains("spl-token="), false);
    });

    test("includes the spl-token param when there is no amount", () {
      final uri = SolanaURI(amount: "", address: address, contractAddress: mint);

      expect(uri.toString(), "solana:$address?spl-token=$mint");
    });

    test("converts a comma decimal separator in the amount", () {
      final uri = SolanaURI(amount: "0,5", address: address);

      expect(uri.toString(), "solana:$address?amount=0.5");
    });

    test("emits a bare address without amount or mint", () {
      final uri = SolanaURI(amount: "", address: address);

      expect(uri.toString(), "solana:$address");
    });
  });

  group("ERC681URI", () {
    const recipient = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6";
    const contract = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

    test("includes the mainnet chainId on a plain native transfer", () {
      final uri = ERC681URI(chainId: 1, address: recipient, amount: "", contractAddress: null);

      expect(uri.toString(), "ethereum:$recipient@1");
    });

    test("appends the chainId for native transfers", () {
      final uri = ERC681URI(chainId: 137, address: recipient, amount: "", contractAddress: null);

      expect(uri.toString(), "ethereum:$recipient@137");
    });

    test("emits the native amount in ERC-681 scientific notation", () {
      final uri = ERC681URI(chainId: 1, address: recipient, amount: "1", contractAddress: null);

      expect(uri.toString(), "ethereum:$recipient@1?value=1.0e18");
    });

    test("includes the mainnet chainId in the transfer form", () {
      final uri = ERC681URI(
        chainId: 1,
        address: recipient,
        amount: "200.172148",
        contractAddress: contract,
        tokenDecimals: 6,
      );

      expect(
        uri.toString(),
        "ethereum:$contract@1/transfer?address=$recipient&amount=200.172148",
      );
    });

    test("builds the transfer form for a token", () {
      final uri =
          ERC681URI(chainId: 137, address: recipient, amount: "", contractAddress: contract);

      expect(uri.toString(), "ethereum:$contract@137/transfer?address=$recipient");
    });

    test("parses the transfer form back into recipient, contract and chainId", () {
      final parsed = ERC681URI.fromUri(
        Uri.parse("ethereum:$contract@1/transfer?address=$recipient&uint256=1000000"),
      );

      expect(parsed.address, recipient);
      expect(parsed.contractAddress, contract);
      expect(parsed.chainId, 1);
      expect(parsed.rawTokenAmount, "1000000");
      expect(parsed.amount, "");
    });

    test("keeps the uint256 raw so the caller can apply the token decimals", () {
      final parsed = ERC681URI.fromUri(
        Uri.parse(
          "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@1/transfer?address=$recipient&uint256=1000000",
        ),
      );

      expect(parsed.rawTokenAmount, "1000000");
      expect(parsed.amount, "");
    });

    test("prefers the amount param over the uint256 when both are present", () {
      final parsed = ERC681URI.fromUri(
        Uri.parse(
          "ethereum:$contract@1/transfer?address=$recipient&uint256=1000000000000000000&amount=1",
        ),
      );

      expect(parsed.amount, "1");
      expect(parsed.rawTokenAmount, "1000000000000000000");
    });

    test("treats a uint256 with a decimal point as a display amount", () {
      final parsed = ERC681URI.fromUri(
        Uri.parse("ethereum:$contract@1/transfer?address=$recipient&uint256=1.5"),
      );

      expect(parsed.amount, "1.5");
      expect(parsed.rawTokenAmount, null);
    });

    test("parses a native transfer with chainId", () {
      final parsed = ERC681URI.fromUri(
        Uri.parse("ethereum:$recipient@137?value=2000000000000000000"),
      );

      expect(parsed.address, recipient);
      expect(parsed.contractAddress, null);
      expect(parsed.chainId, 137);
      expect(parsed.amount, "2");
    });

    test("emits the uint256 and the amount param for an 18 decimal token", () {
      final uri =
          ERC681URI(chainId: 137, address: recipient, amount: "1", contractAddress: contract);

      expect(
        uri.toString(),
        "ethereum:$contract@137/transfer?address=$recipient&uint256=1000000000000000000&amount=1",
      );
    });

    test("omits the uint256 for tokens that do not use 18 decimals", () {
      final uri = ERC681URI(
        chainId: 137,
        address: recipient,
        amount: "1.5",
        contractAddress: contract,
        tokenDecimals: 6,
      );

      expect(uri.toString(), "ethereum:$contract@137/transfer?address=$recipient&amount=1.5");
    });

    test("emits a stored raw token amount verbatim", () {
      final uri = ERC681URI(
        chainId: 1,
        address: recipient,
        amount: "",
        contractAddress: contract,
        tokenDecimals: 6,
        rawTokenAmount: "1000000",
      );

      expect(uri.toString(), "ethereum:$contract@1/transfer?address=$recipient&uint256=1000000");
    });

    test("parses a scientific notation value", () {
      final parsed = ERC681URI.fromUri(
        Uri.parse("ethereum:$recipient@1?value=2.014e18"),
      );

      expect(parsed.amount, "2.014");
    });

    test("parses a Cake style amount param", () {
      final parsed = ERC681URI.fromUri(
        Uri.parse("ethereum:$recipient?amount=1.5"),
      );

      expect(parsed.address, recipient);
      expect(parsed.amount, "1.5");
      expect(parsed.chainId, 1);
    });

    test("defaults to mainnet when the chainId is absent", () {
      final parsed = ERC681URI.fromUri(Uri.parse("ethereum:$recipient"));

      expect(parsed.address, recipient);
      expect(parsed.contractAddress, null);
      expect(parsed.chainId, 1);
      expect(parsed.amount, "");
    });
  });
}
