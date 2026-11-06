part of "morpho_bloc.dart";

enum MorphoAction { approve, deposit, withdraw, withdrawAll }

@immutable
class MorphoData {
  const MorphoData({
    required this.shares,
    required this.positionValue,
    required this.walletBalance,
    required this.availableLiquidity,
    required this.apy,
    required this.earned,
  });

  final BigInt shares;
  final Money positionValue;
  final Money walletBalance;
  final Money? availableLiquidity;
  final double? apy;
  final Money? earned;

  bool get hasPosition => shares > BigInt.zero;

  Money? get withdrawableNow {
    final liquidity = availableLiquidity;
    if (liquidity == null) {
      return null;
    }
    return liquidity < positionValue ? liquidity : positionValue;
  }
}

@immutable
class MorphoOperation {
  const MorphoOperation({
    required this.action,
    required this.amount,
    required this.transaction,
  });

  final MorphoAction action;
  final Money amount;
  final PendingTransaction transaction;

  String get transactionHash => transaction.evmTxHashFromRawHex!;
}

@immutable
sealed class MorphoState {
  const MorphoState();

  MorphoData? get data;

  bool get isBusy => false;
}

sealed class MorphoStateWithData extends MorphoState {
  const MorphoStateWithData(this.data);

  @override
  final MorphoData data;
}

final class MorphoLoading extends MorphoState {
  const MorphoLoading(this.data);

  @override
  final MorphoData? data;

  @override
  bool get isBusy => true;
}

final class MorphoReady extends MorphoStateWithData {
  const MorphoReady(super.data);
}

final class MorphoPreparing extends MorphoStateWithData {
  const MorphoPreparing(super.data);

  @override
  bool get isBusy => true;
}

final class MorphoPrepared extends MorphoStateWithData {
  const MorphoPrepared(super.data, this.operation);

  final MorphoOperation operation;
}

final class MorphoSubmitting extends MorphoStateWithData {
  const MorphoSubmitting(super.data, this.operation);

  final MorphoOperation operation;

  @override
  bool get isBusy => true;
}

final class MorphoConfirming extends MorphoStateWithData {
  const MorphoConfirming(super.data, this.operation);

  final MorphoOperation operation;

  @override
  bool get isBusy => true;
}

final class MorphoConfirmed extends MorphoStateWithData {
  const MorphoConfirmed(super.data, this.operation);

  final MorphoOperation operation;
}

final class MorphoFailure extends MorphoState {
  const MorphoFailure(this.data, this.error);

  @override
  final MorphoData? data;

  final String error;
}
