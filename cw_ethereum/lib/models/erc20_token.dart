import 'package:cw_core/keyable.dart';
import 'package:hive/hive.dart';

part 'erc20_token.g.dart';

@HiveType(typeId: Erc20Token.typeId)
class Erc20Token extends HiveObject with Keyable {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String symbol;
  @HiveField(2)
  final String contractAddress;

  Erc20Token({required this.name, required this.symbol, required this.contractAddress});

  static const typeId = 12;
  static const boxName = 'Erc20Tokens';

  @override
  bool operator ==(other) =>
      other is Erc20Token &&
      (other.name == name && other.symbol == symbol && other.contractAddress == contractAddress);

  @override
  int get hashCode => name.hashCode ^ symbol.hashCode ^ contractAddress.hashCode;

  @override
  dynamic get keyIndex {
    _keyIndex ??= key;
    return _keyIndex;
  }

  dynamic _keyIndex;
}
