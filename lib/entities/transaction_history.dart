import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_info.dart';

abstract class TransactionHistory {
  Observable<List<TransactionInfo>> transactions;
  Future<List<TransactionInfo>> getAll();
  Future update();
}
