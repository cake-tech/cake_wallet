import "package:cw_core/amount/money.dart";

abstract interface class TronOutputData {
  String get fiatAmount;
  Money get cryptoAmountMoney;
  String get address;
  String get note;
  String get memo;
  bool get sendAll;
  String get extractedAddress;
  bool get isParsedAddress;
}
