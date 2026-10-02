import "dart:convert";
import "dart:io";

import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const assetPath = "assets/evm_networks/popular.json";
  const iconFolder = "assets/new-ui/network_icons/";

  TestWidgetsFlutterBinding.ensureInitialized();

  final rawEntries = (jsonDecode(File(assetPath).readAsStringSync()) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  bool isHttpsUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == "https" && uri.host.isNotEmpty;
  }

  group("popular.json", () {
    test("parses through the service into the eight Popular networks", () async {
      final entries = await ChainListService().loadPopularNetworks();

      expect(
        entries.map((entry) => entry.chainId),
        [10, 999, 5042, 143, 9745, 57073, 196, 25],
      );
    });

    test("has unique chain IDs", () {
      final chainIds = rawEntries.map((entry) => entry["chainId"] as int).toList();

      expect(chainIds.toSet(), hasLength(chainIds.length));
    });

    test("no chain ID is a built-in EVM network's", () {
      final builtinChainIds = evm!
          .getAllChains()
          .where((chain) => chain.source == ChainSource.builtin)
          .map((chain) => chain.chainId)
          .toSet();

      expect(builtinChainIds, containsAll([1, 137, 8453, 42161, 56]));
      for (final entry in rawEntries) {
        expect(builtinChainIds, isNot(contains(entry["chainId"])), reason: entry["name"] as String);
      }
    });

    test("every RPC is https with no key template, and each network has a failover", () {
      for (final entry in rawEntries) {
        final rpcUrls = (entry["rpc"] as List<dynamic>)
            .map((rpc) => rpc is Map<String, dynamic> ? rpc["url"] : rpc)
            .toList();

        expect(rpcUrls.length, greaterThanOrEqualTo(2), reason: entry["name"] as String);
        for (final url in rpcUrls) {
          expect(url, isA<String>(), reason: entry["name"] as String);
          expect(isHttpsUrl(url as String), isTrue, reason: url);
          expect(url, isNot(contains(r"${")), reason: url);
        }
        expect(rpcUrls.toSet(), hasLength(rpcUrls.length), reason: entry["name"] as String);
      }
    });

    test("every explorer is https", () {
      for (final entry in rawEntries) {
        final explorer = entry["explorer"];

        expect(explorer, isA<String>(), reason: entry["name"] as String);
        expect(isHttpsUrl(explorer as String), isTrue, reason: explorer);
      }
    });

    test("every icon is a bundled svg whose source picture exists", () {
      for (final entry in rawEntries) {
        final icon = entry["icon"] as String;

        expect(icon, startsWith(iconFolder), reason: entry["name"] as String);
        expect(icon, endsWith(".svg"), reason: entry["name"] as String);
        // CakeImageWidget loads "<icon>.vec", which compile_graphics.sh builds from res/pictures
        final source = File(icon.replaceFirst("assets/new-ui/", "res/pictures/"));
        expect(source.existsSync(), isTrue, reason: source.path);
      }
    });

    test("name, symbol and decimals pass the details form's own rules", () {
      final builtinNames = builtinNetworkTypes.map(walletTypeToDisplayName).toSet();

      for (final entry in rawEntries) {
        final name = entry["name"] as String;
        final symbol = entry["symbol"] as String;

        expect(name.trim(), isNotEmpty);
        expect(name.length, lessThanOrEqualTo(maxNetworkNameLength), reason: name);
        expect(
          builtinNames.map((other) => other.toLowerCase()),
          isNot(contains(name.toLowerCase())),
        );
        expect(RegExp(r"^[A-Z0-9]{1,10}$").hasMatch(symbol), isTrue, reason: symbol);
        // All eight native currencies use 18 decimals on their chains, Arc's USDC gas token too
        expect(entry["decimals"], 18, reason: name);
      }
    });

    test("names are unique ignoring case", () {
      final names = rawEntries.map((entry) => (entry["name"] as String).toLowerCase()).toList();

      expect(names.toSet(), hasLength(names.length));
    });
  });
}
