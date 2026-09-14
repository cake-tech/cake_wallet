import "dart:convert";

import "package:cake_wallet/core/aeon_pay/models.dart";
import "package:crypto/crypto.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_type.dart";
import "package:eth_sig_util/util/utils.dart";

class AeonPayService {
  static bool isAeonPaySQR(String value) =>
      RegExp(r"^.*704.*VN.*$").hasMatch(value) ||
      RegExp(r"^.*608.*PH.*$").hasMatch(value) ||
      RegExp(r"^0002.*986.*BR.*$").hasMatch(value);

  final sandUrl = "https://qrpay-sbx.aeon.xyz";
  final prodUrl = "https://qrpay.aeon.xyz";

  Future<AeonPayDecodeQrDTO?> decodeQR(String qrString) async {
    final payload = {"appId": appId, "qrCode": qrString};
    payload["sign"] = _signParams(payload, signKey);

    final response = await ProxyWrapper().post(
      clearnetUri: Uri.parse("$sandUrl/open/api/scanCode"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      printV(response.body);
      return AeonPayDecodeQrDTO.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<AeonPayCreateOrderDTO?> createOrder(String qrString, AeonPayDecodeQrModel order) async {
    final merchantOrderNo = DateTime.now().millisecondsSinceEpoch.toRadixString(15);
    final payload = {
      "amount": order.amount?.toString() ?? "131500",
      "appId": appId,
      "callbackUrl": "https://cakewallet.com/dont-callback-me-maybe",
      "currency": order.currency,
      "feeType": "INNER_BUCKLE",
      "merchantOrderNo": merchantOrderNo,
      "qrCode": qrString,
      "userId": "kons",
      "userIp": "8.8.8.8",
    };
    payload["sign"] = _signParams(payload, signKey);
    payload["email"] = "";

    final response = await ProxyWrapper().post(
      clearnetUri: Uri.parse("$sandUrl/open/api/scan/payment"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      printV(response.body);
      return AeonPayCreateOrderDTO.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> commitTransaction(String qrString) async {}

  CryptoCurrency getSupportedCryptoCurrency(WalletType walletType) {
    switch (walletType) {
      case WalletType.monero:
        throw UnimplementedError(); // Coming soon
      case WalletType.bitcoin:
        throw UnimplementedError(); // Coming soon
      case WalletType.ethereum:
        return Erc20Token(
          name: "USDT Tether",
          symbol: "USDT",
          contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
          decimal: 6,
        );
      case WalletType.polygon:
        return CryptoCurrency.usdtPoly;
      case WalletType.solana:
        return CryptoCurrency.usdcsol;
      case WalletType.tron:
        return CryptoCurrency.usdcTrc20;
      default:
        throw UnimplementedError();
    }
  }

  String _signParams(Map<String, String> params, String key) {
    final message = "${params.entries.map((e) => "${e.key}=${e.value}").join("&")}&key=$key";
    printV(message);
    return bytesToHex(sha512.convert(utf8.encode(message).toList()).bytes).toUpperCase();
  }
}
