import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/houdiniswap_exchange_provider.dart';

class HoudiniSwapCEXProvider extends HoudiniSwap {
  HoudiniSwapCEXProvider() : super();

  @override
  String get title => 'HoudiniSwap (CEX)';

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.houdiniCex;

  @override
  bool get defaultCexOnly => true;

  @override
  String get tokensPath => '/tokens';
}