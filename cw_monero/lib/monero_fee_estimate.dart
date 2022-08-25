import 'package:mobx/mobx.dart';
import 'package:cw_core/fee_estimate.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_monero/api/wallet.dart' as monero_wallet;

part 'monero_fee_estimate.g.dart';

class MoneroFeeEstimate = _MoneroFeeEstimate with _$MoneroFeeEstimate;

abstract class _MoneroFeeEstimate extends FeeEstimate with Store {
  _MoneroFeeEstimate()
      : _estimatedFee = new ObservableMap<String, int>();

  @observable
  ObservableMap<String, int> _estimatedFee;

  @override
  void update({TransactionPriority priority, int outputsCount}) {
    Future(() async {
      final fee = await monero_wallet.estimateTransactionFee(priorityRaw: priority.raw, outputsCount: outputsCount);
      set(priority: priority, fee: fee, outputsCount: outputsCount);
    });
  }

  @override
  int get({TransactionPriority priority, int amount, int outputsCount}) {
    return _estimatedFee[_key(priority, outputsCount)] ?? 0;
  }

  @override
  void set({TransactionPriority priority, int outputsCount, int fee}) {
    _estimatedFee[_key(priority, outputsCount)] = fee;
  }

  String _key(TransactionPriority priority, int outputsCount) {
    return "$priority:$outputsCount";
  }
}
