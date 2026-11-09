part of "morpho_bloc.dart";

@immutable
sealed class MorphoEvent {
  const MorphoEvent();
}

final class YieldDataRequested extends MorphoEvent {
  const YieldDataRequested();
}

sealed class TransactionRequested extends MorphoEvent {
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

final class TransactionConfirmed extends MorphoEvent {
  const TransactionConfirmed(this.operation);

  final MorphoOperation operation;
}
