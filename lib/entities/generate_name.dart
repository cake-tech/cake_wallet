import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

extension StringExtension on String {
  String capitalized() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

Future<String> generateName() async {
  final randomThing = Random();
  final adjectiveStringRaw =
      await rootBundle.loadString('assets/text/Wallet_Adjectives.txt');
  final nounStringRaw =
      await rootBundle.loadString('assets/text/Wallet_Nouns.txt');

  final ls = LineSplitter();
  final adjectives = ls.convert(adjectiveStringRaw);
  final nouns = ls.convert(nounStringRaw);

  final chosenAdjective = adjectives[randomThing.nextInt(adjectives.length)];
  final chosenNoun = nouns[randomThing.nextInt(nouns.length)];
  final returnString =
      chosenAdjective.capitalized() + ' ' + chosenNoun.capitalized();
  return returnString;
}
