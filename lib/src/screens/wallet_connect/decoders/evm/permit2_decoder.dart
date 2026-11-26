import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class Permit2Decoder {
  Permit2Decoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  static const _maxBatchTokens = 64;

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String? contractAddress,
    required int? chainId,
  }) async {
    if (calldata.selector == EvmSelectors.erc2612Permit) {
      return _decodeErc2612Permit(calldata, contractAddress, chainId);
    }
    if (contractAddress?.toLowerCase() != EvmSelectors.permit2Address) {
      return null;
    }

    switch (calldata.selector) {
      case EvmSelectors.permit2Approve:
        return _decodeApprove(calldata, chainId);
      case EvmSelectors.permit2Permit:
        return _decodePermitSingle(calldata, chainId);
      case EvmSelectors.permit2PermitBatch:
        return _decodePermitBatch(calldata, chainId);
      case EvmSelectors.permit2PermitTransferFrom:
        return _decodePermitTransferFrom(calldata, chainId);
      case EvmSelectors.permit2TransferFrom:
        return _decodePermit2TransferFrom(calldata, chainId);
    }
    return null;
  }

  Future<WCDecodedRequest> _decodeApprove(EvmCalldata calldata, int? chainId) async {
    final token = calldata.addressAt(0);
    final spender = calldata.addressAt(1);
    final amount = calldata.uintAt(2);
    if (token == null || spender == null || amount == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    return _buildPermit(
      details: [_PermitDetail(token, amount, calldata.uintAt(3))],
      spender: spender,
      sigDeadline: null,
      chainId: chainId,
      isSigned: false,
    );
  }

  Future<WCDecodedRequest> _decodePermitSingle(EvmCalldata calldata, int? chainId) async {
    final token = calldata.addressAt(1);
    final amount = calldata.uintAt(2);
    final expiration = calldata.uintAt(3);
    final spender = calldata.addressAt(5);
    final sigDeadline = calldata.uintAt(6);
    if (token == null || amount == null || spender == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    return _buildPermit(
      details: [_PermitDetail(token, amount, expiration)],
      spender: spender,
      sigDeadline: sigDeadline,
      chainId: chainId,
    );
  }

  Future<WCDecodedRequest> _decodePermitBatch(EvmCalldata calldata, int? chainId) async {
    final struct = calldata.structAt(1);
    if (struct == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    final spender = struct.addressAt(1);
    final sigDeadline = struct.uintAt(2);
    final detailsArray = struct.structAt(0);
    final count = detailsArray?.uintAt(0)?.toInt();
    if (spender == null ||
        detailsArray == null ||
        count == null ||
        count <= 0 ||
        count > _maxBatchTokens) {
      return _opaque(S.current.wc_action_permit2);
    }

    final details = <_PermitDetail>[];
    for (var index = 0; index < count; index++) {
      final base = 1 + index * 4;
      final token = detailsArray.addressAt(base);
      final amount = detailsArray.uintAt(base + 1);
      final expiration = detailsArray.uintAt(base + 2);
      if (token == null || amount == null) {
        return _opaque(S.current.wc_action_permit2);
      }
      details.add(_PermitDetail(token, amount, expiration));
    }

    return _buildPermit(
      details: details,
      spender: spender,
      sigDeadline: sigDeadline,
      chainId: chainId,
    );
  }

  Future<WCDecodedRequest> _decodePermitTransferFrom(EvmCalldata calldata, int? chainId) async {
    final token = calldata.addressAt(0);
    final amount = calldata.uintAt(1);
    final deadline = calldata.uintAt(3);
    final recipient = calldata.addressAt(4);
    final requestedAmount = calldata.uintAt(5);
    if (token == null || amount == null || recipient == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    final resolved = await tokenResolver.resolve(token);
    final isKnown = tokenResolver.isKnown(token, chainId: chainId);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit2,
      actionSubtitle: "Permit2",
      rows: [
        ...tokenResolver.tokenRows(resolved, token, isKnown: isKnown),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: tokenResolver.amountText(requestedAmount ?? amount, resolved, token),
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(label: S.current.to, value: recipient, kind: WCDecodedRowKind.address),
        if (deadline != null)
          WCDecodedRow(
            label: S.current.wc_signature_valid_until,
            value: tokenResolver.formatExpiry(deadline),
          ),
      ],
      warnings: [
        S.current.wc_warning_permit_review,
        if (!isKnown) S.current.wc_warning_unknown_token,
      ],
    );
  }

  Future<WCDecodedRequest> _decodePermit2TransferFrom(EvmCalldata calldata, int? chainId) async {
    final sender = calldata.addressAt(0);
    final recipient = calldata.addressAt(1);
    final amount = calldata.uintAt(2);
    final token = calldata.addressAt(3);
    if (sender == null || recipient == null || amount == null || token == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    final resolved = await tokenResolver.resolve(token);
    final isKnown = tokenResolver.isKnown(token, chainId: chainId);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_transfer,
      actionSubtitle: "Permit2",
      rows: [
        ...tokenResolver.tokenRows(resolved, token, isKnown: isKnown),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: tokenResolver.amountText(amount, resolved, token),
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(label: S.current.from, value: sender, kind: WCDecodedRowKind.address),
        WCDecodedRow(label: S.current.to, value: recipient, kind: WCDecodedRowKind.address),
      ],
      warnings: [if (!isKnown) S.current.wc_warning_unknown_token],
    );
  }

  Future<WCDecodedRequest> _decodeErc2612Permit(
    EvmCalldata calldata,
    String? contractAddress,
    int? chainId,
  ) async {
    final spender = calldata.addressAt(1);
    final value = calldata.uintAt(2);
    final deadline = calldata.uintAt(3);
    if (spender == null || value == null || contractAddress == null) {
      return _opaque(S.current.wc_action_permit);
    }

    final resolved = await tokenResolver.resolve(contractAddress);
    final isKnown = tokenResolver.isKnown(contractAddress, chainId: chainId);
    final symbol = tokenResolver.symbolOrShort(resolved, contractAddress);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit,
      actionSubtitle: tokenResolver.displayName(resolved, symbol),
      rows: [
        ...tokenResolver.tokenRows(resolved, contractAddress, isKnown: isKnown),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: tokenResolver.amountText(value, resolved, contractAddress),
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: spender,
          kind: WCDecodedRowKind.address,
        ),
        if (deadline != null)
          WCDecodedRow(
            label: S.current.wc_signature_valid_until,
            value: tokenResolver.formatExpiry(deadline),
          ),
      ],
      warnings: [
        S.current.wc_warning_permit_review,
        if (tokenResolver.isUnlimitedAmount(value)) S.current.wc_warning_unlimited_approval,
        if (!isKnown) S.current.wc_warning_unknown_token,
      ],
    );
  }

  Future<WCDecodedRequest> _buildPermit({
    required List<_PermitDetail> details,
    required String spender,
    required BigInt? sigDeadline,
    required int? chainId,
    bool isSigned = true,
  }) async {
    final resolved = await Future.wait(
      details.map((detail) => tokenResolver.resolve(detail.token)),
    );
    final rows = <WCDecodedRow>[];
    bool hasUnknownToken = false;

    for (final (index, detail) in details.indexed) {
      final isKnown = tokenResolver.isKnown(detail.token, chainId: chainId);
      hasUnknownToken = hasUnknownToken || !isKnown;

      rows.addAll(tokenResolver.tokenRows(resolved[index], detail.token, isKnown: isKnown));
      rows.add(
        WCDecodedRow(
          label: S.current.wc_amount,
          value: tokenResolver.amountText(detail.amount, resolved[index], detail.token),
          kind: WCDecodedRowKind.amount,
        ),
      );
      final expiration = detail.expiration;
      if (expiration != null) {
        rows.add(
          WCDecodedRow(
            label: S.current.wc_expiration,
            value: tokenResolver.formatExpiry(expiration),
          ),
        );
      }
    }

    rows.add(
      WCDecodedRow(
        label: S.current.wc_approved_spender,
        value: spender,
        kind: WCDecodedRowKind.address,
      ),
    );
    if (sigDeadline != null) {
      rows.add(
        WCDecodedRow(
          label: S.current.wc_signature_valid_until,
          value: tokenResolver.formatExpiry(sigDeadline),
        ),
      );
    }

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit2,
      actionSubtitle: "Permit2",
      rows: rows,
      warnings: [
        if (isSigned) S.current.wc_warning_permit_review,
        if (details.any((detail) => tokenResolver.isUnlimitedAmount(detail.amount)))
          S.current.wc_warning_unlimited_approval,
        if (hasUnknownToken) S.current.wc_warning_unknown_token,
      ],
    );
  }

  WCDecodedRequest _opaque(String title) =>
      WCDecodedRequest(actionTitle: title, warnings: [S.current.wc_warning_permit_review]);
}

class _PermitDetail {
  const _PermitDetail(this.token, this.amount, this.expiration);

  final String token;
  final BigInt amount;
  final BigInt? expiration;
}
