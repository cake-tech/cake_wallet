import 'package:cw_zano/api/consts.dart';
import 'package:cw_zano/api/exceptions/api_exception.dart';

class AlreadyExistsException extends ApiException {
  AlreadyExistsException(String message): super(Consts.errorAlreadyExists, message);
}