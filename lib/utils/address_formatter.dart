import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

class AddressFormatter {
  static Widget buildSegmentedAddress({
    required String address,
    WalletType? walletType,
    required TextStyle evenTextStyle,
    TextStyle? oddTextStyle,
    TextAlign? textAlign,
    bool shouldTruncate = false,
  }) {

    final cleanAddress = address.replaceAll('bitcoincash:', '');
    final isMWEB = address.startsWith('ltcmweb');
    final chunkSize = walletType != null ? _getChunkSize(walletType) : 4;
    final isHumanReadable = address.contains("@");

    if (isHumanReadable) {
      return Text(address, style: evenTextStyle, textAlign: textAlign ?? TextAlign.start);
    }

    if (shouldTruncate) {
      return _buildTruncatedAddress(
        address: cleanAddress,
        isMWEB: isMWEB,
        chunkSize: chunkSize,
        evenTextStyle: evenTextStyle,
        oddTextStyle: oddTextStyle ?? evenTextStyle.copyWith(color: evenTextStyle.color!.withAlpha(150)),
        textAlign: textAlign,
      );
    } else {
      return _buildFullSegmentedAddress(
        address: cleanAddress,
        isMWEB: isMWEB,
        chunkSize: chunkSize,
        evenTextStyle: evenTextStyle,
        oddTextStyle: oddTextStyle ?? evenTextStyle.copyWith(color: evenTextStyle.color!.withAlpha(128)),
        textAlign: textAlign,
      );
    }
  }

  static Widget _buildFullSegmentedAddress({
    required String address,
    required bool isMWEB,
    required int chunkSize,
    required TextStyle evenTextStyle,
    required TextStyle oddTextStyle,
    TextAlign? textAlign,
  }) {

    final chunks = <String>[];

    if (isMWEB) {
      const mwebDisplayPrefix = 'ltcmweb';
      chunks.add(mwebDisplayPrefix);
      final startIndex = mwebDisplayPrefix.length;
      for (int i = startIndex; i < address.length; i += chunkSize) {
        final chunk = address.substring(
          i,
          math.min(i + chunkSize, address.length),
        );
        chunks.add(chunk);
      }
    } else {
      for (int i = 0; i < address.length; i += chunkSize) {
        final chunk = address.substring(
          i,
          math.min(i + chunkSize, address.length),
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
    required bool isMWEB,
    required int chunkSize,
    required TextStyle evenTextStyle,
    required TextStyle oddTextStyle,
    TextAlign? textAlign,
  }) {

    if (isMWEB) {
      const fixedPrefix = 'ltcmweb';
      final secondChunkStart = fixedPrefix.length;
      const chunkSize = 4;
      final secondChunk = address.substring(
        secondChunkStart,
        math.min(secondChunkStart + chunkSize, address.length),
      );
      final lastChunk = address.substring(address.length - chunkSize);

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
      final int digitCount = chunkSize;

      if (address.length <= 2 * digitCount) {
        return _buildFullSegmentedAddress(
          address: address,
          isMWEB: isMWEB,
          chunkSize: chunkSize,
          evenTextStyle: evenTextStyle,
          oddTextStyle: oddTextStyle,
          textAlign: textAlign,
        );
      }

      final String firstPart = address.substring(0, digitCount);
      final String secondPart =
      address.substring(digitCount, digitCount * 2);
      final String lastPart =
      address.substring(address.length - digitCount);

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
