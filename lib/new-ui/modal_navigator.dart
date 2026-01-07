import 'package:cake_wallet/router.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';

/// allows for full navigation with pages and routes inside a single modal sheet.
/// call this in your modal sheet's builder, passing whatever the modal's first page should be to rootPage.
/// afterwards you can call pushNamed to push other pages, they'll be created inside the modal.
/// you can use the back button (android) or the swipe back gesture (both android and iphone) to go back.
/// calling Navigator.of(context).pop() will pop the page INSIDE the modal sheet.
/// if you want to pop the whole sheet, use Navigator.of(context, rootNavigator: true).pop().
class ModalNavigator extends StatefulWidget {
  const ModalNavigator({super.key, required this.rootPage});

  final Widget rootPage;

  @override
  State<ModalNavigator> createState() => _ModalNavigatorState();
}

class _ModalNavigatorState extends State<ModalNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Theme(
        data: Theme.of(context).copyWith(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              // requested by ui - iphone-style back anim on every platform
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final navigator = _navigatorKey.currentState;
            if (navigator != null) {
              final popped = await navigator.maybePop();
              if (popped) return;
            }

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Navigator(
              key: _navigatorKey,
              onGenerateRoute: (settings) {

                printV(settings.name);

                if (settings.name == "/")
                  return handleRouteWithPlatformAwareness((context) => widget.rootPage,
                      fullscreenDialog: false);
                else
                  return createRoute(settings);
              }),
        ),
      ),
    );
  }
}
