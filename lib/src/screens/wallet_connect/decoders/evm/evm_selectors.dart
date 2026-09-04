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

  static String humanNameFor(String selector) => selectorToHumanName[selector] ?? "0x$selector";
}
