part of "stablecoin_yield_bloc.dart";

@immutable
sealed class StablecoinYieldEvent {
  const StablecoinYieldEvent();
}

final class YieldDataRequested extends StablecoinYieldEvent {
  const YieldDataRequested();
}

sealed class TransactionRequested extends StablecoinYieldEvent {
  const TransactionRequested();
}

final class DepositRequested extends TransactionRequested {
  const DepositRequested(this.amount);

  final Money amount;
}

final class WithdrawRequested extends TransactionRequested {
  const WithdrawRequested(this.amount);

  final Money amount;
}

final class WithdrawAllRequested extends TransactionRequested {
  const WithdrawAllRequested();
}

final class TransactionConfirmed extends StablecoinYieldEvent {
  const TransactionConfirmed(this.operation);

  final StablecoinYieldOperation operation;
}
