class EvmSelectors {
  static const erc20Approve = "095ea7b3";
  static const erc20Transfer = "a9059cbb";
  static const erc20TransferFrom = "23b872dd";
  static const erc20IncreaseAllowance = "39509351";
  static const erc20DecreaseAllowance = "a457c2d7";

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
  // SwapRouter02 drops the deadline field from the V3 param structs.
  static const uniV3Router02ExactInputSingle = "04e45aaf";
  static const uniV3Router02ExactOutputSingle = "5023b4df";
  static const uniV3Router02ExactInput = "b858183f";
  static const uniV3Router02ExactOutput = "09b81346";
  static const multicall = "ac9650d8";
  static const multicallWithDeadline = "5ae401dc";
  static const multicallWithPreviousBlockhash = "1f0464d1";
  static const uniV3UniversalRouterExecute = "24856bc3";
  static const uniV3UniversalRouterExecuteWithDeadline = "3593564c";

  static const zeroXTransformErc20 = "415565b0";
  static const zeroXFillLimitOrder = "f6274f66";

  static const oneInchSwap = "7c025200";
  static const oneInchUnoswap = "0502b1c5";
  static const oneInchClipperSwap = "b0431182";
  static const oneInchAggregationSwap = "12aa3caf";

  static const permit2Permit = "2b67b570";
  static const permit2PermitBatch = "2a2d80d1";
  static const permit2TransferFrom = "36c78516";
  static const permit2PermitTransferFrom = "30f28b7a";

  static const erc2612Permit = "d505accf";

  static const Map<String, String> selectorToRouterName = {
    uniV2SwapExactTokensForTokens: "Uniswap V2",
    uniV2SwapTokensForExactTokens: "Uniswap V2",
    uniV2SwapExactETHForTokens: "Uniswap V2",
    uniV2SwapETHForExactTokens: "Uniswap V2",
    uniV2SwapExactTokensForETH: "Uniswap V2",
    uniV2SwapTokensForExactETH: "Uniswap V2",
    uniV2SwapExactTokensForTokensSupportingFeeOnTransferTokens: "Uniswap V2",
    uniV2SwapExactETHForTokensSupportingFeeOnTransferTokens: "Uniswap V2",
    uniV2SwapExactTokensForETHSupportingFeeOnTransferTokens: "Uniswap V2",
    uniV3ExactInputSingle: "Uniswap V3",
    uniV3ExactOutputSingle: "Uniswap V3",
    uniV3ExactInput: "Uniswap V3",
    uniV3ExactOutput: "Uniswap V3",
    uniV3Router02ExactInputSingle: "Uniswap V3",
    uniV3Router02ExactOutputSingle: "Uniswap V3",
    uniV3Router02ExactInput: "Uniswap V3",
    uniV3Router02ExactOutput: "Uniswap V3",
    uniV3UniversalRouterExecute: "Uniswap Universal Router",
    uniV3UniversalRouterExecuteWithDeadline: "Uniswap Universal Router",
    zeroXTransformErc20: "0x Protocol",
    zeroXFillLimitOrder: "0x Protocol",
    oneInchSwap: "1inch",
    oneInchUnoswap: "1inch",
    oneInchClipperSwap: "1inch",
    oneInchAggregationSwap: "1inch",
  };

