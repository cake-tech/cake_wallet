import 'dart:core';

import 'package:cw_core/transaction_history.dart';
import 'package:cw_monero/monero_transaction_info.dart';

// History lives in the wallet file, which the wallet itself persists — so this
// is not a SavableTransactionHistory.
class MoneroTransactionHistory extends TransactionHistory<MoneroTransactionInfo> {}
