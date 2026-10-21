import "dart:convert";
import "dart:io";

/// Loads a response body captured by tool/fetch_exchange_fixtures.dart, exactly as it came off
/// the wire.
String fixtureBody(String provider, String name) {
  final file = File("test/exchange/fixtures/$provider/$name.json");
  if (!file.existsSync()) {
    throw StateError(
      "missing fixture ${file.path}. run: dart run tool/fetch_exchange_fixtures.dart",
    );
  }
  return file.readAsStringSync();
}

/// The fixture decoded into a map, for asserting a parsed object field by field against the raw
/// json. Comparing against the fixture rather than against literals keeps these tests honest
/// when the fixtures get re-fetched, since almost every value in them moves with the market.
Map<String, dynamic> fixtureMap(String provider, String name) =>
    json.decode(fixtureBody(provider, name)) as Map<String, dynamic>;

/// Same, for the endpoints that answer with a bare array.
List<dynamic> fixtureList(String provider, String name) =>
    json.decode(fixtureBody(provider, name)) as List<dynamic>;
