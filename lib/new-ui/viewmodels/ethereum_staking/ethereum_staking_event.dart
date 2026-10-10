part of "ethereum_staking_bloc.dart";

@immutable
sealed class EthereumStakingEvent {
  const EthereumStakingEvent();
}

final class LoadStakingData extends EthereumStakingEvent {
  const LoadStakingData();
}

sealed class PrepareTransaction extends EthereumStakingEvent {
  const PrepareTransaction();
}

final class PrepareStake extends PrepareTransaction {
  const PrepareStake(this.amount);

  final Money amount;
}

final class PrepareUnstake extends PrepareTransaction {
  const PrepareUnstake(this.amount);

  final Money amount;
}

final class PreparePendingUnstake extends PrepareTransaction {
  const PreparePendingUnstake(this.amount);

  final Money amount;
}

final class PrepareWithdrawalClaim extends PrepareTransaction {
  const PrepareWithdrawalClaim();
}

final class SubmitTransaction extends EthereumStakingEvent {
  const SubmitTransaction();
}
