import 'package:flutter/material.dart';
import 'package:cake_wallet/main.dart';

class RouteAwareWidget extends StatefulWidget {
  RouteAwareWidget(
      {required this.child,
      this.pushToWidget,
      this.pushToNextWidget,
      this.popWidget,
      this.popNextWidget});

  final Widget child;
  final Function()? pushToWidget;
  final Function()? pushToNextWidget;
  final Function()? popWidget;
  final Function()? popNextWidget;

  @override
  State<RouteAwareWidget> createState() => RouteAwareWidgetState();
}

class RouteAwareWidgetState extends State<RouteAwareWidget> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    if (widget.pushToWidget != null) {
      widget.pushToWidget!();
    }
  }

  @override
  void didPushNext() {
    if (widget.pushToNextWidget != null) {
      widget.pushToNextWidget!();
    }
  }

  @override
  void didPop() {
    if (widget.popWidget != null) {
      widget.popWidget!();
    }
  }

  @override
  void didPopNext() {
    if (widget.popNextWidget != null) {
      widget.popNextWidget!();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
