import "package:cake_wallet/core/links/link_service.dart";
import "package:flutter/widgets.dart";

class LinkListener extends StatefulWidget {
  const LinkListener({required this.linkService, required this.child, super.key});

  final LinkService linkService;
  final Widget child;

  @override
  State<LinkListener> createState() => _LinkListenerState();
}

class _LinkListenerState extends State<LinkListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.linkService.attach(context);
      }
    });
  }

  @override
  void dispose() {
    widget.linkService.detach(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
