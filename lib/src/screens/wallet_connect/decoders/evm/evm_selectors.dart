import "package:hashlib/hashlib.dart";

enum UniversalRouterVersion {
  v1(commandMask: 0x1f, hasV12Commands: false),
  v12(commandMask: 0x3f),
  v20(commandMask: 0x3f, v4MultiHopHeadWords: 4),
  v210(commandMask: 0x7f, v4MultiHopHeadWords: 5),
  v211(commandMask: 0x7f, v4MultiHopHeadWords: 5, hasFullPrecisionPortion: true),
  unlisted(commandMask: 0x7f, hasV12Commands: false);

  const UniversalRouterVersion({
    required this.commandMask,
    this.hasV12Commands = true,
    this.hasFullPrecisionPortion = false,
    this.v4MultiHopHeadWords,
  });

  final int commandMask;
  final bool hasV12Commands;
  final bool hasFullPrecisionPortion;
  final int? v4MultiHopHeadWords;
}

enum DexRouter {
  uniswapV2("Uniswap V2"),
  uniswapV3("Uniswap V3"),
  universalRouter("Uniswap Universal Router"),
  zeroX("0x Protocol"),
  oneInch("1inch");

  const DexRouter(this.displayName);

  final String displayName;
}

class EvmSelectors {
  static const erc20Approve = "095ea7b3";
  static const erc20Transfer = "a9059cbb";
  static const erc20TransferFrom = "23b872dd";
  static const erc20IncreaseAllowance = "39509351";
  static const erc20DecreaseAllowance = "a457c2d7";
  static const erc20IncreaseApproval = "d73dd623";
  static const erc20DecreaseApproval = "66188463";

  static const wethDeposit = "d0e30db0";
  static const wethWithdraw = "2e1a7d4d";

  static const erc721SafeTransferFrom = "42842e0e";
  static const erc721SafeTransferFromData = "b88d4fde";
  static const erc721SetApprovalForAll = "a22cb465";

  static const erc1155SafeTransferFrom = "f242432a";
  static const erc1155SafeBatchTransferFrom = "2eb2c2d6";

  static const uniV2SwapExactTokensForTokens = "38ed1739";
  static const uniV2SwapTokensForExactTokens = "8803dbee";
  static const uniV2SwapExactETHForTokens = "7ff36ab5";
  static const uniV2SwapETHForExactTokens = "fb3bdb41";
  static const uniV2SwapExactTokensForETH = "18cbafe5";
  static const uniV2SwapTokensForExactETH = "4a25d94a";
  static const uniV2SwapExactTokensForTokensSupportingFeeOnTransferTokens = "5c11d795";
  static const uniV2SwapExactETHForTokensSupportingFeeOnTransferTokens = "b6f9de95";
  static const uniV2SwapExactTokensForETHSupportingFeeOnTransferTokens = "791ac947";

  static const uniV3ExactInputSingle = "414bf389";
  static const uniV3ExactOutputSingle = "db3e2198";
  static const uniV3ExactInput = "c04b8d59";
  static const uniV3ExactOutput = "f28c0498";
  static const uniV3Router02ExactInputSingle = "04e45aaf";
  static const uniV3Router02ExactOutputSingle = "5023b4df";
  static const uniV3Router02ExactInput = "b858183f";
  static const uniV3Router02ExactOutput = "09b81346";
  static const uniV2Router02SwapExactTokensForTokens = "472b43f3";
  static const uniV2Router02SwapTokensForExactTokens = "42712a67";
  static const multicall = "ac9650d8";
  static const multicallWithDeadline = "5ae401dc";
  static const multicallWithPreviousBlockhash = "1f0464d1";
  static const routerUnwrapWeth9 = "49404b7c";
  static const routerUnwrapWeth9ToSender = "49616997";
  static const routerUnwrapWeth9WithFee = "9b2c0a37";
  static const routerUnwrapWeth9WithFeeToSender = "d4ef38de";
  static const routerSweepToken = "df2ab5bb";
  static const routerSweepTokenToSender = "e90a182f";
  static const routerSweepTokenWithFee = "e0e189a0";
  static const routerSweepTokenWithFeeToSender = "3068c554";
  static const routerRefundEth = "12210e8a";
  static const routerSelfPermit = "f3995c67";
  static const routerSelfPermitIfNecessary = "c2e3140a";
  static const routerSelfPermitAllowed = "4659a494";
  static const routerSelfPermitAllowedIfNecessary = "a4a78f0c";
  static const uniV3UniversalRouterExecute = "24856bc3";
  static const uniV3UniversalRouterExecuteWithDeadline = "3593564c";

  static const zeroXTransformErc20 = "415565b0";
  static const zeroXFillLimitOrder = "f6274f66";

