import 'package:cw_core/crypto_currency.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';

class PolygonTransactionCreationException extends EVMChainTransactionCreationException {
  PolygonTransactionCreationException(CryptoCurrency currency) : super(currency);
}
