import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class CopyWrapper extends StatefulWidget {
  const CopyWrapper(
      {super.key,
      this.data,
      this.requireLongPress = false,
      this.isSensitive = false,
      this.builder,
      this.controlBuilder,
      this.duration = const Duration(milliseconds: 1200)})
      : assert((builder == null) != (controlBuilder == null),
            "Provide exactly one of builder or controlBuilder");

  final ClipboardData? data;
  final bool isSensitive;
  final bool requireLongPress;

  /// Builds content that this widget makes copyable with its own gesture
  /// detector. Receives the transient "copied" state.
  final Widget Function(BuildContext, bool)? builder;

  /// Builds a control that performs the copy itself, so no extra gesture or
  /// semantics layer is stacked on top of it. [onCopy] is null when there is
  /// nothing to copy.
  final Widget Function(BuildContext context, bool copied, VoidCallback? onCopy)? controlBuilder;

  final Duration duration;

  @override
  State<CopyWrapper> createState() => _CopyWrapperState();
}

class _CopyWrapperState extends State<CopyWrapper> {
  bool copied = false;

  void handleCopy() async {
    if (widget.data == null) return;
    ClipboardUtil.setSensitiveDataToClipboard(widget.data!, isSensitive: widget.isSensitive);
    HapticFeedback.mediumImpact();
    SemanticsService.announce(S.of(context).copied, Directionality.of(context));
    if (await shouldShowCopied()) {
      setState(() => copied = true);
      Future.delayed(widget.duration, () {
        if (mounted) setState(() => copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onCopy = widget.data == null ? null : handleCopy;

    if (widget.controlBuilder != null) return widget.controlBuilder!(context, copied, onCopy);

    final content = widget.builder!(context, copied);

    // Nothing to copy: don't leave behind a gesture detector that a screen
    // reader would present as an actionable target that does nothing.
    if (onCopy == null) return content;

    return MergeSemantics(
      child: Semantics(
        button: !widget.requireLongPress,
        hint: widget.requireLongPress ? S.of(context).long_press_to_copy : S.of(context).copy,
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          CustomSemanticsAction(label: S.of(context).copy): onCopy,
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.requireLongPress ? null : onCopy,
          onLongPress: !widget.requireLongPress ? null : onCopy,
          child: content,
        ),
      ),
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