  static const oneInchSwap = "7c025200";
  static const oneInchUnoswap = "0502b1c5";
  static const oneInchClipperSwap = "b0431182";
  static const oneInchAggregationSwap = "12aa3caf";

  static const permit2Approve = "87517c45";
  static const permit2Permit = "2b67b570";
  static const permit2PermitBatch = "2a2d80d1";
  static const permit2TransferFrom = "36c78516";
  static const permit2PermitTransferFrom = "30f28b7a";

  static const erc2612Permit = "d505accf";

  static const permit2Address = "0x000000000022d473030f116ddee9f6b43ac78ba3";
  static const Map<String, DexRouter> _selectorToRouter = {
    uniV2SwapExactTokensForTokens: DexRouter.uniswapV2,
    uniV2SwapTokensForExactTokens: DexRouter.uniswapV2,
    uniV2SwapExactETHForTokens: DexRouter.uniswapV2,
    uniV2SwapETHForExactTokens: DexRouter.uniswapV2,
    uniV2SwapExactTokensForETH: DexRouter.uniswapV2,
    uniV2SwapTokensForExactETH: DexRouter.uniswapV2,
    uniV2SwapExactTokensForTokensSupportingFeeOnTransferTokens: DexRouter.uniswapV2,
    uniV2SwapExactETHForTokensSupportingFeeOnTransferTokens: DexRouter.uniswapV2,
    uniV2SwapExactTokensForETHSupportingFeeOnTransferTokens: DexRouter.uniswapV2,
    uniV3ExactInputSingle: DexRouter.uniswapV3,
    uniV3ExactOutputSingle: DexRouter.uniswapV3,
    uniV3ExactInput: DexRouter.uniswapV3,
    uniV3ExactOutput: DexRouter.uniswapV3,
    uniV3Router02ExactInputSingle: DexRouter.uniswapV3,
    uniV3Router02ExactOutputSingle: DexRouter.uniswapV3,
    uniV3Router02ExactInput: DexRouter.uniswapV3,
    uniV3Router02ExactOutput: DexRouter.uniswapV3,
    uniV2Router02SwapExactTokensForTokens: DexRouter.uniswapV3,
    uniV2Router02SwapTokensForExactTokens: DexRouter.uniswapV3,
    uniV3UniversalRouterExecute: DexRouter.universalRouter,
    uniV3UniversalRouterExecuteWithDeadline: DexRouter.universalRouter,
    zeroXTransformErc20: DexRouter.zeroX,
    zeroXFillLimitOrder: DexRouter.zeroX,
    oneInchSwap: DexRouter.oneInch,
    oneInchUnoswap: DexRouter.oneInch,
    oneInchClipperSwap: DexRouter.oneInch,
    oneInchAggregationSwap: DexRouter.oneInch,
  };

  static const Map<DexRouter, Map<int, Set<String>>> _knownRouterAddresses = {
    DexRouter.uniswapV2: {
      1: {"0x7a250d5630b4cf539739df2c5dacb4c659f2488d"},
      56: {"0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"},
      137: {"0xedf6066a2b290c185783862c7f4776a2c8077ad1"},
      4663: {"0x89e5db8b5aa49aa85ac63f691524311aeb649eba"},
      8453: {"0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"},
      42161: {"0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"},
    },
    DexRouter.uniswapV3: {
      1: {
        "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        "0xe592427a0aece92de3edee1f18e0157c05861564",
      },
      56: {"0xb971ef87ede563556b2ed4b1c0b0019111dd85d2"},
      137: {
        "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        "0xe592427a0aece92de3edee1f18e0157c05861564",
      },
      4663: {"0xcaf681a66d020601342297493863e78c959e5cb2"},
      8453: {"0x2626664c2603336e57b271c5c0b26f421741e481"},
      42161: {
        "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        "0xe592427a0aece92de3edee1f18e0157c05861564",
      },
    },
    DexRouter.zeroX: {
      1: {"0xdef1c0ded9bec7f1a1670819833240f027b25eff"},
      56: {"0xdef1c0ded9bec7f1a1670819833240f027b25eff"},
      137: {"0xdef1c0ded9bec7f1a1670819833240f027b25eff"},
      8453: {"0xdef1c0ded9bec7f1a1670819833240f027b25eff"},
      42161: {"0xdef1c0ded9bec7f1a1670819833240f027b25eff"},
    },
    DexRouter.oneInch: {
      1: {"0x1111111254eeb25477b68fb85ed929f73a960582"},
      56: {"0x1111111254eeb25477b68fb85ed929f73a960582"},
      137: {"0x1111111254eeb25477b68fb85ed929f73a960582"},
      4663: {"0x5a705de8982235a7fa45bb83dcacf03a211389c7"},
      8453: {"0x1111111254eeb25477b68fb85ed929f73a960582"},
      42161: {"0x1111111254eeb25477b68fb85ed929f73a960582"},
    },
  };

