import 'package:cw_core/amount/money.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/keyable.dart';

abstract class TransactionInfo extends Object with Keyable {
  late String id;
  late String txHash = id;
  late Money amount;
  Money? fee;
  late TransactionDirection direction;
  late bool isPending;
  late DateTime date;
  int? height;
  int confirmations = 0;
  String? to;
  String? from;
  String? evmSignatureName;
  bool? isReplaced;
  List<String>? inputAddresses;
  List<String>? outputAddresses;

  @override
  dynamic get keyIndex => id;

  Map<String, dynamic> additionalInfo = {};

  /// Whether the displayed amount (and direction) may still change.
  ///
  /// The amount is computed from the inputs this wallet owns, and ownership is
  /// resolved input by input, so it can grow until every input is resolved.
  /// This also covers a tx still classified as incoming only because an
  /// input's ownership can't be told without its parent (e.g. P2TR key-path):
  /// it may turn out to be a send, with its change shown as a receive.
  ///
  /// Always false for wallets other than Electrum, which never set the
  /// `additionalInfo` flags read here.
  bool get isAmountPending {
    final inputsOwnershipFullyResolved = additionalInfo['inputsOwnershipFullyResolved'] as bool?;

    // Checked first: every input being resolved guarantees the amount is
    // exact, safe since this tx will never be re-fetched to change it.
    if (inputsOwnershipFullyResolved == true) {
      return false;
    }

    final isWalletDisplayAmountExact = additionalInfo['isWalletDisplayAmountExact'] as bool?;

    // Amount depends only on our own inputs, so it can be final before
    // foreign inputs resolve.
    if (isWalletDisplayAmountExact != null) {
      return !isWalletDisplayAmountExact;
    }

    // History saved before isWalletDisplayAmountExact existed.
    return inputsOwnershipFullyResolved == false;
  }

  String? _fiatAmount;
  String fiatAmount() => _fiatAmount ?? '';
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);
}
