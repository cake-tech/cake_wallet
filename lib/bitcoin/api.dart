import 'dart:convert';
import 'package:http/http.dart';

const blockchainInfoBaseURI = 'https://blockchain.info';
const multiAddressURI = '$blockchainInfoBaseURI/multiaddr';

Future<List<String>> fetchAllAddresses({String xpub}) async {
  final uri = '$multiAddressURI?active=$xpub';
  final response = await get(uri);
  final responseJSON = json.decode(response.body) as Map<String, dynamic>;

  print(responseJSON);

  return (responseJSON['addresses'] as List<dynamic>).map((dynamic row) {
    if (row is Map<String, Object>) {
      return row['address'] as String;
    }

    return '';
  }).toList();
}
