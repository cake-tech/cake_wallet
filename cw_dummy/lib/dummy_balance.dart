import 'package:cw_core/balance.dart';

class DummyBalance extends Balance {
  DummyBalance(super.available, super.additional);

  @override
  // TODO: implement formattedAdditionalBalance
  String get formattedAdditionalBalance => throw UnimplementedError();

  @override
  // TODO: implement formattedAvailableBalance
  String get formattedAvailableBalance => throw UnimplementedError();

}