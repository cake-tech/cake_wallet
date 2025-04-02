import 'package:cw_xelis/src/api/utils.dart';

Future<String> formatAmountWithSymbol(
  BigInt rawAmount, {
  required int decimals,
  String? symbol,
}) async {
  final formatted = await formatCoin(value: rawAmount, decimals: decimals);
  final symbol = assetId == null || assetId == xelisAsset ? 'XEL' : assetId;
  return '$formatted $symbol';
}