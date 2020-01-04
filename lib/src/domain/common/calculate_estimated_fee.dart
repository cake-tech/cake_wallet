import 'package:cake_wallet/src/domain/common/transaction_priority.dart';

double calculateEstimatedFee({TransactionPriority priority}) {
  if (priority == TransactionPriority.slow) {
    return 0.00002459;
  }

  if (priority == TransactionPriority.regular) {
    return 0.00012305;
  }

  if (priority == TransactionPriority.medium) {
    return 0.00024503;
  }

  if (priority == TransactionPriority.fast) {
    return 0.00061453;
  }

  if (priority == TransactionPriority.fastest) {
    return 0.0260216;
  }

  return 0;
}