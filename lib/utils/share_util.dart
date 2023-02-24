import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtil {
  static void share({required String text, required BuildContext context}) {
    final box = context.findRenderObject() as RenderBox?;

    Share.share(
      text,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }
}