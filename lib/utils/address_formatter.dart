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

    final isMWEB = walletType == WalletType.litecoin && address.startsWith('ltcmweb');
    final cleanAddress = address.replaceAll('bitcoincash:', '');
    final chunkSize = _getChunkSize(walletType);
    final chunks = <String>[];

    if (isMWEB) {
      const mwebDisplayPrefix = 'ltcmweb';
      chunks.add(mwebDisplayPrefix);
      final startIndex = 7;
      for (int i = startIndex; i < cleanAddress.length; i += chunkSize) {
        final chunk = cleanAddress.substring(
          i,
          math.min(i + chunkSize, cleanAddress.length),
        );
        chunks.add(chunk);
      }
    } else {
      for (int i = 0; i < cleanAddress.length; i += chunkSize) {
        final chunk = cleanAddress.substring(
          i,
          math.min(i + chunkSize, cleanAddress.length),
        );
        chunks.add(chunk);
      }
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
    final isMWEB = walletType == WalletType.litecoin && address.startsWith('ltcmweb');

    if (isMWEB) {
      const fixedPrefix = 'ltcmweb';
      final secondChunkStart = 7;
      const chunkSize = 4;
      final secondChunk = cleanAddress.substring(
        secondChunkStart,
        math.min(secondChunkStart + chunkSize, cleanAddress.length),
      );
      final lastChunk = cleanAddress.substring(cleanAddress.length - chunkSize);

      final spans = <TextSpan>[
        TextSpan(text: '$fixedPrefix ', style: evenTextStyle),
        TextSpan(text: '$secondChunk ', style: oddTextStyle),
        TextSpan(text: '... ', style: oddTextStyle),
        TextSpan(text: lastChunk, style: evenTextStyle),
      ];

      return RichText(
        text: TextSpan(children: spans),
        textAlign: textAlign ?? TextAlign.start,
        overflow: TextOverflow.visible,
      );
    } else {
      final int digitCount = _getChunkSize(walletType);

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
      final String secondPart =
      cleanAddress.substring(digitCount, digitCount * 2);
      final String lastPart =
      cleanAddress.substring(cleanAddress.length - digitCount);

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