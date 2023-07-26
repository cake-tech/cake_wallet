import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import "package:ed25519_hd_key/ed25519_hd_key.dart";
import 'package:flutter/material.dart';
import 'package:libcrypto/libcrypto.dart';
import 'package:nanodart/nanodart.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:nanodart/nanodart.dart';

class NanoUtil {
  // standard:
  static String seedToPrivate(String seed, int index) {
    // return NanoHelpers.byteToHex(Ed25519Blake2b.derivePrivkey(NanoHelpers.hexToBytes(seed), index)!)
    //     .toUpperCase();
    return NanoKeys.seedToPrivate(seed, index);
  }

  static String seedToAddress(String seed, int index) {
    return NanoAccounts.createAccount(
        NanoAccountType.NANO, privateKeyToPublic(seedToPrivate(seed, index)));
  }

  // static String createPublicKey(String privateKey) {
  //   return NanoHelpers.byteToHex(Ed25519Blake2b.getPubkey(NanoHelpers.hexToBytes(privateKey))!);
  // }

  static String privateKeyToPublic(String privateKey) {
    // return NanoHelpers.byteToHex(Ed25519Blake2b.getPubkey(NanoHelpers.hexToBytes(privateKey))!);
    return NanoKeys.createPublicKey(privateKey);
  }

  static String addressToPublicKey(String publicAddress) {
    return NanoAccounts.extractPublicKey(publicAddress);
  }

  // universal:
  static String privateKeyToAddress(String privateKey) {
    return NanoAccounts.createAccount(NanoAccountType.NANO, privateKeyToPublic(privateKey));
  }

  static String publicKeyToAddress(String publicKey) {
    return NanoAccounts.createAccount(NanoAccountType.NANO, publicKey);
  }

  // standard + hd:
  static bool isValidSeed(String seed) {
    // Ensure seed is 64 or 128 characters long
    if (seed == null || (seed.length != 64 && seed.length != 128)) {
      return false;
    }
    // Ensure seed only contains hex characters, 0-9;A-F
    return NanoHelpers.isHexString(seed);
  }

  // // hd:
  // static Future<String> hdMnemonicListToSeed(List<String> words) async {
  //   // if (words.length != 24) {
  //   //   throw Exception('Expected a 24-word list, got a ${words.length} list');
  //   // }
  //   final Uint8List salt = Uint8List.fromList(utf8.encode('mnemonic'));
  //   final Pbkdf2 hasher = Pbkdf2(iterations: 2048);
  //   final String seed = await hasher.sha512(words.join(' '), salt);
  //   return seed;
  // }

  static Future<String> hdSeedToPrivate(String seed, int index) async {
    List<int> seedBytes = hex.decode(seed);
    KeyData data = await ED25519_HD_KEY.derivePath("m/44'/165'/$index'", seedBytes);
    return hex.encode(data.key);
  }

  static Future<String> hdSeedToAddress(String seed, int index) async {
    return NanoAccounts.createAccount(
        NanoAccountType.NANO, privateKeyToPublic(await hdSeedToPrivate(seed, index)));
  }

  static Future<String> uniSeedToAddress(String seed, int index, String type) {
    if (type == "standard") {
      return Future<String>.value(seedToAddress(seed, index));
    } else if (type == "hd") {
      return hdSeedToAddress(seed, index);
    } else {
      throw Exception('Unknown seed type');
    }
  }

  static Future<String> uniSeedToPrivate(String seed, int index, String type) {
    if (type == "standard") {
      return Future<String>.value(seedToPrivate(seed, index));
    } else if (type == "hd") {
      return hdSeedToPrivate(seed, index);
    } else {
      throw Exception('Unknown seed type');
    }
  }

  // static String hdSeedToPrivate(String seed, int index) {
  //   // List<int> seedBytes = hex.decode(seed);
  //   // KeyData data = await ED25519_HD_KEY.derivePath("m/44'/165'/$index'", seedBytes);
  //   // return hex.encode(data.key);
  //   Chain chain = Chain.seed(hex.encode(utf8.encode(seed)));
  //   ExtendedKey key = chain.forPath("m/44'/165'/$index'");
  //   print(key.privateKeyHex());
  //   return "";
  // }

  // static String hdSeedToAddress(String seed, int index) {
  //   // return NanoAccounts.createAccount(NanoAccountType.NANO, NanoKeys.createPublicKey(seedToPrivate(seed, index)));

  //   return "";
  // }

  static bool isValidBip39Seed(String seed) {
    // Ensure seed is 128 characters long
    if (seed == null || seed.length != 128) {
      return false;
    }
    // Ensure seed only contains hex characters, 0-9;A-F
    return NanoHelpers.isHexString(seed);
  }
}
