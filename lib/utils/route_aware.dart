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
  final Function(BuildContext context)? pushToWidget;
  final Function(BuildContext context)? pushToNextWidget;
  final Function(BuildContext context)? popWidget;
  final Function(BuildContext context)? popNextWidget;

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
      widget.pushToWidget!(context);
    }
  }

  @override
  void didPushNext() {
    if (widget.pushToNextWidget != null) {
      widget.pushToNextWidget!(context);
    }
  }

  @override
  void didPop() {
    if (widget.popWidget != null) {
      widget.popWidget!(context);
    }
  }

  @override
  void didPopNext() {
    if (widget.popNextWidget != null) {
      widget.popNextWidget!(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
