part of "network_details_bloc.dart";

sealed class NetworkDetailsEvent {
  const NetworkDetailsEvent();
}

final class _Init extends NetworkDetailsEvent {
  const _Init();
}

final class NetworkFieldChanged extends NetworkDetailsEvent {
  const NetworkFieldChanged(this.field, this.value);

  final NetworkField field;
  final String value;
}

final class FailoverUrlRevealed extends NetworkDetailsEvent {
  const FailoverUrlRevealed();
}

final class ResetToDefaultRequested extends NetworkDetailsEvent {
  const ResetToDefaultRequested();
}

final class NetworkSaveRequested extends NetworkDetailsEvent {
  const NetworkSaveRequested();
}

final class BorrowedTickerConfirmationAnswered extends NetworkDetailsEvent {
  const BorrowedTickerConfirmationAnswered({required this.isConfirmed});

  final bool isConfirmed;
}

final class NetworkDeleteConfirmed extends NetworkDetailsEvent {
  const NetworkDeleteConfirmed();
}
