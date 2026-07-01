import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa_enter_code_page.dart';

class TotpAuthArgumentsModel {
  final bool? isForSetup;
  final bool? isClosable;
  final OnTotpAuthenticationFinished? onTotpAuthenticationFinished;

  TotpAuthArgumentsModel({
    this.isForSetup,
    this.isClosable,
    this.onTotpAuthenticationFinished,
  });
}
