part of "everstake_bloc.dart";

@immutable
sealed class EverstakeEvent {
  const EverstakeEvent();
}

final class StakingDataRequested extends EverstakeEvent {
  const StakingDataRequested();
}

sealed class TransactionRequested extends EverstakeEvent {
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

final class MaxUnstakeRequested extends TransactionRequested {
  const MaxUnstakeRequested({required this.pending});

  final bool pending;
}

final class PendingUnstakeRequested extends TransactionRequested {
  const PendingUnstakeRequested(this.amount);

  final Money amount;
}

final class WithdrawalClaimRequested extends TransactionRequested {
  const WithdrawalClaimRequested();
}

final class TransactionConfirmed extends EverstakeEvent {
  const TransactionConfirmed(this.operation);

  final EverstakeOperation operation;
}
