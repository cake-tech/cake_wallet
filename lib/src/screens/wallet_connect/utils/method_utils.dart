import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/wallet_connect/bottom_sheet/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/deeplink_handler.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/request_widget.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class MethodsUtils {
  static final walletKit = getIt.get<WalletKitService>().walletKit;

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
    final bottomSheetService = getIt.get<BottomSheetService>();
    final WCBottomSheetResult rs = (await bottomSheetService.queueBottomSheet(
          widget: WCRequestWidget(
            verifyContext: verifyContext,
            child: WCConnectionWidget(
              title: title ?? 'Approve Request',
              info: [
                WCConnectionModel(
                  title: 'Method: $method\n'
                      'Transport Type: ${transportType.toUpperCase()}\n'
                      'Chain ID: $chainId\n'
                      'Address: $address\n\n'
                      'Message:',
                  elements: [
                    text,
                  ],
                ),
                ...extraModels,
              ],
            ),
          ),
        ) as WCBottomSheetResult?) ??
        WCBottomSheetResult.reject;

    return rs != WCBottomSheetResult.reject;
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
        title: success ? 'Success' : 'Error',
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
    DeepLinkHandler.waiting.value = false;
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
    await getIt.get<BottomSheetService>().queueBottomSheet(
          closeAfter: success ? 3 : 0,
          widget: Container(
            color: Colors.white,
            height: 280.0,
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  success ? Icons.check_circle_sharp : Icons.error_outline_sharp,
                  color: success ? Colors.green[100] : Colors.red[100],
                  size: 80.0,
                ),
                Text(
                  title ?? 'Connected',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(message ?? 'You can go back to your dApp now'),
              ],
            ),
          ),
        );
  }
}
