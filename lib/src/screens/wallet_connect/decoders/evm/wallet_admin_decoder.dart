import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class WalletAdminDecoder {
  WCDecodedRequest decodeSwitchChain(dynamic params) {
    final chainIdHex = _extractChainIdHex(params);
    final chainIdInt = _hexToInt(chainIdHex);
    final info = chainIdInt == null ? null : evm?.getChainInfoByChainId(chainIdInt);

    final rows = <WCDecodedRow>[
      if (info != null) WCDecodedRow(label: S.current.wc_target_chain, value: info.name),
      WCDecodedRow(
        label: S.current.wc_target_chain_id,
        value: chainIdInt?.toString() ?? (chainIdHex ?? "?"),
      ),
    ];

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_switch_chain,
      actionSubtitle: info?.name,
      rows: rows,
      warnings: [
        if (info == null) S.current.wc_warning_chain_not_supported,
      ],
      hideTo: true,
      hideValue: true,
    );
  }

  WCDecodedRequest decodeAddChain(dynamic params) {
    final config = _firstMap(params);
    if (config == null) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_add_chain,
        warnings: [S.current.wc_warning_add_chain_not_supported],
        hideTo: true,
        hideValue: true,
      );
    }
    final chainIdHex = config["chainId"]?.toString();
    final chainIdInt = _hexToInt(chainIdHex);
    final chainName = config["chainName"]?.toString() ?? "?";
    final currency = (config["nativeCurrency"] as Map?)?.cast<String, dynamic>();
    final rpcs = (config["rpcUrls"] as List?)?.cast<String>() ?? const [];
    final explorers = (config["blockExplorerUrls"] as List?)?.cast<String>() ?? const [];

    final builtIn = chainIdInt == null ? null : evm?.getChainInfoByChainId(chainIdInt);

    final rows = <WCDecodedRow>[
      WCDecodedRow(label: S.current.wc_chain_name, value: chainName),
      WCDecodedRow(
        label: S.current.wc_target_chain_id,
        value: chainIdInt?.toString() ?? (chainIdHex ?? "?"),
      ),
      if (currency != null && currency["symbol"] != null)
        WCDecodedRow(
          label: S.current.wc_currency,
          value: '${currency['name'] ?? currency['symbol']} (${currency['symbol']})',
        ),
      if (rpcs.isNotEmpty) WCDecodedRow(label: S.current.wc_new_rpc, value: rpcs.first),
      if (explorers.isNotEmpty) WCDecodedRow(label: S.current.wc_explorer, value: explorers.first),
    ];

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_add_chain,
      actionSubtitle: chainName,
      rows: rows,
      warnings: [
        if (builtIn == null) S.current.wc_warning_add_chain_not_supported,
      ],
      hideTo: true,
      hideValue: true,
    );
  }

  int? extractChainId(dynamic params) => _hexToInt(_extractChainIdHex(params));

  String? _extractChainIdHex(dynamic params) {
    final config = _firstMap(params);
    if (config == null) {
      return null;
    }
    return config["chainId"]?.toString();
  }

  Map<String, dynamic>? _firstMap(dynamic params) {
    if (params is List && params.isNotEmpty && params.first is Map) {
      return (params.first as Map).cast<String, dynamic>();
    }
    if (params is Map) {
      return params.cast<String, dynamic>();
    }
    return null;
  }

  int? _hexToInt(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.toLowerCase().startsWith("0x")) {
      return int.tryParse(value.substring(2), radix: 16);
    }
    return int.tryParse(value);
  }
}
