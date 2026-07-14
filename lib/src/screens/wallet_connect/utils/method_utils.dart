import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_message_card.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_signing_request_sheet.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class MethodsUtils {
  static final walletKit = getIt.get<WalletKitService>().walletKit;
  static final bottomSheetService = getIt.get<BottomSheetService>();

  static const _transactionMethods = {
    'eth_sendTransaction',
    'eth_signTransaction',
    'solana_signTransaction',
    'solana_signAllTransactions',
    'solana_signAndSendTransaction',
  };

  static Future<bool> requestApproval(
    String text, {
    String? title,
    String? method,
    String? chainId,
    String? address,
    required String transportType,
    List<WCConnectionModel> extraModels = const [],
    VerifyContext? verifyContext,
  }) async {
    final appStore = getIt.get<AppStore>();
    final pending = walletKit.pendingRequests.getAll();
    final session = pending.isNotEmpty ? walletKit.sessions.get(pending.last.topic) : null;
    final dAppMetadata = session?.peer.metadata;

    final isTransaction = method != null && _transactionMethods.contains(method);
    final resolvedTitle = title ??
        (isTransaction ? S.current.wc_approve_request_title : S.current.wc_signing_request_title);
    final swipeLabel = isTransaction ? S.current.wc_swipe_to_approve : S.current.wc_swipe_to_sign;

    final extraRows = <WCMessageRow>[];
    if (method != null && method.isNotEmpty) {
      extraRows.add(WCMessageRow(label: S.current.method, value: method));
    }
    if (chainId != null && chainId.isNotEmpty) {
      extraRows.add(WCMessageRow(label: S.current.chain_id, value: chainId));
    }
    if (transportType.isNotEmpty) {
      extraRows.add(WCMessageRow(
        label: S.current.transport_type,
        value: transportType.toUpperCase(),
      ));
    }
    for (final model in extraModels) {
      if (model.title == null) continue;
      final value = model.elements?.join(', ') ?? model.text ?? '';
      extraRows.add(WCMessageRow(label: model.title!, value: value));
    }

    final WCBottomSheetResult result = (await bottomSheetService.queueBottomSheet(
          widget: WCSigningRequestSheet(
            title: resolvedTitle,
            swipeLabel: swipeLabel,
            dappName: dAppMetadata?.name ?? '',
            dappIconUrl:
                (dAppMetadata?.icons.isNotEmpty ?? false) ? dAppMetadata!.icons.first : null,
            dappSubtitle: method ?? dAppMetadata?.url ?? '',
            message: text,
            walletName: appStore.wallet?.name ?? '',
            address: address ?? '',
            verifyContext: verifyContext,
            extraRows: extraRows,
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
      onFail: (e) => goBackModal(
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

  static void goBackModal({
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
