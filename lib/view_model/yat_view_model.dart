import 'package:cake_wallet/store/yat_store.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'dart:convert';
import 'package:cake_wallet/yat/yat_exception.dart';
import 'package:http/http.dart';

part 'yat_view_model.g.dart';

class YatViewModel = YatViewModelBase with _$YatViewModel;

abstract class YatViewModelBase with Store {
  YatViewModelBase({@required this.yatStore});

  final YatStore yatStore;

  Future<void> fetchCartInfo() async {
    const _apiKey = ''; // FIXME

    final url = 'https://api.y.at/cart';

    final response = await get(
        url,
        headers: {
          'Accept': '*/*',
          'Authorization,X-Api-Key': _apiKey
        }
    );

    if (response.statusCode != 200) {
      throw YatException(text: response.body.toString());
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    yatStore.yatAddress = responseJSON[''] as String; // FIXME
  }
}