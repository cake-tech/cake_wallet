// https://developers.circle.com/cctp/references/contract-addresses
class CctpConfig {
  CctpConfig._();

  static const String tokenMessenger = "0x28b5a0e9C621a5BadaA536219b3a228C8168cf5d";

  static const Map<int, String> usdcTokenAddressByChainId = {
    1: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    137: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
    8453: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
    42161: "0xaf88d065e77c8cc2239327c5edb3a432268e5831",
  };

  static const Map<int, int> domainByChainId = {
    1: 0,
    137: 7,
    8453: 6,
    42161: 3,
  };

  // Hook data that asks Circle's Forwarding Service to submit the mint on the destination chain:
  // "cctp-forward" padded to 24 bytes, then version 0 and data length 0 (4 bytes each).
  static const String forwardingHookData =
      "636374702d666f72776172640000000000000000000000000000000000000000";

  static int? getDomain(int chainId) => domainByChainId[chainId];
}
