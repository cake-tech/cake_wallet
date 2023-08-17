import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SocksProxyNodeAddressValidator extends TextValidator {
  SocksProxyNodeAddressValidator()
      : super(
      errorMessage: S.current.error_text_node_proxy_address,
      pattern:
      '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+\$');
}
