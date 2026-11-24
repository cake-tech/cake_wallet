import 'package:cake_wallet/ask_cake/ask_cake_engine.dart';
import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/ask_cake/ask_cake_guards.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guards were developed and scored in Python (bench/ask_cake/v2); these
/// fixtures hold that implementation's verdict on every test request.
void main() {
  final guards = AskCakeGuards(
      (jsonDecode(File('assets/ask_cake/seed_words.json').readAsStringSync()) as List).cast<String>().toSet());
  final rows = (jsonDecode(File('test/ask_cake/guards_fixture.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  test('pasted secrets are detected exactly as in the reference', () {
    for (final row in rows) {
      expect(guards.secretInput(row['text'] as String), row['secret'], reason: row['text'] as String);
    }
  });

  test('the keyword backstop matches the reference for acting and non-acting capabilities', () {
    const tools = ['general_question', 'change_setting', 'send_payment', 'transactions'];
    for (final row in rows) {
      final text = row['text'] as String;
      expect([for (final tool in tools) AskCakeGuards.backstop(text, tool)], row['backstop'], reason: text);
    }
  });

  test('ungrounded settings become the same question as in the reference', () {
    for (final row in rows) {
      final label = (row['label'] as Map).cast<String, dynamic>();
      final result = AskCakeGuards.groundSetting(row['text'] as String, label);
      final outcome = result.question != null ? 'ask_user' : result.label!['tool'];
      expect(outcome, row['ground'], reason: '${row['text']} / $label');
      expect(result.question?.text, row['question'], reason: row['text'] as String);
    }
  });

  test('explicit durations decide the price range', () {
    for (final row in rows) {
      expect(AskCakeGuards.priceRange(row['text'] as String, '7d'), row['range'], reason: row['text'] as String);
    }
  });

  test('questions about the app are told apart from politely phrased orders', () {
    expect(AskCakeGuards.isQuestion('can BitBox be used on iPhone'), isTrue);
    expect(AskCakeGuards.isQuestion('what does a lightning address look like'), isTrue);
    expect(AskCakeGuards.isQuestion('how many digits is the default PIN'), isTrue);
    expect(AskCakeGuards.isQuestion('can u send bob a quarter litecoin'), isFalse);
    expect(AskCakeGuards.isQuestion('could you turn on tor'), isFalse);
    expect(AskCakeGuards.isQuestion('turn on tor'), isFalse);
  });

  test('questions about the app and about my own activity are recognised', () {
    expect(AskCakeGuards.isAboutTheApp('which swap providers do you support'), isTrue);
    expect(AskCakeGuards.isAboutTheApp('is zcash supported'), isTrue);
    expect(AskCakeGuards.isAboutTheApp('show my swaps'), isFalse);
    expect(AskCakeGuards.isAboutTheApp('which provider handled my swap yesterday'), isFalse);
    expect(AskCakeGuards.isAboutMyActivity('how much did I blow on cake pay'), isTrue);
    expect(AskCakeGuards.isAboutMyActivity('how do I use cake pay'), isFalse);
  });

  test('the newest message decides which setting is meant, not earlier ones', () {
    final result = AskCakeGuards.groundSetting(
        'turn off the swap service \n turn on mweb', {'tool': 'change_setting', 'setting': 'swap_api', 'value': 'on'},
        latest: 'turn on mweb');
    expect(result.label, {'tool': 'change_setting', 'setting': 'mweb', 'value': 'on'});
    // A follow-up that names nothing still leans on the earlier message.
    final followUp = AskCakeGuards.groundSetting(
        'turn on tor \n actually switch it back off', {'tool': 'change_setting', 'setting': 'tor', 'value': 'off'},
        latest: 'actually switch it back off');
    expect(followUp.label?['setting'], 'tor');
  });

  test('the words for a connection mode override a flattened on/off reading', () {
    expect(AskCakeGuards.connectionMode('fetch price data over clearnet', 'off'), 'on');
    expect(AskCakeGuards.connectionMode('get prices over tor', 'on'), 'tor only');
    expect(AskCakeGuards.connectionMode('use swaps without tor', 'tor only'), 'on');
    expect(AskCakeGuards.connectionMode('turn off price data', 'off'), 'off');
    expect(AskCakeGuards.connectionMode('turn on the monitor price feed', 'on'), 'on');
  });

  test('blocking screenshots means protection on, allowing them means off', () {
    expect(AskCakeGuards.screenshotProtection('block screenshots', 'off'), 'on');
    expect(AskCakeGuards.screenshotProtection('stop people taking a screenshot', 'off'), 'on');
    expect(AskCakeGuards.screenshotProtection('allow screenshots please', 'on'), 'off');
    expect(AskCakeGuards.screenshotProtection('turn screenshot protection off', 'off'), 'off');
    expect(AskCakeGuards.screenshotProtection('turn on screenshot protection', 'on'), 'on');
  });

  test('problem reports are told apart from plain requests', () {
    for (final text in [
      'my swap never arrived',
      'What happened with my USDT swap?',
      'was there a refund at some point?',
      "my wallet won't sync",
      'balance is showing zero',
      'why is my transaction still pending',
    ]) {
      expect(AskCakeGuards.isProblem(text), isTrue, reason: text);
    }
    for (final text in ['show my recent swaps', 'what is my balance', 'list my last 5 transactions']) {
      expect(AskCakeGuards.isProblem(text), isFalse, reason: text);
    }
  });

  test('own-wallet and own-sync questions are recognised', () {
    expect(AskCakeGuards.isAboutMyWallets('Do I have a Monero wallet?'), isTrue);
    expect(AskCakeGuards.isAboutMyWallets('how do I create a wallet'), isFalse);
    expect(AskCakeGuards.isAboutMySync("my wallet won't sync"), isTrue);
    expect(AskCakeGuards.isAboutMySync('it is stuck syncing'), isTrue);
    expect(AskCakeGuards.isAboutMySync('how long should syncing normally take'), isFalse);
    expect(AskCakeGuards.isAboutMySync('how do I connect to my own node'), isFalse);
  });

  test('phone self-test slips stay fixed', () {
    expect(AskCakeGuards.isAboutMyWallets('which hardware wallets work with monero'), isFalse);
    expect(AskCakeGuards.isAboutMyWallets('which wallets do I have'), isTrue);
    expect(AskCakeGuards.isRecapRequest('Give me a quick recap of the past 90 days'), isTrue);
    expect(AskCakeGuards.isRecapRequest('give me an overview of how swaps work'), isFalse);
    expect(AskCakeGuards.isAboutFeesPaid('what have network fees cost me this year'), isTrue);
    expect(AskCakeGuards.isAboutFeesPaid('what are fees like right now'), isFalse);
    expect(AskCakeGuards.isAboutMyActivity('was there a refund at some point?'), isTrue);
  });

  test('connection-privacy worries are recognised', () {
    expect(AskCakeGuards.isAboutConnectionPrivacy("my isp snoops, hide where I'm connecting from"), isTrue);
    expect(AskCakeGuards.isAboutConnectionPrivacy('hide my balance'), isFalse);
  });

  test('a summary sentence may not invent a cause', () {
    const data = '- 2026-07-07 150 USDT -> 0.93 XMR via Exolix (failed) swap ID: X1';
    expect(AskCakeEngine.claimsACause('The difference occurred because the swap failed.', data), isTrue);
    expect(AskCakeEngine.claimsACause('Your swap on 2026-07-07 via Exolix failed.', data), isFalse);
  });
}
