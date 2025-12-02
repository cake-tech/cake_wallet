import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

// Get the deno tool at https://github.com/cake-tech/lws-interface-cli-deno.git
final dio = Dio();
final isDebug = true;
// TODO: Pull isDebug from where Cake does it

// Configure Dio to ignore bad certificates
Dio createDio({required String baseUrl, bool trustSelfSigned = false}) {
  // initialize dio
  final dio = Dio()..options.baseUrl = baseUrl;
  // allow self-signed certificate
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => trustSelfSigned;
    return client;
  };
  return dio;
}

// A basic implementation of a Monero LWS client in Dart
// Technically, addresses and viewkeys aren't strings, but let's go with
// String for a first pass
class MoneroLightweightWalletServiceClient {
  String? lwsDaemonAddress;
  Dio dio;

  // Construct an instance of this class
  MoneroLightweightWalletServiceClient({Dio? dio, String? lwsDaemonAddress})
      : lwsDaemonAddress = lwsDaemonAddress ?? "https://127.0.0.1:8443",
        dio = dio ?? Dio();

  // deno run --unsafely-ignore-certificate-errors --allow-net index.js --host https://127.0.0.1:8443 login --address 43zxvpcj5Xv9SEkNXbMCG7LPQStHMpFCQCmkmR4u5nzjWwq5Xkv5VmGgYEsHXg4ja2FGRD5wMWbBVMijDTqmmVqm93wHGkg --view_key 7bea1907940afdd480eff7c4bcadb478a0fbb626df9e3ed74ae801e18f53e104 --
  Future<Response> login(
    String address,
    String viewKey,
    String createAccountIfDoesntExist,
    String generated_locally,
  ) async {
    Response response;
    String Uri = "${lwsDaemonAddress}/login";
    try {
      response = await dio.post(
        Uri,
        data: {
          'address': address,
          'view_key': viewKey,
          'create_account':
              true, // TODO: verify - I think this creates new accounts
          'generated_locally': true,
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            print('Bad Request: ${e.response!.data}');
            break;
          case 401:
            print('Unauthorized: ${e.response!.data}');
            // Potentially refresh token or redirect to login
            break;
          case 403:
            print(
              'Approval: your account is pending approval from the administrator. Try again later',
            );
            break;
          case 422:
            print(
              'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
            );
            break;
          case 501:
            print(
              'This server does not allow account creations: ${e.response!.data}',
            );
            break;
          default:
            print(
              'Unhandled HTTP Error: ${e.response!.statusCode} - ${e.response!.data}',
            );
        }
        rethrow;
      }
    }
    throw (Exception('An unexpected error occurred during login'));
  }

  //   // Now I need to use dio to craft a request to send to 127.0.0.1

  // Sends a request to a LWS wallet to scan our address using our public spend key.
  // TODO: This hasn't been configured and run yet, but we do know that if a query
  // returns a 501 status, it doesn't accept requests for new wallets.
  // If it accepts them, will return non-200 status indicating admin approval status
  Future<bool> import_wallet_request(String address, String viewKey) async {
    // TODO: Finish this function
    Response response;
    String Uri = "${lwsDaemonAddress}/login";
    try {
      response = await dio.post(
        Uri,
        data: {'address': address, 'view_key': viewKey},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            print('Bad Request: ${e.response!.data}');
            break;
          case 401:
            print('Unauthorized: ${e.response!.data}');
            // Potentially refresh token or redirect to login
            break;
          case 403:
            print(
              'Approval: your account is pending approval from the administrator. Try again later',
            );
            break;
          case 422:
            print(
              'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
            );
            break;
          case 501:
            print(
              'This server does not allow account creations: ${e.response!.data}',
            );
            break;
          default:
            print(
              'Unhandled HTTP Error: ${e.response!.statusCode} - ${e.response!.data}',
            );
        }
      }
    }
    return false;
  }

  // Returns the minimal set of information needed to calculate a wallet balance.
  // The server cannot calculate when a spend occurs without the spend key,
  // so a list of candidate spends is returned.
  // Technically, these aren't strings, but let's go with String for a first pass
  // deno run --unsafely-ignore-certificate-errors --allow-net index.js --host https://127.0.0.1:8443 get_address_info --address 43zxvpcj5Xv9SEkNXbMCG7LPQStHMpFCQCmkmR4u5nzjWwq5Xkv5VmGgYEsHXg4ja2FGRD5wMWbBVMijDTqmmVqm93wHGkg --view_key 7bea1907940afdd480eff7c4bcadb478a0fbb626df9e3ed74ae801e18f53e104
  // DANGER: TLS certificate validation is disabled for all hostnames
  // {
  //   "locked_funds": "0",
  //   "total_received": "0",
  //   "total_sent": "0",
  //   "scanned_height": 3545781,
  //   "scanned_block_height": 3545781,
  //   "start_height": 3542413,
  //   "transaction_height": 3548229,
  //   "blockchain_height": 3548229
  // }
  // Note that this endpoint may or may not return a rates field with fiat rates
  // This is dependant on the LWS server configuration.

  Future<Response> get_address_info(String address, String viewKey) async {
    Response response;
    String Uri = "${this.lwsDaemonAddress}/get_address_info";
    try {
      response = await dio.post(
        Uri,
        data: {'address': address, 'view_key': viewKey},
      );
      return response;
    } on DioException catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /* 
  Returns information needed to show transaction history. 
  
  The server cannot calculate when a spend occurs without the spend key, 
  so a list of candidate spends is returned. 

  We will obviously need to do that specific calculation ourselves.
  */
  Future<Response> getAddressTxs(String address, String viewKey) async {
    Response response;
    String Uri = "${this.lwsDaemonAddress}/get_address_txs";
    try {
      response = await dio.post(
        Uri,
        data: {'address': address, 'view_key': viewKey},
      );
      // Return a response to the invoking function to store wallet transaction
      // data based on what we receive here
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 403:
            print('Your address is not authorised');
            break;
          case 422:
            print(
              'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
            );
            break;
          default:
            print('Error: ${e.response!.data}');
        }
      } else {
        print("Error: Network connection error");
      }
      rethrow;
    }
  }

  /* Selects random outputs to use in a ring signature of a new transaction. */
  // * Fetches the accounts unspent outputss. It also returns the fees per byte for calculating network fees.
  Future<Response> getRandomOuts(String address, String viewKey) async {
    Response response;
    String Uri = "${this.lwsDaemonAddress}/get_random_outs";
    try {
      response = await dio.post(
        Uri,
        data: {'address': address, 'view_key': viewKey},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        switch (e.response!.statusCode) {
          // TODO: Add error conditions
          case 403:
            print("Forbidden");
            break;
          case 422:
            print(
              'Error: Make sure your address / viewkey is properly set in your request. ${e.response!.data}',
            );
            break;
          default:
            print('Error: ${e.response!.data}');
        }
      } else {
        // The LWS server is unreachable for some reason
        print("Error: Network connection error");
      }
    } catch (error) {
      print(error);
      rethrow;
    }
    throw UnimplementedError();
  }

  // /* Returns a list of outputs that are received outputs.
  //  * We need to determine cliesnt-side determine when the output was actually spent, since LWS
  //  * won’t be able to calculate which have been spent with only an address and a viewkey
  //  Expect a result like documented in the tests
  Future<Response> getUnspentOuts(String address, String viewKey) async {
    // todo: implement this
    throw UnimplementedError();
  }
}

  // submit_raw_tx(address, viewKey, rawTx) {}