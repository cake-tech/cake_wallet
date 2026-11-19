import "package:cake_wallet/core/address_resolver/ens/ens_universal_resolver.dart";
import "package:ens_dart/ens_dart.dart";
import "package:flutter_test/flutter_test.dart";
import "package:web3dart/json_rpc.dart";
import "package:web3dart/web3dart.dart";

class _FakeNode extends RpcService {
  _FakeNode(this._reply) : super("fake");

  final String Function() _reply;
  final methods = <String>[];
  final calls = <Map<dynamic, dynamic>>[];

  @override
  Future<RPCResponse> call(String function, [List<dynamic>? params]) async {
    methods.add(function);
    calls.add(params!.first as Map<dynamic, dynamic>);
    return RPCResponse(calls.length, _reply());
  }
}

void main() {
  const vitalik = "0xd8da6bf26964af9d7eed9e03e53415d37aa96045";
  const vitalikNode = "ee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835";
  const resolver = "231b0ee14048e9dccd1d247744d114a4eb5e8e63";

  String word(String hex) => hex.padLeft(64, "0");

  String resolvesTo(String address) =>
      "0x${word("40")}${word(resolver)}${word("20")}${word(address.substring(2))}";

  Future<String> resolve(_FakeNode node, String name, [CoinType coinType = CoinType.ETH]) =>
      EnsUniversalResolver.resolveAddress(Web3Client.custom(node), name, coinType);

  group("EnsUniversalResolver", () {
    test("calls resolve(dnsName, addr(node)) on the Universal Resolver", () async {
      final node = _FakeNode(() => resolvesTo(vitalik));

      expect(await resolve(node, "vitalik.eth"), vitalik);
      expect(node.methods, ["eth_call"]);
      expect(node.calls.single["to"], "0xeeeeeeee14d718c2b47d9923deab1335e144eeee");
      expect(
        node.calls.single["data"],
        "0x9061b923${word("40")}${word("80")}"
        "${word("d")}${"07766974616c696b0365746800".padRight(64, "0")}"
        "${word("24")}${"3b3b57de$vitalikNode".padRight(128, "0")}",
      );
    });

    test("encodes addr(node, coinType) for other coins", () async {
      final node = _FakeNode(() => throw const RPCError(3, "execution reverted", "0x77209fe8"));
      await resolve(node, "vitalik.eth", CoinType.BTC);

      expect(node.calls.single["data"], contains("f1cb7e06$vitalikNode${word("0")}"));
    });

    test("lowercases the name before encoding it", () async {
      final node = _FakeNode(() => resolvesTo(vitalik));
      await resolve(node, "Nick.eth");
      await resolve(node, "nick.eth");

      final data = node.calls.first["data"] as String;
      expect(node.calls.last["data"], data);
      expect(data, contains("046e69636b0365746800"));
      expect(
        data,
        contains("3b3b57de05a67c0ee82964c4f7394cdd47fee7f4d9503a23c09c38341779ea012afe6e00"),
      );
    });

    test("rejects names outside the ENSIP-15 ASCII subset without calling the node", () async {
      final node = _FakeNode(() => resolvesTo(vitalik));
      final names = [
        "vitalik\u200d.eth",
        "vitalik\u200c.eth",
        "vit\u0430lik.eth",
        "\u212aick.eth",
        "caf\u00e9.eth",
        "\u2764\u2764\u2764.eth",
        "o'brien.eth",
        "vitalik!.eth",
        "a_b.eth",
        "ab_.eth",
        "ab--c.eth",
        "xn--ab.eth",
        "----.eth",
        "nick .eth",
        "nick\u007f.eth",
      ];
      for (final name in names) {
        expect(await resolve(node, name), "", reason: name);
      }
      expect(node.calls, isEmpty);
    });

    test("accepts the ASCII names ENSIP-15 keeps", () async {
      final node = _FakeNode(() => resolvesTo(vitalik));
      final names = ["_ab.eth", "___.eth", r"$.eth", r"abc$123.eth", "---a.eth", "ab-c.eth"];
      for (final name in names) {
        expect(await resolve(node, name), vitalik, reason: name);
      }
      expect(node.calls, hasLength(names.length));
    });

    test("rejects empty and oversized labels without calling the node", () async {
      final node = _FakeNode(() => resolvesTo(vitalik));
      for (final name in ["foo..eth", ".eth", "${"a" * 256}.eth"]) {
        expect(await resolve(node, name), "");
      }
      expect(node.calls, isEmpty);

      expect(await resolve(node, "${"a" * 255}.eth"), vitalik);
    });

    test("returns an empty string when the call reverts", () async {
      final node = _FakeNode(() => throw const RPCError(3, "execution reverted", "0x77209fe8"));

      expect(await resolve(node, "nobody.eth"), "");
      expect(node.calls, hasLength(1));
    });

    test("returns an empty string when the node returns no data", () async {
      final node = _FakeNode(() => "0x");

      expect(await resolve(node, "vitalik.eth"), "");
      expect(node.calls, hasLength(1));
    });
  });
}
