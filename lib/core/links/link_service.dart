import "dart:async";

import "package:cake_wallet/core/links/app_link.dart";
import "package:flutter/widgets.dart";

class LinkService {
  BuildContext? _context;
  AppLink? _pending;
  bool _paused = false;

  Future<void> handle(Uri uri) {
    _pending = appLinkFor(uri);
    return _flush();
  }

  void attach(BuildContext context) {
    _context = context;
    unawaited(_flush());
  }

  void detach(BuildContext context) {
    if (!identical(_context, context)) {
      return;
    }

    _context = null;
    _paused = false;
  }

  void pause() => _paused = true;

  Future<void> resume() {
    _paused = false;
    return _flush();
  }

  Future<void> _flush() async {
    final link = _pending;
    final context = _context;
    if (link == null || context == null || !context.mounted || _paused) return;

    _pending = null;
    await link.navigate(context);
  }
}
