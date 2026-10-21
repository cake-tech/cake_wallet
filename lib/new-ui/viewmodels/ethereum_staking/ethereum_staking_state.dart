part of "ethereum_staking_bloc.dart";

enum EthereumStakingAction { stake, unstake, unstakePending, claimWithdrawal }

enum EthereumStakingError implements Exception {
  nonPositiveAmount,
  belowMinimum,
  exceedsBalance,
  remainderBelowMinimum,
  withdrawalNotReady,
  notMainnet,
}

@immutable
class EthereumStakingData {
  const EthereumStakingData({
    required this.minStakeAmount,
    required this.poolFee,
    required this.balances,
    required this.restakedRewards,
    required this.withdrawRequest,
  });

  final Money minStakeAmount;
  final String poolFee;
  final EverstakeEthereumUserBalances balances;
  final Money restakedRewards;
  final EverstakeEthereumWithdrawRequest withdrawRequest;

  bool get canClaimWithdrawal =>
      withdrawRequest.requested.amount > BigInt.zero &&
      withdrawRequest.readyForClaim == withdrawRequest.requested;
}

@immutable
class EthereumStakingOperation {
  const EthereumStakingOperation({
    required this.action,
    required this.amount,
    required this.transaction,
    this.instantUnstakeAmount,
  });

  final EthereumStakingAction action;
  final Money amount;
  final PendingTransaction transaction;
  final Money? instantUnstakeAmount;

  String get transactionHash => transaction.evmTxHashFromRawHex!;
}

@immutable
sealed class EthereumStakingState {
  const EthereumStakingState();

  EthereumStakingData? get data;
}

sealed class EthereumStakingStateWithData extends EthereumStakingState {
  const EthereumStakingStateWithData(this.data);

  @override
  final EthereumStakingData data;
}

final class EthereumStakingLoading extends EthereumStakingState {
  const EthereumStakingLoading(this.data);

  @override
  final EthereumStakingData? data;
}

final class EthereumStakingReady extends EthereumStakingStateWithData {
  const EthereumStakingReady(super.data);
}

final class EthereumStakingPreparing extends EthereumStakingStateWithData {
  const EthereumStakingPreparing(super.data);
}

final class EthereumStakingPrepared extends EthereumStakingStateWithData {
  const EthereumStakingPrepared(super.data, this.operation);

  final EthereumStakingOperation operation;
}

final class EthereumStakingSubmitting extends EthereumStakingStateWithData {
  const EthereumStakingSubmitting(super.data, this.operation);

  final EthereumStakingOperation operation;
}

final class EthereumStakingSubmitted extends EthereumStakingStateWithData {
  const EthereumStakingSubmitted(super.data, this.operation);

  final EthereumStakingOperation operation;
}

final class EthereumStakingFailure extends EthereumStakingState {
  const EthereumStakingFailure(this.data, this.error);

  @override
  final EthereumStakingData? data;

  /// An [EthereumStakingError], or whatever loading, signing or broadcasting threw.
  final Object error;
}
