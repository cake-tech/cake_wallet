import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import "package:ed25519_hd_key/ed25519_hd_key.dart";
import 'package:libcrypto/libcrypto.dart';
import 'package:nanodart/nanodart.dart';
import 'package:decimal/decimal.dart';

class NanoUtil {
  // standard:
  static String seedToPrivate(String seed, int index) {
    return NanoKeys.seedToPrivate(seed, index);
  }

  static String seedToAddress(String seed, int index) {
    return NanoAccounts.createAccount(
        NanoAccountType.NANO, privateKeyToPublic(seedToPrivate(seed, index)));
  }

  static String seedToMnemonic(String seed) {
    return NanoMnemomics.seedToMnemonic(seed).join(" ");
  }

  static Future<String> mnemonicToSeed(String mnemonic) async {
    return NanoMnemomics.mnemonicListToSeed(mnemonic.split(' '));
  }

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
  static Future<String> hdMnemonicListToSeed(List<String> words) async {
    // if (words.length != 24) {
    //   throw Exception('Expected a 24-word list, got a ${words.length} list');
    // }
    final Uint8List salt = Uint8List.fromList(utf8.encode('mnemonic'));
    final Pbkdf2 hasher = Pbkdf2(iterations: 2048);
    final String seed = await hasher.sha512(words.join(' '), salt);
    return seed;
  }

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

  static bool isValidBip39Seed(String seed) {
    // Ensure seed is 128 characters long
    if (seed.length != 128) {
      return false;
    }
    // Ensure seed only contains hex characters, 0-9;A-F
    return NanoHelpers.isHexString(seed);
  }

  // number util:

  static const int maxDecimalDigits = 6; // Max digits after decimal
  static BigInt rawPerNano = BigInt.parse("1000000000000000000000000000000");
  static BigInt rawPerNyano = BigInt.parse("1000000000000000000000000");
  static BigInt rawPerBanano = BigInt.parse("100000000000000000000000000000");
  static BigInt rawPerXMR = BigInt.parse("1000000000000");
  static BigInt convertXMRtoNano = BigInt.parse("1000000000000000000");
  // static BigInt convertXMRtoNano = BigInt.parse("1000000000000000000000000000");

  /// Convert raw to ban and return as BigDecimal
  ///
  /// @param raw 100000000000000000000000000000
  /// @return Decimal value 1.000000000000000000000000000000
  ///
  static Decimal getRawAsDecimal(String? raw, BigInt? rawPerCur) {
    rawPerCur ??= rawPerNano;
    final Decimal amount = Decimal.parse(raw.toString());
    final Decimal result = (amount / Decimal.parse(rawPerCur.toString())).toDecimal();
    return result;
  }

  static String truncateDecimal(Decimal input, {int digits = maxDecimalDigits}) {
    Decimal bigger = input.shift(digits);
    bigger = bigger.floor(); // chop off the decimal: 1.059 -> 1.05
    bigger = bigger.shift(-digits);
    return bigger.toString();
  }

  /// Return raw as a NANO amount.
  ///
  /// @param raw 100000000000000000000000000000
  /// @returns 1
  ///
  static String getRawAsUsableString(String? raw, BigInt rawPerCur) {
    final String res =
        truncateDecimal(getRawAsDecimal(raw, rawPerCur), digits: maxDecimalDigits + 9);

    if (raw == null || raw == "0" || raw == "00000000000000000000000000000000") {
      return "0";
    }

    if (!res.contains(".")) {
      return res;
    }

    final String numAmount = res.split(".")[0];
    String decAmount = res.split(".")[1];

    // truncate:
    if (decAmount.length > maxDecimalDigits) {
      decAmount = decAmount.substring(0, maxDecimalDigits);
      // remove trailing zeros:
      decAmount = decAmount.replaceAllMapped(RegExp(r'0+$'), (Match match) => '');
      if (decAmount.isEmpty) {
        return numAmount;
      }
    }

    return "$numAmount.$decAmount";
  }

  static String getRawAccuracy(String? raw, BigInt rawPerCur) {
    final String rawString = getRawAsUsableString(raw, rawPerCur);
    final String rawDecimalString = getRawAsDecimal(raw, rawPerCur).toString();

    if (raw == null || raw.isEmpty || raw == "0") {
      return "";
    }

    if (rawString != rawDecimalString) {
      return "~";
    }
    return "";
  }

  /// Return readable string amount as raw string
  /// @param amount 1.01
  /// @returns  101000000000000000000000000000
  ///
  static String getAmountAsRaw(String amount, BigInt rawPerCur) {
    final Decimal asDecimal = Decimal.parse(amount);
    final Decimal rawDecimal = Decimal.parse(rawPerCur.toString());
    return (asDecimal * rawDecimal).toString();
  }
}
