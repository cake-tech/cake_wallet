import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/ask_cake/ask_cake_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tokenizer =
      AskCakeRouterTokenizer.fromJson(File('assets/ask_cake/router_tokenizer.json').readAsStringSync());
  final fixture = jsonDecode(File('test/ask_cake/router_tokenizer_fixture.json').readAsStringSync())
      as Map<String, dynamic>;

  test('chat prompt matches the template the router was trained with', () {
    expect(askCakeRouterChat('BTC', 'X'), fixture['template']);
  });

  test('token ids match the reference tokenizer on every fixture prompt', () {
    for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
      final ids = tokenizer.encode(askCakeRouterChat(c['coin'] as String, c['text'] as String));
      expect(ids, (c['ids'] as List).cast<int>(), reason: c['text'] as String);
    }
  });

  test('generated ids decode to the reference text', () {
    expect(tokenizer.decode((fixture['decode_ids'] as List).cast<int>()), fixture['decode_text']);
  });

  test('addresses and invoices are masked before routing', () {
    expect(askCakeMaskAddresses('send 0.1 to bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh, thanks'),
        'send 0.1 to [address], thanks');
    expect(askCakeMaskAddresses('pay lnbc20u1p3xnhl2pp5jptserfk'), 'pay [address]');
    expect(askCakeMaskAddresses('send 26 dollars to Bob'), 'send 26 dollars to Bob');
  });
}
