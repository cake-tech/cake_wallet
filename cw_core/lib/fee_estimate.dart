import 'package:cw_core/transaction_priority.dart';

abstract class FeeEstimate
{
  void update({TransactionPriority priority, int outputsCount});

  int get({TransactionPriority priority, int amount, int outputsCount});

  void set({TransactionPriority priority, int outputsCount, int fee});
}