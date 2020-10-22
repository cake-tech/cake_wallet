import 'dart:math';

import 'package:flutter/services.dart';

Future<String> generateName() async {
  final randomThing = Random();
  final adjectiveStringRaw =
  await rootBundle.loadString('assets/text/Wallet_Adjectives.txt');
  final nounStringRaw =
  await rootBundle.loadString('assets/text/Wallet_Nouns.txt');
  final adjectives = List<String>.from(adjectiveStringRaw.split('\n'));
  final nouns = List<String>.from(nounStringRaw.split('\n'));
  final chosenAdjective = adjectives[randomThing.nextInt(adjectives.length)];
  final chosenNoun = nouns[randomThing.nextInt(nouns.length)];
  final returnString = chosenAdjective + ' ' + chosenNoun;

  return returnString;
}