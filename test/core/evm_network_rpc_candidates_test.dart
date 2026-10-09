import "package:cake_wallet/new-ui/services/evm_network_service.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  // Avalanche C-Chain, whose feed RPCs are the candidates here
  const chainId = 43114;
  const deadRpc = "https://dead.example";
  const otherChainRpc = "https://other-chain.example";

  group("EvmNetworkService.firstAnsweringRpcs", () {
    late List<String> checked;
    late Set<String> answering;

    Future<void> check(String url) async {
      checked.add(url);
      if (url == otherChainRpc) {
        throw RpcChainIdMismatchException(url: url, answeredChainId: 1, expectedChainId: chainId);
      }

      if (!answering.contains(url)) {
        throw RpcNoAnswerException(url);
      }
    }

    setUp(() {
      checked = [];
      answering = {};
    });

    test("keeps the first two candidates that answer and stops there", () async {
      answering = {"https://second.example", "https://fourth.example", "https://fifth.example"};

      final result = await EvmNetworkService.firstAnsweringRpcs(
        [
          deadRpc,
          "https://second.example",
          otherChainRpc,
          "https://fourth.example",
          "https://fifth.example",
        ],
        check,
      );

      expect(result, ["https://second.example", "https://fourth.example"]);
      expect(checked, [deadRpc, "https://second.example", otherChainRpc, "https://fourth.example"]);
    });

    test("checks at most four candidates", () async {
      answering = {"https://fifth.example"};

      await expectLater(
        EvmNetworkService.firstAnsweringRpcs(
          [
            deadRpc,
            "https://second-dead.example",
            "https://third-dead.example",
            "https://fourth-dead.example",
            "https://fifth.example",
          ],
          check,
        ),
        throwsA(isA<RpcNoAnswerException>()),
      );
      expect(checked, hasLength(4));
      expect(checked, isNot(contains("https://fifth.example")));
    });

    test("one answering candidate is kept alone, with no failover", () async {
      answering = {"https://third.example"};

      final result = await EvmNetworkService.firstAnsweringRpcs(
        [deadRpc, otherChainRpc, "https://third.example"],
        check,
      );

      expect(result, ["https://third.example"]);
    });

    test("when none answers, the prefilled RPC's failure is thrown", () async {
      await expectLater(
        EvmNetworkService.firstAnsweringRpcs([otherChainRpc, deadRpc], check),
        throwsA(
          isA<RpcChainIdMismatchException>()
              .having((e) => e.answeredChainId, "answeredChainId", 1)
              .having((e) => e.expectedChainId, "expectedChainId", chainId),
        ),
      );
    });
  });
}
