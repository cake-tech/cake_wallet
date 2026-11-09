import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class ShareUtil {
  static void share({required String text, required BuildContext context}) {
    Share.share(
      text,
      sharePositionOrigin: _sharePosition(context),
    ).catchError((Object _) => ShareResult.unavailable, test: _isAlreadyPresenting);
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
    ).catchError((Object _) => ShareResult.unavailable, test: _isAlreadyPresenting);
  }

  // _sharePosition always gives a valid anchor, so on iOS this only means something is already
  // presented on top, in practice a share sheet after a quick double tap. Drop the duplicate.
  static bool _isAlreadyPresenting(Object error) =>
      error is PlatformException && (error.message?.startsWith('sharePositionOrigin') ?? false);

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

    // A page context (rather than the tapped button's) gives a rect covering most of the screen,
    // which leaves an iPad popover no room: iPadOS 17 lays the share sheet out 0pt wide and the
    // next share throws. Anchor such rects at their centre.
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        clipped.width > screen.width / 2 &&
        clipped.height > screen.height / 2) {
      return Rect.fromCenter(center: clipped.center, width: 1, height: 1);
    }
    return clipped;
  }
}
