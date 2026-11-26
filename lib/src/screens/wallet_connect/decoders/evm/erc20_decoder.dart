import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class Erc20Decoder {
  Erc20Decoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  static const _argumentWords = {
    EvmSelectors.erc20Approve: 2,
    EvmSelectors.erc20Transfer: 2,
    EvmSelectors.erc20TransferFrom: 3,
    EvmSelectors.erc20IncreaseAllowance: 2,
    EvmSelectors.erc20IncreaseApproval: 2,
    EvmSelectors.erc20DecreaseAllowance: 2,
    EvmSelectors.erc20DecreaseApproval: 2,
    EvmSelectors.wethWithdraw: 1,
  };

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String? contractAddress,
    required String nativeSymbol,
    required int? chainId,
  }) async {
    final padded = calldata.zeroPaddedTo(_argumentWords[calldata.selector] ?? 0);
    final decoded = await _decodeCall(padded ?? calldata, contractAddress, nativeSymbol, chainId);
    if (decoded == null || padded == null) {
      return decoded;
    }
    return decoded.copyWith(warnings: [...decoded.warnings, S.current.wc_warning_decode_failed]);
  }

  Future<WCDecodedRequest?> _decodeCall(
    EvmCalldata calldata,
    String? contractAddress,
    String nativeSymbol,
    int? chainId,
  ) async {
    switch (calldata.selector) {
      case EvmSelectors.erc20Approve:
        return _decodeApprove(calldata, contractAddress, chainId);
      case EvmSelectors.erc20Transfer:
        return _decodeTransfer(calldata, contractAddress, chainId);
      case EvmSelectors.erc20TransferFrom:
        return _decodeTransferFrom(calldata, contractAddress, chainId);
      case EvmSelectors.erc20IncreaseAllowance:
      case EvmSelectors.erc20IncreaseApproval:
        return _decodeAllowanceDelta(calldata, contractAddress, chainId, isIncrease: true);
      case EvmSelectors.erc20DecreaseAllowance:
      case EvmSelectors.erc20DecreaseApproval:
        return _decodeAllowanceDelta(calldata, contractAddress, chainId, isIncrease: false);
      case EvmSelectors.wethDeposit:
        return _decodeWethWrap(contractAddress, nativeSymbol, chainId);
      case EvmSelectors.wethWithdraw:
        return _decodeWethUnwrap(calldata, contractAddress, nativeSymbol, chainId);
    }
    return null;
  }

  Future<WCDecodedRequest?> _decodeApprove(
    EvmCalldata calldata,
    String? contractAddress,
    int? chainId,
  ) async {
    final spender = calldata.addressAt(0);
    final rawAmount = calldata.uintAt(1);
    if (spender == null || rawAmount == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final isKnown = tokenResolver.isKnown(contractAddress, chainId: chainId);
    final isUnlimited = tokenResolver.isUnlimitedAmount(rawAmount);
    final isRevoke = rawAmount == BigInt.zero && isKnown;
    final isPermit2Spender = spender.toLowerCase() == EvmSelectors.permit2Address;

    return WCDecodedRequest(
      actionTitle: isRevoke ? S.current.wc_action_revoke_approval : S.current.wc_action_approve,
      actionSubtitle: isPermit2Spender ? "Permit2" : null,
      rows: [
        ...tokenResolver.tokenRows(token, contractAddress, isKnown: isKnown),
        if (!isRevoke)
          WCDecodedRow(
            label: isKnown
                ? S.current.wc_amount
                : "${S.current.wc_amount} / ${S.current.wc_token_id}",
            value: tokenResolver.amountText(rawAmount, token, contractAddress),
            kind: WCDecodedRowKind.amount,
          ),
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: spender,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [
        if (isUnlimited) S.current.wc_warning_unlimited_approval,
        if (isPermit2Spender && !isRevoke) S.current.wc_warning_permit2_approval,
        if (!isKnown) S.current.wc_warning_unknown_token,
      ],
    );
  }

  Future<WCDecodedRequest?> _decodeTransfer(
    EvmCalldata calldata,
    String? contractAddress,
    int? chainId,
  ) async {
    final recipient = calldata.addressAt(0);
    final rawAmount = calldata.uintAt(1);
    if (recipient == null || rawAmount == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final isKnown = tokenResolver.isKnown(contractAddress, chainId: chainId);
    final hasFiatValue = token != null && !tokenResolver.isUnlimitedAmount(rawAmount);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_transfer,
      rows: [
        ...tokenResolver.tokenRows(token, contractAddress, isKnown: isKnown),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: tokenResolver.amountText(rawAmount, token, contractAddress),
          kind: WCDecodedRowKind.amount,
          fiatValue: hasFiatValue
              ? tokenResolver.fiatFor(token, tokenResolver.formatAmount(rawAmount, token))
              : null,
        ),
        WCDecodedRow(label: S.current.to, value: recipient, kind: WCDecodedRowKind.address),
      ],
      warnings: [if (!isKnown) S.current.wc_warning_unknown_token],
    );
  }

  Future<WCDecodedRequest?> _decodeTransferFrom(
    EvmCalldata calldata,
    String? contractAddress,
    int? chainId,
  ) async {
    final sender = calldata.addressAt(0);
    final recipient = calldata.addressAt(1);
    final rawAmount = calldata.uintAt(2);
    if (sender == null || recipient == null || rawAmount == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final isKnown = tokenResolver.isKnown(contractAddress, chainId: chainId);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_transfer,
      rows: [
        ...tokenResolver.tokenRows(token, contractAddress, isKnown: isKnown),
        WCDecodedRow(
          label: isKnown
              ? S.current.wc_amount
              : "${S.current.wc_amount} / ${S.current.wc_token_id}",
          value: tokenResolver.amountText(rawAmount, token, contractAddress),
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(label: S.current.from, value: sender, kind: WCDecodedRowKind.address),
        WCDecodedRow(label: S.current.to, value: recipient, kind: WCDecodedRowKind.address),
      ],
      warnings: [if (!isKnown) S.current.wc_warning_unknown_token],
    );
  }

  Future<WCDecodedRequest?> _decodeAllowanceDelta(
    EvmCalldata calldata,
    String? contractAddress,
    int? chainId, {
    required bool isIncrease,
  }) async {
    final spender = calldata.addressAt(0);
    final delta = calldata.uintAt(1);
    if (spender == null || delta == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final isKnown = tokenResolver.isKnown(contractAddress, chainId: chainId);

    return WCDecodedRequest(
      actionTitle: isIncrease
          ? S.current.wc_increase_allowance
          : S.current.wc_action_decrease_allowance,
      rows: [
        ...tokenResolver.tokenRows(token, contractAddress, isKnown: isKnown),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: tokenResolver.amountText(delta, token, contractAddress),
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: spender,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [
        if (isIncrease && tokenResolver.isUnlimitedAmount(delta))
          S.current.wc_warning_unlimited_approval,
        if (!isKnown) S.current.wc_warning_unknown_token,
      ],
    );
  }

  Future<WCDecodedRequest?> _decodeWethWrap(
    String? contractAddress,
    String nativeSymbol,
    int? chainId,
  ) async {
    if (contractAddress == null) {
      return null;
    }
    if (!EvmSelectors.isWrappedNative(chainId, contractAddress)) {
      return null;
    }
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_wrap(nativeSymbol),
      actionSubtitle: shortAddress(contractAddress),
      rows: [
        WCDecodedRow(label: S.current.to, value: contractAddress, kind: WCDecodedRowKind.address),
      ],
    );
  }

  Future<WCDecodedRequest?> _decodeWethUnwrap(
    EvmCalldata calldata,
    String? contractAddress,
    String nativeSymbol,
    int? chainId,
  ) async {
    if (contractAddress == null) {
      return null;
    }
    if (!EvmSelectors.isWrappedNative(chainId, contractAddress)) {
      return null;
    }
    final rawAmount = calldata.uintAt(0);
    if (rawAmount == null) {
      return null;
    }

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_unwrap(nativeSymbol),
      actionSubtitle: shortAddress(contractAddress),
      rows: [
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "${tokenResolver.formatNativeAmount(rawAmount)} $nativeSymbol",
          kind: WCDecodedRowKind.amount,
        ),
      ],
    );
  }
}
