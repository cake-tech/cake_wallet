import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

class AddressFormatter {
  static Widget buildSegmentedAddress({
    required String address,
    required WalletType walletType,
    required TextStyle evenTextStyle,
    required TextStyle oddTextStyle,
    TextAlign? textAlign,
  }) {
    final chunkSize = _getChunkSize(walletType);

    final spans = <TextSpan>[];

    for (int i = 0; i < address.length; i += chunkSize) {
      final chunk = address.substring(i, math.min(i + chunkSize, address.length));
      final style = (i ~/ chunkSize % 2 == 0) ? evenTextStyle : oddTextStyle;

      spans.add(
        TextSpan(text: '$chunk ', style: style),
      );
    }

    return RichText(
      text: TextSpan(children: spans, style: evenTextStyle),
      textAlign: textAlign ?? TextAlign.start,
      overflow: TextOverflow.visible,
    );
  }

  static int _getChunkSize(WalletType walletType) {
    switch (walletType) {
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.zano:
        return 6;
      default:
        return 4;
    }
  }
}
