import 'package:cake_wallet/generated/i18n.dart';

abstract class Failure {
  const Failure(this.errorMessage);

  final String errorMessage;
}

class ServerFailure extends Failure {
  ServerFailure(int statusCode, {String error}) : super(_formatErrorMessage(statusCode, error));

  static String _formatErrorMessage(int statusCode, String error) {
    switch (statusCode) {
      case 401:
        return S.current.unauthorized;
      case 404:
        return S.current.page_not_found;
      case 500:
        return S.current.server_failure;
      default:
        return error ?? S.current.something_went_wrong;
    }
  }
}

class UnknownFailure extends Failure {
  UnknownFailure({String errorMessage}) : super(errorMessage ?? S.current.something_went_wrong);
}
