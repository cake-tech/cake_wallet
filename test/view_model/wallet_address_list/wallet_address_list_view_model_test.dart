import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("PaymentURI", () {

    group("TariURI", () {
      test("uri with amont", () {
        final uri = TariURI(network: "nextnet", amount: "5000000", base58Address: "349jdYen2RMBGeWm1SyUBzEsfqSJ9NGGiZXAsWUK3TQQbdeQ3wJJnjRwi1EzUqxdAhNQ4YcRmFFDLvtXxx8kBgBboXb", address: '349jdYen2RMBGeWm1SyUBzEsfqSJ9NGGiZXAsWUK3TQQbdeQ3wJJnjRwi1EzUqxdAhNQ4YcRmFFDLvtXxx8kBgBboXb');

        expect(uri.toString(), "tari://nextnet/transactions/send?tariAddress=349jdYen2RMBGeWm1SyUBzEsfqSJ9NGGiZXAsWUK3TQQbdeQ3wJJnjRwi1EzUqxdAhNQ4YcRmFFDLvtXxx8kBgBboXb&amount=5000000");
      });
    });
  });
}
