import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyWrapper extends StatefulWidget {
  const CopyWrapper(
      {super.key,
      this.data,
      required this.builder,
      this.duration = const Duration(milliseconds: 1200)});

  final ClipboardData? data;
  final Widget Function(BuildContext, bool) builder;
  final Duration duration;

  @override
  State<CopyWrapper> createState() => _CopyWrapperState();
}

class _CopyWrapperState extends State<CopyWrapper> {
  bool copied = false;

  void handleCopy() async {
    if (widget.data == null) return;
    Clipboard.setData(widget.data!);
    if (await shouldShowCopied()) {
      setState(() => copied = true);
      Future.delayed(widget.duration, () {
        if (mounted) setState(() => copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: handleCopy,
      child: widget.builder(context, copied),
    );
  }

  // android 13 (sdk 33) added a built-in "text was copied to clipboard" ui element
  Future<bool> shouldShowCopied() async {
    if (!Platform.isAndroid) return true;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdk = androidInfo.version.sdkInt;

      return sdk < 33;
    } catch (_) {
      return true;
    }
  }
}
