import 'dart:convert';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class EthUtils {
  static String getUtf8Message(String maybeHex) {
    if (maybeHex.startsWith('0x')) {
      final List<int> decoded = hex.decode(
        maybeHex.substring(2),
      );
      return utf8.decode(decoded);
    }

    return maybeHex;
  }

  static String? getAddressFromSessionRequest(SessionRequest request) {
    try {
      final paramsList = List<String?>.from((request.params as List));
      if (request.method == 'personal_sign') {
        // for `personal_sign` first value in params has to be always the message
        paramsList.removeAt(0);
      }

      return paramsList.firstWhere((p) {
        try {
          EthereumAddress.fromHex(p ?? '');
          return true;
        } catch (e) {
          return false;
        }
      });
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  static dynamic getDataFromSessionRequest(SessionRequest request) {
    try {
      final paramsList = List.from((request.params as List));
      if (request.method == 'personal_sign') {
        return paramsList.first;
      }
      return paramsList.firstWhere((p) {
        final address = getAddressFromSessionRequest(request);
        return p != address;
      });
    } catch (e) {
      debugPrint('getDataFromSessionRequest $e');
      return null;
    }
  }

  static Map<String, dynamic>? getTransactionFromSessionRequest(
    SessionRequest request,
  ) {
    try {
      final param = (request.params as List<dynamic>).first;
      return param as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getTransactionFromSessionRequest $e');
      return null;
    }
  }

  static Future<dynamic> decodeMessageEvent(MessageEvent event) async {
    final walletKit = getIt<WalletKitService>().walletKit;

    final payloadString = await walletKit.core.crypto.decode(
      event.topic,
      event.message,
    );

    if (payloadString == null) return null;

    final data = jsonDecode(payloadString) as Map<String, dynamic>;
    if (data.containsKey('method')) {
      return JsonRpcRequest.fromJson(data);
    } else {
      return JsonRpcResponse.fromJson(data);
    }
  }
}
