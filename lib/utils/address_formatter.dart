import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

class AddressFormatter {
  static Widget buildSegmentedAddress({
    required String address,
    required WalletType walletType,
    required TextStyle evenTextStyle,
    TextStyle? oddTextStyle,
    TextAlign? textAlign,
    bool shouldTruncate = false,
  }) {
    if (shouldTruncate) {
      return _buildTruncatedAddress(
        address: address,
        walletType: walletType,
        evenTextStyle: evenTextStyle,
        oddTextStyle: oddTextStyle ?? evenTextStyle.copyWith(color: evenTextStyle.color!.withAlpha(150)),
        textAlign: textAlign,
      );
    } else {
      return _buildFullSegmentedAddress(
        address: address,
        walletType: walletType,
        evenTextStyle: evenTextStyle,
        oddTextStyle: oddTextStyle ?? evenTextStyle.copyWith(color: evenTextStyle.color!.withAlpha(128)),
        textAlign: textAlign,
      );
    }
  }

  static Widget _buildFullSegmentedAddress({
    required String address,
    required WalletType walletType,
    required TextStyle evenTextStyle,
    required TextStyle oddTextStyle,
    TextAlign? textAlign,
  }) {

    final cleanAddress = address.replaceAll('bitcoincash:', '');
    final chunkSize = _getChunkSize(walletType);
    final chunks = <String>[];

    for (int i = 0; i < cleanAddress.length; i += chunkSize) {
      final chunk = cleanAddress.substring(i, math.min(i + chunkSize, cleanAddress.length));
      chunks.add(chunk);
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < chunks.length; i++) {
      final style = (i % 2 == 0) ? evenTextStyle : oddTextStyle;
      spans.add(TextSpan(text: '${chunks[i]} ', style: style));
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      overflow: TextOverflow.visible,
    );
  }

  static Widget _buildTruncatedAddress({
    required String address,
    required WalletType walletType,
    required TextStyle evenTextStyle,
    required TextStyle oddTextStyle,
    TextAlign? textAlign,
  }) {

    final cleanAddress = address.replaceAll('bitcoincash:', '');

    final int digitCount = (walletType == WalletType.monero ||
        walletType == WalletType.wownero ||
        walletType == WalletType.zano)
        ? 6
        : 4;

    if (cleanAddress.length <= 2 * digitCount) {
      return _buildFullSegmentedAddress(
        address: cleanAddress,
        walletType: walletType,
        evenTextStyle: evenTextStyle,
        oddTextStyle: oddTextStyle,
        textAlign: textAlign,
      );
    }

    final String firstPart = cleanAddress.substring(0, digitCount);
    final String secondPart = cleanAddress.substring(digitCount, digitCount * 2);
    final String lastPart = cleanAddress.substring(cleanAddress.length - digitCount);

    final spans = <TextSpan>[
      TextSpan(text: '$firstPart ', style: evenTextStyle),
      TextSpan(text: '$secondPart ', style: oddTextStyle),
      TextSpan(text: '... ', style: oddTextStyle),
      TextSpan(text: lastPart, style: evenTextStyle),
    ];

    return RichText(
      text: TextSpan(children: spans),
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
