import "package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart";
import "package:flutter_test/flutter_test.dart";
import "package:reown_walletkit/reown_walletkit.dart";

import "wc_service_rig.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WcServiceRig rig;

  setUp(() async {
    rig = await WcServiceRig.start();
  });

  Future<void> store(
    int id,
    Object? params, {
    String topic = "topic",
    String method = "personal_sign",
    String chainId = "eip155:1",
  }) => rig.kit.pendingRequests.set(
    id.toString(),
    SessionRequest(
      id: id,
      topic: topic,
      method: method,
      chainId: chainId,
      params: params,
      verifyContext: const VerifyContext(
        origin: "https://dapp.example",
        validation: Validation.UNKNOWN,
        verifyUrl: "",
      ),
    ),
  );

  group("pendingRequestFor", () {
    test("returns the request that holds the params object the handler was given", () async {
      final olderParams = ["0x01", "0xaaaa"];
      final newerParams = ["0x02", "0xbbbb"];
      await store(101, olderParams);
      await store(102, newerParams);

      final found = MethodsUtils.pendingRequestFor(
        "topic",
        "personal_sign",
        "eip155:1",
        olderParams,
      );

      expect(found?.id, 101);
    });

    test("with no request holding the object nothing is returned", () async {
      await store(101, ["0x01"]);
      await store(102, ["0x02"]);

      final found = MethodsUtils.pendingRequestFor("topic", "personal_sign", "eip155:1", ["0x03"]);

      expect(found, isNull);
    });

    for (final params in [7, null]) {
      test("two requests whose params are both $params are each handed out once", () async {
        await store(101, params);
        await store(102, params);

        SessionRequest? next() =>
            MethodsUtils.pendingRequestFor("topic", "personal_sign", "eip155:1", params);

        expect([next()?.id, next()?.id], [101, 102]);
        expect(next(), isNull);
      });
    }

    test("a request is handed to one handler only", () async {
      final params = ["0x01", "0xaaaa"];
      await store(101, params);

      SessionRequest? next() =>
          MethodsUtils.pendingRequestFor("topic", "personal_sign", "eip155:1", params);

      expect(next()?.id, 101);
      expect(next(), isNull);
    });

    test("a request of another topic, method or chain is never returned", () async {
      final params = ["0x01"];
      await store(101, params, topic: "another-topic");
      await store(102, params, method: "eth_sign");
      await store(103, params, chainId: "eip155:137");

      expect(MethodsUtils.pendingRequestFor("topic", "personal_sign", "eip155:1", params), isNull);
    });
  });
}
