import 'package:rxdart/rxdart.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';

abstract class TransactionHistory {
  Observable<List<TransactionInfo>> transactions;
  Future<List<TransactionInfo>> getAll();
  Future<int> count();
  Future refresh();
  Future update();
}
