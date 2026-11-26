import "package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart";
import "package:flutter_test/flutter_test.dart";
import "package:reown_walletkit/reown_walletkit.dart";

void main() {
  group("hasConflictingCalldata", () {
    const transfer = "0xa9059cbb000000000000000000000000000000000000000000000000000000000000dead";
    const approve = "0x095ea7b3000000000000000000000000000000000000000000000000000000000000beef";

    test("data and input that differ conflict", () {
      expect(EthUtils.hasConflictingCalldata({"data": approve, "input": transfer}), isTrue);
    });

    test("the same bytes in both fields, in any case or prefix, do not conflict", () {
      expect(EthUtils.hasConflictingCalldata({"data": transfer, "input": transfer}), isFalse);
      expect(
        EthUtils.hasConflictingCalldata({
          "data": transfer.toUpperCase().replaceFirst("0X", "0x"),
          "input": transfer.substring(2),
        }),
        isFalse,
      );
    });

    test("an empty field next to calldata conflicts in either order", () {
      expect(EthUtils.hasConflictingCalldata({"data": "0x", "input": transfer}), isTrue);
      expect(EthUtils.hasConflictingCalldata({"data": transfer, "input": "0x"}), isTrue);
    });

    test("one field alone never conflicts", () {
      expect(EthUtils.hasConflictingCalldata({"input": transfer}), isFalse);
      expect(EthUtils.hasConflictingCalldata({"data": transfer}), isFalse);
      expect(EthUtils.hasConflictingCalldata({"data": "0x", "input": ""}), isFalse);
      expect(EthUtils.hasConflictingCalldata({}), isFalse);
    });
  });

  group("hasMalformedQuantity", () {
    test("hex quantities with the prefix pass", () {
      expect(
        EthUtils.hasMalformedQuantity({
          "value": "0xde0b6b3a7640000",
          "gas": "0x5208",
          "gasPrice": "0x3b9aca00",
          "maxFeePerGas": "0x77359400",
          "maxPriorityFeePerGas": "0x3b9aca00",
          "nonce": "0x0",
        }),
        isFalse,
      );
      expect(EthUtils.hasMalformedQuantity({"to": "1111", "data": "a9059cbb"}), isFalse);
    });

    for (final field in [
      "value",
      "gas",
      "maxGas",
      "gasPrice",
      "maxFeePerGas",
      "maxPriorityFeePerGas",
      "nonce",
    ]) {
      test("$field as a decimal string, a bare hex string or a number is caught", () {
        expect(EthUtils.hasMalformedQuantity({field: "21000"}), isTrue);
        expect(EthUtils.hasMalformedQuantity({field: "5208"}), isTrue);
        expect(EthUtils.hasMalformedQuantity({field: 21000}), isTrue);
        expect(EthUtils.hasMalformedQuantity({field: "0X5208"}), isTrue);
      });

      test("$field that is negative, empty or not hex after the prefix is caught", () {
        expect(EthUtils.hasMalformedQuantity({field: "0x-7538dcfb76180000"}), isTrue);
        expect(EthUtils.hasMalformedQuantity({field: "0x-1"}), isTrue);
        expect(EthUtils.hasMalformedQuantity({field: "0x"}), isTrue);
        expect(EthUtils.hasMalformedQuantity({field: "0x12g4"}), isTrue);
        expect(EthUtils.hasMalformedQuantity({field: "0x+1"}), isTrue);
      });
    }
  });

  group("address and payload of a signing request", () {
    const account = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const message = "0x68656c6c6f";
    const hash = "0xabababababababababababababababababababababababababababababababab";
    const typedData = {"primaryType": "Mail"};

    SessionRequest request(String method, Object? params) => SessionRequest(
      id: 1,
      topic: "topic",
      method: method,
      chainId: "eip155:1",
      params: params,
      verifyContext: const VerifyContext(
        origin: "https://dapp.example",
        validation: Validation.UNKNOWN,
        verifyUrl: "",
      ),
    );

    void expectRead(String method, List<Object?> params, {String? address, Object? data}) {
      final read = request(method, params);
      expect(EthUtils.getAddressFromSessionRequest(read), address, reason: "address of $params");
      expect(EthUtils.getDataFromSessionRequest(read), data, reason: "payload of $params");
    }

    test("personal_sign reads [message, address] and the reversed pair the same", () {
      expectRead(
        "personal_sign",
        [message, account],
        address: account.toLowerCase(),
        data: message,
      );
      expectRead(
        "personal_sign",
        [account, message],
        address: account.toLowerCase(),
        data: message,
      );
    });

    test("eth_sign reads [address, message] and the reversed pair the same", () {
      expectRead("eth_sign", [account, hash], address: account.toLowerCase(), data: hash);
      expectRead("eth_sign", [hash, account], address: account.toLowerCase(), data: hash);
    });

    for (final method in ["eth_signTypedData", "eth_signTypedData_v3", "eth_signTypedData_v4"]) {
      test("$method reads [address, payload] and the reversed pair the same", () {
        expectRead(method, [account, typedData], address: account.toLowerCase(), data: typedData);
        expectRead(method, [typedData, account], address: account.toLowerCase(), data: typedData);
      });
    }

    test("a 32 byte hash is never taken for the address", () {
      expectRead("personal_sign", [hash], address: null, data: hash);
      expectRead("eth_sign", [hash, message], address: null, data: message);
    });

    test("an address with a broken checksum is still the address, so it gets compared", () {
      final brokenChecksum = account.replaceFirst("F39F", "f39F");
      expectRead(
        "personal_sign",
        [message, brokenChecksum],
        address: account.toLowerCase(),
        data: message,
      );
    });

    test("a message that is 20 bytes long stays the message in the standard order", () {
      const twentyByteMessage = "0x1111111111111111111111111111111111111111";
      expectRead(
        "personal_sign",
        [twentyByteMessage, account],
        address: account.toLowerCase(),
        data: twentyByteMessage,
      );
    });

    test("a request without its payload has none", () {
      expectRead("eth_sign", [account], address: account.toLowerCase(), data: null);
      expectRead("eth_signTypedData_v4", [], address: null, data: null);
      expect(
        EthUtils.getDataFromSessionRequest(request("personal_sign", {"not": "a list"})),
        isNull,
      );
    });
  });
}
