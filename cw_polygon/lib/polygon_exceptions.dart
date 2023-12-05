import 'package:cw_core/crypto_currency.dart';
import 'package:cw_ethereum/ethereum_exceptions.dart';

class PolygonTransactionCreationException extends EthereumTransactionCreationException {
  PolygonTransactionCreationException(CryptoCurrency currency) : super(currency);
}
