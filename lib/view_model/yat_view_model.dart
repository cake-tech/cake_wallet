import 'package:cake_wallet/store/yat_store.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'dart:convert';
import 'package:cake_wallet/yat/yat_exception.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

part 'yat_view_model.g.dart';

class YatViewModel = YatViewModelBase with _$YatViewModel;

abstract class YatViewModelBase with Store {
  YatViewModelBase({@required this.yatStore});

  final YatStore yatStore;

  Future<void> fetchCartInfo() async {
    final url = 'https://a.y.at/cart';
    final _apiKey = secrets.yatApiToken;

    final response = await get(
        url,
        headers: {
          'Accept':'*/*',
          'X-Api-Key': _apiKey
        }
    );

    print('RESPONSE = ${response.body.toString()}');

    /*if (response.statusCode != 200) {
      throw YatException(text: response.body.toString());
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    yatStore.yatAddress = responseJSON[''] as String;*/ // FIXME
  }
}