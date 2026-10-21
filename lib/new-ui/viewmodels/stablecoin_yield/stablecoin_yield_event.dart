part of "stablecoin_yield_bloc.dart";

@immutable
sealed class StablecoinYieldEvent {
  const StablecoinYieldEvent();
}

final class LoadYieldData extends StablecoinYieldEvent {
  const LoadYieldData();
}

sealed class PrepareTransaction extends StablecoinYieldEvent {
  const PrepareTransaction();
}

final class PrepareDeposit extends PrepareTransaction {
  const PrepareDeposit(this.amount);

  final Money amount;
}

final class PrepareWithdraw extends PrepareTransaction {
  const PrepareWithdraw(this.amount);

  final Money amount;
}

final class PrepareWithdrawAll extends PrepareTransaction {
  const PrepareWithdrawAll();
}

final class SubmitTransaction extends StablecoinYieldEvent {
  const SubmitTransaction();
}
