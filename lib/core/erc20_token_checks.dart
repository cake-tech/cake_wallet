import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/entities/erc20_token_info_moralis.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

class Erc20TokenChecks {
  static Future<bool?> isPotentialScamViaMoralis(String contractAddress, int chainId) async {
    if (!evm!.isMoralisSupportedChain(chainId)) {
      return null;
    }

    final uri = Uri.https(
      "deep-index.moralis.io",
      "/api/v2.2/erc20/metadata",
      {
        "chain": evm!.getHexChainId(chainId),
        "addresses": contractAddress,
      },
    );

    try {
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: {
          "Accept": "application/json",
          "X-API-Key": secrets.moralisApiKey,
        },
      ).timeout(const Duration(seconds: 15));

      final decodedResponse = jsonDecode(response.body);

      final tokenInfo = Erc20TokenInfoMoralis.fromJson(decodedResponse[0] as Map<String, dynamic>);

      // Based on analysis using Moralis internal metrics
      if (tokenInfo.possibleSpam == true) {
        return true;
      }

      // Tokens with a security score less than 40 are potentially risky
      if (tokenInfo.securityScore != null && tokenInfo.securityScore! < 40) {
        return true;
      }

      return false;
    } catch (e) {
      printV("Error while checking scam via moralis: ${e.toString()}");
      return null;
    }
  }

  static Future<bool?> isContractUnverified(String contractAddress, int chainId) async {
    final uri = evm!.getContractSourceCodeUri(chainId, contractAddress);

    if (uri == null) {
      return null;
    }

    try {
      final response =
          await ProxyWrapper().get(clearnetUri: uri).timeout(const Duration(seconds: 15));

      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

      // Status 0 is an error such as a rate limit or a bad key, an unverified contract is status 1
      if (decodedResponse["status"] == "0") {
        printV("Contract verification check failed: ${decodedResponse["result"]}");
        return null;
      }

      final isBlockscout = uri.host != "api.etherscan.io";
      return [if (isBlockscout) null, "Contract source code not verified"]
          .contains(decodedResponse["result"][0]["ABI"]);
    } catch (e) {
      printV("Error while checking contract verification: ${e.toString()}");
      return null;
    }
  }
}
