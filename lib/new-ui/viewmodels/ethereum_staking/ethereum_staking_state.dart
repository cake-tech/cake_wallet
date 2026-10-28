part of "ethereum_staking_bloc.dart";

enum EthereumStakingAction { stake, unstake, unstakePending, claimWithdrawal }

@immutable
class EthereumStakingData {
  const EthereumStakingData({
    required this.minStakeAmount,
    required this.poolFee,
    required this.balances,
    required this.restakedRewards,
    required this.withdrawRequest,
    required this.walletBalance,
    this.apr,
    this.activationTime,
    this.totalRewards,
  });

  final Money minStakeAmount;

  final double poolFee; // fraction, e.g. 0.1 for 10%
  final EverstakeEthereumUserBalances balances;
  final Money restakedRewards;
  final EverstakeEthereumWithdrawRequest withdrawRequest;
  final Money walletBalance;

  final double? apr; // fraction, e.g. 0.026 for 2.6%
  final Duration? activationTime;
  final Money? totalRewards;

  bool get canClaimWithdrawal =>
      withdrawRequest.requested.amount > BigInt.zero &&
      withdrawRequest.readyForClaim == withdrawRequest.requested;

  Money get pendingActivation => balances.pendingBalance + balances.pendingDepositedBalance;

  Money get stakedBalance => balances.autocompoundBalance + pendingActivation;

  Money get earned => totalRewards ?? restakedRewards;

  bool get hasPosition => !stakedBalance.isZero || !withdrawRequest.requested.isZero;

  bool get withdrawsPendingStake => !balances.pendingBalance.isZero;

  Money get withdrawableBalance =>
      withdrawsPendingStake ? balances.pendingBalance : balances.autocompoundBalance;
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

  final String error;
}
