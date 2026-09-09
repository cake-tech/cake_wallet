import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class Permit2Decoder {
  Permit2Decoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String? contractAddress,
  }) async {
    switch (calldata.selector) {
      case EvmSelectors.permit2Permit:
        return _decodePermitSingle(calldata);
      case EvmSelectors.permit2PermitBatch:
        return _decodePermitBatch(calldata);
      case EvmSelectors.permit2PermitTransferFrom:
        return _decodePermitTransferFrom(calldata);
      case EvmSelectors.permit2TransferFrom:
        return _decodePermit2TransferFrom(calldata);
      case EvmSelectors.erc2612Permit:
        return _decodeErc2612Permit(calldata, contractAddress);
    }
    return null;
  }

  Future<WCDecodedRequest?> _decodePermitSingle(EvmCalldata calldata) async {
    final token = calldata.addressAt(1);
    final amount = calldata.uintAt(2);
    final expiration = calldata.uintAt(3);
    final spender = calldata.addressAt(5);
    final sigDeadline = calldata.uintAt(6);
    if (token == null || amount == null || spender == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    return _buildPermit(
      title: S.current.wc_action_permit2,
      details: [_PermitDetail(token, amount, expiration)],
      spender: spender,
      sigDeadline: sigDeadline,
    );
  }

  Future<WCDecodedRequest?> _decodePermitBatch(EvmCalldata calldata) async {
    final struct = calldata.structAt(1);
    if (struct == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    final spender = struct.addressAt(1);
    final sigDeadline = struct.uintAt(2);
    final detailsArray = struct.structAt(0);
    final count = detailsArray?.uintAt(0)?.toInt();
    if (spender == null || detailsArray == null || count == null || count <= 0 || count > 64) {
      return _opaque(S.current.wc_action_permit2);
    }

    final details = <_PermitDetail>[];
    for (var i = 0; i < count; i++) {
      final base = 1 + i * 4;
      final token = detailsArray.addressAt(base);
      final amount = detailsArray.uintAt(base + 1);
      final expiration = detailsArray.uintAt(base + 2);
      if (token == null || amount == null) {
        return _opaque(S.current.wc_action_permit2);
      }
      details.add(_PermitDetail(token, amount, expiration));
    }

    return _buildPermit(
      title: S.current.wc_action_permit2,
      details: details,
      spender: spender,
      sigDeadline: sigDeadline,
    );
  }

  Future<WCDecodedRequest?> _decodePermitTransferFrom(EvmCalldata calldata) async {
    final token = calldata.addressAt(0);
    final amount = calldata.uintAt(1);
    final deadline = calldata.uintAt(3);
    final toAddr = calldata.addressAt(4);
    final requestedAmount = calldata.uintAt(5);
    if (token == null || amount == null || toAddr == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    final resolved = await tokenResolver.resolve(token);
    final symbol = tokenResolver.symbolOrShort(resolved, token);
    final shownAmount = requestedAmount ?? amount;

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit2,
      actionSubtitle: "Permit2",
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: tokenResolver.displayName(resolved, symbol)),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "${tokenResolver.formatAmount(shownAmount, resolved)} $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(label: S.current.to, value: toAddr, kind: WCDecodedRowKind.address),
        if (deadline != null)
          WCDecodedRow(
            label: S.current.wc_signature_valid_until,
            value: tokenResolver.formatTimestamp(deadline),
          ),
      ],
      warnings: [
        S.current.wc_warning_permit_review,
        if (resolved == null) S.current.wc_warning_unknown_token,
      ],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodePermit2TransferFrom(EvmCalldata calldata) async {
    final fromAddr = calldata.addressAt(0);
    final toAddr = calldata.addressAt(1);
    final amount = calldata.uintAt(2);
    final token = calldata.addressAt(3);
    if (fromAddr == null || toAddr == null || amount == null || token == null) {
      return _opaque(S.current.wc_action_permit2);
    }

    final resolved = await tokenResolver.resolve(token);
    final symbol = tokenResolver.symbolOrShort(resolved, token);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_transfer,
      actionSubtitle: "Permit2",
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: tokenResolver.displayName(resolved, symbol)),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "${tokenResolver.formatAmount(amount, resolved)} $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(label: S.current.from, value: fromAddr, kind: WCDecodedRowKind.address),
        WCDecodedRow(label: S.current.to, value: toAddr, kind: WCDecodedRowKind.address),
      ],
      warnings: [if (resolved == null) S.current.wc_warning_unknown_token],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodeErc2612Permit(
    EvmCalldata calldata,
    String? contractAddress,
  ) async {
    final spender = calldata.addressAt(1);
    final value = calldata.uintAt(2);
    final deadline = calldata.uintAt(3);
    if (spender == null || value == null || contractAddress == null) {
      return _opaque(S.current.wc_action_permit);
    }

    final resolved = await tokenResolver.resolve(contractAddress);
    final symbol = tokenResolver.symbolOrShort(resolved, contractAddress);
    final unlimited = tokenResolver.isUnlimitedAmount(value);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit,
      actionSubtitle: tokenResolver.displayName(resolved, symbol),
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: tokenResolver.displayName(resolved, symbol)),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "${tokenResolver.formatAmount(value, resolved)} $symbol",
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
            value: tokenResolver.formatTimestamp(deadline),
          ),
      ],
      warnings: [
        S.current.wc_warning_permit_review,
        if (unlimited) S.current.wc_warning_unlimited_approval,
        if (resolved == null) S.current.wc_warning_unknown_token,
      ],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest> _buildPermit({
    required String title,
    required List<_PermitDetail> details,
    required String spender,
    required BigInt? sigDeadline,
  }) async {
    final rows = <WCDecodedRow>[];
    bool unlimited = false;
    bool unknownToken = false;

    for (final detail in details) {
      final resolved = await tokenResolver.resolve(detail.token);
      final symbol = tokenResolver.symbolOrShort(resolved, detail.token);
      unknownToken = unknownToken || resolved == null;
      unlimited = unlimited || tokenResolver.isUnlimitedAmount(detail.amount);

      rows.add(
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenResolver.displayName(resolved, symbol),
        ),
      );
      rows.add(
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "${tokenResolver.formatAmount(detail.amount, resolved)} $symbol",
          kind: WCDecodedRowKind.amount,
        ),
      );
      if (detail.expiration != null) {
        rows.add(
          WCDecodedRow(
            label: S.current.wc_expiration,
            value: tokenResolver.formatTimestamp(detail.expiration),
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
          value: tokenResolver.formatTimestamp(sigDeadline),
        ),
      );
    }

    return WCDecodedRequest(
      actionTitle: title,
      actionSubtitle: "Permit2",
      rows: rows,
      warnings: [
        S.current.wc_warning_permit_review,
        if (unlimited) S.current.wc_warning_unlimited_approval,
        if (unknownToken) S.current.wc_warning_unknown_token,
      ],
      hideTo: true,
    );
  }

  WCDecodedRequest _opaque(String title) => WCDecodedRequest(
        actionTitle: title,
        warnings: [S.current.wc_warning_permit_review],
        hideTo: true,
      );
}

class _PermitDetail {
  const _PermitDetail(this.token, this.amount, this.expiration);

  final String token;
  final BigInt amount;
  final BigInt? expiration;
}
