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
    // Check for parentheses in the address
    final bracketIndex = address.indexOf('[');
    
    if (bracketIndex != -1) {
      // Split address and amount parts
      final addressPart = address.substring(0, bracketIndex).trim();
      final amountPart = address.substring(bracketIndex);
      
      // For truncated addresses, handle differently
      if (shouldTruncate) {
        final addressWidget = _buildAddressWidget(
          address: addressPart,
          walletType: walletType,
          evenTextStyle: evenTextStyle,
          oddTextStyle: oddTextStyle,
          textAlign: textAlign,
          shouldTruncate: shouldTruncate,
        );
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            addressWidget,
            Text(amountPart, style: evenTextStyle),
          ],
        );
      }
      
      // For full addresses, integrate amount with last line
      final cleanAddress = addressPart.replaceAll('bitcoincash:', '');
      final isMWEB = addressPart.startsWith('ltcmweb');
      final chunkSize = walletType != null ? _getChunkSize(walletType) : 4;
      
      // Build chunks
      final chunks = <String>[];
      if (isMWEB) {
        const mwebDisplayPrefix = 'ltcmweb';
        chunks.add(mwebDisplayPrefix);
        final startIndex = mwebDisplayPrefix.length;
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
      
      // Build text spans with amount appended to last chunk
      final spans = <TextSpan>[];
      for (int i = 0; i < chunks.length; i++) {
        final style = (i % 2 == 0) ? evenTextStyle : oddTextStyle ?? evenTextStyle.copyWith(color: evenTextStyle.color!.withAlpha(128));
        
        if (i == chunks.length - 1) {
          // Last chunk - append amount
          spans.add(TextSpan(text: '${chunks[i]} ', style: style));
          spans.add(TextSpan(text: amountPart, style: evenTextStyle));
        } else {
          spans.add(TextSpan(text: '${chunks[i]} ', style: style));
        }
      }
      
      return RichText(
        text: TextSpan(children: spans),
        textAlign: textAlign ?? TextAlign.start,
        overflow: TextOverflow.visible,
      );
    }
    
    // No parentheses - use original logic
    return _buildAddressWidget(
      address: address,
      walletType: walletType,
      evenTextStyle: evenTextStyle,
      oddTextStyle: oddTextStyle,
      textAlign: textAlign,
      shouldTruncate: shouldTruncate,
    );
  }

  static Widget _buildAddressWidget({
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