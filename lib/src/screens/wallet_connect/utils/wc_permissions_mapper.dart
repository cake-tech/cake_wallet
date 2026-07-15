import 'package:cake_wallet/generated/i18n.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCPermission {
  const WCPermission({required this.iconUrl, required this.label});

  final String iconUrl;
  final String label;
}

class WCPermissionsMapper {
  static const _transactionMethods = {
    'eth_sendTransaction',
    'eth_signTransaction',
    'solana_signTransaction',
    'solana_signAllTransactions',
    'solana_signAndSendTransaction',
  };

  static const _messageSigningMethods = {
    'personal_sign',
    'eth_sign',
    'eth_signTypedData',
    'eth_signTypedData_v1',
    'eth_signTypedData_v3',
    'eth_signTypedData_v4',
    'solana_signMessage',
  };

  static const _chainAdminMethods = {
    'wallet_switchEthereumChain',
    'wallet_addEthereumChain',
  };

  static List<WCPermission> fromGeneratedNamespaces(Map<String, Namespace> generatedNamespaces) {
    final methods = <String>{};
    for (final ns in generatedNamespaces.values) {
      methods.addAll(ns.methods);
    }

    final permissions = <WCPermission>[
      WCPermission(
          iconUrl: "assets/new-ui/global_view.svg", label: S.current.wc_permission_view_balance),
    ];

    final wantsTransactionApproval = methods.any(_transactionMethods.contains);
    if (wantsTransactionApproval) {
      permissions.add(WCPermission(
        iconUrl: "assets/new-ui/green_check.svg",
        label: S.current.wc_permission_request_approval,
      ));
    }

    final wantsMessageSigning = methods.any(_messageSigningMethods.contains);
    if (wantsMessageSigning) {
      permissions.add(WCPermission(
        iconUrl: "assets/new-ui/pencil.svg",
        label: S.current.wc_permission_sign_messages,
      ));
    }

    final wantsChainAdmin = methods.any(_chainAdminMethods.contains);
    if (wantsChainAdmin) {
      permissions.add(WCPermission(
        iconUrl: "assets/new-ui/exchange_providers.svg",
        label: S.current.wc_permission_switch_chains,
      ));
    }

    final known = {..._transactionMethods, ..._messageSigningMethods, ..._chainAdminMethods};
    final unknown = methods.where((m) => !known.contains(m)).toList()..sort();
    for (final method in unknown) {
      permissions.add(WCPermission(
        iconUrl: "assets/new-ui/help.svg",
        label: S.current.wc_permission_other(method),
      ));
    }

    return permissions;
  }
}
