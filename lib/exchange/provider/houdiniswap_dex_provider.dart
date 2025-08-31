import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/houdiniswap_exchange_provider.dart';

class HoudiniSwapDEXProvider extends HoudiniSwap {
  HoudiniSwapDEXProvider() : super();

  @override
  String get title => 'HoudiniSwap (DEX)';

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.houdiniDex;

  @override
  bool get defaultCexOnly => false;

  @override
  String get tokensPath => '/dexTokens';
}