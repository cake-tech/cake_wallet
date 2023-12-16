import 'package:cw_zano/api/exceptions/api_exception.dart';

class RestoreFromSeedException extends ApiException {
  RestoreFromSeedException(String code, String message): super(code, message);
}