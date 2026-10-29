part of "everstake_bloc.dart";

enum EverstakeAction { stake, unstake, unstakePending, claimWithdrawal }

@immutable
class EverstakeData {
  const EverstakeData({
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
class EverstakeOperation {
  const EverstakeOperation({
    required this.action,
    required this.amount,
    required this.transaction,
    this.instantUnstakeAmount,
  });

  final EverstakeAction action;
  final Money amount;
  final PendingTransaction transaction;
  final Money? instantUnstakeAmount;
}

@immutable
sealed class EverstakeState {
  const EverstakeState();

  EverstakeData? get data;
}

sealed class EverstakeStateWithData extends EverstakeState {
  const EverstakeStateWithData(this.data);

  @override
  final EverstakeData data;
}

final class EverstakeLoading extends EverstakeState {
  const EverstakeLoading(this.data);

  @override
  final EverstakeData? data;
}

final class EverstakeReady extends EverstakeStateWithData {
  const EverstakeReady(super.data);
}

final class EverstakePreparing extends EverstakeStateWithData {
  const EverstakePreparing(super.data);
}

final class EverstakePrepared extends EverstakeStateWithData {
  const EverstakePrepared(super.data, this.operation);

  final EverstakeOperation operation;
}

final class EverstakeSubmitting extends EverstakeStateWithData {
  const EverstakeSubmitting(super.data, this.operation);

  final EverstakeOperation operation;
}

final class EverstakeSubmitted extends EverstakeStateWithData {
  const EverstakeSubmitted(super.data, this.operation);

  final EverstakeOperation operation;
}

final class EverstakeFailure extends EverstakeState {
  const EverstakeFailure(this.data, this.error);

  @override
  final EverstakeData? data;

  final String error;
}
