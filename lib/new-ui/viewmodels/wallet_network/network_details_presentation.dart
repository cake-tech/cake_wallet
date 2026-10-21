part of "network_details_bloc.dart";

sealed class NetworkDetailsPresentation {
  const NetworkDetailsPresentation();
}

final class NetworkDetailsSaved extends NetworkDetailsPresentation {
  const NetworkDetailsSaved();
}

final class NetworkDetailsDeleted extends NetworkDetailsPresentation {
  const NetworkDetailsDeleted();
}

final class NetworkDetailsFieldsFilled extends NetworkDetailsPresentation {
  const NetworkDetailsFieldsFilled(this.values);

  final Map<NetworkField, String> values;
}

final class BorrowedTickerConfirmationRequested extends NetworkDetailsPresentation {
  const BorrowedTickerConfirmationRequested({required this.networkName, required this.symbol});

  final String networkName;
  final String symbol;
}

final class NetworkDetailsFailed extends NetworkDetailsPresentation {
  const NetworkDetailsFailed(this.message);

  final String message;
}
