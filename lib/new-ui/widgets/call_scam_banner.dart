import "dart:async";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/call_scam_warning_sheet.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/phone_call_native.dart";
import "package:flutter/material.dart";

class CallScamBanner extends StatefulWidget {
  const CallScamBanner({required this.child, super.key});

  final Widget child;

  @override
  State<CallScamBanner> createState() => _CallScamBannerState();
}

class _CallScamBannerState extends State<CallScamBanner> {
  late final AppLifecycleListener _lifecycleListener;
  late final StreamSubscription<bool> _phoneCallSubscription;
  bool _isOnPhoneCall = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _checkPhoneCall);
    _phoneCallSubscription = phoneCallStatusNative.listen(_setOnPhoneCall);
    _checkPhoneCall();
  }

  @override
  void dispose() {
    _phoneCallSubscription.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneCall() async => _setOnPhoneCall(await isOnPhoneCallNative());

  void _setOnPhoneCall(bool isOnPhoneCall) {
    if (mounted && isOnPhoneCall != _isOnPhoneCall) {
      setState(() => _isOnPhoneCall = isOnPhoneCall);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Column(
      children: [
        if (_isOnPhoneCall)
          _CallScamBannerContent(topInset: mediaQuery.padding.top)
        else
          const SizedBox.shrink(),
        Expanded(
          child: MediaQuery(
            data: _isOnPhoneCall
                ? mediaQuery.copyWith(padding: mediaQuery.padding.copyWith(top: 0))
                : mediaQuery,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _CallScamBannerContent extends StatelessWidget {
  const _CallScamBannerContent({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: () => CallScamWarningSheet.show(context),
            child: Ink(
              padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x1CB71919), Color(0x54B71919)],
                ),
                border: Border(bottom: BorderSide(color: colorScheme.error, width: 0.4)),
              ),
              child: Row(
                children: [
                  CakeImageWidget(
                    imageUrl: "assets/new-ui/phone_in_talk.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(colorScheme.error, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          S.of(context).call_scam_banner_title(approximatedAppName),
                          style: textTheme.labelMedium?.copyWith(color: colorScheme.error),
                        ),
                        Text(
                          S.of(context).call_scam_banner_description(
                                isMoneroOnly ? approximatedAppName : "Cake",
                              ),
                          style: textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CakeImageWidget(
                    imageUrl: "assets/new-ui/info_outlined.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(colorScheme.onSurfaceVariant, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
