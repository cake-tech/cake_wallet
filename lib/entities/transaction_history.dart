import 'package:rxdart/rxdart.dart';
import 'package:cake_wallet/entities/transaction_info.dart';

abstract class TransactionHistory {
  Observable<List<TransactionInfo>> transactions;
  Future<List<TransactionInfo>> getAll();
  Future update();
}
