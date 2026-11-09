enum SupportChatNavigation { allow, openOutside, cancel }

/// Main-frame navigations stay on the chat host. Other http(s) links leave
/// the webview so the support screen cannot be used as a general browser.
SupportChatNavigation decideSupportChatNavigation({
  required Uri? request,
  required bool isMainFrame,
  required String allowedHost,
}) {
  if (!isMainFrame) {
    return SupportChatNavigation.allow;
  }
  if (request == null) {
    return SupportChatNavigation.cancel;
  }

  final scheme = request.scheme.toLowerCase();
  if (scheme == 'about' || scheme == 'blob' || scheme == 'data') {
    return SupportChatNavigation.allow;
  }
  if (scheme != 'http' && scheme != 'https') {
    return SupportChatNavigation.cancel;
  }
  if (request.host.toLowerCase() == allowedHost.toLowerCase()) {
    return SupportChatNavigation.allow;
  }
  return SupportChatNavigation.openOutside;
}
