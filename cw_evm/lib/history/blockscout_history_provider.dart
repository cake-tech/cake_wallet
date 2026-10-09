import "package:cw_evm/history/etherscan_history_provider.dart";

class BlockscoutHistoryProvider extends EtherscanHistoryProvider {
  BlockscoutHistoryProvider() : super(apiKey: "");

  // From https://chains.blockscout.com/api/chains (pulled 2026-09-25)
  // Gnosis and Scroll are left out, the list points them at Etherscan's gnosisscan and scrollscan
  static const Map<int, String> hosts = {
    1: "eth.blockscout.com",
    10: "explorer.optimism.io",
    30: "rootstock.blockscout.com",
    61: "etc.blockscout.com",
    122: "explorer.fuse.io",
    130: "unichain.blockscout.com",
    137: "polygon.blockscout.com",
    177: "hsk.blockscout.com",
    239: "explorer.tac.build",
    314: "filecoin.blockscout.com",
    324: "zksync.blockscout.com",
    360: "shapescan.xyz",
    480: "worldchain-mainnet.explorer.alchemy.com",
    484: "basecamp.cloud.blockscout.com",
    488: "blackfortscan.com",
    592: "astar.blockscout.com",
    698: "matchscan.io",
    714: "eden.blockscout.com",
    747: "evm.flow.com",
    869: "explorer.worldmobile.io",
    957: "explorer.derive.xyz",
    1135: "blockscout.lisk.com",
    1514: "www.datanetscan.io",
    1729: "explorer.reya.network",
    1829: "explorer.playblock.io",
    1868: "soneium.blockscout.com",
    1890: "phoenix.lightlink.io",
    2020: "explorer.roninchain.com",
    2288: "scan.mocachain.org",
    2366: "kitescan.ai",
    4326: "megaeth.blockscout.com",
    4663: "robinhoodchain.blockscout.com",
    5042: "explorer.arc.io",
    6497: "awaji.blockscout.com",
    6498: "mizuhiki.blockscout.com",
    7000: "zetascan.com",
    8021: "numine.blockscout.com",
    8453: "base.blockscout.com",
    8822: "explorer.evm.iota.org",
    13371: "explorer.immutable.com",
    32769: "zilliqa.blockscout.com",
    34443: "explorer.mode.network",
    42161: "arbitrum.blockscout.com",
    42170: "arbitrum-nova.blockscout.com",
    42220: "celo.blockscout.com",
    42793: "explorer.etherlink.com",
    57073: "explorer.inkonchain.com",
    97477: "explorer.doma.xyz",
    97741: "pepuscan.com",
    98866: "explorer.plume.org",
    101010: "explorer.stabilityprotocol.com",
    102030: "creditcoin.blockscout.com",
    190415: "explorer.hpp.io",
    612055: "www.crossscan.io",
    685689: "gensyn-mainnet.explorer.alchemy.com",
    245022934: "neon.blockscout.com",
  };

  @override
  String get name => "Blockscout";

  @override
  bool covers(int chainId) => hosts.containsKey(chainId);

  @override
  Uri queryUri(int chainId, Map<String, String> params) =>
      Uri.https(hosts[chainId]!, "/api", params);
}
