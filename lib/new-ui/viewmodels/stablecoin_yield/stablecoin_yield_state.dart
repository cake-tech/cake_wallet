part of "stablecoin_yield_bloc.dart";

enum StablecoinYieldAction { approve, deposit, withdraw, withdrawAll }

enum StablecoinYieldError implements Exception {
  networkMismatch,
  nonPositiveAmount,
  exceedsBalance,
  exceedsWithdrawable,
  feeEstimateFailed,
  transactionFailed,
}

@immutable
class StablecoinYieldData {
  const StablecoinYieldData({
    required this.shares,
    required this.positionValue,
    required this.availableLiquidity,
    required this.apy,
  });

  final BigInt shares;
  final Money positionValue;
  final Money? availableLiquidity;
  final double? apy;

  Money? get withdrawableNow {
    final liquidity = availableLiquidity;
    if (liquidity == null) {
      return null;
    }
    return liquidity < positionValue ? liquidity : positionValue;
  }
}

@immutable
class StablecoinYieldOperation {
  const StablecoinYieldOperation({
    required this.action,
    required this.amount,
    required this.transaction,
  });

  final StablecoinYieldAction action;
  final Money amount;
  final PendingTransaction transaction;

  String get transactionHash => transaction.evmTxHashFromRawHex!;
}

@immutable
sealed class StablecoinYieldState {
  const StablecoinYieldState();

  StablecoinYieldData? get data;
}

sealed class StablecoinYieldStateWithData extends StablecoinYieldState {
  const StablecoinYieldStateWithData(this.data);

  @override
  final StablecoinYieldData data;
}

final class StablecoinYieldLoading extends StablecoinYieldState {
  const StablecoinYieldLoading(this.data);

  @override
  final StablecoinYieldData? data;
}

final class StablecoinYieldReady extends StablecoinYieldStateWithData {
  const StablecoinYieldReady(super.data);
}

final class StablecoinYieldPreparing extends StablecoinYieldStateWithData {
  const StablecoinYieldPreparing(super.data);
}

final class StablecoinYieldPrepared extends StablecoinYieldStateWithData {
  const StablecoinYieldPrepared(super.data, this.operation);

  final StablecoinYieldOperation operation;
}

final class StablecoinYieldSubmitting extends StablecoinYieldStateWithData {
  const StablecoinYieldSubmitting(super.data, this.operation);

  final StablecoinYieldOperation operation;
}

final class StablecoinYieldConfirming extends StablecoinYieldStateWithData {
  const StablecoinYieldConfirming(super.data, this.operation);

  final StablecoinYieldOperation operation;
}

final class StablecoinYieldConfirmed extends StablecoinYieldStateWithData {
  const StablecoinYieldConfirmed(super.data, this.operation);

  final StablecoinYieldOperation operation;
}

final class StablecoinYieldFailure extends StablecoinYieldState {
  const StablecoinYieldFailure(this.data, this.error);

  @override
  final StablecoinYieldData? data;

  final Object error;
}
