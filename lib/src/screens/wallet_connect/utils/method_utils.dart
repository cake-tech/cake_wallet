import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_signing_request_sheet.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/themes/core/custom_theme_colors.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:flutter/material.dart";
import "package:reown_walletkit/reown_walletkit.dart";

class MethodsUtils {
  static ReownWalletKit get walletKit => getIt.get<WalletKitService>().walletKit;
  static final bottomSheetService = getIt.get<BottomSheetService>();

  static bool isSessionOwnedByWallet(SessionData? session, String walletPublicKey) {
    if (session == null || walletPublicKey.isEmpty) {
      return false;
    }

    final accounts = session.namespaces.values.expand((namespace) => namespace.accounts);

    return accounts.any((account) => isSameAccount(account.split(":").last, walletPublicKey));
  }

  static bool isSameAccount(String a, String b) {
    if (a.startsWith("0x") && b.startsWith("0x")) {
      return a.toLowerCase() == b.toLowerCase();
    }

    return a == b;
  }

  static const _transactionMethods = {
    "eth_sendTransaction",
    "eth_signTransaction",
    "solana_signTransaction",
    "solana_signAllTransactions",
    "solana_signAndSendTransaction",
    "wallet_switchEthereumChain",
    "wallet_addEthereumChain",
  };

  static SessionRequest? pendingRequestFor(String topic, String method, String chainId) {
    final matches = walletKit.pendingRequests.getAll().where(
          (r) => r.topic == topic && r.method == method && r.chainId == chainId,
        );
    return matches.isEmpty ? null : matches.last;
  }

  static Future<void> respondForTopic(String topic, JsonRpcResponse<dynamic> response) async {
    final session = walletKit.sessions.get(topic);
    try {
      await walletKit.respondSessionRequest(topic: topic, response: response);
      if (session == null) {
        return;
      }
      handleRedirect(
        topic,
        session.peer.metadata.redirect,
        response.error?.message,
        response.error == null,
      );
    } on ReownSignError catch (error) {
      if (session == null) {
        return;
      }
      handleRedirect(topic, session.peer.metadata.redirect, error.message);
    }
  }

  static Future<bool> requestApproval(
    WCDecodedRequest decoded, {
    required String topic,
    required String transportType,
    String? title,
    String? method,
    String? chainId,
    String? address,
    List<WCDecodedRow> extraRows = const [],
    VerifyContext? verifyContext,
    int? signAllCount,
  }) async {
    final appStore = getIt.get<AppStore>();
    final session = walletKit.sessions.get(topic);
    final dAppMetadata = session?.peer.metadata;

    final isTransaction = method != null && _transactionMethods.contains(method);
    final resolvedTitle = title ??
        (isTransaction ? S.current.wc_approve_request_title : S.current.wc_signing_request_title);
    final swipeLabel = isTransaction ? S.current.wc_swipe_to_approve : S.current.wc_swipe_to_sign;

    final infoRows = <WCDecodedRow>[
      if (method != null && method.isNotEmpty) WCDecodedRow(label: S.current.method, value: method),
      if (chainId != null && chainId.isNotEmpty)
        WCDecodedRow(label: S.current.chain_id, value: chainId),
      if (transportType.isNotEmpty)
        WCDecodedRow(label: S.current.transport_type, value: transportType.toUpperCase()),
      ...extraRows,
    ];

    final WCBottomSheetResult result = (await bottomSheetService.queueBottomSheet(
          widget: WCSigningRequestSheet(
            title: resolvedTitle,
            swipeLabel: swipeLabel,
            dappName: dAppMetadata?.name ?? "",
            dappIconUrl:
                (dAppMetadata?.icons.isNotEmpty ?? false) ? dAppMetadata!.icons.first : null,
            dappSubtitle: dAppMetadata?.url ?? method ?? "",
            decoded: decoded,
            infoRows: infoRows,
            walletName: appStore.wallet?.name ?? "",
            address: address ?? "",
            verifyContext: verifyContext,
            signAllCount: signAllCount,
          ),
        ) as WCBottomSheetResult?) ??
        WCBottomSheetResult.reject;

    return result != WCBottomSheetResult.reject;
  }

  static void handleRedirect(
    String topic,
    Redirect? redirect, [
    String? error,
    bool success = false,
  ]) {
    printV("handleRedirect topic: $topic, redirect: $redirect, error: $error");
    openApp(
      topic,
      redirect,
      onFail: (e) => goBackModal(
        title: success ? S.current.success : S.current.error,
        message: error,
        success: success,
      ),
    );
  }

  static Future<void> openApp(
    String topic,
    Redirect? redirect, {
    int delay = 100,
    Function(ReownSignError? error)? onFail,
  }) async {
    await Future.delayed(Duration(milliseconds: delay));
    try {
      await walletKit.redirectToDapp(
        topic: topic,
        redirect: redirect,
      );
    } on ReownSignError catch (e) {
      onFail?.call(e);
    }
  }

  static Future<void> goBackModal({
    String? title,
    String? message,
    bool success = true,
  }) async {
    await bottomSheetService.queueBottomSheet(
      closeAfter: success ? 3 : 0,
      widget: GoBackModalWidget(
        isSuccess: success,
        title: title,
        message: message,
      ),
    );
  }
}

class GoBackModalWidget extends StatelessWidget {
  const GoBackModalWidget({
    required this.isSuccess,
    this.message,
    this.title,
    super.key,
  });

  final bool isSuccess;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surface,
        height: 280,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_sharp : Icons.error_outline_sharp,
              color: isSuccess
                  ? CustomThemeColors.syncGreen
                  : Theme.of(context).colorScheme.errorContainer,
              size: 80,
            ),
            Text(
              title ?? S.current.connected,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              message ?? S.current.youCanGoBackToYourDapp,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                  ),
            ),
          ],
        ),
      );
}
