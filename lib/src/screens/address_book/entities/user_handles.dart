import 'package:cake_wallet/address_resolver/parsed_address.dart';

class UserHandles {
  factory UserHandles({required String handleKey}) {
    assert(handleKey.isNotEmpty, 'handleKey cannot be empty');

    final dash = handleKey.indexOf('-');

    final prefix = dash == -1 ? handleKey : handleKey.substring(0, dash);
    final label =
        dash == -1 || dash == handleKey.length - 1 ? handleKey : handleKey.substring(dash + 1);

    final src = AddressSourceNameParser.fromLabel(prefix);

    return UserHandles._(handleKey, label, src);
  }

  const UserHandles._(this.handleKey, this.label, this.src);

  final String handleKey;
  final String label;
  final AddressSource? src;
}
