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
  const ModalNavigator({super.key, required this.rootPage, required this.parentContext, this.heightMode = ModalHeightModes.fullScreen});

  final Widget rootPage;
  final BuildContext parentContext;
  final ModalHeightModes heightMode;

  @override
  State<ModalNavigator> createState() => _ModalNavigatorState();
}

enum ModalHeightModes {
  /// just render as big a modal as possible
  fullScreen,
  /// after first frame, read height and lock to that height
  autoLock,
  /// let the content size itself. jumps around when pushing different-sized pages!
  natural
}

class _ModalNavigatorState extends State<ModalNavigator> {
  final GlobalKey _sheetKey = GlobalKey();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  double? _sheetHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _sheetKey.currentContext;
      if (context == null) return;
      if(_sheetHeight != null) return;

      final box = context.findRenderObject() as RenderBox;
      setState(() {
        _sheetHeight = box.size.height;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    late final double? height;
    switch(widget.heightMode) {
      case ModalHeightModes.fullScreen:
        height = MediaQuery.of(context).size.height; break;
        case ModalHeightModes.autoLock:
        height = _sheetHeight; break;
      case ModalHeightModes.natural:
        height = null; break;
    }
    return Container(
      key:_sheetKey,
      height: height,
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
            if (navigator != null && await navigator.maybePop()) {
              return;
            }

            Navigator.of(widget.parentContext).pop();
          },
          child: Navigator(
              key: _navigatorKey,
              onGenerateRoute: (settings) {

                printV(settings.name);

                if (settings.name == "/")
                  return handleRouteWithPlatformAwareness((context) => PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, result) async {
                        Navigator.of(widget.parentContext).pop();
                      },
                      child: widget.rootPage),
                      fullscreenDialog: false);
                else
                  return createRoute(settings);
              }),
        ),
      ),
    );
  }
}
