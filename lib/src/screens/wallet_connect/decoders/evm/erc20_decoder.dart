import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class Erc20Decoder {
  Erc20Decoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String? contractAddress,
    required String nativeSymbol,
  }) async {
    switch (calldata.selector) {
      case EvmSelectors.erc20Approve:
        return _decodeApprove(calldata, contractAddress);
      case EvmSelectors.erc20Transfer:
        return _decodeTransfer(calldata, contractAddress);
      case EvmSelectors.erc20TransferFrom:
        return _decodeTransferFrom(calldata, contractAddress);
      case EvmSelectors.erc20IncreaseAllowance:
        return _decodeAllowanceDelta(
          calldata,
          contractAddress,
          S.current.wc_action_increase_allowance,
        );
      case EvmSelectors.erc20DecreaseAllowance:
        return _decodeAllowanceDelta(
          calldata,
          contractAddress,
          S.current.wc_action_decrease_allowance,
        );
      case EvmSelectors.wethDeposit:
        return _decodeWethWrap(contractAddress, nativeSymbol);
      case EvmSelectors.wethWithdraw:
        return _decodeWethUnwrap(calldata, contractAddress, nativeSymbol);
    }
    return null;
  }

  Future<bool> _isWrappedNative(String contractAddress, String nativeSymbol) async {
    final token = await tokenResolver.resolve(contractAddress);
    if (token == null) {
      return false;
    }
    final symbol = token.symbol.toUpperCase();
    final native = nativeSymbol.toUpperCase();
    return symbol == "W$native" || symbol == native;
  }

  Future<WCDecodedRequest?> _decodeApprove(
    EvmCalldata calldata,
    String? contractAddress,
  ) async {
    final spender = calldata.addressAt(0);
    final rawAmount = calldata.uintAt(1);
    if (spender == null || rawAmount == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final amountStr = tokenResolver.formatAmount(rawAmount, token);
    final symbol = tokenResolver.symbolOrShort(token, contractAddress);
    final isUnlimited = tokenResolver.isUnlimitedAmount(rawAmount);
    final isRevoke = rawAmount == BigInt.zero;

    return WCDecodedRequest(
      actionTitle: isRevoke ? S.current.wc_action_revoke_approval : S.current.wc_action_approve,
      rows: [
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenResolver.displayName(token, symbol),
        ),
        if (!isRevoke)
          WCDecodedRow(
            label: S.current.wc_amount,
            value: "$amountStr $symbol",
            kind: WCDecodedRowKind.amount,
          ),
        WCDecodedRow(
          label: S.current.wc_spender,
          value: spender,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [
        if (isUnlimited) S.current.wc_warning_unlimited_approval,
        if (token == null) S.current.wc_warning_unknown_token,
      ],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodeTransfer(
    EvmCalldata calldata,
    String? contractAddress,
  ) async {
    final recipient = calldata.addressAt(0);
    final rawAmount = calldata.uintAt(1);
    if (recipient == null || rawAmount == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final amountStr = tokenResolver.formatAmount(rawAmount, token);
    final symbol = tokenResolver.symbolOrShort(token, contractAddress);

    final fiat = token == null ? null : tokenResolver.fiatFor(token, amountStr);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_transfer,
      rows: [
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenResolver.displayName(token, symbol),
        ),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $symbol",
          kind: WCDecodedRowKind.amount,
          fiatValue: fiat,
        ),
        WCDecodedRow(
          label: S.current.to,
          value: recipient,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [if (token == null) S.current.wc_warning_unknown_token],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodeTransferFrom(
    EvmCalldata calldata,
    String? contractAddress,
  ) async {
    final fromAddr = calldata.addressAt(0);
    final toAddr = calldata.addressAt(1);
    final rawAmount = calldata.uintAt(2);
    if (fromAddr == null || toAddr == null || rawAmount == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final amountStr = tokenResolver.formatAmount(rawAmount, token);
    final symbol = tokenResolver.symbolOrShort(token, contractAddress);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_transfer,
      rows: [
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenResolver.displayName(token, symbol),
        ),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.from,
          value: fromAddr,
          kind: WCDecodedRowKind.address,
        ),
        WCDecodedRow(
          label: S.current.to,
          value: toAddr,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [if (token == null) S.current.wc_warning_unknown_token],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodeAllowanceDelta(
    EvmCalldata calldata,
    String? contractAddress,
    String actionTitle,
  ) async {
    final spender = calldata.addressAt(0);
    final delta = calldata.uintAt(1);
    if (spender == null || delta == null || contractAddress == null) {
      return null;
    }

    final token = await tokenResolver.resolve(contractAddress);
    final amountStr = tokenResolver.formatAmount(delta, token);
    final symbol = tokenResolver.symbolOrShort(token, contractAddress);

    return WCDecodedRequest(
      actionTitle: actionTitle,
      rows: [
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenResolver.displayName(token, symbol),
        ),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.wc_spender,
          value: spender,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [
        if (tokenResolver.isUnlimitedAmount(delta)) S.current.wc_warning_unlimited_approval,
        if (token == null) S.current.wc_warning_unknown_token,
      ],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodeWethWrap(
    String? contractAddress,
    String nativeSymbol,
  ) async {
    if (contractAddress == null) {
      return null;
    }
    if (!await _isWrappedNative(contractAddress, nativeSymbol)) {
      return null;
    }
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_wrap(nativeSymbol),
      actionSubtitle: tokenResolver.shortAddress(contractAddress),
      rows: const [],
      hideTo: false,
    );
  }

  Future<WCDecodedRequest?> _decodeWethUnwrap(
    EvmCalldata calldata,
    String? contractAddress,
    String nativeSymbol,
  ) async {
    if (contractAddress == null) {
      return null;
    }
    if (!await _isWrappedNative(contractAddress, nativeSymbol)) {
      return null;
    }
    final rawAmount = calldata.uintAt(0);
    if (rawAmount == null) {
      return null;
    }

    final amountStr = tokenResolver.formatNativeAmount(rawAmount);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_unwrap(nativeSymbol),
      actionSubtitle: tokenResolver.shortAddress(contractAddress),
      rows: [
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $nativeSymbol",
          kind: WCDecodedRowKind.amount,
        ),
      ],
      hideTo: true,
    );
  }
}
