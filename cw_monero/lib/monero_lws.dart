// import 'dart:convert';
// import 'dart:io';
// import 'dart:isolate';
// import 'package:dio/dio.dart';
// import 'package:dio/io.dart';
// import 'package:cw_core/utils/proxy_wrapper.dart';

// // Get the deno tool at https://github.com/cake-tech/lws-interface-cli-deno.git
// final dio = Dio();
// final isDebug = true;
// // TODO: Pull isDebug from where Cake does it

// // A basic implementation of a Monero LWS client in Dart
// // Technically, addresses and viewkeys aren't strings, but let's go with
// // String for a first pass
// class MoneroLWSClient {
//   String lwsDaemonAddress;
//   String port;

//   // Construct an instance of this class
//   MoneroLWSClient(String lwsDaemonAddress, String port)
//       : lwsDaemonAddress = lwsDaemonAddress,
//         port = port;

//   // deno run --unsafely-ignore-certificate-errors --allow-net index.js --host https://127.0.0.1:8443 login --address 43zxvpcj5Xv9SEkNXbMCG7LPQStHMpFCQCmkmR4u5nzjWwq5Xkv5VmGgYEsHXg4ja2FGRD5wMWbBVMijDTqmmVqm93wHGkg --view_key 7bea1907940afdd480eff7c4bcadb478a0fbb626df9e3ed74ae801e18f53e104 --
//   Future<dynamic> login(
//     String address,
//     String viewKey,
//     bool createAccountIfDoesntExist,
//     bool generated_locally,
//   ) async {
//     return true;
//     //   // TODO: What kind of returns do we get from response?
//     // } on DioException catch (e) {
//     //   if (e.response != null) {
//     //     // print("Received response from lws");
//     //     // print("e.response.statusCode: ${e.response!.statusCode}");
//     //     // switch (e.response!.statusCode) {
//     //     //   case 400:
//     //     //     print('Bad Request: ${e.response!.data}');
//     //     //     break;
//     //     //   case 401:
//     //     //     print('Unauthorized: ${e.response!.data}');
//     //     //     // Potentially refresh token or redirect to login
//     //     //     break;
//     //     //   case 403:
//     //     //     print(
//     //     //       'Either your account awaits approval, or doesn\'t exist on the server',
//     //     //     );
//     //     //     break;
//     //     //   case 422:
//     //     //     print(
//     //     //       'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
//     //     //     );
//     //     //     break;
//     //     //   case 501:
//     //     //     print(
//     //     //       'This server does not allow account creations: ${e.response!.data}',
//     //     //     );
//     //     //     break;
//     //     //   default:
//     //     //     print(
//     //     //       'Unhandled HTTP Error: ${e.response!.statusCode} - ${e.response!.data}',
//     //     //     );
//     //     // }

//     //     // print(e.response!.data);
//     //     // rethrow;
//     //   }
//     // }
//     // throw (Exception('An unexpected error occurred during login'));
//   }

//   //   // Now I need to use dio to craft a request to send to 127.0.0.1

//   // Sends a request to a LWS wallet to scan our address using our public spend key.
//   // TODO: This hasn't been configured and run yet, but we do know that if a query
//   // returns a 501 status, it doesn't accept requests for new wallets.
//   // If it accepts them, will return non-200 status indicating admin approval status
//   Future<Map<String, String>> import_wallet_request(String address, String viewKey) async {
//     // TODO: Finish this function
//     Response response;
//     String Uri = "${lwsDaemonAddress}/login";
//     try {
//       response = await dio.post(
//         Uri,
//         data: {'address': address, 'view_key': viewKey},
//       );
//       if (response.statusCode != 501) {
//         return {"501": "server does not accept requests"};
//       } else if (response.statusCode != 200) {
//         return {response.statusCode.toString(): "account awaiting admin approval"};
//       }
//     } on DioException catch (e) {
//       if (e.response != null) {
//         switch (e.response!.statusCode) {
//           case 400:
//             print('Bad Request: ${e.response!.data}');
//             break;
//           case 401:
//             print('Unauthorized: ${e.response!.data}');
//             // Potentially refresh token or redirect to login
//             break;
//           case 403:
//             print(
//               'Approval: your account is pending approval from the administrator. Try again later',
//             );
//             break;
//           case 422:
//             print(
//               'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
//             );
//             break;
//           case 501:
//             print(
//               'This server does not allow account creations: ${e.response!.data}',
//             );
//             break;
//           default:
//             print(
//               'Unhandled HTTP Error: ${e.response!.statusCode} - ${e.response!.data}',
//             );
//         }
//       }
//     }
//     return {"500": "Undefined HTTP Error"};
//   }

