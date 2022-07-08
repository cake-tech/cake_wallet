import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CakePhoneProvider {
  final _baseUrl = 'cake-phone.cakewallet.com';

  Future<bool> authenticate(String email) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final body = <String, String>{"email": email};

      final uri = Uri.https(_baseUrl, '/email');
      final response = await http.post(uri, headers: headers, body: json.encode(body));

      if (response.statusCode != 200) {
        debugPrint(response.body);
        return false;
      }

      return true;
    } catch (err) {
      debugPrint(err.toString());
      return false;
    }
  }

  Future<String> verifyEmail({@required String email, @required String code}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final body = <String, String>{
        "code": code,
        "email": email,
      };

      final uri = Uri.https(_baseUrl, '/email/verify');
      final response = await http.post(uri, headers: headers, body: json.encode(body));

      if (response.statusCode != 200) {
        debugPrint(response.body);
        return null;
      }

      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final String token = responseJSON['token'] as String;

      return token;
    } catch (err) {
      debugPrint(err.toString());
      return null;
    }
  }
}
