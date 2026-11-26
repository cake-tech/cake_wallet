import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_signing_request_sheet.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import "package:cw_core/utils/print_verbose.dart";
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

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
    'eth_sendTransaction',
    'eth_signTransaction',
    'solana_signTransaction',
    'solana_signAllTransactions',
    'solana_signAndSendTransaction',
    "tron_signTransaction",
    "wallet_switchEthereumChain",
    "wallet_addEthereumChain",
  };

  static JsonRpcError get userRejectedError {
    final error = Errors.getSdkError(Errors.USER_REJECTED);

    return JsonRpcError(code: error.code, message: error.message);
  }

  static final _handedOut = Expando<bool>();

  static SessionRequest? pendingRequestFor(
    String topic,
    String method,
    String chainId,
    dynamic parameters,
  ) {
    final matches = walletKit.pendingRequests.getAll().where(
          (r) => r.topic == topic && r.method == method && r.chainId == chainId,
        );
    for (final request in matches) {
      if (identical(request.params, parameters) && _handedOut[request] == null) {
        _handedOut[request] = true;
        return request;
      }
    }

    return null;
  }

  static Future<void> respondUnauthorized(String topic, int requestId) async {
    try {
      await walletKit.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: "2.0",
          error: const JsonRpcError(
            code: 4100,
            message: "The requested account has not been authorized by the user.",
          ),
        ),
      );
    } catch (e) {
      printV("respondUnauthorized failed: $e");
    }
  }

  static Future<bool> isRequestStillPending(String topic, int requestId) async {
    final id = requestId.toString();

    return walletKit.sessions.has(topic) &&
        !await walletKit.core.expirer.checkAndExpire(topic) &&
        walletKit.pendingRequests.has(id) &&
        !await walletKit.core.expirer.checkAndExpire(id);
  }

  static Future<void> respondForTopic(
    String topic,
    JsonRpcResponse<dynamic> response, {
    bool isUserDecision = true,
    bool isBroadcast = false,
  }) async {
    final session = walletKit.sessions.get(topic);
    try {
      await walletKit.respondSessionRequest(topic: topic, response: response);
    } catch (e) {
      printV("respondForTopic could not reply: $e");
      if (response.error == null) {
        goBackModal(
          title: isBroadcast ? S.current.transaction_sent : S.current.error,
          message: isBroadcast ? null : S.current.please_try_again_later,
          success: isBroadcast,
        );
      }
      return;
    }

    if (!isUserDecision || session == null) {
      return;
    }

    final redirect = session.peer.metadata.redirect;
    if (response.error?.code == userRejectedError.code) {
      openApp(topic, redirect);
      return;
    }

    handleRedirect(topic, redirect, response.error?.message, response.error == null);
  }

  static Future<bool> requestApproval(
    WCDecodedRequest decoded, {
    required String topic,
    required String transportType,
    String? method,
    String? chainId,
    String? address,
    List<WCDecodedRow> extraRows = const [],
    VerifyContext? verifyContext,
  }) async {
    final appStore = getIt.get<AppStore>();
    final session = walletKit.sessions.get(topic);
    final dAppMetadata = session?.peer.metadata;

    final isTransaction = method != null && _transactionMethods.contains(method);
    final resolvedTitle =
        isTransaction ? S.current.wc_approve_request_title : S.current.wc_signing_request_title;
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
            dappName: dAppMetadata?.name ?? '',
            dappIconUrl:
                (dAppMetadata?.icons.isNotEmpty ?? false) ? dAppMetadata!.icons.first : null,
            dappSubtitle: dAppMetadata?.url ?? method ?? "",
            decoded: decoded,
            infoRows: infoRows,
            walletName: appStore.wallet?.name ?? '',
            address: address ?? '',
            verifyContext: verifyContext,
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
    debugPrint('handleRedirect topic: $topic, redirect: $redirect, error: $error');
    openApp(
      topic,
      redirect,
      onFail: () => goBackModal(
        title: success ? S.current.success : S.current.error,
        message: error,
        success: success,
      ),
    );
  }

  static void openApp(
    String topic,
    Redirect? redirect, {
    int delay = 100,
    void Function()? onFail,
  }) async {
    await Future.delayed(Duration(milliseconds: delay));
    try {
      await walletKit.redirectToDapp(
        topic: topic,
        redirect: redirect,
      );
    } catch (e) {
      printV("openApp could not open the dApp: $e");
      onFail?.call();
    }
  }

  static void goBackModal({
    String? title,
    String? message,
    bool success = true,
  }) async {
    await bottomSheetService.queueBottomSheet(
      isModalDismissible: !success,
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
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      height: 280.0,
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_sharp : Icons.error_outline_sharp,
            color: isSuccess
                ? CustomThemeColors.syncGreen
                : Theme.of(context).colorScheme.errorContainer,
            size: 80.0,
          ),
          Text(
            title ?? S.current.connected,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            message ?? S.current.youCanGoBackToYourDapp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16.0,
                ),
          ),
        ],
      ),
    );
  }
}