//   // Returns the minimal set of information needed to calculate a wallet balance.
//   // The server cannot calculate when a spend occurs without the spend key,
//   // so a list of candidate spends is returned.
//   // Technically, these aren't strings, but let's go with String for a first pass
//   // deno run --unsafely-ignore-certificate-errors --allow-net index.js --host https://127.0.0.1:8443 get_address_info --address 43zxvpcj5Xv9SEkNXbMCG7LPQStHMpFCQCmkmR4u5nzjWwq5Xkv5VmGgYEsHXg4ja2FGRD5wMWbBVMijDTqmmVqm93wHGkg --view_key 7bea1907940afdd480eff7c4bcadb478a0fbb626df9e3ed74ae801e18f53e104
//   // DANGER: TLS certificate validation is disabled for all hostnames
//   // {
//   //   "locked_funds": "0",
//   //   "total_received": "0",
//   //   "total_sent": "0",
//   //   "scanned_height": 3545781,
//   //   "scanned_block_height": 3545781,
//   //   "start_height": 3542413,
//   //   "transaction_height": 3548229,
//   //   "blockchain_height": 3548229
//   // }
//   // Note that this endpoint may or may not return a rates field with fiat rates
//   // This is dependant on the LWS server configuration.

//   Future<dynamic> get_address_info(String address, String viewKey) async {
//     Response response;
//     try {
//       Uri url = Uri(
//         scheme: 'https',
//         host: lwsDaemonAddress,
//         port: int.parse(port),
//         path: '/get_address_info',
//       );

//       // final body = const {
//       //   "address": address,
//       //   "viewKey": viewKey,
//       //   // "createAccountIfDoesntExist": "true",
//       //   // "generated_locally": "true",
//       // };
//       // response = await dio.post(
//       //   Uri,
//       //   data: {'address': address, 'view_key': viewKey},
//       // );
//       // return response;
//       //final data = json.encode({'address': address, 'view_key': viewKey});
//       // print("Override mitm?");
//       // returns {"locked_funds":"0","total_received":"0","total_sent":"0","scanned_height":3553384,"scanned_block_height":3553384,"start_height":3542413,"transaction_height":3558148,"blockchain_height":3558148}
//       //{"locked_funds":"0","total_received":"0","total_sent":"0","scanned_height":3558387,"scanned_block_height":3558387,"start_height":3558271,"transaction_height":3558387,"blockchain_height":3558387}
//       // {"locked_funds":"0","total_received":"0","total_sent":"0","scanned_height":3558389,"scanned_block_height":3558389,"start_height":3558349,"transaction_height":3558389,"blockchain_height":3558389}
//       final data = json.encode({
//         'address':
//             '47QinGb37esXtgWjw6oHhqUkdyUSRMZiEHsUJUt7X3qZb6o6NuYVEBz2mevwkeinLPT9Zj6amjhsSb37FQ3ycLNdLTZKeTh',
//         'view_key': 'f7afa147a354965aef24163e21687a0acb9fbeedb97b26dfc8885c8661e89f0b'
//       });
//       final response = await ProxyWrapper()
//           .post(clearnetUri: url, body: data, allowMitmMoneroBypassSSLCheck: true);
//       print(response);
//       return response;
//     } on DioException catch (e) {
//       print('Error: $e');
//       rethrow;
//     }
//   }

//   /* 
//   Returns information needed to show transaction history. 
  
//   The server cannot calculate when a spend occurs without the spend key, 
//   so a list of candidate spends is returned. 

//   We will obviously need to do that specific calculation ourselves.
//   Returns a JSON object with following format:   
//   Basically gives us address_information details, then a list of transactions
//   {"total_received":"59969279000","scanned_height":3558755,"scanned_block_height":3558755,"start_height":3558271,"transaction_height":3558755,"blockchain_height":3558755,
  
//   "transactions":
//   [{"id":0,"hash":"6feaa9afc64c61283321353239fe62edf21b17cfd1eac4f48d6580b0cd23f197","timestamp":"2025-12-04T21:00:50Z","total_received":"59969279000","total_sent":"0","fee":"30720000","unlock_time":0,"height":3558393,"payment_id":"4d36cde641ebd9e9","coinbase":false,"mempool":false,"mixin":15,
//   "recipient":{"maj_i":0,"min_i":0}},{"id":1,"hash":"e854cf6090e9a8807ba564da1d55cb1c2299e3a43df9620cb8f257a2bc84e161","timestamp":"2025-12-04T21:42:03Z","total_received":"0","total_sent":"59969279000","fee":"0","unlock_time":0,"height":3558408,"coinbase":false,"mempool":false,"mixin":15,"recipient":{"maj_i":0,"min_i":0},"spent_outputs":[{"amount":"59969279000","key_image":"171ac2d6f526372871f4431732b770a4b3206a92d94b2b17ca8adec0259a0df1","tx_pub_key":"ecc2f54b93d4363e6ff17def4d7cd863a568a9e270117ff4fb0540db1ccb5f51","out_index":1,"mixin":
  
