import 'package:flutter/material.dart';

class QRCodeTheme extends ThemeExtension<QRCodeTheme> {
  final Color qrCodeColor;
  final Color qrWidgetCopyButtonColor;

  QRCodeTheme(
      {required this.qrCodeColor, required this.qrWidgetCopyButtonColor});

  @override
  QRCodeTheme copyWith({Color? qrCodeColor, Color? qrWidgetCopyButtonColor}) =>
      QRCodeTheme(
          qrCodeColor: qrCodeColor ?? this.qrCodeColor,
          qrWidgetCopyButtonColor:
              qrWidgetCopyButtonColor ?? this.qrWidgetCopyButtonColor);

  @override
  QRCodeTheme lerp(ThemeExtension<QRCodeTheme>? other, double t) {
    if (other is! QRCodeTheme) {
      return this;
    }

    return QRCodeTheme(
        qrCodeColor: Color.lerp(qrCodeColor, other.qrCodeColor, t)!,
        qrWidgetCopyButtonColor: Color.lerp(
            qrWidgetCopyButtonColor, other.qrWidgetCopyButtonColor, t)!);
  }
}
