import 'package:cake_wallet/entities/monero_transaction_priority.dart';

double calculateEstimatedFee({MoneroTransactionPriority priority}) {
  if (priority == MoneroTransactionPriority.slow) {
    return 0.00002459;
  }

  if (priority == MoneroTransactionPriority.regular) {
    return 0.00012305;
  }

  if (priority == MoneroTransactionPriority.medium) {
    return 0.00024503;
  }

  if (priority == MoneroTransactionPriority.fast) {
    return 0.00061453;
  }

  if (priority == MoneroTransactionPriority.fastest) {
    return 0.0260216;
  }

  return 0;
}