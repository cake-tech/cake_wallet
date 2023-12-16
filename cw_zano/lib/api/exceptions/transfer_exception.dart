import 'package:cw_zano/api/exceptions/api_exception.dart';

class TransferException extends ApiException {
  TransferException(String code, String message): super(code, message);
}
