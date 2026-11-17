import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

extension StringExtension on String {
  String capitalized() => "${this[0].toUpperCase()}${this.substring(1)}";
}

Future<List<String>> _loadWords(String path) async =>
    LineSplitter().convert(await rootBundle.loadString(path));

Future<List<String>> _loadAdjectives() => _loadWords("assets/text/Wallet_Adjectives.txt");

Future<List<String>> _loadNouns() => _loadWords("assets/text/Wallet_Nouns.txt");

Future<String> generateName() async {
  final randomThing = Random();
  final adjectives = await _loadAdjectives();
  final nouns = await _loadNouns();

  final chosenAdjective = adjectives[randomThing.nextInt(adjectives.length)].capitalized();
  final chosenNoun = nouns[randomThing.nextInt(nouns.length)].capitalized();
  return "$chosenAdjective $chosenNoun";
}

Future<String> generateWordPassword({int segments = 8}) async {
  final random = Random.secure();
  final words = {...await _loadAdjectives(), ...await _loadNouns()}
      .map((word) => word.trim().toLowerCase())
      .where(RegExp(r"^[a-z]+$").hasMatch)
      .toSet()
      .toList();

  return List.generate(
    segments,
    (_) => "${words[random.nextInt(words.length)].capitalized()}${random.nextInt(10)}",
  ).join("-");
}
