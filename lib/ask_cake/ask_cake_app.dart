import 'package:cake_wallet/ask_cake/ask_cake_tools.dart';

/// Everything Ask Cake can read from or prepare in the app beyond the open
/// wallet's history. The chat uses the real app; the self-test uses a fixture.
///
/// Read methods return compact text for the model to quote from. Methods that
/// return an [AskCakeToolResult] never change anything themselves: they
/// describe what would happen and attach an action the user must tap.
abstract class AskCakeApp {
  /// Sync state, node, Tor and the main display settings.
  String status();

  /// Current price and, with a [range] of 1d, 7d, 30d, 1y or all, how it moved.
  Future<String> price(String? asset, String? range);

  Future<String> lightningInfo();

  String tokens();

  Future<String> fees();

  /// A setting change: either a one-tap confirm, or a pointer to the screen
  /// when the change would weaken privacy or security, or is not available.
  AskCakeToolResult setting(String setting, String value);

  AskCakeToolResult switchWallet(String? name);

  /// The name of another wallet on this device that [message] mentions, if exactly one.
  String? walletMentionedIn(String message);

  /// The accounts inside the open wallet (Monero, Wownero); empty when it has none.
  List<AskCakeAccount> accounts();

  /// Receive with a specific address type or over Lightning.
  AskCakeToolResult receive({String? addressType, bool fresh = false, String? amount});

  /// Screens for the remaining capabilities; null when [tool] has none.
  AskCakeToolResult? open(String tool, Map<String, dynamic> details);
}
