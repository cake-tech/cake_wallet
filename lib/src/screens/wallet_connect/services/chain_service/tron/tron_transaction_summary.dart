import "dart:convert";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:on_chain/tron/tron.dart";

class TronTransactionSummary {
  const TronTransactionSummary({
    required this.title,
    required this.rows,
    required this.extraRows,
    required this.ownerAddress,
  });

  factory TronTransactionSummary.of(
    TransactionRaw rawTransaction,
    Map<String, CryptoCurrency> tokensByContract,
  ) {
    if (rawTransaction.contract.length != 1) {
      throw ArgumentError("transaction must carry exactly one contract");
    }

    final contract = rawTransaction.contract.first;
    final value = contract.parameter.value;
    if (contract.type != value.contractType) {
      throw ArgumentError("contract type tag does not match the contract");
    }

    String title;
    final rows = <WCDecodedRow>[];
    final extraRows = <WCDecodedRow>[];
    String? ownerAddress;
    String? callData;

    if (value is TransferContract) {
      ownerAddress = value.ownerAddress.toAddress();
      title = S.current.send;
      rows.add(_amountRow(_trx(value.amount)));
      rows.add(_addressRow(S.current.from, ownerAddress));
      rows.add(_addressRow(S.current.to, value.toAddress.toAddress()));
    } else if (value is TriggerSmartContract) {
      ownerAddress = value.ownerAddress.toAddress();
      final contractAddress = value.contractAddress.toAddress();
      final token = tokensByContract[contractAddress];
      final callValue = value.callValue ?? BigInt.zero;
      final callTokenValue = value.callTokenValue ?? BigInt.zero;
      final call = callValue > BigInt.zero || callTokenValue > BigInt.zero
          ? null
          : _Trc20Call.tryDecode(value.data);

      if (call != null) {
        if (call.isIncrease) {
          title = S.current.wc_increase_allowance;
        } else if (call.isApprove) {
          title = S.current.approve_tokens;
        } else {
          title = S.current.send;
        }
        rows.add(_amountRow(_tokenAmount(call.amount, token, call.isApprove)));
        rows.add(_addressRow(S.current.from, ownerAddress));
        final counterparty = call.isApprove ? S.current.wc_approved_address : S.current.to;
        rows.add(_addressRow(counterparty, call.address));
      } else {
        title = S.current.wc_contract_call;
        rows.add(_addressRow(S.current.from, ownerAddress));
        rows.add(_addressRow(S.current.to, contractAddress));
        callData = BytesUtils.toHexString(value.data ?? const [], prefix: "0x");
      }

      if (callValue > BigInt.zero) {
        rows.add(_amountRow(_trx(callValue)));
      }

      if (callTokenValue > BigInt.zero) {
        final tokenAmount = S.current.wc_raw_amount(callTokenValue.toString());
        rows.add(
          WCDecodedRow(label: S.current.token, value: "TRC10 ${value.tokenId ?? ""}, $tokenAmount"),
        );
      }

      if (token != null) {
        extraRows.add(WCDecodedRow(label: S.current.token, value: token.title));
      }
      extraRows.add(_addressRow(S.current.contract_address, contractAddress));
    } else {
      final json = value.toJson()..removeWhere((_, field) => field == null);
      ownerAddress = json["owner_address"]?.toString();
      title = contract.type.name;
      for (final entry in _withTrxAmounts(json).entries) {
        final field = entry.value;
        rows.add(
          WCDecodedRow(
            label: entry.key,
            value: field is Map || field is List ? _prettyJson.convert(field) : field.toString(),
          ),
        );
      }
    }
    final feeLimit =
        rawTransaction.feeLimit ?? (value is TriggerSmartContract ? BigInt.zero : null);
    if (feeLimit != null) {
      extraRows.add(WCDecodedRow(label: S.current.wc_max_network_fee, value: _trx(feeLimit)));
    }

    final memo = rawTransaction.data;
    if (memo != null && memo.isNotEmpty) {
      extraRows.add(
        WCDecodedRow(label: S.current.memo, value: utf8.decode(memo, allowMalformed: true)),
      );
    }

    if (callData != null) {
      extraRows.add(WCDecodedRow(label: S.current.wc_call_data, value: callData));
    }

    return TronTransactionSummary(
      title: title,
      rows: rows,
      extraRows: extraRows,
      ownerAddress: ownerAddress,
    );
  }

  final String title;
  final List<WCDecodedRow> rows;
  final List<WCDecodedRow> extraRows;

  final String? ownerAddress;

  static WCDecodedRow _amountRow(String amount) =>
      WCDecodedRow(label: S.current.value, value: amount, kind: WCDecodedRowKind.amount);

  static WCDecodedRow _addressRow(String label, String address) =>
      WCDecodedRow(label: label, value: address, kind: WCDecodedRowKind.address);

  static final _unlimitedAllowance = (BigInt.one << 256) - BigInt.one;

  static const _sunFields = {"frozen_balance", "unfreeze_balance", "balance"};

  static Map<String, dynamic> _withTrxAmounts(Map<String, dynamic> json) => {
        for (final entry in json.entries)
          entry.key: _sunFields.contains(entry.key) ? _trxOrOriginal(entry.value) : entry.value,
      };

  static Object? _trxOrOriginal(Object? value) {
    final sun = value is String ? BigInt.tryParse(value) : null;

    return sun == null ? value : _trx(sun);
  }

  static final _prettyJson = JsonEncoder.withIndent("  ", (value) => value.toString());

  static String _trx(BigInt sun) => Money(sun, CryptoCurrency.trx).toStringWithSymbol();

  static String _tokenAmount(BigInt amount, CryptoCurrency? token, bool isAllowance) {
    if (isAllowance && amount == _unlimitedAllowance) {
      return token == null ? S.current.wc_unlimited : "${S.current.wc_unlimited} ${token.title}";
    }

    if (token == null) {
      return S.current.wc_raw_amount(amount.toString());
    }

    return Money(amount, token).toStringWithSymbol();
  }
}

class _Trc20Call {
  const _Trc20Call({
    required this.isApprove,
    required this.isIncrease,
    required this.address,
    required this.amount,
  });

  final bool isApprove;
  final bool isIncrease;
  final String address;
  final BigInt amount;

  static const _transferSelector = "a9059cbb";
  static const _approveSelector = "095ea7b3";
  static const _increaseApprovalSelector = "d73dd623";

  static _Trc20Call? tryDecode(List<int>? data) {
    if (data == null || data.length != 68) {
      return null;
    }

    final selector = BytesUtils.toHexString(data.sublist(0, 4));
    final isApprove = selector == _approveSelector || selector == _increaseApprovalSelector;
    if (!isApprove && selector != _transferSelector) {
      return null;
    }

    if (data.sublist(4, 16).any((byte) => byte != 0)) {
      return null;
    }

    return _Trc20Call(
      isApprove: isApprove,
      isIncrease: selector == _increaseApprovalSelector,
      address: TronAddress.fromEthAddress(data.sublist(16, 36)).toAddress(),
      amount: BigintUtils.fromBytes(data.sublist(36, 68)),
    );
  }
}
