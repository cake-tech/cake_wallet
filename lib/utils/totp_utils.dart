import 'dart:math';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';

//*========================== TOTP 2FA Related Utilities ==========================================

String generateRandomBase32SecretKey(int byteLength) {
  final Random _secureRandom = Random.secure();
  // Generate random bytes
  final randomBytes = Uint8List.fromList(
    List<int>.generate(byteLength, (i) => _secureRandom.nextInt(256)),
  );

  // Encode bytes to base32
  final base32SecretKey = base32.encode(randomBytes);

  return base32SecretKey;
}

String generateOTP({required String secretKey, required int input}) {
  /// base32 decode the secret
  var hmacKey = base32.decode(secretKey);
  
  /// initial the HMAC-SHA1 object
  var hmacSha = Hmac(sha512, hmacKey);

  /// get hmac answer
  var hmac = hmacSha.convert(intToBytelist(input: input)).bytes;

  /// calculate the init offset
  int offset = hmac[hmac.length - 1] & 0xf;

  /// calculate the code
  int code = ((hmac[offset] & 0x7f) << 24 |
      (hmac[offset + 1] & 0xff) << 16 |
      (hmac[offset + 2] & 0xff) << 8 |
      (hmac[offset + 3] & 0xff));

  /// get the initial string code
  var strCode = (code % pow(10, 8)).toString();
  strCode = strCode.padLeft(8, '0');

  return strCode;
}

List<int> intToBytelist({required int input, int padding = 8}) {
  List<int> _result = [];
  var _input = input;
  while (_input != 0) {
    _result.add(_input & 0xff);
    _input >>= padding;
  }
  _result.addAll(List<int>.generate(padding, (_) => 0));
  _result = _result.sublist(0, padding);
  _result = _result.reversed.toList();
  return _result;
}

String totpNow(String secretKey) {
  int _formatTime = timeFormat(time: DateTime.now());
  return generateOTP(input: _formatTime, secretKey: secretKey);
}

int timeFormat({required DateTime time}) {
  final _timeStr = time.millisecondsSinceEpoch.toString();
  final _formatTime = _timeStr.substring(0, _timeStr.length - 3);

  return int.parse(_formatTime) ~/ 30;
}

bool verify({String? otp, DateTime? time, required String secretKey}) {
  if (otp == null) {
    return false;
  }

  var _time = time ?? DateTime.now();
  var _input = timeFormat(time: _time);

  String otpTime = generateOTP(input: _input, secretKey: secretKey);
  return otp == otpTime;
}