//   */

//   Future<dynamic> get_address_txs(String address, String viewKey) async {
//     Response response;
//     try {
//       Uri url = Uri(
//         scheme: 'https',
//         host: lwsDaemonAddress,
//         port: int.parse(port),
//         path: '/get_address_txs',
//       );

//       address =
//           "45mrNgxwbBmDjGsrYCrvRtJcd5XEW6YKuJojxE9Zr1jHckwTZ1tstti4EaM6GgrAFtZnSks2qYwqNVxPrMjgEL2SMXbfmJw";
//       viewKey = "dc4e4c9509ed0c6def1f6fbfe6ac45f08636e8f2610949e4419d821297aa3a00";
//       // );
//       // // the following account has transaction records we could use
//       final data = json.encode({'address': address, 'view_key': viewKey});
//       final response = await ProxyWrapper()
//           .post(clearnetUri: url, body: data, allowMitmMoneroBypassSSLCheck: true);

//       final jsonData = json.decode(response.body);
//       final transactions = jsonData['transactions'];

//       print(jsonData);
//       return transactions;
//     } catch (e) {
//       print(e);
//       rethrow;
//     }
//   }

//   Future<List<dynamic>> get_unspent_outs(String address, String viewKey) async {
//     Response response;
//     try {
//       Uri url = Uri(
//         scheme: 'https',
//         host: lwsDaemonAddress,
//         port: int.parse(port),
//         path: '/get_unspent_outs',
//       );

//       address =
//           "45mrNgxwbBmDjGsrYCrvRtJcd5XEW6YKuJojxE9Zr1jHckwTZ1tstti4EaM6GgrAFtZnSks2qYwqNVxPrMjgEL2SMXbfmJw";
//       viewKey = "dc4e4c9509ed0c6def1f6fbfe6ac45f08636e8f2610949e4419d821297aa3a00";
//       // );
//       // // the following account has transaction records we could use
//       final data = json.encode({'address': address, 'view_key': viewKey});
//       final response = await ProxyWrapper()
//           .post(clearnetUri: url, body: data, allowMitmMoneroBypassSSLCheck: true);

//       final jsonData = json.decode(response.body);
//       final transactions = jsonData['transactions'];

//       print(jsonData);
//       return transactions;
//     } catch (e) {
//       print(e);
//       rethrow;
//     }
//     //return response;
//     // Response response;
//     //String Uri = "${this.lwsDaemonAddress}/get_address_txs";

//     // try {
//     //   response = await dio.post(
//     //     Uri,
//     //     data: {'address': address, 'view_key': viewKey},
//     //   );
//     //   // Return a response to the invoking function to store wallet transaction
//     //   // data based on what we receive here
//     //   return response;
//     // } on DioException catch (e) {
//     //   if (e.response != null) {
//     //     switch (e.response!.statusCode) {
//     //       case 403:
//     //         print('Your address is not authorised');
//     //         break;
//     //       case 422:
//     //         print(
//     //           'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
//     //         );
//     //         break;
//     //       default:
//     //         print('Error: ${e.response!.data}');
//     //     }
//     //   } else {
//     //     print("Error: Network connection error");
//     //   }
//     //   rethrow;
//     // }
//   }

//   /* Selects random outputs to use in a ring signature of a new transaction. */
//   // * Fetches the accounts unspent outputss. It also returns the fees per byte for calculating network fees.
//   Future<Response> getRandomOuts(String address, String viewKey) async {
//     Response response;
//     String Uri = "${this.lwsDaemonAddress}/get_random_outs";
//     try {
//       response = await dio.post(
//         Uri,
//         data: {'address': address, 'view_key': viewKey},
//       );
//     } on DioException catch (e) {
//       if (e.response != null) {
//         switch (e.response!.statusCode) {
//           // TODO: Add error conditions
//           case 403:
//             print("Forbidden");
//             break;
//           case 422:
//             print(
//               'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
//             );
//             break;
//           default:
//             print('Error: ${e.response!.data}');
//         }
//       } else {
//         // The LWS server is unreachable for some reason
//         print("Error: Network connection error");
//       }
//     } catch (error) {
//       print(error);
//       rethrow;
//     }
//     throw UnimplementedError();
//   }

//   // /* Returns a list of outputs that are received outputs.
//   //  * We need to determine cliesnt-side determine when the output was actually spent, since LWS
//   //  * won’t be able to calculate which have been spent with only an address and a viewkey
//   //  Expect a result like documented in the tests
//   Future<Response> getUnspentOuts(String address, String viewKey) async {
//     // todo: implement this
//     throw UnimplementedError();
//   }
// }

//   // submit_raw_tx(address, viewKey, rawTx) {}