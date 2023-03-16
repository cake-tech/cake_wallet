import 'package:web3dart/web3dart.dart';

class EthereumFormatter {
  static int parseEthereumAmount(String amount) =>
      EtherAmount.fromUnitAndValue(EtherUnit.ether, amount).getInWei.toInt();
}