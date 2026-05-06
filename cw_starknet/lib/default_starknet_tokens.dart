import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/starknet_token.dart';
import 'package:cw_starknet/starknet_client.dart';

class DefaultStarknetTokens {
  List<StarknetToken> get initialStarknetTokens => [
        StarknetToken(
          name: 'Ethereum',
          symbol: 'ETH',
          contractAddress: StarknetTokenAddresses.eth,
          decimal: CryptoCurrency.eth.decimals,
          iconPath: CryptoCurrency.eth.iconPath,
        ),
      ];
}
