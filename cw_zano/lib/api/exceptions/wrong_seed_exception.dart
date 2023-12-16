import 'package:cw_zano/api/consts.dart';
import 'package:cw_zano/api/exceptions/api_exception.dart';

class WrongSeedException extends ApiException {
  WrongSeedException(String message): super(Consts.errorWrongSeed, message);
}