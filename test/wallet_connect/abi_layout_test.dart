import "dart:typed_data";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/permit2_decoder.dart";
import "package:flutter_test/flutter_test.dart";
import "package:web3dart/crypto.dart";
import "package:web3dart/web3dart.dart";

void main() {
  setUpAll(() => S.current = const S());

  final weth = EthereumAddress.fromHex("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
  final usdc = EthereumAddress.fromHex("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
  final owner = EthereumAddress.fromHex("0x1e65377828BFCB975c22c33fef51f5bf021dB613");
  final spender = EthereumAddress.fromHex("0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45");

  String encodeCall(String selector, TupleType args, List<dynamic> values) {
    final sink = LengthTrackingByteSink();
    args.encode(values, sink);
    return "0x$selector${sink.asBytes().map((b) => b.toRadixString(16).padLeft(2, '0')).join()}";
  }

  test("the selectors we branch on are the signatures we decode for", () {
    String selectorOf(String signature) => keccak256(Uint8List.fromList(signature.codeUnits))
        .take(4)
        .map((b) => b.toRadixString(16).padLeft(2, "0"))
        .join();

    const v3Single =
        "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))";
    const router02Single =
        "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))";
    const permitSingle = "permit(address,((address,uint160,uint48,uint48),address,uint256),bytes)";
    const permitBatch = "permit(address,((address,uint160,uint48,uint48)[],address,uint256),bytes)";

    expect(selectorOf(v3Single), "414bf389");
    expect(selectorOf(router02Single), "04e45aaf");
    expect(selectorOf(permitSingle), "2b67b570");
    expect(selectorOf(permitBatch), "2a2d80d1");
  });

  test("exactInputSingle reads the real amounts out of spec-encoded calldata", () async {
    const params = TupleType([
      AddressType(),
      AddressType(),
      UintType(length: 24),
      AddressType(),
      UintType(),
      UintType(),
      UintType(),
      UintType(length: 160),
    ]);
    final data = encodeCall("414bf389", const TupleType([params]), [
      [
        weth,
        usdc,
        BigInt.from(3000),
        owner,
        BigInt.from(1793190000),
        BigInt.from(10).pow(16),
        BigInt.from(25000000),
        BigInt.zero,
      ],
    ]);

    // No leading offset: the first word is the token, not 0x20.
    expect(data.substring(10, 74), "000000000000000000000000${weth.hex.substring(2)}");

    final decoded = await DexRouterDecoder(Erc20TokenResolver(null)).decode(
      calldata: EvmCalldata.parse(data)!,
      nativeSymbol: "ETH",
      routerAddress: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      walletAddress: owner.hex,
      valueWei: BigInt.zero,
    );

    expect(decoded!.rows[0].value, startsWith("10000000000000000"));
    expect(decoded.rows[1].value, startsWith("25000000"));
    expect(
      decoded.rows.any((r) => r.value.toLowerCase() == owner.hex.toLowerCase()),
      isTrue,
      reason: "recipient must be the real recipient word",
    );
  });

  test("permit shows the real spender and unlimited amount, signature offset last", () async {
    const details = TupleType([
      AddressType(),
      UintType(length: 160),
      UintType(length: 48),
      UintType(length: 48),
    ]);
    const permitSingle = TupleType([details, const AddressType(), const UintType()]);
    final uint160Max = (BigInt.one << 160) - BigInt.one;

    final data = encodeCall(
      "2b67b570",
      TupleType([const AddressType(), permitSingle, const DynamicBytes()]),
      [
        owner,
        [
          [usdc, uint160Max, BigInt.from(1793190000), BigInt.zero],
          spender,
          BigInt.from(1793193600),
        ],
        Uint8List.fromList(List<int>.filled(65, 0xab)),
      ],
    );

    // The signature is the only dynamic argument, so its offset sits after the
    // inline struct at word 7, not at word 2 where the amount lives.
    expect(data.substring(10 + 2 * 64, 74 + 2 * 64), "0" * 24 + "f" * 40);
    expect(BigInt.parse(data.substring(10 + 7 * 64, 74 + 7 * 64), radix: 16), BigInt.from(0x100));

    final decoded = await Permit2Decoder(Erc20TokenResolver(null))
        .decode(calldata: EvmCalldata.parse(data)!, contractAddress: "0xpermit2");

    expect(
      decoded!.rows
          .any((r) => r.value.toLowerCase().contains(spender.hex.substring(2).toLowerCase())),
      isTrue,
      reason: "the real spender must reach the sheet",
    );
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
  });
}
