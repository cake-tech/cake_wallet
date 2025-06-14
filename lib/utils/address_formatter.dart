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
    int visibleChunks = 2,
  }) {
    final cleanAddress = address.replaceAll('bitcoincash:', '');
    final isMWEB = address.startsWith('ltcmweb');
    final chunkSize = walletType != null ? _getChunkSize(walletType) : 4;

    if (shouldTruncate) {
      return _buildTruncatedAddress(
        address: cleanAddress,
        isMWEB: isMWEB,
        chunkSize: chunkSize,
        visibleChunks: visibleChunks,
        evenTextStyle: evenTextStyle,
        oddTextStyle:
            oddTextStyle ?? evenTextStyle.copyWith(color: evenTextStyle.color!.withAlpha(150)),
        textAlign: textAlign,
      );
    } else {
      return _buildFullSegmentedAddress(
        address: cleanAddress,
        isMWEB: isMWEB,
        chunkSize: chunkSize,
        evenTextStyle: evenTextStyle,
        oddTextStyle:
            oddTextStyle ?? evenTextStyle.copyWith(color: evenTextStyle.color!.withAlpha(128)),
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
    required int visibleChunks,
    required TextStyle evenTextStyle,
    required TextStyle oddTextStyle,
    TextAlign? textAlign,
  }) {
    if (isMWEB) {
      const prefix = 'ltcmweb';
      final rest = address.substring(prefix.length);

      final chunks = <String>[];
      for (int i = 0; i < rest.length; i += chunkSize) {
        chunks.add(rest.substring(i, math.min(i + chunkSize, rest.length)));
      }

      if (chunks.length <= visibleChunks + 1) {
        return _buildFullSegmentedAddress(
          address: address,
          isMWEB: true,
          chunkSize: chunkSize,
          evenTextStyle: evenTextStyle,
          oddTextStyle: oddTextStyle,
          textAlign: textAlign,
        );
      }

      final spans = <TextSpan>[
        TextSpan(text: '$prefix ', style: evenTextStyle),
      ];

      for (var i = 0; i < visibleChunks; i++) {
        final style = (i.isEven) ? oddTextStyle : evenTextStyle;
        spans.add(TextSpan(text: '${chunks[i]} ', style: style));
      }

      spans.add(TextSpan(text: '... ', style: oddTextStyle));

      final lastStyle = (visibleChunks.isEven) ? evenTextStyle : oddTextStyle;
      spans.add(TextSpan(text: chunks.last, style: lastStyle));

      return RichText(
        text: TextSpan(children: spans),
        textAlign: textAlign ?? TextAlign.start,
        overflow: TextOverflow.visible,
      );
    }

    final chunks = <String>[];
    for (int i = 0; i < address.length; i += chunkSize) {
      chunks.add(address.substring(i, math.min(i + chunkSize, address.length)));
    }

    if (chunks.length <= visibleChunks + 1) {
      return _buildFullSegmentedAddress(
        address: address,
        isMWEB: false,
        chunkSize: chunkSize,
        evenTextStyle: evenTextStyle,
        oddTextStyle: oddTextStyle,
        textAlign: textAlign,
      );
    }

    final spans = <TextSpan>[];

    for (var i = 0; i < visibleChunks; i++) {
      final style = (i.isEven) ? evenTextStyle : oddTextStyle;
      spans.add(TextSpan(text: '${chunks[i]} ', style: style));
    }

    spans.add(TextSpan(text: '... ', style: oddTextStyle));

    final lastStyle = (visibleChunks.isEven) ? oddTextStyle : evenTextStyle;
    spans.add(TextSpan(text: chunks.last, style: lastStyle));

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