  static const Map<int, Map<String, UniversalRouterVersion>> _universalRouterVersions = {
    1: {
      "0xef1c6e67703c7bd7107eed8303fbe6ec2554bf6b": UniversalRouterVersion.v1,
      "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad": UniversalRouterVersion.v12,
      "0x66a9893cc07d91d95644aedd05d03f95e1dba8af": UniversalRouterVersion.v20,
      "0x4c82d1fbfe28c977cbb58d8c7ff8fcf9f70a2cca": UniversalRouterVersion.v211,
      "0x23617e59a5925b2a4bf75d73ff6711cd0b29de85": UniversalRouterVersion.v211,
      "0xab863e752bf67d8dcdd929eaae9be9dc83fb3bbb": UniversalRouterVersion.v211,
    },
    56: {
      "0x5dc88340e1c5c6366864ee415d6034cadd1a9897": UniversalRouterVersion.v1,
      "0xec8b0f7ffe3ae75d7ffab09429e3675bb63503e4": UniversalRouterVersion.v12,
      "0x4dae2f939acf50408e13d58534ff8c2776d45265": UniversalRouterVersion.v12,
      "0x1906c1d672b88cd1b9ac7593301ca990f94eae07": UniversalRouterVersion.v20,
      "0x91bf3bfaef8d771a74e1a8fe460b3ee646b2e588": UniversalRouterVersion.v210,
      "0x8b844f885672f333bc0042cb669255f93a4c1e6b": UniversalRouterVersion.v211,
      "0xdc264714f68d84cf29bc605589405e78bdbe7c9f": UniversalRouterVersion.v211,
    },
    137: {
      "0x4c60051384bd2d3c01bfc845cf5f4b44bcbe9de5": UniversalRouterVersion.v1,
      "0x643770e279d5d0733f21d6dc03a8efbabf3255b4": UniversalRouterVersion.v12,
      "0xec7be89e9d109e7e3fec59c222cf297125fefda2": UniversalRouterVersion.v12,
      "0x1095692a6237d83c6a72f3f5efedb9a670c49223": UniversalRouterVersion.v20,
      "0xe27610fd9dd05fc061366bc9da414ca6f948f204": UniversalRouterVersion.v210,
      "0x8b844f885672f333bc0042cb669255f93a4c1e6b": UniversalRouterVersion.v211,
      "0xdc264714f68d84cf29bc605589405e78bdbe7c9f": UniversalRouterVersion.v211,
    },
    4663: {
      "0x06afba43fd06227fa663b0daecf536f6eaa6bf99": UniversalRouterVersion.v211,
      "0x8876789976decbfcbbbe364623c63652db8c0904": UniversalRouterVersion.v211,
      "0x204faca1764b154221e35c0d20abb3c525710498": UniversalRouterVersion.v211,
    },
    8453: {
      "0xec8b0f7ffe3ae75d7ffab09429e3675bb63503e4": UniversalRouterVersion.v12,
      "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad": UniversalRouterVersion.v12,
      "0x6ff5693b99212da76ad316178a184ab56d299b43": UniversalRouterVersion.v20,
      "0xf3a4f4094bd2c6c06ca2f61789d8727b8d1e7259": UniversalRouterVersion.v210,
      "0xfdf682f51fe81aa4898f0ae2163d8a55c127fbc7": UniversalRouterVersion.v211,
      "0xd6145b2d3f379919e8cdeda7b97e37c4b2ca9c40": UniversalRouterVersion.v211,
      "0xbe2257d1aafbe6b73f67a9ac971c2f0b344bb3c5": UniversalRouterVersion.v211,
    },
    42161: {
      "0x4c60051384bd2d3c01bfc845cf5f4b44bcbe9de5": UniversalRouterVersion.v1,
      "0xec8b0f7ffe3ae75d7ffab09429e3675bb63503e4": UniversalRouterVersion.v12,
      "0x5e325eda8064b456f4781070c0738d849c824258": UniversalRouterVersion.v12,
      "0xa51afafe0263b40edaef0df8781ea9aa03e381a3": UniversalRouterVersion.v20,
      "0x96b2fd2f80e9428daa65d859653117d453981ab4": UniversalRouterVersion.v210,
      "0x8b844f885672f333bc0042cb669255f93a4c1e6b": UniversalRouterVersion.v211,
      "0x2d01411773c8c24805306e89a41f7855c3c4fe65": UniversalRouterVersion.v211,
    },
  };

