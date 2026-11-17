import "dart:async";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/call_scam_warning_sheet.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/phone_call_native.dart";
import "package:flutter/material.dart";

class CallScamBanner extends StatefulWidget {
  const CallScamBanner({
    required this.navigatorKey,
    required this.enabled,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;
  final Widget child;

  @override
  State<CallScamBanner> createState() => _CallScamBannerState();
}

class _CallScamBannerState extends State<CallScamBanner> {
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription<bool>? _phoneCallSubscription;
  bool _isOnPhoneCall = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _checkPhoneCall);
    _updatePhoneCallDetection();
  }

  @override
  void didUpdateWidget(CallScamBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      _updatePhoneCallDetection();
    }
  }

  @override
  void dispose() {
    _phoneCallSubscription?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _updatePhoneCallDetection() {
    if (widget.enabled) {
      _phoneCallSubscription = phoneCallStatusNative.listen(_setOnPhoneCall);
      _checkPhoneCall();
    } else {
      _phoneCallSubscription?.cancel();
      _phoneCallSubscription = null;
      _isOnPhoneCall = false;
    }
  }

  Future<void> _checkPhoneCall() async {
    if (widget.enabled) {
      _setOnPhoneCall(await isOnPhoneCallNative());
    }
  }

  void _setOnPhoneCall(bool isOnPhoneCall) {
    if (mounted && widget.enabled && isOnPhoneCall != _isOnPhoneCall) {
      setState(() => _isOnPhoneCall = isOnPhoneCall);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Column(
      children: [
        if (_isOnPhoneCall)
          _CallScamBannerContent(
            topInset: mediaQuery.padding.top,
            onTap: () => CallScamWarningSheet.show(widget.navigatorKey.currentContext!),
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: Semantics(
            container: _isOnPhoneCall,
            child: MediaQuery(
              data: _isOnPhoneCall
                  ? mediaQuery.copyWith(padding: mediaQuery.padding.copyWith(top: 0))
                  : mediaQuery,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

class _CallScamBannerContent extends StatelessWidget {
  const _CallScamBannerContent({required this.topInset, required this.onTap});

  final double topInset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        child: MergeSemantics(
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.errorContainer
                      : null,
                  gradient: Theme.of(context).brightness == Brightness.light
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x1CB71919), Color(0x54B71919)],
                        ),
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).colorScheme.error, width: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/phone_in_talk.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.error,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).call_scam_banner_title(approximatedAppName),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.error),
                          ),
                          Text(
                            S.of(context).call_scam_banner_description(
                                  isMoneroOnly ? approximatedAppName : "Cake",
                                ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: CakeImageWidget(
                        imageUrl: "assets/new-ui/info.svg",
                        width: 19,
                        height: 19,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
