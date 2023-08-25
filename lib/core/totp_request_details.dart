import 'package:cake_wallet/core/authentication_request_data.dart';

class TotpResponse {
  TotpResponse({bool success = false, required this.close, String? error})
      : this.success = success,
        this.error = success == false ? error ?? '' : null;

  final bool success;
  final String? error;
  final CloseAuth close;
}

typedef OnTotpAuthenticationFinished = void Function(TotpResponse);

class TotpAuthArgumentsModel {
  final bool? isForSetup;
  final bool? isClosable;
  final bool? showPopup;
  final OnTotpAuthenticationFinished? onTotpAuthenticationFinished;

  TotpAuthArgumentsModel({
    this.isForSetup,
    this.isClosable,
    this.showPopup,
    this.onTotpAuthenticationFinished,
  });
}
