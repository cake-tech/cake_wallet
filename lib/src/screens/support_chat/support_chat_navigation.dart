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

/// `onCreateWindow` cannot keep a page inside this webview: returning false
/// drops the navigation. http(s) targets that would have stayed on the chat
/// host, such as a file attachment, open in the system browser instead.
SupportChatNavigation decideSupportChatPopup({
  required Uri? request,
  required String allowedHost,
}) {
  final decision = decideSupportChatNavigation(
    request: request,
    isMainFrame: true,
    allowedHost: allowedHost,
  );
  if (decision != SupportChatNavigation.allow || request == null) {
    return decision;
  }
  final scheme = request.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return SupportChatNavigation.openOutside;
  }
  return decision;
}