  static const Map<String, Map<int, Set<String>>> knownRouterAddresses = {
    "Uniswap V2": {
      1: {
        "0x7a250d5630b4cf539739df2c5dacb4c659f2488d",
      },
      56: {
        "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24",
      },
      137: {
        "0xedf6066a2b290c185783862c7f4776a2c8077ad1",
      },
      4663: {
        "0x89e5db8b5aa49aa85ac63f691524311aeb649eba",
      },
      8453: {
        "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24",
      },
      42161: {
        "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24",
      },
    },
    "Uniswap V3": {
      1: {
        "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        "0xe592427a0aece92de3edee1f18e0157c05861564",
      },
      56: {
        "0xb971ef87ede563556b2ed4b1c0b0019111dd85d2",
      },
      137: {
        "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        "0xe592427a0aece92de3edee1f18e0157c05861564",
      },
      4663: {
        "0xcaf681a66d020601342297493863e78c959e5cb2",
      },
      8453: {
        "0x2626664c2603336e57b271c5c0b26f421741e481",
      },
      42161: {
        "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        "0xe592427a0aece92de3edee1f18e0157c05861564",
      },
    },
    "Uniswap Universal Router": {
      1: {
        "0x23617e59a5925b2a4bf75d73ff6711cd0b29de85",
        "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad",
        "0x4c82d1fbfe28c977cbb58d8c7ff8fcf9f70a2cca",
        "0x66a9893cc07d91d95644aedd05d03f95e1dba8af",
        "0xab863e752bf67d8dcdd929eaae9be9dc83fb3bbb",
        "0xef1c6e67703c7bd7107eed8303fbe6ec2554bf6b",
      },
      56: {
        "0x1906c1d672b88cd1b9ac7593301ca990f94eae07",
        "0x4dae2f939acf50408e13d58534ff8c2776d45265",
        "0x5dc88340e1c5c6366864ee415d6034cadd1a9897",
        "0x8b844f885672f333bc0042cb669255f93a4c1e6b",
        "0x91bf3bfaef8d771a74e1a8fe460b3ee646b2e588",
        "0xdc264714f68d84cf29bc605589405e78bdbe7c9f",
        "0xec8b0f7ffe3ae75d7ffab09429e3675bb63503e4",
      },
      137: {
        "0x1095692a6237d83c6a72f3f5efedb9a670c49223",
        "0x4c60051384bd2d3c01bfc845cf5f4b44bcbe9de5",
        "0x643770e279d5d0733f21d6dc03a8efbabf3255b4",
        "0x8b844f885672f333bc0042cb669255f93a4c1e6b",
        "0xdc264714f68d84cf29bc605589405e78bdbe7c9f",
        "0xe27610fd9dd05fc061366bc9da414ca6f948f204",
        "0xec7be89e9d109e7e3fec59c222cf297125fefda2",
      },
      4663: {
        "0x06afba43fd06227fa663b0daecf536f6eaa6bf99",
        "0x204faca1764b154221e35c0d20abb3c525710498",
        "0x8876789976decbfcbbbe364623c63652db8c0904",
      },
      8453: {
        "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad",
        "0x6ff5693b99212da76ad316178a184ab56d299b43",
        "0xbe2257d1aafbe6b73f67a9ac971c2f0b344bb3c5",
        "0xd6145b2d3f379919e8cdeda7b97e37c4b2ca9c40",
        "0xec8b0f7ffe3ae75d7ffab09429e3675bb63503e4",
        "0xf3a4f4094bd2c6c06ca2f61789d8727b8d1e7259",
        "0xfdf682f51fe81aa4898f0ae2163d8a55c127fbc7",
      },
      42161: {
        "0x2d01411773c8c24805306e89a41f7855c3c4fe65",
        "0x4c60051384bd2d3c01bfc845cf5f4b44bcbe9de5",
        "0x5e325eda8064b456f4781070c0738d849c824258",
        "0x8b844f885672f333bc0042cb669255f93a4c1e6b",
        "0x96b2fd2f80e9428daa65d859653117d453981ab4",
        "0xa51afafe0263b40edaef0df8781ea9aa03e381a3",
        "0xec8b0f7ffe3ae75d7ffab09429e3675bb63503e4",
      },
    },
    "0x Protocol": {
      1: {
        "0xdef1c0ded9bec7f1a1670819833240f027b25eff",
      },
      56: {
        "0xdef1c0ded9bec7f1a1670819833240f027b25eff",
      },
      137: {
        "0xdef1c0ded9bec7f1a1670819833240f027b25eff",
      },
      8453: {
        "0xdef1c0ded9bec7f1a1670819833240f027b25eff",
      },
      42161: {
        "0xdef1c0ded9bec7f1a1670819833240f027b25eff",
      },
    },
    "1inch": {
      1: {
        "0x111111125421ca6dc452d289314280a0f8842a65",
        "0x1111111254eeb25477b68fb85ed929f73a960582",
      },
      56: {
        "0x111111125421ca6dc452d289314280a0f8842a65",
        "0x1111111254eeb25477b68fb85ed929f73a960582",
      },
      137: {
        "0x111111125421ca6dc452d289314280a0f8842a65",
        "0x1111111254eeb25477b68fb85ed929f73a960582",
      },
      4663: {
        "0x5a705de8982235a7fa45bb83dcacf03a211389c7",
      },
      8453: {
        "0x111111125421ca6dc452d289314280a0f8842a65",
        "0x1111111254eeb25477b68fb85ed929f73a960582",
      },
      42161: {
        "0x111111125421ca6dc452d289314280a0f8842a65",
        "0x1111111254eeb25477b68fb85ed929f73a960582",
      },
    },
  };

  static const Map<String, String> selectorToHumanName = {
    erc20Approve: "approve",
    erc20Transfer: "transfer",
    erc20TransferFrom: "transferFrom",
    erc20IncreaseAllowance: "increaseAllowance",
    erc20DecreaseAllowance: "decreaseAllowance",
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
    erc2612Permit: "permit",
    permit2Permit: "permit2",
    permit2PermitBatch: "permit2Batch",
    permit2TransferFrom: "permit2TransferFrom",
    permit2PermitTransferFrom: "permit2PermitTransferFrom",
  };

  static String? routerNameFor(String selector) => selectorToRouterName[selector];

  static bool isKnownRouter(String routerName, int? chainId, String address) =>
      knownRouterAddresses[routerName]?[chainId]?.contains(address.toLowerCase()) ?? false;

  static String humanNameFor(String selector) => selectorToHumanName[selector] ?? "0x$selector";
}
