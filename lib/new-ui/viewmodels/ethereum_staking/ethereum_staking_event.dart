part of "ethereum_staking_bloc.dart";

@immutable
sealed class EthereumStakingEvent {
  const EthereumStakingEvent();
}

final class StakingDataRequested extends EthereumStakingEvent {
  const StakingDataRequested();
}

sealed class TransactionRequested extends EthereumStakingEvent {
  const TransactionRequested();
}

final class StakeRequested extends TransactionRequested {
  const StakeRequested(this.amount);

  final Money amount;
}

final class MaxStakeRequested extends TransactionRequested {
  const MaxStakeRequested();
}

final class UnstakeRequested extends TransactionRequested {
  const UnstakeRequested(this.amount);

  final Money amount;
}

final class PendingUnstakeRequested extends TransactionRequested {
  const PendingUnstakeRequested(this.amount);

  final Money amount;
}

final class WithdrawalClaimRequested extends TransactionRequested {
  const WithdrawalClaimRequested();
}

final class TransactionConfirmed extends EthereumStakingEvent {
  const TransactionConfirmed(this.operation);

  final EthereumStakingOperation operation;
}
