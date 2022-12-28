import 'package:cw_core/balance.dart';

class EthereumBalance extends Balance {
  EthereumBalance(super.available, super.additional);

  @override
  // TODO: implement formattedAdditionalBalance
  String get formattedAdditionalBalance => throw UnimplementedError();

  @override
  // TODO: implement formattedAvailableBalance
  String get formattedAvailableBalance => throw UnimplementedError();
}