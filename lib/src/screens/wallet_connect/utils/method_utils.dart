import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_connection_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_request_widget.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class MethodsUtils {
  static final walletKit = getIt.get<WalletKitService>().walletKit;
  static final bottomSheetService = getIt.get<BottomSheetService>();

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
    final WCBottomSheetResult result = (await bottomSheetService.queueBottomSheet(
          widget: WCRequestWidget(
            verifyContext: verifyContext,
            child: WCConnectionWidget(
              title: title ?? S.current.approve_request,
              info: [
                WCConnectionModel(
                  title: '${S.current.method}: $method\n'
                      '${S.current.transport_type}: ${transportType.toUpperCase()}\n'
                      '${S.current.chain_id}: $chainId\n'
                      '${S.current.address}: $address\n\n'
                      '${S.current.message}:',
                  elements: [text],
                ),
                ...extraModels,
              ],
            ),
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