  static const Map<String, String> _selectorToHumanName = {
    erc20Approve: "approve",
    erc20Transfer: "transfer",
    erc20TransferFrom: "transferFrom",
    erc20IncreaseAllowance: "increaseAllowance",
    erc20DecreaseAllowance: "decreaseAllowance",
    erc20IncreaseApproval: "increaseApproval",
    erc20DecreaseApproval: "decreaseApproval",
    wethDeposit: "deposit",
    wethWithdraw: "withdraw",
    erc721SafeTransferFrom: "safeTransferFrom",
    erc721SafeTransferFromData: "safeTransferFrom(bytes)",
    erc721SetApprovalForAll: "setApprovalForAll",
    erc1155SafeTransferFrom: "safeTransferFrom",
    erc1155SafeBatchTransferFrom: "safeBatchTransferFrom",
    multicall: "multicall",
    multicallWithDeadline: "multicall",
    multicallWithPreviousBlockhash: "multicall",
    routerUnwrapWeth9: "unwrapWETH9",
    routerUnwrapWeth9ToSender: "unwrapWETH9",
    routerUnwrapWeth9WithFee: "unwrapWETH9WithFee",
    routerUnwrapWeth9WithFeeToSender: "unwrapWETH9WithFee",
    routerSweepToken: "sweepToken",
    routerSweepTokenToSender: "sweepToken",
    routerSweepTokenWithFee: "sweepTokenWithFee",
    routerSweepTokenWithFeeToSender: "sweepTokenWithFee",
    routerRefundEth: "refundETH",
    routerSelfPermit: "selfPermit",
    routerSelfPermitIfNecessary: "selfPermitIfNecessary",
    routerSelfPermitAllowed: "selfPermitAllowed",
    routerSelfPermitAllowedIfNecessary: "selfPermitAllowedIfNecessary",
    uniV3UniversalRouterExecute: "execute",
    uniV3UniversalRouterExecuteWithDeadline: "execute",
    erc2612Permit: "permit",
    permit2Permit: "permit2",
    permit2PermitBatch: "permit2Batch",
    permit2TransferFrom: "permit2TransferFrom",
    permit2PermitTransferFrom: "permit2PermitTransferFrom",
  };

  static DexRouter? routerFor(String selector) => _selectorToRouter[selector];

  static const Map<int, String> wrappedNativeAddresses = {
    1: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    56: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
    137: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
    4663: "0x0bd7d308f8e1639fab988df18a8011f41eacad73",
    8453: "0x4200000000000000000000000000000000000006",
    42161: "0x82af49447d8a07e3bd95bd0d56f35241523fbab1",
  };

  static bool isWrappedNative(int? chainId, String address) =>
      wrappedNativeAddresses[chainId] == address.toLowerCase();

  static const Map<int, String> _uniswapV2Factories = {
    1: "5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f",
    56: "8909dc15e40173ff4699343b6eb8132c65e18ec6",
    137: "9e5a52f57b3038f1b8eee45f28b3c1967e22799c",
    4663: "8bceaa40b9acdfaedf85adf4ff01f5ad6517937f",
    8453: "8909dc15e40173ff4699343b6eb8132c65e18ec6",
    42161: "f1d7cc64fb4452f05c498126312ebe29f30fbcf9",
  };
  static const _uniswapV2PairInitCodeHash =
      "96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f";

  static String? uniswapV2Pair(int? chainId, String tokenA, String tokenB) {
    final factory = _uniswapV2Factories[chainId];
    if (factory == null) {
      return null;
    }
    final tokens = [tokenA.toLowerCase().substring(2), tokenB.toLowerCase().substring(2)]..sort();
    final salt = _keccakHex(tokens.join());
    return "0x${_keccakHex("ff$factory$salt$_uniswapV2PairInitCodeHash").substring(24)}";
  }

  static String _keccakHex(String hex) => keccak256.convert([
    for (var byteStart = 0; byteStart < hex.length; byteStart += 2)
      int.parse(hex.substring(byteStart, byteStart + 2), radix: 16),
  ]).hex();

  static UniversalRouterVersion universalRouterVersion(int? chainId, String address) =>
      _universalRouterVersions[chainId]?[address.toLowerCase()] ?? UniversalRouterVersion.unlisted;

  static bool isKnownRouter(DexRouter router, int? chainId, String address) {
    if (router == DexRouter.universalRouter) {
      return universalRouterVersion(chainId, address) != UniversalRouterVersion.unlisted;
    }
    return _knownRouterAddresses[router]?[chainId]?.contains(address.toLowerCase()) ?? false;
  }

  static String humanNameFor(String selector) => _selectorToHumanName[selector] ?? "0x$selector";
}
