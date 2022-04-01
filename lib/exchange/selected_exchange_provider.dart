import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:hive/hive.dart';
part 'selected_exchange_provider.g.dart';

@HiveType(typeId: SelectedExchangeProvider.typeId)
class SelectedExchangeProvider extends HiveObject{
  SelectedExchangeProvider({this.provider});

  static const typeId = 10;
  static const boxName = 'SelectedExchangeProvider';

  @HiveField(0)
  String provider;

}