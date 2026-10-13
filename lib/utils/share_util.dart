import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class ShareUtil {
  static void share({required String text, required BuildContext context}) {
    Share.share(
      text,
      sharePositionOrigin: _sharePosition(context),
    );
  }

  static Future<ShareResult> shareFile({
    required String filePath,
    required String fileName,
    required BuildContext context,
    String? subject,
    String? text,
  }) {
    const _mimeType = 'application/*';
    return Share.shareXFiles(
      <XFile>[
        XFile(
          filePath,
          name: fileName,
          mimeType: _mimeType,
        )
      ],
      subject: subject,
      text: text,
      sharePositionOrigin: _sharePosition(context),
    );
  }

  static Rect _sharePosition(BuildContext context) {
    if (!context.mounted) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }

    final screen = Offset.zero & MediaQuery.of(context).size;
    final fallback = Rect.fromCenter(center: screen.center, width: 1, height: 1);

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return fallback;
    }

    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final clipped = rect.intersect(screen);
    if (clipped.isEmpty) {
      return fallback;
    }
    return clipped;
  }
}
