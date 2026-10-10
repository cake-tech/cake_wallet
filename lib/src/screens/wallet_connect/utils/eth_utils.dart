import "dart:convert";
import "dart:typed_data";

import "package:cake_wallet/di.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart";
import "package:convert/convert.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:reown_walletkit/reown_walletkit.dart";

class EthUtils {
  static String getUtf8Message(String maybeHex) {
    if (maybeHex.startsWith("0x")) {
      try {
        return utf8.decode(hex.decode(maybeHex.substring(2)));
      } catch (e) {
        printV("getUtf8Message: payload is not utf8 text, showing it as hex: $e");
      }
    }
    return maybeHex;
  }

  static Uint8List getMessageBytes(String maybeHex) {
    if (maybeHex.startsWith("0x")) {
      try {
        return Uint8List.fromList(hex.decode(maybeHex.substring(2)));
      } catch (e) {
        printV("getMessageBytes: 0x payload is not hex, signing it as text: $e");
      }
    }
    return Uint8List.fromList(utf8.encode(maybeHex));
  }

  static String? stringifyTypedData(dynamic payload) {
    if (payload is String) {
      return payload;
    }
    if (payload == null) {
      return null;
    }
    try {
      return jsonEncode(payload);
    } catch (e) {
      printV("stringifyTypedData: payload cannot be encoded: $e");
      return null;
    }
  }

  static String? getAddressFromSessionRequest(SessionRequest request) {
    try {
      final params = request.params;
      if (params is! List) {
        return null;
      }
      final list = List<dynamic>.from(params);

      switch (request.method) {
        case "personal_sign":
          if (list.length >= 2) {
            return _toAddress(list[1]);
          }
          break;
        case "eth_sign":
          if (list.isNotEmpty) {
            return _toAddress(list[0]);
          }
          break;
        case "eth_signTypedData":
        case "eth_signTypedData_v1":
        case "eth_signTypedData_v3":
        case "eth_signTypedData_v4":
          if (list.isNotEmpty) {
            return _toAddress(list[0]);
          }
          break;
      }

      for (final p in list) {
        final addr = _toAddress(p);
        if (addr != null) {
          return addr;
        }
      }
    } catch (e) {
      printV("getAddressFromSessionRequest $e");
    }
    return null;
  }

  static dynamic getDataFromSessionRequest(SessionRequest request) {
    try {
      final params = request.params;
      if (params is! List) {
        return null;
      }
      final list = List<dynamic>.from(params);

      switch (request.method) {
        case "personal_sign":
          if (list.isNotEmpty) {
            return list[0];
          }
          break;
        case "eth_sign":
          if (list.length >= 2) {
            return list[1];
          }
          break;
        case "eth_signTypedData":
        case "eth_signTypedData_v1":
        case "eth_signTypedData_v3":
        case "eth_signTypedData_v4":
          if (list.length >= 2) {
            return _toAddress(list[1]) != null && _toAddress(list[0]) == null ? list[0] : list[1];
          }
          break;
      }

      for (final p in list) {
        if (_toAddress(p) == null) {
          return p;
        }
      }
    } catch (e) {
      printV("getDataFromSessionRequest $e");
    }
    return null;
  }

  static Map<String, dynamic>? getTransactionFromSessionRequest(SessionRequest request) {
    try {
      final param = (request.params as List<dynamic>).first;
      return param as Map<String, dynamic>;
    } catch (e) {
      printV("getTransactionFromSessionRequest $e");
      return null;
    }
  }

  static Future<dynamic> decodeMessageEvent(MessageEvent event) async {
    final walletKit = getIt<WalletKitService>().walletKit;
    final payloadString = await walletKit.core.crypto.decode(event.topic, event.message);
    if (payloadString == null) {
      return null;
    }

    final data = jsonDecode(payloadString) as Map<String, dynamic>;
    if (data.containsKey("method")) {
      return JsonRpcRequest.fromJson(data);
    } else {
      return JsonRpcResponse.fromJson(data);
    }
  }

  static String? _toAddress(dynamic value) {
    if (value is! String) {
      return null;
    }
    try {
      return EthereumAddress.fromHex(value).hex;
    } catch (_) {
      return null;
    }
  }
}
