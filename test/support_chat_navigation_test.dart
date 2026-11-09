import 'package:cake_wallet/src/screens/support_chat/support_chat_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const chatHost = 'app.chatwoot.com';

  test('keeps the chat widget on its own host', () {
    final decision = decideSupportChatNavigation(
      request: Uri.parse('https://app.chatwoot.com/widget?website_token=abc'),
      isMainFrame: true,
      allowedHost: chatHost,
    );

    expect(decision, SupportChatNavigation.allow);
  });

  test('sends a link off the chat host to the system browser', () {
    final decision = decideSupportChatNavigation(
      request: Uri.parse('https://www.chatwoot.com'),
      isMainFrame: true,
      allowedHost: chatHost,
    );

    expect(decision, SupportChatNavigation.openOutside);
  });

  test('sends a merchant site linked from chat to the system browser', () {
    final decision = decideSupportChatNavigation(
      request: Uri.parse('https://www.youtube.com/watch?v=1'),
      isMainFrame: true,
      allowedHost: chatHost,
    );

    expect(decision, SupportChatNavigation.openOutside);
  });

  test('lets the widget load subframes and blank documents', () {
    expect(
      decideSupportChatNavigation(
        request: Uri.parse('https://www.chatwoot.com/packs/js/sdk.js'),
        isMainFrame: false,
        allowedHost: chatHost,
      ),
      SupportChatNavigation.allow,
    );
    expect(
      decideSupportChatNavigation(
        request: Uri.parse('about:blank'),
        isMainFrame: true,
        allowedHost: chatHost,
      ),
      SupportChatNavigation.allow,
    );
  });

  test('drops non-http schemes instead of navigating to them', () {
    final decision = decideSupportChatNavigation(
      request: Uri.parse('javascript:alert(1)'),
      isMainFrame: true,
      allowedHost: chatHost,
    );

    expect(decision, SupportChatNavigation.cancel);
  });
}
